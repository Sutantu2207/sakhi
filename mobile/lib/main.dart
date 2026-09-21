import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/journey_provider.dart';
import 'providers/sos_provider.dart';
import 'providers/safety_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SakhiApp());
}

class SakhiApp extends StatelessWidget {
  const SakhiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => JourneyProvider()),
        ChangeNotifierProvider(create: (_) => SOSProvider()),
        ChangeNotifierProvider(create: (_) => SafetyProvider()),
      ],
      child: MaterialApp(
        title: 'SAKHI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
