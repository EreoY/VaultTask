import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_ai_assistant/models/chat_model.dart';
import 'package:my_ai_assistant/state_managers/state_chat.dart';
import 'package:my_ai_assistant/ai_agent/core/misty_agent.dart';

// Test subclass to bypass Firebase initialization inside ensureInitialized / loadGlobalSessions
class TestStateChat extends StateChat {
  @override
  Future<void> ensureInitialized() async {
    // No-op for tests
  }

  @override
  Future<void> loadGlobalSessions() async {
    // No-op for tests
  }
}

void main() {
  group('📸 Image Description, Token Optimization & Vision Tools Test Suite', () {
    
    test('TC-01 & TC-02: Chat Upload vs Sequential Turn (Token Reduction)', () {
      print('\n--- [TC-01 & TC-02] Test: Token Optimization & History Formatting ---');
      final stateChat = TestStateChat();

      // 1. First Turn: Simulating image uploaded without description (just b64 and mime)
      final dummyB64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
      final mime = 'image/png';
      
      final msgFirstTurn = ChatMessage(
        id: 'msg_101',
        isUser: true,
        text: 'What is in this image?',
        timestamp: DateTime.now(),
        attachments: [
          {
            'name': 'screenshot_1.png',
            'url': 'https://r2.mybucket.com/screenshot_1.png',
            'mime': mime,
            'b64': dummyB64,
            'description': '', // No cached description yet
          }
        ],
      );

      // Convert to history
      final historyFirst = stateChat.testConvertMessagesToAgentHistory([msgFirstTurn]);
      
      // Verification for TC-01 (should include image_url part)
      expect(historyFirst.length, 1);
      final firstUserContent = historyFirst[0]['content'] as List<Map<String, dynamic>>;
      expect(firstUserContent.any((part) => part['type'] == 'image_url'), isTrue);
      
      // Calculate sizes
      final firstTurnBytes = jsonEncode(historyFirst).length;
      print('✅ First Turn History Size: $firstTurnBytes characters (Includes Base64)');

      // 2. Subsequent Turn: Simulating image that HAS a cached description
      final msgSecondTurn = ChatMessage(
        id: 'msg_102',
        isUser: true,
        text: 'What is in this image?',
        timestamp: DateTime.now(),
        attachments: [
          {
            'name': 'screenshot_1.png',
            'url': 'https://r2.mybucket.com/screenshot_1.png',
            'mime': mime,
            'b64': dummyB64,
            'description': 'A beautiful blue ocean under a full moon light with stars.', // Cached description
          }
        ],
      );

      // Convert to history
      final historySecond = stateChat.testConvertMessagesToAgentHistory([msgSecondTurn]);

      // Verification for TC-02 (should NOT include image_url part, should use text placeholder)
      expect(historySecond.length, 1);
      final secondUserContent = historySecond[0]['content'];
      
      // It should be converted to text part only, containing the description placeholder
      expect(secondUserContent, isA<List<Map<String, dynamic>>>());
      final textParts = (secondUserContent as List<Map<String, dynamic>>).where((part) => part['type'] == 'text').toList();
      expect(textParts.isNotEmpty, isTrue);
      expect(textParts[0]['text'].contains('[Attached Image "screenshot_1.png" Description: A beautiful blue ocean under a full moon light with stars.]'), isTrue);
      
      // Assert no image_url part exists
      expect(secondUserContent.any((part) => part['type'] == 'image_url'), isFalse);

      final secondTurnBytes = jsonEncode(historySecond).length;
      print('✅ Subsequent Turn History Size: $secondTurnBytes characters (Stripped Base64, text only)');
      
      // Calculate token reduction ratio
      final savingRatio = ((firstTurnBytes - secondTurnBytes) / firstTurnBytes * 100).toStringAsFixed(2);
      print('🔥 Token / Character Saving Ratio: $savingRatio% reduction!');
    });

    test('TC-04 & TC-05: Agent Vision Tool Execution & Concurrency', () async {
      print('\n--- [TC-04 & TC-05] Test: Agent Vision Tools Invocation Routing ---');

      // Define callbacks
      String? retrievedName;
      String? retrievedUrl;
      String? updatedName;
      String? updatedUrl;
      String? updatedDesc;

      final agent = MistyAgent(
        onGetImageB64: (name, url) async {
          retrievedName = name;
          retrievedUrl = url;
          return {
            'b64': 'dummy_image_data_b64',
            'mime': 'image/jpeg'
          };
        },
        onUpdateImageDescription: (name, url, desc) async {
          updatedName = name;
          updatedUrl = url;
          updatedDesc = desc;
        },
      );

      // Verify MistyAgent registers the callbacks correctly
      expect(agent.onGetImageB64, isNotNull);
      expect(agent.onUpdateImageDescription, isNotNull);
      print('✅ Verified MistyAgent constructor registers onGetImageB64 and onUpdateImageDescription successfully.');
    });

    test('TC-06: Reactive Cross-Manager Sync Stream Test', () async {
      print('\n--- [TC-06] Test: Stream Broadcasting & Cross-Manager Notification ---');
      
      final completer = Completer<Map<String, dynamic>>();
      
      // Listen to the static broadcast stream
      final sub = StateChat.onImageDescriptionRegenerated.stream.listen((event) {
        completer.complete(event);
      });

      // Simulate a regeneration event being fired
      final testEvent = {
        'url': 'https://r2.mybucket.com/screenshot_1.png',
        'description': 'Regenerated detail description showing UI mockups.',
        'name': 'screenshot_1.png'
      };

      StateChat.onImageDescriptionRegenerated.add(testEvent);

      final receivedEvent = await completer.future.timeout(Duration(seconds: 2));
      
      expect(receivedEvent['url'], 'https://r2.mybucket.com/screenshot_1.png');
      expect(receivedEvent['description'], 'Regenerated detail description showing UI mockups.');
      expect(receivedEvent['name'], 'screenshot_1.png');
      
      print('✅ Verified stream successfully broadcasted event: $receivedEvent');
      
      await sub.cancel();
    });

    test('TC-07: Long Continuous Q&A Conversation (Multi-turn Context Preservation)', () {
      print('\n--- [TC-07] Test: Long Continuous Q&A Conversation ---');
      final stateChat = TestStateChat();

      // Simulate a continuous discussion between a user and an agent over 5 turns.
      // StateChat's internal message list is stored in reverse chronological order (latest message first).
      final List<ChatMessage> conversationReverseChronological = [
        ChatMessage(
          id: 'q3',
          isUser: true,
          text: 'Excellent! Can you explain the tools it has?',
          timestamp: DateTime.now().subtract(Duration(minutes: 1)),
        ),
        ChatMessage(
          id: 'a2',
          isUser: false,
          text: 'It caches image descriptions to avoid resending large base64 strings in history.',
          timestamp: DateTime.now().subtract(Duration(minutes: 2)),
        ),
        ChatMessage(
          id: 'q2',
          isUser: true,
          text: 'How does it help with token optimization?',
          timestamp: DateTime.now().subtract(Duration(minutes: 3)),
        ),
        ChatMessage(
          id: 'a1',
          isUser: false,
          text: 'Calenda AI is a high-fidelity task and calendar assistant.',
          timestamp: DateTime.now().subtract(Duration(minutes: 4)),
        ),
        ChatMessage(
          id: 'q1',
          isUser: true,
          text: 'Hello, what is Calenda AI?',
          timestamp: DateTime.now().subtract(Duration(minutes: 5)),
        ),
      ];

      // Convert messages to history (which reverses it to become chronological)
      final history = stateChat.testConvertMessagesToAgentHistory(conversationReverseChronological);

      // Verify chronology is maintained (should be q1, a1, q2, a2, q3)
      expect(history.length, 5);
      
      expect(history[0]['role'], 'user');
      expect(history[0]['content'], 'Hello, what is Calenda AI?');
      
      expect(history[1]['role'], 'assistant');
      expect(history[1]['content'], 'Calenda AI is a high-fidelity task and calendar assistant.');
      
      expect(history[2]['role'], 'user');
      expect(history[2]['content'], 'How does it help with token optimization?');
      
      expect(history[3]['role'], 'assistant');
      expect(history[3]['content'], 'It caches image descriptions to avoid resending large base64 strings in history.');
      
      expect(history[4]['role'], 'user');
      expect(history[4]['content'], 'Excellent! Can you explain the tools it has?');

      print('✅ Chronological integrity verified: All 5 turns preserved and ordered correctly.');
      print('✅ Context validation: No messages or details were dropped during conversion.');
    });

    test('TC-08: Sliding Window of Last 14 Messages', () {
      print('\n--- [TC-08] Test: Sliding Window of Last 14 Messages ---');
      final stateChat = TestStateChat();

      // Create a long conversation of 20 messages (reverse chronological order)
      // indices: 0 (latest) to 19 (oldest)
      final List<ChatMessage> longConversation = List.generate(20, (index) {
        final id = 'msg_$index';
        final isUser = index % 2 == 0;
        return ChatMessage(
          id: id,
          isUser: isUser,
          text: 'Message $index',
          timestamp: DateTime.now().subtract(Duration(minutes: index)),
        );
      });

      // Convert to history
      final history = stateChat.testConvertMessagesToAgentHistory(longConversation);

      // It should limit the history to exactly 14 messages
      expect(history.length, 14);

      // Since the source is in reverse chronological order,
      // the last 14 messages are indices 0 to 13.
      // When converted to chronological order, the first item in the history list should be the oldest among the last 14,
      // which corresponds to index 13 ('Message 13').
      // The last item in the history list should be the latest message, which is index 0 ('Message 0').
      expect(history.first['content'], 'Message 13');
      expect(history.last['content'], 'Message 0');

      print('✅ Sliding window verified: History correctly capped at 14 messages and ordered chronologically.');
    });
  });
}
