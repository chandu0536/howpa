import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:howpa_nurse/features/profile/presentation/screens/payment_earnings_screen.dart';

void main() {
  group('PaymentEarningsScreen Layout Tests', () {
    testWidgets('Renders properly on standard screen (360x800)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentEarningsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PaymentEarningsScreen), findsOneWidget);
      expect(find.text('Payment & Earnings'), findsOneWidget);
    });

    testWidgets('Renders properly on narrow screen (320x640)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentEarningsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PaymentEarningsScreen), findsOneWidget);
    });

    testWidgets('Renders properly with large accessibility text scale (1.5x)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: PaymentEarningsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PaymentEarningsScreen), findsOneWidget);
    });
  });
}
