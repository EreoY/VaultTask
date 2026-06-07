const API_KEY = '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';
const MODEL = 'google/gemma-4-26b-a4b-it';

// 1x1 pixel red PNG base64
const dummyB64 = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

async function main() {
  console.log('🚀 Starting Real-world OpenRouter Token Usage Analysis...\n');

  // ==================== TURN 1: Sending Image ====================
  console.log('--- [Turn 1] Sending Image (Base64) to OpenRouter ---');
  const payloadTurn1 = {
    model: MODEL,
    messages: [
      {
        role: 'user',
        content: [
          { type: 'text', text: 'This is a 1x1 pixel image. What is its color? (Answer in 1-2 words)' },
          { type: 'image_url', image_url: { url: dummyB64 } }
        ]
      }
    ]
  };

  try {
    const res1 = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${API_KEY}`,
        'HTTP-Referer': 'https://calenda.flow',
        'X-Title': 'Calenda Flow'
      },
      body: JSON.stringify(payloadTurn1)
    });

    if (!res1.ok) {
      const errorText = await res1.text();
      throw new Error(`OpenRouter Error Turn 1: ${res1.status} - ${errorText}`);
    }

    const data1 = await res1.json();
    const reply1 = data1.choices[0].message.content.trim();
    const usage1 = data1.usage;

    console.log(`🤖 AI Reply: "${reply1}"`);
    if (usage1) {
      console.log(`📊 Usage Turn 1:`);
      console.log(`   - Prompt Tokens: ${usage1.prompt_tokens}`);
      console.log(`   - Completion Tokens: ${usage1.completion_tokens}`);
      console.log(`   - Total Tokens: ${usage1.total_tokens}`);
    } else {
      console.log('⚠️ No usage statistics returned for Turn 1');
    }

    console.log('\n---------------------------------------------------\n');

    // ==================== TURN 2: Stripping Image, Sending Description ====================
    console.log('--- [Turn 2] Sending Cached Description (Base64 Stripped) ---');
    // Simulate subsequent message list in history where the first message has the image stripped into a text placeholder
    const payloadTurn2 = {
      model: MODEL,
      messages: [
        {
          role: 'user',
          content: 'This is a 1x1 pixel image. What is its color? (Answer in 1-2 words)\n\n[Attached Image "red_dot.png" Description: A 1x1 solid red pixel.]'
        },
        {
          role: 'assistant',
          content: reply1
        },
        {
          role: 'user',
          content: 'Based on the description of the image from our previous turn, confirm the color again.'
        }
      ]
    };

    const res2 = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${API_KEY}`,
        'HTTP-Referer': 'https://calenda.flow',
        'X-Title': 'Calenda Flow'
      },
      body: JSON.stringify(payloadTurn2)
    });

    if (!res2.ok) {
      const errorText = await res2.text();
      throw new Error(`OpenRouter Error Turn 2: ${res2.status} - ${errorText}`);
    }

    const data2 = await res2.json();
    const reply2 = data2.choices[0].message.content.trim();
    const usage2 = data2.usage;

    console.log(`🤖 AI Reply: "${reply2}"`);
    if (usage2) {
      console.log(`📊 Usage Turn 2:`);
      console.log(`   - Prompt Tokens: ${usage2.prompt_tokens}`);
      console.log(`   - Completion Tokens: ${usage2.completion_tokens}`);
      console.log(`   - Total Tokens: ${usage2.total_tokens}`);
      
      const promptSavings = (usage1.prompt_tokens + usage1.completion_tokens) - usage2.prompt_tokens;
      console.log(`\n🎉 Prompt Tokens Saved on subsequent turn: ${promptSavings} tokens!`);
    } else {
      console.log('⚠️ No usage statistics returned for Turn 2');
    }

  } catch (err) {
    console.error('❌ Error during execution:', err);
  }
}

main();
