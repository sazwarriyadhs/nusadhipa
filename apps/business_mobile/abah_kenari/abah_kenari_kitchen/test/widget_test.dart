import 'package:flutter_test/flutter_test.dart';
import 'package:abah_kenari_kitchen/main.dart';

void main() {
  testWidgets('RM Abah Kenari Kitchen app smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AbahKenariKitchenApp());

    expect(find.text('RM Abah Kenari'), findsOneWidget);
    expect(find.text('Kitchen Orders'), findsOneWidget);
  });
}
