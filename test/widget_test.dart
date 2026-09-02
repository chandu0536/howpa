// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:howpa_nurse/core/network/api_client.dart';
import 'package:howpa_nurse/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(apiClient: ApiClient()));
    await tester.pump();

    // Verify MyApp is mounted
    expect(find.byType(MyApp), findsOneWidget);

    // Unmount to clean up active timers and controllers
    await tester.pumpWidget(const SizedBox());
  });
}
