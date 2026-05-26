import 'package:flutter/material.dart';
import 'package:la_repe/theme/theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.sports_soccer_rounded,
      iconColor: AppTheme.primaryGold,
      title: '¡Bienvenido a La Repe! 🎉',
      body:
          'La app para completar tu álbum\ndel Mundial 2026 intercambiando\nfiguritas con personas cerca de vos.',
    ),
    _OnboardingPage(
      icon: Icons.bolt_rounded,
      iconColor: AppTheme.primaryGold,
      title: 'Clasificá Rápido ⚡',
      body:
          'Entrá al Swipe y deslizá cada figurita:\n← LA TENGO    LA NECESITO →\nEn 2 minutos tenés todo tu álbum\nclasificado sin esfuerzo.',
    ),
    _OnboardingPage(
      icon: Icons.compare_arrows_rounded,
      iconColor: AppTheme.neededGreen,
      title: 'Matches Automáticos 🤝',
      body:
          'La app detecta automáticamente\nquién tiene lo que necesitás\ny necesita lo que vos tenés.\n¡Sin buscar manualmente!',
    ),
    _OnboardingPage(
      icon: Icons.grid_on_rounded,
      iconColor: AppTheme.primaryGold,
      title: 'Tu Álbum Completo 📚',
      body:
          'En Colección ves todas tus figuritas.\nFiltrá por faltantes, repetidas\no prioridades para organizarte mejor.',
    ),
    _OnboardingPage(
      icon: Icons.emoji_events_rounded,
      iconColor: AppTheme.primaryGold,
      title: '¡Ya sabés todo! 🏆',
      body:
          'Empezá clasificando tus figuritas\nen el Swipe y la app se encarga\nde encontrarte los mejores\nintercambios cerca de vos.',
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onCompleted();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // PageView — fixed height so Dialog doesn't overflow
            SizedBox(
              height: 380,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) =>
                    _PageContent(page: _pages[index]),
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentPage ? 10 : 8,
                  height: i == _currentPage ? 10 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _currentPage
                        ? AppTheme.primaryGold
                        : Colors.white24,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: isLast
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onCompleted,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGold,
                          foregroundColor: AppTheme.background,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '¡EMPEZAR!',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        TextButton(
                          onPressed: widget.onCompleted,
                          child: const Text(
                            'Saltar',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGold,
                            foregroundColor: AppTheme.background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Siguiente →',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Datos de cada paso ───────────────────────────────────────────────────────

class _OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });
}

// ─── Contenido visual de una página ──────────────────────────────────────────

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;

  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 16),
      child: Column(
        children: [
          // Ícono con fondo circular suave
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.iconColor.withValues(alpha: 0.15),
            ),
            child: Icon(page.icon, size: 52, color: page.iconColor),
          ),

          const SizedBox(height: 32),

          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            page.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white60,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
