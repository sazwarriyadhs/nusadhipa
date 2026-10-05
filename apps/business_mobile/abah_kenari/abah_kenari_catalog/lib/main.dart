import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/nusa_dhipa_theme.dart';
import 'features/home/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AbahKenariCatalogApp());
}

class AbahKenariCatalogApp extends StatelessWidget {
  const AbahKenariCatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: NusaDhipaTheme.light,
      home: const CatalogHomePage(),
    );
  }
}
