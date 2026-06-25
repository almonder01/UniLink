import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/unilink_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted || _navigated) return;
    final auth = context.read<AuthProvider>();
    await auth.checkAuthState();
    if (!mounted || _navigated) return;
    // Wait for any pending rebuilds triggered by notifyListeners()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _navigated) return;
      if (auth.isLoggedIn) {
        _goHome();
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  void _goHome() {
    if (_navigated) return;
    _navigated = true;
    // Schedule after frame so notifyListeners rebuilds finish before we leave
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final role = context.read<AuthProvider>().currentUser?.role ?? 'student';
      Navigator.pushReplacementNamed(context, '/$role');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF9333EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -40,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const UnilinkLogo(size: LogoSize.large, color: Colors.white)
                      .animate()
                      .fade(duration: 700.ms)
                      .scale(
                        begin: const Offset(0.6, 0.6),
                        duration: 700.ms,
                        curve: Curves.easeOutBack,
                      ),
                  const SizedBox(height: 20),
                  Text(
                    'Connect. Discover. Belong.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  )
                      .animate()
                      .fade(delay: 500.ms, duration: 600.ms)
                      .slideY(begin: 0.3, delay: 500.ms, duration: 600.ms),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ).animate().fade(delay: 1200.ms, duration: 400.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
