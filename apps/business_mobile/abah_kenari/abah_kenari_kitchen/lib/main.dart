import 'package:flutter/material.dart';
import 'core/theme/nusa_dhipa_theme.dart';
import 'features/home/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const AbahKenariKitchenApp());
}

class AbahKenariKitchenApp extends StatelessWidget {
  const AbahKenariKitchenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RM Abah Kenari - Kitchen',
      theme: NusaDhipaTheme.light(),
      home: const KitchenHomePage(),
    );
  }
}
