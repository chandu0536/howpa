import 'package:flutter_test/flutter_test.dart';
import 'package:howpa_nurse/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HowpaNurseApp());
    expect(find.byType(HowpaNurseApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
