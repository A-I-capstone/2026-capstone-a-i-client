// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:capstone_ai_client/main.dart';
import 'package:capstone_ai_client/viewmodels/chat_view_model.dart';

void main() {
  testWidgets('ChatView rendering smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ],
        child: const CapstoneAiApp(),
      ),
    );

    // Verify that the greeting message is displayed.
    expect(find.textContaining('안녕! 반가워요'), findsOneWidget);
  });
}
