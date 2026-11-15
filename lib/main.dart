import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/models/models.dart';
import 'core/data/repository.dart';
import 'core/data/api_repository.dart';
import 'core/data/demo_repository.dart';
import 'features/auth/login_page.dart';
import 'features/shell/app_shell.dart';
import 'features/client/client_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ObratekApp());
}

class ObratekApp extends StatefulWidget {
  const ObratekApp({super.key});
  @override
  State<ObratekApp> createState() => _ObratekAppState();
}

class _ObratekAppState extends State<ObratekApp> {
  late final ObratekRepository repository =
      AppConfig.demoMode ? DemoRepository() : ApiRepository();
  UserSession? current;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Obratek',
    theme: AppTheme.light(),
    locale: const Locale('es'),
    supportedLocales: const [Locale('es'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: current == null
      ? LoginPage(repository: repository,
          onAuthenticated: (user) => setState(() => current = user))
      : current!.isClient
        ? ClientShell(repository: repository, user: current!,
            onLogout: () { repository.logout(); setState(() => current = null); })
        : AppShell(repository: repository, user: current!,
            onLogout: () { repository.logout(); setState(() => current = null); }),
  );
}
