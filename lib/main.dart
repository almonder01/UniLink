import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/club_follow_provider.dart';
import 'providers/club_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/student/student_shell.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/manager/manager_shell.dart';
import 'widgets/glass_scaffold_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final clubProvider = ClubProvider()..startListening();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ClubFollowProvider>(
          create: (_) => ClubFollowProvider(),
          update: (_, auth, prev) {
            prev!.loadFollowsIfNeeded(auth.currentUser?.id);
            return prev;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, auth, prev) {
            prev!.setUser(auth.currentUser?.id);
            return prev;
          },
        ),
        ChangeNotifierProvider.value(value: clubProvider),
      ],
      child: const UniLinkApp(),
    ),
  );
}

class UniLinkApp extends StatelessWidget {
  const UniLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'UniLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      builder: (context, child) => GlassScaffoldBackground(
        child: child ?? const SizedBox.shrink(),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/student': (_) => const StudentShell(),
        '/admin': (_) => const AdminShell(),
        '/manager': (_) => const ManagerShell(),
      },
    );
  }
}
