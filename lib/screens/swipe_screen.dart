import 'package:flutter/material.dart';
import 'package:la_repe/models/models.dart';
import 'package:la_repe/screens/main_layout.dart';
import 'package:la_repe/services/supabase_service.dart';
import 'package:la_repe/state/album_state.dart';
import 'package:la_repe/theme/app_assets.dart';
import 'package:la_repe/theme/theme.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen>
    with SingleTickerProviderStateMixin {
  bool _isSessionActive = false;
  int _batchSize = 20;

  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _rotateAnim;

  double _dragStartX = 0;
  double _dragStartY = 0;
  double _offsetX    = 0;
  double _offsetY    = 0;

  // null = sin overlay, true = izquierda (completa/rojo), false = derecha (necesito/verde)
  bool? _swipeDirection;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnim  = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _rotateAnim = Tween<double>(begin: 0, end: 0)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─── Sesión ────────────────────────────────────────────────────────────────

  void _startSession(int size, AlbumState state) {
    setState(() {
      _batchSize = size;
      _isSessionActive = true;
      state.startNewSwipeSession(size, unclassifiedOnly: true);
    });
  }

  // ─── Swipe ─────────────────────────────────────────────────────────────────

  /// izquierda = true → completa (rojo)   LA TENGO
  /// izquierda = false → necesito (verde) LA NECESITO
  void _triggerSwipe(bool isLeft, AlbumState state) {
    final action = isLeft ? StickerState.completa : StickerState.necesito;
    final endOffset = isLeft
        ? const Offset(-4.0, 0.4)
        : const Offset(4.0, 0.4);

    setState(() => _swipeDirection = isLeft);

    _slideAnim = Tween<Offset>(
      begin: Offset(_offsetX / 200, _offsetY / 200),
      end: endOffset,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.fastOutSlowIn));

    _rotateAnim = Tween<double>(
      begin: _offsetX / 1000,
      end: endOffset.dx * 0.12,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.fastOutSlowIn));

    if (action == StickerState.completa &&
        state.swipeIndex < state.swipeQueue.length) {
      state.checkQuickMatchFor(state.swipeQueue[state.swipeIndex].id);
    }

    _animController.forward(from: 0).then((_) {
      state.advanceSwipe(action, qty: 1);
      _syncWithSupabase(
        state.swipeQueue[state.swipeIndex - 1],
        action,
        state,
      );
      setState(() {
        _offsetX = 0;
        _offsetY = 0;
        _swipeDirection = null;
      });
      _animController.reset();
    });
  }

  void _syncWithSupabase(Sticker sticker, StickerState action, AlbumState state) {
    final userId     = SupabaseService.currentUserId;
    final figuritaId = SupabaseService.getFiguritaId(sticker.id);
    if (userId == null || figuritaId == null) return;

    SupabaseService.upsertFigurita(
      userId:     userId,
      figuritaId: figuritaId,
      estado:     action == StickerState.completa ? 'completa' : 'necesito',
      cantidad:   1,
    ).catchError((_) {});
  }

  void _navigateToTab(BuildContext context, int tabIndex) {
    context.findAncestorStateOfType<MainLayoutState>()?.switchTab(tabIndex);
  }

  // ─── Fondo estadio ─────────────────────────────────────────────────────────

  Widget _withStadiumBg({required Widget child}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(AppAssets.backgroundStadium, fit: BoxFit.cover),
        Container(color: Colors.black.withValues(alpha: 0.70)),
        child,
      ],
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = AlbumStateProvider.of(context);
    final finished =
        state.swipeIndex >= state.swipeQueue.length &&
        state.swipeQueue.isNotEmpty;

    if (!_isSessionActive) return _buildStartScreen(state);
    if (finished)          return _buildSummaryScreen(state);
    if (state.swipeQueue.isEmpty) return _buildStartScreen(state);

    final current   = state.swipeQueue[state.swipeIndex];
    final progress  = state.swipeIndex / _batchSize;
    final dragging  = _offsetX.abs() > 40;
    final goingLeft = _offsetX < 0;

    // Color del overlay dinámico mientras arrastra
    Color overlayColor = Colors.transparent;
    if (dragging) {
      overlayColor = goingLeft
          ? AppTheme.completedRed.withValues(alpha: (_offsetX.abs() / 200).clamp(0, 0.5))
          : AppTheme.neededGreen.withValues(alpha: (_offsetX.abs() / 200).clamp(0, 0.5));
    }
    if (_swipeDirection != null) {
      overlayColor = _swipeDirection!
          ? AppTheme.completedRed.withValues(alpha: 0.75)
          : AppTheme.neededGreen.withValues(alpha: 0.75);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${state.swipeIndex + 1} / ${state.swipeQueue.length}'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => setState(() => _isSessionActive = false),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: _withStadiumBg(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                // ── Barra de progreso ──────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.surfaceLight,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Labels de dirección ────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DirectionLabel(
                      text: 'LA TENGO',
                      icon: Icons.check_rounded,
                      color: AppTheme.completedRed,
                      visible: dragging && goingLeft,
                    ),
                    _DirectionLabel(
                      text: 'LA NECESITO',
                      icon: Icons.close_rounded,
                      color: AppTheme.neededGreen,
                      visible: dragging && !goingLeft,
                      alignRight: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Stack de tarjetas ──────────────────────────────────────────
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Tarjeta siguiente (fondo)
                      if (state.swipeIndex + 1 < state.swipeQueue.length)
                        Opacity(
                          opacity: 0.4,
                          child: Transform.scale(
                            scale: 0.93,
                            child:
                                _buildCard(state.swipeQueue[state.swipeIndex + 1]),
                          ),
                        ),

                      // Tarjeta actual (con gesture)
                      GestureDetector(
                        onPanStart: (d) {
                          _dragStartX = d.globalPosition.dx;
                          _dragStartY = d.globalPosition.dy;
                        },
                        onPanUpdate: (d) => setState(() {
                          _offsetX = d.globalPosition.dx - _dragStartX;
                          _offsetY = d.globalPosition.dy - _dragStartY;
                        }),
                        onPanEnd: (_) {
                          if (_offsetX < -100) {
                            _triggerSwipe(true, state);  // izquierda = LA TENGO
                          } else if (_offsetX > 100) {
                            _triggerSwipe(false, state); // derecha = LA NECESITO
                          } else {
                            setState(() { _offsetX = 0; _offsetY = 0; });
                          }
                        },
                        child: AnimatedBuilder(
                          animation: _animController,
                          builder: (_, child) {
                            final offset = _animController.isAnimating
                                ? _slideAnim.value * 200
                                : Offset(_offsetX, _offsetY);
                            final angle = _animController.isAnimating
                                ? _rotateAnim.value
                                : _offsetX / 1000;
                            return Transform.translate(
                              offset: offset,
                              child: Transform.rotate(
                                angle: angle,
                                child: Stack(children: [
                                  _buildCard(current),
                                  if (overlayColor != Colors.transparent)
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: Container(color: overlayColor),
                                      ),
                                    ),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Botones ────────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _SwipeButton(
                        icon: Icons.check_rounded,
                        label: 'LA TENGO',
                        color: AppTheme.completedRed,
                        onTap: () => _triggerSwipe(true, state),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SwipeButton(
                        icon: Icons.close_rounded,
                        label: 'LA NECESITO',
                        color: AppTheme.neededGreen,
                        onTap: () => _triggerSwipe(false, state),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Pantallas auxiliares ──────────────────────────────────────────────────

  Widget _buildStartScreen(AlbumState state) {
    final pending = state.allStickers
        .where((s) => !state.userCollection.containsKey(s.id))
        .length;

    return Scaffold(
      body: _withStadiumBg(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, color: AppTheme.primaryGold, size: 60),
                const SizedBox(height: 20),
                const Text(
                  'CLASIFICACIÓN RÁPIDA',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Deslizá cada figurita:\n← LA TENGO   LA NECESITO →',
                  style: TextStyle(fontSize: 14, color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  '$pending figuritas sin clasificar',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                _buildBatchButton('Clasificar 20', 20, state),
                const SizedBox(height: 14),
                _buildBatchButton('Clasificar 50', 50, state),
                const SizedBox(height: 14),
                if (pending > 0)
                  _buildBatchButton('Clasificar todas ($pending)', pending, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBatchButton(String label, int size, AlbumState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _startSession(size, state),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSummaryScreen(AlbumState state) {
    final tengo    = state.swipeSessionCompletas;
    final necesito = state.swipeSessionNecesitadas;
    final total    = tengo + necesito;
    final matches  = state.activeMatches.length;

    return Scaffold(
      body: _withStadiumBg(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.primaryGold.withValues(alpha: 0.4),
                        width: 2),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppTheme.primaryGold, size: 56),
                ),
                const SizedBox(height: 28),
                const Text(
                  '¡Sesión completada!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Clasificaste $total figuritas',
                  style:
                      const TextStyle(fontSize: 16, color: Colors.white60),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SummaryStat(
                      label: 'La tengo',
                      value: '$tengo',
                      color: AppTheme.completedRed,
                    ),
                    const SizedBox(width: 24),
                    _SummaryStat(
                      label: 'La necesito',
                      value: '$necesito',
                      color: AppTheme.neededGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                if (matches > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.neededGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppTheme.neededGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt,
                            color: AppTheme.neededGreen, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '$matches matches disponibles para intercambio',
                          style: const TextStyle(
                            color: AppTheme.neededGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _navigateToTab(context, 3),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neededGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'VER INTERCAMBIOS',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isSessionActive = false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: const Text(
                      'NUEVA SESIÓN',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _navigateToTab(context, 0),
                  child: const Text(
                    'Volver al inicio',
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Sticker sticker) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth   = screenWidth * 0.68;
    final cardHeight  = cardWidth * 1.35;

    return Container(
      width:  cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: AppTheme.shadowCard,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              sticker.number,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryGold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              sticker.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            sticker.teamName,
            style: const TextStyle(fontSize: 13, color: Colors.white38),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return Icon(
                Icons.local_fire_department,
                size: 14,
                color: i < sticker.difficultyIndex
                    ? Colors.orange
                    : Colors.white10,
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets privados ────────────────────────────────────────────────────────

class _DirectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final bool visible;
  final bool alignRight;

  const _DirectionLabel({
    required this.text,
    required this.icon,
    required this.color,
    required this.visible,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 80),
      child: Row(
        children: alignRight
            ? [
                Text(text,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(width: 4),
                Icon(icon, color: color, size: 18),
              ]
            : [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 4),
                Text(text,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
      ),
    );
  }
}

class _SwipeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SwipeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.white54),
        ),
      ],
    );
  }
}
