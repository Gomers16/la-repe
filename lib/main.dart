import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

  try {
    debugPrint('[LaRepe] Iniciando Supabase...');
    await SupabaseService.initialize();
    debugPrint('[LaRepe] Supabase OK');
  } catch (e) {
    debugPrint('[LaRepe] Error Supabase: $e');
  }

  try {
    debugPrint('[LaRepe] Iniciando Hive...');
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(CollectionLocalDatasource.boxName);
    debugPrint('[LaRepe] Hive OK');
  } catch (e) {
    debugPrint('[LaRepe] Error Hive (continuando sin cache): $e');
  }

  final state = AlbumState(
    userRepo: UserRepository(UserLocalDatasource()),
    collectionRepo: CollectionRepository(CollectionLocalDatasource()),
  );

  try {
    debugPrint('[LaRepe] Iniciando AlbumState...');
    await state.initialize();
    debugPrint('[LaRepe] AlbumState OK');

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
  } catch (e) {
    debugPrint('[LaRepe] Error AlbumState (continuando sin datos guardados): $e');
  }

  SupabaseService.preloadFiguritaIds(1).then((_) {
    debugPrint('[Repe] Cache cargado: ${SupabaseService.cacheSize} figuritas');
  }).catchError((_) {
    debugPrint('[Repe] Cache no disponible (sin sesión o sin internet)');
  });

  debugPrint('[LaRepe] Lanzando app...');
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
