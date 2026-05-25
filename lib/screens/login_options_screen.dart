import 'package:flutter/material.dart';
import 'package:la_repe/screens/auth/login_screen.dart';
import 'package:la_repe/screens/auth/register_screen.dart';
import 'package:la_repe/screens/profile_completion_screen.dart';
import 'package:la_repe/services/supabase_service.dart';
import 'package:la_repe/theme/app_assets.dart';
import 'package:la_repe/theme/app_logo.dart';
import 'package:la_repe/theme/theme.dart';
import 'package:la_repe/utils/supabase_errors.dart';

class LoginOptionsScreen extends StatefulWidget {
  const LoginOptionsScreen({super.key});

  @override
  State<LoginOptionsScreen> createState() => _LoginOptionsScreenState();
}

class _LoginOptionsScreenState extends State<LoginOptionsScreen> {
  bool _loadingGoogle = false;

  Future<void> _handleGoogle() async {
    setState(() => _loadingGoogle = true);
    try {
      await SupabaseService.signInWithGoogle();
      // La sesión llega vía deep-link — el onAuthStateChange de main.dart
      // detecta el cambio y actualiza el estado. Navegamos al perfil de
      // completado por si el usuario es nuevo.
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileCompletionScreen(isGoogle: true),
        ),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StadiumBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── AppBar manual con botón atrás ────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: GlassCard(
                    radius: 12,
                    blurSigma: 8,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      color: Colors.white,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // ── Isotipo ──────────────────────────────────────────────────
                Image.asset(
                  AppAssets.isotipo,
                  width: 100,
                  filterQuality: FilterQuality.high,
                ),

                const SizedBox(height: 16),

                // ── Logo horizontal (isotipo + wordmark) ─────────────────────
                Image.asset(
                  AppAssets.logo,
                  width: 220,
                  filterQuality: FilterQuality.high,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Intercambia figuritas.\nCompleta tu álbum.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0x99FFFFFF), // white 60 %
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 2),

                // ── Botón Google ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loadingGoogle ? null : _handleGoogle,
                    icon: _loadingGoogle
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.background),
                          )
                        : const Icon(Icons.g_mobiledata_rounded,
                            size: 30, color: AppTheme.background),
                    label: const Text('Continuar con Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Botón registro manual ────────────────────────────────────
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
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Registro manual',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.background,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // ── Link inicio de sesión ─────────────────────────────────────
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: RichText(
                    text: const TextSpan(
                      text: '¿Ya tienes cuenta? ',
                      style: TextStyle(color: Colors.white60),
                      children: [
                        TextSpan(
                          text: 'Inicia sesión',
                          style: TextStyle(
                            color: AppTheme.primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
