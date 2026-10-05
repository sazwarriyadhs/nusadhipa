import 'package:flutter_test/flutter_test.dart';
import 'package:abah_kenari_catalog/main.dart';

void main() {
  testWidgets(
    'RM Abah Kenari catalog app loads',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const AbahKenariCatalogApp(),
      );

      expect(
        find.text('RM Abah Kenari'),
        findsOneWidget,
      );

      expect(
        find.text('Pilih Meja'),
        findsOneWidget,
      );
    },
  );
}
