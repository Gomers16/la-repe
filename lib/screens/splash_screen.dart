import 'package:flutter/material.dart';
import 'package:la_repe/screens/login_options_screen.dart';
import 'package:la_repe/screens/main_layout.dart';
import 'package:la_repe/state/album_state.dart';
import 'package:la_repe/theme/app_assets.dart';
import 'package:la_repe/theme/app_logo.dart';
import 'package:la_repe/theme/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _routeIfOnboarded());
  }

  void _routeIfOnboarded() {
    if (!mounted) return;
    final isOnboarded = AlbumStateProvider.of(context).isOnboarded;
    if (isOnboarded) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoWidth = (screenWidth * 0.52).clamp(200.0, 320.0);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fondo: foto de estadio ───────────────────────────────────────
          Image.asset(
            AppAssets.backgroundStadium,
            fit: BoxFit.cover,
            // Fallback si el asset no carga (nunca debería ocurrir en producción)
            errorBuilder: (_, _, _) => const DecoratedBox(
              decoration: BoxDecoration(color: AppTheme.background),
            ),
          ),

          // ── Overlay degradado para legibilidad del texto ─────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xD90B0F19), // 85 % — zona del logo
                  Color(0x990B0F19), // 60 % — zona media (estadio visible)
                  Color(0xE60B0F19), // 90 % — zona de botones
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // ── Contenido ────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo real PNG (logo_la_repe.png = isotipo + wordmark)
                  Image.asset(
                    AppAssets.logo,
                    width: logoWidth,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, _, _) {
                      // Si la imagen falla, muestra el widget dibujado
                      return RepeLogoWidget(
                        size: logoWidth * 0.42,
                        showLabel: true,
                        showTagline: true,
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Tagline debajo del logo
                  const Text(
                    'INTERCAMBIA · COMPLETA · COLECCIONA',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0x80FFFFFF),
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 2),

                  // Cards de características
                  Row(
                    children: [
                      _FeatureChip(
                        icon: Icons.compare_arrows_rounded,
                        label: 'Intercambia',
                        color: AppTheme.primaryGold,
                      ),
                      const SizedBox(width: 10),
                      _FeatureChip(
                        icon: Icons.auto_awesome,
                        label: 'Completa',
                        color: AppTheme.neededGreen,
                      ),
                      const SizedBox(width: 10),
                      _FeatureChip(
                        icon: Icons.collections_bookmark_outlined,
                        label: 'Colecciona',
                        color: AppTheme.infoBlue,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Botón CTA con degradado dorado
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppTheme.shadowGold,
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginOptionsScreen(),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'COMENZAR',
                          style: TextStyle(
                            fontFamily: 'Bebas Neue',
                            fontSize: 22,
                            letterSpacing: 2.0,
                            color: AppTheme.background,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'La app de figuritas de Colombia 🇨🇴',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0x60FFFFFF),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        radius: 14,
        accent: color.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
