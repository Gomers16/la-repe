import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:la_repe/data/datasources/collection_local_datasource.dart';
import 'package:la_repe/data/datasources/user_local_datasource.dart';
import 'package:la_repe/data/repositories/collection_repository.dart';
import 'package:la_repe/data/repositories/user_repository.dart';
import 'package:la_repe/screens/splash_screen.dart';
import 'package:la_repe/services/supabase_service.dart';
import 'package:la_repe/state/album_state.dart';
import 'package:la_repe/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase primero — necesario antes de cualquier llamada a la DB
  await SupabaseService.initialize();

  // Hive — almacenamiento local offline
  Hive.init('');
  await Hive.openBox<dynamic>(CollectionLocalDatasource.boxName);

  final state = AlbumState(
    userRepo: UserRepository(UserLocalDatasource()),
    collectionRepo: CollectionRepository(CollectionLocalDatasource()),
  );
  await state.initialize();

  // Si hay sesión activa en Supabase pero el estado local está vacío,
  // restauramos el perfil desde la base de datos remota
  if (state.currentUser == null) {
    final supaUser = await SupabaseService.getCurrentUser();
    if (supaUser != null) {
      state.loginOrRegister(
        supaUser.nombre,
        '',
        '',
        supaUser.whatsapp ?? '',
      );
    }
  }

  // Precarga el mapa numero→ID de figuritas en background para que
  // collection_screen y swipe_screen puedan sincronizar con Supabase sin
  // hacer queries extra por cada tap
  SupabaseService.preloadFiguritaIds(1).then((_) {
    debugPrint('[Repe] Cache cargado: ${SupabaseService.cacheSize} figuritas');
  }).catchError((_) {
    debugPrint('[Repe] Cache no disponible (sin sesión o sin internet)');
  });

  runApp(
    AlbumStateProvider(
      notifier: state,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'La Repe - Sticker Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

