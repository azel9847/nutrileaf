import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'utils/constants.dart';
import 'utils/api_config.dart';
import 'services/settings_service.dart';
import 'screens/splash_screen.dart';
import 'screens/main_shell.dart';
import 'screens/landing_screen.dart';
import 'screens/update_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Lock to portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables from the bundled .env asset.
  // This MUST run before ApiConfig.supabaseUrl is first accessed.
  await dotenv.load(fileName: '.env');

  // Initialize settings service
  final settingsService = SettingsService();
  await settingsService.load();

  // Initialize Supabase
  try {
    if (ApiConfig.supabaseUrl.isEmpty || ApiConfig.supabaseAnonKey.isEmpty) {
      throw Exception(
          'Supabase URL or Key is missing. Ensure you run with --dart-define flags.');
    }
    await Supabase.initialize(
      url: ApiConfig.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: ApiConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    debugPrint('Supabase initialized successfully.');
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
    // We catch the error so the app doesn't crash completely.
  }

  runApp(
    ChangeNotifierProvider.value(
      value: settingsService,
      child: const NutriLeafApp(),
    ),
  );
}

class NutriLeafApp extends StatelessWidget {
  const NutriLeafApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'NutriLeaf',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showSplash = true;
  bool _isRecoveringPassword = false;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    // Keep splash screen for at least 2.5 seconds for branding
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showSplash = false);
    });

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;

      if (event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
          setState(() {
            _isRecoveringPassword = true;
          });
          // Pop any screens overlaying the root
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else if (event == AuthChangeEvent.userUpdated) {
        if (mounted) {
          setState(() {
            _isRecoveringPassword = false;
          });
        }
      } else if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
        if (mounted) {
          setState(() {}); // Rebuild to ensure AuthGate returns MainShell
        }

        // Pop any screens overlaying the root (like LoginScreen/RegisterScreen) to reveal MainShell
        if (event == AuthChangeEvent.signedIn && mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        if (mounted) {
          setState(() {
            _isRecoveringPassword = false;
          }); // Rebuild to ensure AuthGate returns LandingScreen
          // Pop any screens to reveal the LandingScreen
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return const SplashScreen();

    if (_isRecoveringPassword) return const UpdatePasswordScreen();

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return const MainShell();
    }
    return const LandingScreen();
  }
}
