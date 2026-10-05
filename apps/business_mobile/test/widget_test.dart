import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nusa_dhipa_business/features/auth/presentation/login_page.dart';

void main() {
  testWidgets('Login page renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );

    await tester.pump();

    expect(find.text('Selamat datang kembali'), findsOneWidget);

    expect(find.text('Masuk'), findsOneWidget);

    expect(find.byType(TextField), findsNWidgets(2));

    expect(find.byType(FilledButton), findsOneWidget);
  });
}
