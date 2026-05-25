import 'package:flutter/material.dart';
import 'package:la_repe/models/models.dart';
import 'package:la_repe/services/supabase_service.dart';
import 'package:la_repe/services/whatsapp_service.dart';
import 'package:la_repe/state/album_state.dart';
import 'package:la_repe/theme/theme.dart';
import 'package:la_repe/utils/supabase_errors.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<MatchConDetalle>? _supaMatches;
  bool _loadingSupabase = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSupabaseMatches();
  }

  Future<void> _loadSupabaseMatches() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return; // sin sesión, usamos datos locales

    setState(() { _loadingSupabase = true; _error = null; });
    try {
      final matches = await SupabaseService.getMatches(userId);
      if (mounted) setState(() => _supaMatches = matches);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loadingSupabase = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AlbumStateProvider.of(context);

    final hasSupabase = _supaMatches != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intercambios y Matches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSupabaseMatches,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚡ Matches Compatibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasSupabase
                    ? 'Usuarios con los que podés intercambiar figuritas directamente.'
                    : 'Usuarios cercanos con los que puedes cambiar repetidas directamente.',
                style: const TextStyle(fontSize: 13, color: Colors.white38),
              ),
              const SizedBox(height: 20),

              if (_loadingSupabase)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGold,
                    ),
                  ),
                )
              else if (_error != null)
                Expanded(child: _buildError(_error!))
              else if (hasSupabase)
                Expanded(child: _buildSupabaseList(_supaMatches!, state))
              else
                Expanded(child: _buildLocalList(state)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Lista de matches desde Supabase ──────────────────────────────────────

  Widget _buildSupabaseList(List<MatchConDetalle> matches, AlbumState state) {
    if (matches.isEmpty) return _buildEmptyState();
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final m = matches[index];
        final isPerfect = m.porcentaje >= 80;
        return GestureDetector(
          onTap: () => _showSupabaseMatchDialog(context, m, state),
          child: _MatchCard(
            nombre:       m.otroUsuario.nombre,
            porcentaje:   m.porcentaje,
            ciudad:       null,
            distanciaKm:  null,
            daTe:         m.figuritasQueNecesito.length,
            leDas:        m.figuritasQueElNecesita.length,
            isPerfect:    isPerfect,
          ),
        );
      },
    );
  }

  void _showSupabaseMatchDialog(
    BuildContext context,
    MatchConDetalle m,
    AlbumState state,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.2),
              child: Text(
                m.otroUsuario.nombre.isNotEmpty ? m.otroUsuario.nombre[0] : '?',
                style: const TextStyle(
                    color: AppTheme.primaryGold, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.otroUsuario.nombre,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    '${m.porcentaje}% compatibilidad',
                    style: const TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: const Text(
          'Revisá sus repetidas en detalle para coordinar el intercambio por WhatsApp.',
          style: TextStyle(color: Colors.white60, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar',
                style: TextStyle(color: Colors.white38)),
          ),
          if (m.otroUsuario.whatsapp != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                WhatsAppService.openForMultipleTrades(
                  context,
                  phone:      m.otroUsuario.whatsapp!,
                  userName:   m.otroUsuario.nombre,
                  neededIds:  m.figuritasQueNecesito.map((f) => f.numero).toList(),
                  offeredIds: m.figuritasQueElNecesita.map((f) => f.numero).toList(),
                );
              },
              icon: const Icon(Icons.wechat_rounded, size: 18),
              label: const Text('PROPONER CAMBIO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neededGreen,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Lista local (mock) como fallback ─────────────────────────────────────

  Widget _buildLocalList(AlbumState state) {
    final matches = state.activeMatches;
    if (matches.isEmpty) return _buildEmptyState();
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final match = matches[index];
        final isPerfect = match.stickersIHaveHeNeeds.isNotEmpty &&
            match.stickersHeHasINeed.isNotEmpty;
        return GestureDetector(
          onTap: () => _showLocalMatchDialog(context, match),
          child: _MatchCard(
            nombre:      match.userName,
            porcentaje:  match.compatibilityPercent,
            ciudad:      match.city,
            distanciaKm: match.distanceKm,
            daTe:        match.stickersHeHasINeed.length,
            leDas:       match.stickersIHaveHeNeeds.length,
            isPerfect:   isPerfect,
          ),
        );
      },
    );
  }

  void _showLocalMatchDialog(BuildContext context, TradeMatch match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.2),
              child: Text(match.userName[0],
                  style: const TextStyle(
                      color: AppTheme.primaryGold,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(match.userName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${match.distanceKm} km · ${match.city}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white38)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StickerList(
                label:
                    'Él tiene (${match.stickersHeHasINeed.length} que necesitás):',
                ids: match.stickersHeHasINeed,
                color: AppTheme.neededGreen,
                icon: Icons.arrow_downward,
              ),
              const SizedBox(height: 16),
              _StickerList(
                label:
                    'Tú tenés (${match.stickersIHaveHeNeeds.length} que él necesita):',
                ids: match.stickersIHaveHeNeeds,
                color: AppTheme.completedRed,
                icon: Icons.arrow_upward,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              WhatsAppService.openForMultipleTrades(
                context,
                phone:      match.whatsapp,
                userName:   match.userName,
                neededIds:  match.stickersHeHasINeed,
                offeredIds: match.stickersIHaveHeNeeds,
              );
            },
            icon: const Icon(Icons.wechat_rounded, size: 18),
            label: const Text('PROPONER CAMBIO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neededGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Estados vacíos / error ───────────────────────────────────────────────

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.white24),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(color: Colors.white54),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSupabaseMatches,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.compare_arrows_rounded,
                size: 64, color: Colors.white24),
          ),
          const SizedBox(height: 24),
          const Text('Sin matches aún',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white60)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Clasificá más figuritas en la sección Swipe para que el sistema encuentre matches.',
              style: TextStyle(fontSize: 14, color: Colors.white38),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets privados ─────────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  final String nombre;
  final int porcentaje;
  final String? ciudad;
  final double? distanciaKm;
  final int daTe;
  final int leDas;
  final bool isPerfect;

  const _MatchCard({
    required this.nombre,
    required this.porcentaje,
    required this.ciudad,
    required this.distanciaKm,
    required this.daTe,
    required this.leDas,
    required this.isPerfect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPerfect
              ? AppTheme.primaryGold.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          width: isPerfect ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isPerfect
                  ? AppTheme.primaryGold.withValues(alpha: 0.15)
                  : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '$porcentaje%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isPerfect ? AppTheme.primaryGold : AppTheme.neededGreen,
                  ),
                ),
                const Text('Match',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.white38,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        nombre,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPerfect) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.bolt,
                          color: AppTheme.primaryGold, size: 16),
                    ],
                  ],
                ),
                if (ciudad != null || distanciaKm != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (distanciaKm != null) 'A $distanciaKm km',
                      ?ciudad,
                    ].join(' · '),
                    style: const TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.arrow_downward,
                        color: AppTheme.neededGreen, size: 14),
                    const SizedBox(width: 4),
                    Text('Te da: $daTe',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white54)),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_upward,
                        color: AppTheme.completedRed, size: 14),
                    const SizedBox(width: 4),
                    Text('Le das: $leDas',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white54)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white38),
        ],
      ),
    );
  }
}

class _StickerList extends StatelessWidget {
  final String label;
  final List<String> ids;
  final Color color;
  final IconData icon;

  const _StickerList({
    required this.label,
    required this.ids,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white70)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (ids.isEmpty)
          const Text('Ninguna coincidencia directa.',
              style: TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                  fontStyle: FontStyle.italic))
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ids.map((id) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(id,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color)),
              );
            }).toList(),
          ),
      ],
    );
  }
}
