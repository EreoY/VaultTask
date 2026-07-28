import 'package:my_ai_assistant/services/auth_service.dart';
void test() {
  print(AuthService().currentUser?.uid);
}
