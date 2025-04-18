import 'package:flutter/material.dart';
import 'package:devkick/core/constants/app_constants.dart';
import 'package:devkick/core/services/settings_service.dart';
import 'package:devkick/core/theme/app_theme.dart';
import 'package:devkick/features/app/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize settings
  await SettingsService.init();
  
  runApp(const DevKickApp());
}

class DevKickApp extends StatelessWidget {
  const DevKickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
    );
  }
}
