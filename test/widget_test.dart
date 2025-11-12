// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:artihcus_internal_chat/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('renders sign-in screen by default', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ArtihcusApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sign in'), findsWidgets);
    expect(
      find.textContaining('Sign in with your Artihcus email address'),
      findsOneWidget,
    );
  });
}
