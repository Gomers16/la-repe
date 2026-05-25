import 'package:flutter/material.dart';
import 'package:la_repe/screens/login_options_screen.dart';
import 'package:la_repe/services/supabase_service.dart';
import 'package:la_repe/state/album_state.dart';
import 'package:la_repe/theme/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifMatches = true;
  bool _notifMensajes = true;
  bool _showCity = true;
  bool _showWhatsapp = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    try {
      final config = await SupabaseService.getConfigUsuario(userId);
      if (!mounted || config == null) return;
      setState(() {
        _notifMatches  = config.notifMatches;
        _notifMensajes = config.notifMensajes;
        _showCity      = config.mostrarCiudad;
        _showWhatsapp  = config.mostrarWhatsapp;
      });
    } catch (_) {}
  }

  void _updateConfig() {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    SupabaseService.updateConfigUsuario(
      userId:          userId,
      notifMatches:    _notifMatches,
      notifMensajes:   _notifMensajes,
      mostrarCiudad:   _showCity,
      mostrarWhatsapp: _showWhatsapp,
    ).catchError((_) {});
  }

  Future<void> _handleLogout(AlbumState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Cerrar sesión', textAlign: TextAlign.center),
        content: const Text(
          '¿Estás seguro que deseas cerrar sesión? Tu progreso local será reiniciado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.completedRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('CERRAR SESIÓN'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await SupabaseService.signOut();
    } catch (_) {}

    if (!mounted) return;
    state.logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginOptionsScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AlbumStateProvider.of(context);
    final user = state.currentUser;
    final userName = user?.name ?? 'Usuario';
    final userCity = user?.city ?? '';
    final userCountry = user?.country ?? '';
    final locationLabel = [userCity, userCountry]
        .where((s) => s.isNotEmpty)
        .join(', ');

    final completed = state.totalCompletadas;
    final needs     = state.totalNecesito;
    final repeated  = state.totalRepetidas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Avatar
              CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.surfaceLight,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryGold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                userName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),

              Text(
                locationLabel.isNotEmpty ? '📍 $locationLabel' : 'Completá tu perfil',
                style: const TextStyle(fontSize: 14, color: Colors.white38),
              ),

              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Nivel Coleccionista Activo 🔥',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGold,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Stats
              Row(
                children: [
                  Expanded(child: _buildStatItem('Pegadas',  '$completed', AppTheme.primaryGold)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatItem('Faltantes', '$needs',    AppTheme.completedRed)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatItem('Repetidas', '$repeated', AppTheme.repeatedYellow)),
                ],
              ),

              const SizedBox(height: 32),

              // Notifications
              _buildSectionTitle('NOTIFICACIONES'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSwitchRow(
                      title: 'Nuevos intercambios',
                      subtitle: 'Recibe alertas al detectar un match cercano.',
                      value: _notifMatches,
                      onChanged: (val) {
                        setState(() => _notifMatches = val);
                        _updateConfig();
                      },
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    _buildSwitchRow(
                      title: 'Mensajes y solicitudes',
                      subtitle: 'Cuando alguien te escribe o propone un cambio.',
                      value: _notifMensajes,
                      onChanged: (val) {
                        setState(() => _notifMensajes = val);
                        _updateConfig();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Privacy
              _buildSectionTitle('PRIVACIDAD & VISIBILIDAD'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSwitchRow(
                      title: 'Mostrar mi ciudad',
                      subtitle: 'Otros coleccionistas sabrán tu ciudad.',
                      value: _showCity,
                      onChanged: (val) {
                        setState(() => _showCity = val);
                        _updateConfig();
                      },
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    _buildSwitchRow(
                      title: 'Mostrar mi WhatsApp',
                      subtitle: 'Visualización libre de tu contacto para acordar cambios.',
                      value: _showWhatsapp,
                      onChanged: (val) {
                        setState(() => _showWhatsapp = val);
                        _updateConfig();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Logout
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleLogout(state),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('CERRAR SESIÓN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surface,
                    foregroundColor: AppTheme.completedRed,
                    side: const BorderSide(color: Colors.white10),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white30,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white30)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primaryGold,
            activeTrackColor: AppTheme.primaryGold.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white30,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }
}
