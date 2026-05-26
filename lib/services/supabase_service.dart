import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:la_repe/config/supabase_config.dart';
import 'package:la_repe/models/models.dart';
import 'package:la_repe/utils/supabase_errors.dart';

/// Punto de acceso único a Supabase.
/// Todos los métodos son estáticos — el cliente es el singleton Supabase.instance.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get _db => Supabase.instance.client;

  // ─── Inicialización ────────────────────────────────────────────────────────

  /// Llamar en main() antes de runApp().
  static Future<void> initialize() async {
    SupabaseConfig.validate();
    await Supabase.initialize(
      url:     SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// UUID del usuario autenticado actualmente, o null si no hay sesión.
  /// Sincrónico — no hace red call.
  static String? get currentUserId => _db.auth.currentUser?.id;

  // ─── Caché figurita numero → Supabase ID ──────────────────────────────────
  // Se carga una vez en main() para que las pantallas puedan hacer upsert
  // sin una query extra por cada tap.

  static final Map<String, int> _figuritaIdCache = {};

  /// Carga el mapa numero → id de figuritas para un álbum.
  /// Llamar en main() después de initialize() cuando hay sesión activa.
  static Future<void> preloadFiguritaIds(int albumId) async {
    try {
      final figuritas = await getFiguritas(albumId);
      _figuritaIdCache
        ..clear()
        ..addAll({for (final f in figuritas) f.numero: f.id});
    } catch (_) {}
  }

  /// Retorna el Supabase ID de una figurita dado su número (ej: 'COL-001').
  /// Retorna null si el caché no está cargado o el número no existe.
  static int? getFiguritaId(String numero) => _figuritaIdCache[numero];

  static int get cacheSize => _figuritaIdCache.length;

  /// Reestablece la contraseña enviando un link al email.
  static Future<void> resetPassword(String email) async {
    try {
      await _db.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════════════════════════

  /// Registra un nuevo usuario con 3 estrategias de fallback:
  ///
  /// 1. Sin sesión (email confirmation pendiente): el trigger SECURITY DEFINER
  ///    ya creó la fila — retornamos un Usuario mínimo sin tocar la DB.
  ///
  /// 2. Con sesión + trigger exitoso: leemos la fila existente y actualizamos
  ///    los campos extra (whatsapp, ciudad_id) que el trigger no conoce.
  ///
  /// 3. Con sesión + trigger fallido: hacemos upsert manual con JWT activo.
  static Future<Usuario> signUpWithEmail({
    required String email,
    required String password,
    required String nombre,
    String? whatsapp,
    int? ciudadId,
  }) async {
    try {
      final response = await _db.auth.signUp(
        email: email,
        password: password,
        data: {'nombre': nombre, 'provider': 'email'},
      );

      final user = response.user;
      if (user == null) throw const AppException('No se pudo crear la cuenta');

      // ── Caso 1: sin sesión activa (email confirmation requerida) ─────────
      // El trigger on_auth_user_created (SECURITY DEFINER) ya insertó la fila
      // en usuarios. No podemos hacer ops autenticadas aún — retornamos los
      // datos del signUp y el perfil completo se carga en el próximo login.
      final session = _db.auth.currentSession;
      if (session == null) {
        return Usuario(
          id:        user.id,
          nombre:    nombre,
          whatsapp:  whatsapp,
          provider:  'email',
          createdAt: DateTime.now(),
        );
      }

      // ── Caso 2: sesión activa — esperar al trigger y leer ────────────────
      // El trigger se ejecuta en la misma transacción de INSERT en auth.users,
      // pero puede tardar algunos ms en ser visible. Esperamos 500ms.
      await Future.delayed(const Duration(milliseconds: 500));

      final existing = await getUsuario(user.id);
      if (existing != null) {
        // Trigger creó la fila — actualizamos campos que él no pudo inferir
        if (whatsapp != null || ciudadId != null) {
          await updateUsuario(
            userId:   user.id,
            whatsapp: whatsapp,
            ciudadId: ciudadId,
          );
        }
        return existing;
      }

      // ── Caso 3: trigger no corrió — upsert manual con JWT activo ─────────
      await _db.from('usuarios').upsert({
        'id':       user.id,
        'nombre':   nombre,
        'provider': 'email',
        if (whatsapp != null) 'whatsapp':  whatsapp,
        if (ciudadId != null) 'ciudad_id': ciudadId,
      }, onConflict: 'id');

      return await getUsuario(user.id) ??
          Usuario(
            id:        user.id,
            nombre:    nombre,
            whatsapp:  whatsapp,
            provider:  'email',
            createdAt: DateTime.now(),
          );
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Inicia sesión con email y contraseña.
  static Future<Usuario> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _db.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) throw const AppException('Email o contraseña incorrectos');
      final usuario = await getUsuario(user.id);
      if (usuario == null) throw const AppException('Perfil no encontrado. Contactá soporte.');
      return usuario;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Inicia el flujo OAuth con Google.
  /// La sesión se establece vía redirect — escuchá [onAuthStateChange] para
  /// saber cuándo el usuario quedó autenticado.
  /// En Android/iOS configurar el deep-link 'io.supabase.larepe://login-callback/'
  /// en el manifest/Info.plist y en Supabase Dashboard → Auth → URL Configuration.
  static Future<void> signInWithGoogle() async {
    try {
      await _db.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseConfig.redirectUrl,
      );
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  static Future<void> signOut() async {
    try {
      await _db.auth.signOut();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Devuelve el usuario autenticado actual, o null si no hay sesión.
  static Future<Usuario?> getCurrentUser() async {
    final authUser = _db.auth.currentUser;
    if (authUser == null) return null;
    try {
      return await getUsuario(authUser.id);
    } catch (_) {
      return null;
    }
  }

  /// Stream que emite cada vez que cambia el estado de autenticación.
  /// Emite null cuando el usuario cierra sesión.
  static Stream<Usuario?> get onAuthStateChange {
    return _db.auth.onAuthStateChange.asyncMap((event) async {
      final authUser = event.session?.user;
      if (authUser == null) return null;
      try {
        return await getUsuario(authUser.id);
      } catch (_) {
        return null;
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERFIL
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Usuario?> getUsuario(String userId) async {
    try {
      final data = await _db
          .from('usuarios')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return data == null ? null : Usuario.fromJson(data);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  static Future<void> updateUsuario({
    required String userId,
    String? nombre,
    String? foto,
    String? whatsapp,
    int? ciudadId,
    int? paisId,
    String? ciudadActiva,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (nombre != null)       updates['nombre']        = nombre;
      if (foto != null)         updates['foto']           = foto;
      if (whatsapp != null)     updates['whatsapp']       = whatsapp;
      if (ciudadId != null)     updates['ciudad_id']      = ciudadId;
      if (paisId != null)       updates['pais_id']        = paisId;
      if (ciudadActiva != null) updates['ciudad_activa']  = ciudadActiva;
      if (updates.isEmpty)      return;

      await _db.from('usuarios').update(updates).eq('id', userId);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getCiudades({
    int? paisId,
  }) async {
    try {
      final query = _db
          .from('ciudades')
          .select('id, nombre, pais_id');
      final data = paisId != null
          ? await query.eq('pais_id', paisId).order('nombre')
          : await query.order('nombre');
      debugPrint('[Repe] getCiudades pais_id=$paisId → ${(data as List).length} ciudades');
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('[Repe] getCiudades error: $e');
      throw parseSupabaseError(e);
    }
  }

  static Future<ConfigUsuario?> getConfigUsuario(String userId) async {
    try {
      final data = await _db
          .from('config_usuario')
          .select()
          .eq('usuario_id', userId)
          .maybeSingle();
      return data == null ? null : ConfigUsuario.fromJson(data);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  static Future<void> updateConfigUsuario({
    required String userId,
    bool? mostrarCiudad,
    bool? mostrarWhatsapp,
    bool? mostrarPerfil,
    bool? notifMatches,
    bool? notifMensajes,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (mostrarCiudad != null)    updates['mostrar_ciudad']    = mostrarCiudad;
      if (mostrarWhatsapp != null)  updates['mostrar_whatsapp']  = mostrarWhatsapp;
      if (mostrarPerfil != null)    updates['mostrar_perfil']    = mostrarPerfil;
      if (notifMatches != null)     updates['notif_matches']     = notifMatches;
      if (notifMensajes != null)    updates['notif_mensajes']    = notifMensajes;
      if (updates.isEmpty)          return;

      await _db
          .from('config_usuario')
          .update(updates)
          .eq('usuario_id', userId);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COLECCIÓN — la tabla más crítica de la app
  // ═══════════════════════════════════════════════════════════════════════════

  /// Trae todo el inventario del usuario para un álbum dado.
  static Future<List<UsuarioFigurita>> getColeccion(
    String userId,
    int albumId,
  ) async {
    try {
      final data = await _db
          .from('usuarios_figuritas')
          .select('*, figuritas!inner(album_id)')
          .eq('usuario_id', userId)
          .eq('figuritas.album_id', albumId);

      return (data as List)
          .map((row) => UsuarioFigurita.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Marca o actualiza el estado de una figurita para el usuario.
  /// Después de ejecutarse, el trigger de Supabase dispara detectar_matches().
  static Future<void> upsertFigurita({
    required String userId,
    required int figuritaId,
    required String estado, // 'necesito' | 'repetida' | 'completa'
    bool prioridad = false,
    int cantidad = 1,
  }) async {
    try {
      await _db.from('usuarios_figuritas').upsert(
        {
          'usuario_id':  userId,
          'figurita_id': figuritaId,
          'estado':      estado,
          'prioridad':   prioridad,
          'cantidad':    cantidad,
        },
        onConflict: 'usuario_id,figurita_id',
      );
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Marca múltiples figuritas de una sola vez (grilla rápida / bulk swipe).
  static Future<void> upsertFiguritas(
    List<Map<String, dynamic>> figuritas,
  ) async {
    if (figuritas.isEmpty) return;
    try {
      await _db.from('usuarios_figuritas').upsert(
        figuritas,
        onConflict: 'usuario_id,figurita_id',
      );
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Estadísticas rápidas para mostrar en el home.
  static Future<Map<String, int>> getResumenColeccion(
    String userId,
    int albumId,
  ) async {
    try {
      // Una sola query — agrupamos por estado del lado de Supabase
      // usando figuritas como join para filtrar por album_id
      final data = await _db
          .from('usuarios_figuritas')
          .select('estado, figuritas!inner(album_id)')
          .eq('usuario_id', userId)
          .eq('figuritas.album_id', albumId);

      final rows = data as List;
      int completas = 0, necesito = 0, repetidas = 0;

      for (final row in rows) {
        switch (row['estado'] as String?) {
          case 'completa':
            completas++;
          case 'necesito':
            necesito++;
          case 'repetida':
            repetidas++;
        }
      }

      // Total de figuritas en el álbum
      final totalRows = await _db
          .from('figuritas')
          .select('id')
          .eq('album_id', albumId);

      return {
        'completas':  completas,
        'necesito':   necesito,
        'repetidas':  repetidas,
        'total':      (totalRows as List).length,
      };
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CATÁLOGO DE FIGURITAS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<Figurita>> getFiguritas(int albumId) async {
    try {
      final data = await _db
          .from('figuritas')
          .select()
          .eq('album_id', albumId)
          .order('numero');
      return (data as List)
          .map((row) => Figurita.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  static Future<List<Figurita>> getFiguritasPorEquipo(
    int albumId,
    int equipoId,
  ) async {
    try {
      final data = await _db
          .from('figuritas')
          .select()
          .eq('album_id', albumId)
          .eq('equipo_id', equipoId)
          .order('numero');
      return (data as List)
          .map((row) => Figurita.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  static Future<List<Figurita>> getFiguritasPorCategoria(
    int albumId,
    int categoriaId,
  ) async {
    try {
      final data = await _db
          .from('figuritas')
          .select()
          .eq('album_id', albumId)
          .eq('categoria_id', categoriaId)
          .order('numero');
      return (data as List)
          .map((row) => Figurita.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Devuelve TODO el catálogo del álbum con el estado del usuario superpuesto.
  /// Figuritas que el usuario no marcó aparecen con estado == null.
  static Future<List<FiguritaConEstado>> getFiguritasConEstado(
    String userId,
    int albumId,
  ) async {
    try {
      // Dos queries paralelas, merge en Dart — más predecible que un LEFT JOIN en PostgREST
      final results = await Future.wait([
        getFiguritas(albumId),
        getColeccion(userId, albumId),
      ]);

      final catalogo   = results[0] as List<Figurita>;
      final coleccion  = results[1] as List<UsuarioFigurita>;
      final colMap     = {for (final uf in coleccion) uf.figuritaId: uf};

      return catalogo.map((f) {
        final uf = colMap[f.id];
        return FiguritaConEstado(
          figurita:  f,
          estado:    uf?.estado,
          prioridad: uf?.prioridad ?? false,
          cantidad:  uf?.cantidad  ?? 0,
        );
      }).toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MATCHES
  // El trigger de Supabase los calcula automáticamente.
  // Acá solo los leemos.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Devuelve los matches del usuario ordenados por porcentaje de compatibilidad.
  /// Si [ciudadActiva] no es null, filtra matches cuyo otro usuario esté en esa ciudad.
  /// Requiere que la columna ciudad_activa exista en la tabla usuarios (migración TAREA 1).
  static Future<List<MatchConDetalle>> getMatches(
    String userId, {
    String? ciudadActiva,
  }) async {
    // Query base sin filtro de ciudad (siempre funciona)
    Future<List> baseQuery() => _db
        .from('matches')
        .select(
          'id, porcentaje, estado, usuario_match_id, '
          'otro_usuario:usuario_match_id(id, nombre, foto, whatsapp)',
        )
        .eq('usuario_id', userId)
        .eq('estado', 'activo')
        .order('porcentaje', ascending: false)
        .limit(50);

    try {
      List data;
      if (ciudadActiva != null) {
        try {
          // Requiere columna ciudad_activa en usuarios (ALTER TABLE de TAREA 1)
          data = await _db
              .from('matches')
              .select(
                'id, porcentaje, estado, usuario_match_id, '
                'otro_usuario:usuario_match_id!inner(id, nombre, foto, whatsapp)',
              )
              .eq('usuario_id', userId)
              .eq('estado', 'activo')
              .eq('otro_usuario.ciudad_activa', ciudadActiva)
              .order('porcentaje', ascending: false)
              .limit(50);
        } catch (_) {
          // Fallback: columna ciudad_activa todavía no existe en Supabase
          debugPrint('[Repe] getMatches: filtro ciudad_activa no disponible, retornando todos');
          data = await baseQuery();
        }
      } else {
        data = await baseQuery();
      }

      return data
          .map((row) => MatchConDetalle.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERCAMBIOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea una propuesta de intercambio con su detalle de figuritas.
  static Future<Intercambio> crearIntercambio({
    required String userId,
    required String receptorId,
    required List<int> figuritasOfrece,   // IDs de figuritas que el usuario ofrece
    required List<int> figuritasNecesita, // IDs de figuritas que el usuario quiere
    String? mensaje,
  }) async {
    try {
      // 1. Crear el intercambio
      final intercambioData = await _db
          .from('intercambios')
          .insert({
            'usuario_envia_id':  userId,
            'usuario_recibe_id': receptorId,
            'mensaje':           mensaje,
          })
          .select()
          .single();

      final intercambio = Intercambio.fromJson(intercambioData);

      // 2. Insertar el detalle (qué ofrece y qué necesita)
      final detalles = <Map<String, dynamic>>[
        for (final id in figuritasOfrece)
          {'intercambio_id': intercambio.id, 'figurita_id': id, 'tipo': 'ofrece'},
        for (final id in figuritasNecesita)
          {'intercambio_id': intercambio.id, 'figurita_id': id, 'tipo': 'recibe'},
      ];

      if (detalles.isNotEmpty) {
        await _db.from('intercambios_detalle').insert(detalles);
      }

      return intercambio;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Acepta o rechaza un intercambio.
  /// Si se acepta, transfiere las figuritas entre ambos usuarios y marca como completado.
  static Future<void> responderIntercambio(
    int intercambioId,
    bool aceptado,
  ) async {
    try {
      final nuevoEstado = aceptado ? 'aceptado' : 'rechazado';

      await _db
          .from('intercambios')
          .update({'estado': nuevoEstado})
          .eq('id', intercambioId);

      if (!aceptado) return;

      // Traer el intercambio con detalle para transferir figuritas
      final raw = await _db
          .from('intercambios')
          .select('usuario_envia_id, usuario_recibe_id, intercambios_detalle(*)')
          .eq('id', intercambioId)
          .single();

      final enviaId  = raw['usuario_envia_id']  as String;
      final recibeId = raw['usuario_recibe_id'] as String;
      final detalles = (raw['intercambios_detalle'] as List<dynamic>?) ?? [];

      for (final d in detalles) {
        final figId = d['figurita_id'] as int;
        final tipo  = d['tipo'] as String;

        if (tipo == 'ofrece') {
          // El que envía la ofrece → el que recibe la obtiene
          await upsertFigurita(
            userId: recibeId, figuritaId: figId, estado: 'completa',
          );
          await _decreaseCantidad(userId: enviaId, figuritaId: figId);
        } else {
          // El que recibe la ofrece → el que envía la obtiene
          await upsertFigurita(
            userId: enviaId, figuritaId: figId, estado: 'completa',
          );
          await _decreaseCantidad(userId: recibeId, figuritaId: figId);
        }
      }

      await _db
          .from('intercambios')
          .update({'estado': 'completado'})
          .eq('id', intercambioId);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Devuelve todos los intercambios (enviados y recibidos) del usuario.
  static Future<List<IntercambioConDetalle>> getIntercambios(
    String userId,
  ) async {
    try {
      final data = await _db
          .from('intercambios')
          .select(
            '*, '
            'usuario_envia:usuario_envia_id(id, nombre, foto, whatsapp), '
            'usuario_recibe:usuario_recibe_id(id, nombre, foto, whatsapp), '
            'intercambios_detalle(*, figurita:figurita_id(id, numero, nombre, imagen))',
          )
          .or('usuario_envia_id.eq.$userId,usuario_recibe_id.eq.$userId')
          .order('created_at', ascending: false);

      return (data as List)
          .map((row) =>
              IntercambioConDetalle.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REALTIME — streams en vivo via Supabase Realtime
  // ═══════════════════════════════════════════════════════════════════════════

  /// Emite la lista actualizada de matches cada vez que cambia en Supabase.
  static Stream<List<Match>> watchMatches(String userId) {
    return _db
        .from('matches')
        .stream(primaryKey: ['id'])
        .eq('usuario_id', userId)
        .order('porcentaje', ascending: false)
        .map((rows) => rows.map(Match.fromJson).toList());
  }

  /// Emite nuevas notificaciones del usuario en tiempo real.
  static Stream<List<Notificacion>> watchNotificaciones(String userId) {
    return _db
        .from('notificaciones')
        .stream(primaryKey: ['id'])
        .eq('usuario_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Notificacion.fromJson).toList());
  }

  /// Emite mensajes del chat de un intercambio en tiempo real.
  static Stream<List<Chat>> watchChat(int intercambioId) {
    return _db
        .from('chats')
        .stream(primaryKey: ['id'])
        .eq('intercambio_id', intercambioId)
        .order('created_at')
        .map((rows) => rows.map(Chat.fromJson).toList());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTIFICACIONES
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<Notificacion>> getNotificaciones(String userId) async {
    try {
      final data = await _db
          .from('notificaciones')
          .select()
          .eq('usuario_id', userId)
          .order('created_at', ascending: false)
          .limit(100);

      return (data as List)
          .map((row) => Notificacion.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  static Future<void> marcarLeida(int notificacionId) async {
    try {
      await _db
          .from('notificaciones')
          .update({'leida': true})
          .eq('id', notificacionId);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  static Future<void> marcarTodasLeidas(String userId) async {
    try {
      await _db
          .from('notificaciones')
          .update({'leida': true})
          .eq('usuario_id', userId)
          .eq('leida', false);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SINCRONIZACIÓN HIVE ↔ SUPABASE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sincroniza la colección local (Hive) con Supabase.
  ///
  /// REQUISITO: [localCollection] usa como clave el campo `numero` de la figurita
  /// (ej: 'COL-001', 'ARG-001') que debe coincidir exactamente con la columna
  /// `numero` en la tabla `figuritas` de Supabase.
  ///
  /// Retorna el estado actualizado desde Supabase para que el caller
  /// pueda decidir si refresca Hive.
  static Future<List<UsuarioFigurita>> syncColeccionLocal({
    required String userId,
    required int albumId,
    required Map<String, UserSticker> localCollection,
  }) async {
    try {
      // 1. Obtener el catálogo completo para construir el mapa numero → id
      final figuritas  = await getFiguritas(albumId);
      final numeroToId = <String, int>{
        for (final f in figuritas) f.numero: f.id,
      };

      // 2. Construir los rows a upsert desde Hive
      final rows = <Map<String, dynamic>>[];
      for (final entry in localCollection.entries) {
        final figuritaId = numeroToId[entry.key];
        if (figuritaId == null) continue; // no existe en el catálogo Supabase aún

        rows.add({
          'usuario_id':  userId,
          'figurita_id': figuritaId,
          'estado':      _stickerStateToEstado(entry.value.state),
          'prioridad':   entry.value.isPriority,
          'cantidad':    entry.value.quantity,
        });
      }

      // 3. Push local → Supabase (local gana en conflicto)
      if (rows.isNotEmpty) {
        await _db.from('usuarios_figuritas').upsert(
          rows,
          onConflict: 'usuario_id,figurita_id',
        );
      }

      // 4. Pull Supabase → devolver estado actualizado
      return await getColeccion(userId, albumId);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS PRIVADOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Traduce el enum local StickerState al string que usa Supabase.
  static String _stickerStateToEstado(StickerState state) {
    switch (state) {
      case StickerState.necesito: return 'necesito';
      case StickerState.repetida: return 'repetida';
      case StickerState.completa: return 'completa';
    }
  }

  /// Reduce en 1 la cantidad de una figurita repetida del usuario.
  /// Si la cantidad llega a 0, la elimina de la colección.
  static Future<void> _decreaseCantidad({
    required String userId,
    required int figuritaId,
  }) async {
    final data = await _db
        .from('usuarios_figuritas')
        .select('id, cantidad')
        .eq('usuario_id', userId)
        .eq('figurita_id', figuritaId)
        .maybeSingle();

    if (data == null) return;

    final cantidad = (data['cantidad'] as int? ?? 1) - 1;

    if (cantidad <= 0) {
      await _db
          .from('usuarios_figuritas')
          .delete()
          .eq('id', data['id'] as int);
    } else {
      await _db
          .from('usuarios_figuritas')
          .update({'cantidad': cantidad})
          .eq('id', data['id'] as int);
    }
  }
}
