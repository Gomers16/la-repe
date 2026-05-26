import 'package:flutter/material.dart';
import 'package:la_repe/screens/main_layout.dart';
import 'package:la_repe/services/supabase_service.dart';
import 'package:la_repe/services/whatsapp_service.dart';
import 'package:la_repe/state/album_state.dart';
import 'package:la_repe/models/models.dart';
import 'package:la_repe/theme/app_assets.dart';
import 'package:la_repe/theme/app_logo.dart';
import 'package:la_repe/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _totalFiguritas;
  int? _supaMatchCount;
  String _ciudadActiva = '';

  static const _cities = [
    'Ibagué', 'Bogotá', 'Cali', 'Medellín',
    'Barranquilla', 'Cartagena', 'Bucaramanga', 'Otra ciudad',
  ];

  @override
  void initState() {
    super.initState();
    _loadCiudadActiva().then((_) => _loadSupabaseData());
  }

  Future<void> _loadCiudadActiva() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('ciudad_activa');
    if (saved != null && mounted) setState(() => _ciudadActiva = saved);
  }

  Future<void> _loadSupabaseData() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    final ciudad = _ciudadActiva.isNotEmpty ? _ciudadActiva : null;
    try {
      final results = await Future.wait([
        SupabaseService.getResumenColeccion(userId, 1),
        SupabaseService.getMatches(userId, ciudadActiva: ciudad),
      ]);
      if (!mounted) return;
      final resumen = results[0] as Map<String, int>;
      final matches = results[1] as List<MatchConDetalle>;
      setState(() {
        _totalFiguritas = resumen['total'];
        _supaMatchCount = matches.length;
      });
    } catch (_) {}
  }

  Future<void> _setCiudadActiva(String ciudad) async {
    setState(() => _ciudadActiva = ciudad);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ciudad_activa', ciudad);
    final userId = SupabaseService.currentUserId;
    if (userId != null) {
      SupabaseService.updateUsuario(userId: userId, ciudadActiva: ciudad)
          .catchError((_) {});
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Buscando intercambios en $ciudad'),
          backgroundColor: AppTheme.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    _loadSupabaseData();
  }

  void _showCitySelector(BuildContext context, String currentCity) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              '¿Dónde querés intercambiar hoy?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ..._cities.map((city) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Icon(
                  currentCity == city
                      ? Icons.location_on_rounded
                      : Icons.location_city_outlined,
                  size: 20,
                  color: currentCity == city ? AppTheme.primaryGold : Colors.white38,
                ),
                title: Text(
                  city,
                  style: TextStyle(
                    color: currentCity == city ? AppTheme.primaryGold : Colors.white70,
                    fontWeight: currentCity == city ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: currentCity == city
                    ? const Icon(Icons.check_rounded,
                        color: AppTheme.primaryGold, size: 18)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _setCiudadActiva(city);
                },
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _navigateToTab(BuildContext context, int tabIndex) {
    context.findAncestorStateOfType<MainLayoutState>()?.switchTab(tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    final state = AlbumStateProvider.of(context);
    final user = state.currentUser;
    final userName = user?.name ?? 'Coleccionista';

    final progress     = state.progressPercentage;
    final completed    = state.totalCompletadas;
    final needs        = state.totalNecesito;
    final repeated     = state.totalRepetidas;
    final matchesCount = _supaMatchCount ?? state.activeMatches.length;
    final albumTotal   = _totalFiguritas ?? 980;

    final topMatch = state.activeMatches.isNotEmpty ? state.activeMatches.first : null;
    final effectiveCity = _ciudadActiva.isNotEmpty ? _ciudadActiva : (user?.city ?? 'Ibagué');

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: isotipo PNG + wordmark
                      const _HomeHeaderLogo(),
                      const SizedBox(height: 6),
                      Text(
                        '¿Qué más, ${userName.split(' ')[0]}? 👋',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  // Avatar perfil
                  GestureDetector(
                    onTap: () => _navigateToTab(context, 4),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 21,
                        backgroundColor: AppTheme.surfaceLight,
                        child: Text(
                          _initials(userName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showCitySelector(context, effectiveCity),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 14, color: AppTheme.primaryGold),
                    const SizedBox(width: 4),
                    Text(
                      'Intercambiando en: $effectiveCity',
                      style: const TextStyle(fontSize: 13, color: Colors.white54),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16, color: Colors.white38),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ── STATS ROW ─────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Faltantes',
                      count: '$needs',
                      color: AppTheme.completedRed,
                      onTap: () => _navigateToTab(context, 1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: 'Repetidas',
                      count: '$repeated',
                      color: AppTheme.primaryGold,
                      onTap: () => _navigateToTab(context, 1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: 'Intercambios',
                      count: '$matchesCount',
                      color: AppTheme.neededGreen,
                      onTap: () => _navigateToTab(context, 3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ── PROGRESO ─────────────────────────────────────────────────
              GlassCard(
                padding: const EdgeInsets.all(20),
                radius: 20,
                accent: const Color(0x33F59E0B), // gold 20 %
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.emoji_events_outlined,
                                color: AppTheme.primaryGold, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'TU PROGRESO',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${progress.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: const Color(0x26FFFFFF), // white 15 %
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pegadas: $completed / $albumTotal',
                          style: const TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                        const Text(
                          'Meta: 100%',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ── MATCH DESTACADO ──────────────────────────────────────────
              if (topMatch != null &&
                  topMatch.stickersHeHasINeed.isNotEmpty &&
                  topMatch.stickersIHaveHeNeeds.isNotEmpty) ...[
                _buildPerfectMatchHighlight(context, topMatch, state),
                const SizedBox(height: 22),
              ],

              // ── ACCIONES PRINCIPALES ─────────────────────────────────────
              const _SectionLabel(text: 'ACCESOS PRINCIPALES'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SportCard(
                      accentColor: AppTheme.primaryGold,
                      onTap: () => _navigateToTab(context, 1),
                      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                      child: const _ActionCardContent(
                        title: 'Mis Repetidas',
                        icon: Icons.compare_arrows_rounded,
                        color: AppTheme.primaryGold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SportCard(
                      accentColor: AppTheme.completedRed,
                      onTap: () => _navigateToTab(context, 1),
                      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                      child: const _ActionCardContent(
                        title: 'Me Falta',
                        icon: Icons.assignment_late_outlined,
                        color: AppTheme.completedRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SportCard(
                      accentColor: AppTheme.infoBlue,
                      onTap: () => _navigateToTab(context, 2),
                      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                      child: const _ActionCardContent(
                        title: 'Clasificación Rápida',
                        icon: Icons.bolt,
                        color: AppTheme.infoBlue,
                        badge: '⚡ Swipe',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SportCard(
                      accentColor: AppTheme.eventGreen,
                      onTap: () => _showEventsDialog(context),
                      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                      child: const _ActionCardContent(
                        title: 'Eventos Locales',
                        icon: Icons.map_outlined,
                        color: AppTheme.eventGreen,
                        badge: '2 cerca',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // ── ACCESOS RÁPIDOS ───────────────────────────────────────────
              const _SectionLabel(text: 'ACCESOS RÁPIDOS'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickButton(
                    icon: Icons.search,
                    label: 'Buscar',
                    onTap: () => _navigateToTab(context, 1),
                  ),
                  _QuickButton(
                    icon: Icons.checklist_rtl_rounded,
                    label: 'Checklist',
                    onTap: () => _navigateToTab(context, 1),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Widget _buildPerfectMatchHighlight(
      BuildContext context, TradeMatch match, AlbumState state) {
    final myNeedId    = match.stickersHeHasINeed.first;
    final myOfferId   = match.stickersIHaveHeNeeds.first;
    final myNeedSticker  = state.allStickers.firstWhere((s) => s.id == myNeedId);
    final myOfferSticker = state.allStickers.firstWhere((s) => s.id == myOfferId);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x803B82F6), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x333B82F6), // infoBlue 20 %
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt, color: AppTheme.primaryGold, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'INTERCAMBIO PERFECTO',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: Color(0x2610B981), // neededGreen 15 %
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Text(
                  '${match.compatibilityPercent}% match',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neededGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${match.userName} · ${match.distanceKm} km · ${match.city}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ÉL TIENE',
                        style: TextStyle(fontSize: 10, color: Colors.white38)),
                    const SizedBox(height: 4),
                    Text(
                      '#${myNeedSticker.number} ${myNeedSticker.name}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neededGreen,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.swap_horiz, color: Colors.white24, size: 26),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TÚ OFRECES',
                        style: TextStyle(fontSize: 10, color: Colors.white38)),
                    const SizedBox(height: 4),
                    Text(
                      '#${myOfferSticker.number} ${myOfferSticker.name}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.shadowGold,
              ),
              child: ElevatedButton(
                onPressed: () => WhatsAppService.openForSingleTrade(
                  context,
                  phone: match.whatsapp,
                  userName: match.userName,
                  neededNumber: myNeedSticker.number,
                  offeredNumber: myOfferSticker.number,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'PROPONER POR WHATSAPP 💬',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    color: AppTheme.background,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEventsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: AppTheme.eventGreen),
            SizedBox(width: 8),
            Text('Cambiatones en Ibagué'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEventItem(
              title: 'Cambiatón Multicentro',
              detail: 'Domingo 3:00 PM · Pasillo Principal',
              distance: 'A 1.2 km de ti',
            ),
            const Divider(color: Colors.white10),
            _buildEventItem(
              title: 'Reunión de Coleccionistas La Estación',
              detail: 'Sábado 4:00 PM · Plazoleta de Comidas',
              distance: 'A 2.5 km de ti',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: AppTheme.primaryGold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem({
    required String title,
    required String detail,
    required String distance,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
          const SizedBox(height: 4),
          Text(detail, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 2),
          Text(distance,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.primaryGold,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets privados de HomeScreen
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.12), AppTheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCardContent extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String? badge;

  const _ActionCardContent({
    required this.title,
    required this.icon,
    required this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(height: 3),
          Text(
            badge!,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppTheme.primaryGold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: const Border.fromBorderSide(
              BorderSide(color: Color(0x1AFFFFFF)),
            ),
            boxShadow: AppTheme.shadowCard,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: Colors.white60),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header: logo horizontal real (isotipo + wordmark en una sola imagen)
// ─────────────────────────────────────────────────────────────────────────────
class _HomeHeaderLogo extends StatelessWidget {
  const _HomeHeaderLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.logo,
      height: 28,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
