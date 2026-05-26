import 'package:flutter/material.dart';
import 'package:la_repe/theme/theme.dart';

// ── Public model ──────────────────────────────────────────────────────────────

class SpotlightStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  // When highlighting a single tab inside a bar widget (e.g. BottomNavigationBar)
  final int? tabIndex;
  final int? tabCount;

  const SpotlightStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.tabIndex,
    this.tabCount,
  });
}

// ── Entry point ───────────────────────────────────────────────────────────────

void showSpotlight({
  required BuildContext context,
  required List<SpotlightStep> steps,
  required VoidCallback onCompleted,
}) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _SpotlightWidget(
      steps: steps,
      onCompleted: () {
        entry.remove();
        onCompleted();
      },
    ),
  );
  Overlay.of(context).insert(entry);
}

// ── Spotlight widget ──────────────────────────────────────────────────────────

class _SpotlightWidget extends StatefulWidget {
  final List<SpotlightStep> steps;
  final VoidCallback onCompleted;

  const _SpotlightWidget({required this.steps, required this.onCompleted});

  @override
  State<_SpotlightWidget> createState() => _SpotlightWidgetState();
}

class _SpotlightWidgetState extends State<_SpotlightWidget> {
  int _step = 0;
  Rect _fromRect = Rect.zero;
  Rect _toRect = Rect.zero;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final r = _rectFor(widget.steps[0]);
      setState(() {
        _fromRect = r;
        _toRect = r;
        _ready = true;
      });
    });
  }

  Rect _rectFor(SpotlightStep step) {
    try {
      final ctx = step.targetKey.currentContext;
      if (ctx == null) return Rect.zero;
      final box = ctx.findRenderObject() as RenderBox;
      final pos = box.localToGlobal(Offset.zero);

      if (step.tabIndex != null && step.tabCount != null) {
        final tabW = box.size.width / step.tabCount!;
        return Rect.fromLTWH(
          pos.dx + step.tabIndex! * tabW,
          pos.dy,
          tabW,
          box.size.height,
        ).inflate(4);
      }

      return (pos & box.size).inflate(8);
    } catch (_) {
      return Rect.zero;
    }
  }

  void _advance() {
    final next = _step + 1;
    if (next >= widget.steps.length) {
      widget.onCompleted();
      return;
    }
    final newRect = _rectFor(widget.steps[next]);
    setState(() {
      _fromRect = _toRect;
      _toRect = newRect;
      _step = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();

    final screenSize = MediaQuery.of(context).size;
    final step = widget.steps[_step];
    final isLast = _step == widget.steps.length - 1;

    return TweenAnimationBuilder<Rect?>(
      tween: RectTween(begin: _fromRect, end: _toRect),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      builder: (ctx, animRect, _) {
        final rect = animRect ?? _toRect;

        // Tooltip positioning: prefer below, fallback above
        const tooltipH = 155.0;
        const gap = 14.0;
        const margin = 16.0;
        final showBelow = rect.bottom + gap + tooltipH < screenSize.height - 24;
        final rawTop = showBelow ? rect.bottom + gap : rect.top - gap - tooltipH;
        final top = rawTop.clamp(24.0, screenSize.height - tooltipH - 24);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {}, // absorb background taps
          child: Stack(
            children: [
              // Dark overlay with transparent spotlight hole
              Positioned.fill(
                child: CustomPaint(
                  painter: _SpotlightPainter(
                    highlightRect: rect,
                    radius: 14,
                  ),
                ),
              ),
              // Tooltip card
              Positioned(
                left: margin,
                right: margin,
                top: top,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _TooltipCard(
                    key: ValueKey(_step),
                    step: step,
                    isLast: isLast,
                    current: _step + 1,
                    total: widget.steps.length,
                    onNext: _advance,
                    onSkip: widget.onCompleted,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── CustomPainter: dark bg + transparent hole ─────────────────────────────────

class _SpotlightPainter extends CustomPainter {
  final Rect highlightRect;
  final double radius;

  const _SpotlightPainter({required this.highlightRect, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    // 75% black overlay with even-odd hole
    final overlay = Paint()..color = const Color(0xBF000000);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
          RRect.fromRectAndRadius(highlightRect, Radius.circular(radius)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlay);

    // Gold border around the highlighted element
    if (highlightRect != Rect.zero) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(highlightRect, Radius.circular(radius)),
        Paint()
          ..color = const Color(0xCCF59E0B) // gold 80%
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.highlightRect != highlightRect;
}

// ── Tooltip card ──────────────────────────────────────────────────────────────

class _TooltipCard extends StatelessWidget {
  final SpotlightStep step;
  final bool isLast;
  final int current;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _TooltipCard({
    super.key,
    required this.step,
    required this.isLast,
    required this.current,
    required this.total,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x80F59E0B)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                ),
                Text(
                  '$current / $total',
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              step.description,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Saltar',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: AppTheme.background,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isLast ? '¡Listo! 🏆' : 'Siguiente →',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
