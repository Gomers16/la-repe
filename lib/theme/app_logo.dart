import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:la_repe/theme/app_assets.dart';
import 'package:la_repe/theme/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RepeLogoWidget
// Logo completo con isotipo circular + wordmark "LA REPE" + tagline opcional.
// Dibujado 100 % con widgets Flutter — no requiere archivos de imagen.
// ─────────────────────────────────────────────────────────────────────────────
class RepeLogoWidget extends StatelessWidget {
  final double size;
  final bool showLabel;
  final bool showTagline;

  const RepeLogoWidget({
    super.key,
    this.size = 100,
    this.showLabel = true,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Isotipo circular ─────────────────────────────────────────────────
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [AppTheme.surfaceLight, AppTheme.surface],
              center: Alignment(-0.3, -0.3),
              radius: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x52F59E0B), // gold ~32 %
                blurRadius: 32,
                spreadRadius: 6,
              ),
              BoxShadow(
                color: Color(0x66000000), // black 40 %
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: const Color(0x99F59E0B), // gold 60 %
              width: 2.5,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.compare_arrows_rounded,
              size: size * 0.52,
              color: AppTheme.primaryGold,
            ),
          ),
        ),

        // ── Wordmark ─────────────────────────────────────────────────────────
        if (showLabel) ...[
          SizedBox(height: size * 0.14),
          Text(
            'LA REPE',
            style: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: size * 0.36,
              color: Colors.white,
              letterSpacing: size * 0.05,
            ),
          ),
        ],

        // ── Tagline ──────────────────────────────────────────────────────────
        if (showLabel && showTagline) ...[
          SizedBox(height: size * 0.04),
          Text(
            'INTERCAMBIA · COMPLETA · COLECCIONA',
            style: TextStyle(
              fontSize: size * 0.095,
              color: const Color(0x80FFFFFF), // white 50 %
              letterSpacing: size * 0.018,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RepeBadge
// Versión compacta para AppBar y headers de pantalla.
// ─────────────────────────────────────────────────────────────────────────────
class RepeBadge extends StatelessWidget {
  final double size;

  const RepeBadge({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryGold,
            boxShadow: [
              BoxShadow(
                color: Color(0x33F59E0B), // gold 20 %
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.compare_arrows_rounded,
              size: size * 0.60,
              color: AppTheme.background,
            ),
          ),
        ),
        SizedBox(width: size * 0.30),
        Text(
          'LA REPE',
          style: TextStyle(
            fontFamily: 'Bebas Neue',
            fontSize: size * 0.78,
            color: Colors.white,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StadiumBackground
// Fondo oscuro con líneas de campo de fútbol dibujadas con CustomPainter.
// Apilado debajo del contenido de la pantalla.
// ─────────────────────────────────────────────────────────────────────────────
class StadiumBackground extends StatelessWidget {
  final Widget child;
  final double overlayOpacity;

  const StadiumBackground({
    super.key,
    required this.child,
    this.overlayOpacity = 0.75,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(AppAssets.backgroundStadium, fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: overlayOpacity),
          ),
        ),
        child,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GlassCard
// Tarjeta con efecto glassmorphism: blur + superficie translúcida + borde sutil.
// ─────────────────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? accent;
  final double blurSigma;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.accent,
    this.blurSigma = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: AppTheme.glassCard(radius: radius, accent: accent),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SportCard
// Tarjeta estilo deportivo: gradiente diagonal + acento de color izquierdo.
// ─────────────────────────────────────────────────────────────────────────────
class SportCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color accentColor;
  final VoidCallback? onTap;

  const SportCard({
    super.key,
    required this.child,
    required this.accentColor,
    this.padding,
    this.radius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.10),
              AppTheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x29000000), // black 16 %
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            children: [
              // Acento izquierdo
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
