import 'dart:async';
import 'package:flutter/material.dart';
import 'package:la_repe/screens/home_screen.dart';
import 'package:la_repe/screens/collection_screen.dart';
import 'package:la_repe/screens/swipe_screen.dart';
import 'package:la_repe/screens/matches_screen.dart';
import 'package:la_repe/screens/profile_screen.dart';
import 'package:la_repe/models/models.dart';
import 'package:la_repe/services/supabase_service.dart';
import 'package:la_repe/state/album_state.dart';

class MainLayout extends StatefulWidget {
  final int initialTab;

  const MainLayout({super.key, this.initialTab = 0});

  @override
  State<MainLayout> createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> with WidgetsBindingObserver {
  late int _currentIndex;

  int _matchCount  = 0;
  int _unreadCount = 0;

  StreamSubscription<List<Match>>?        _matchSub;
  StreamSubscription<List<Notificacion>>? _notifSub;

  final List<Widget> _screens = const [
    HomeScreen(),
    CollectionScreen(),
    SwipeScreen(),
    MatchesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    WidgetsBinding.instance.addObserver(this);
    _startRealtime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _matchSub?.cancel();
    _notifSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncOnResume();
    }
  }

  void _startRealtime() {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    _matchSub = SupabaseService.watchMatches(userId).listen((matches) {
      if (!mounted) return;
      setState(() => _matchCount = matches.length);
    });

    _notifSub = SupabaseService.watchNotificaciones(userId).listen((notifs) {
      if (!mounted) return;
      setState(() => _unreadCount = notifs.where((n) => !n.leida).length);
    });
  }

  void _syncOnResume() {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    final localCollection = AlbumStateProvider.of(context).userCollection;
    SupabaseService.syncColeccionLocal(
      userId:          userId,
      albumId:         1,
      localCollection: localCollection,
    ).catchError((_) => <UsuarioFigurita>[]);
  }

  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_on_outlined),
            activeIcon: Icon(Icons.grid_on),
            label: 'Colección',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bolt_outlined),
            activeIcon: Icon(Icons.bolt),
            label: 'Swipe',
          ),
          BottomNavigationBarItem(
            icon: _BadgeIcon(
              icon: Icons.compare_arrows_rounded,
              count: _matchCount,
            ),
            activeIcon: _BadgeIcon(
              icon: Icons.compare_arrows_rounded,
              count: _matchCount,
              active: true,
            ),
            label: 'Intercambios',
          ),
          BottomNavigationBarItem(
            icon: _BadgeIcon(
              icon: Icons.person_outline,
              count: _unreadCount,
            ),
            activeIcon: _BadgeIcon(
              icon: Icons.person,
              count: _unreadCount,
              active: true,
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool active;

  const _BadgeIcon({
    required this.icon,
    required this.count,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Icon(icon);
    }
    return Badge(
      label: Text('$count', style: const TextStyle(fontSize: 10)),
      child: Icon(icon),
    );
  }
}
