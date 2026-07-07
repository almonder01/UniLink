import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'splash/splash_logo_mark.dart';
import 'splash/splash_progress_line.dart';
import 'splash/splash_signal_bars.dart';

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
    await Future.delayed(const Duration(milliseconds: 3400));
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final shortestSide = width < height ? width : height;
          final horizontalPadding = (width * 0.08).clamp(20.0, 34.0);
          final contentWidth =
              (width - (horizontalPadding * 2)).clamp(240.0, 340.0);
          final logoSize = (shortestSide * 0.34).clamp(92.0, 132.0);
          final titleSize = (shortestSide * 0.09).clamp(27.0, 34.0);
          final subtitleSize = (shortestSide * 0.04).clamp(13.0, 15.0);
          final topGap = (height * 0.035).clamp(16.0, 24.0);
          final actionGap = (height * 0.048).clamp(22.0, 34.0);

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4F46E5),
                  Color(0xFF7C3AED),
                  Color(0xFF9333EA),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding.toDouble(),
                    vertical: 18,
                  ),
                  physics: const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: contentWidth.toDouble(),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SplashLogoMark(size: logoSize.toDouble())
                            .animate()
                            .fade(duration: 650.ms)
                            .scale(
                              begin: const Offset(0.76, 0.76),
                              duration: 750.ms,
                              curve: Curves.easeOutBack,
                            ),
                        SizedBox(height: topGap.toDouble()),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'UniLink',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.96),
                              fontSize: titleSize.toDouble(),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        )
                            .animate()
                            .fade(delay: 300.ms, duration: 450.ms)
                            .slideY(
                              begin: 0.18,
                              delay: 300.ms,
                              duration: 450.ms,
                            ),
                        const SizedBox(height: 8),
                        Text(
                          'Connect. Discover. Belong.',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: subtitleSize.toDouble(),
                            fontWeight: FontWeight.w600,
                          ),
                        )
                            .animate()
                            .fade(delay: 520.ms, duration: 500.ms)
                            .slideY(
                              begin: 0.16,
                              delay: 520.ms,
                              duration: 500.ms,
                            ),
                        SizedBox(height: actionGap.toDouble()),
                        SplashSignalBars(scale: (logoSize / 132).toDouble())
                            .animate()
                            .fade(delay: 850.ms, duration: 350.ms),
                        SizedBox(
                          height: (height * 0.025)
                              .clamp(12.0, 18.0)
                              .toDouble(),
                        ),
                        SplashProgressLine(
                          width: (contentWidth * 0.56).clamp(132.0, 168.0),
                        )
                            .animate()
                            .fade(delay: 1050.ms, duration: 350.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
