enum StickerRarity {
  comun,
  especial,
  paralelaBronce,
  paralelaPlata,
  paralelaOro,
}

enum StickerState {
  necesito,
  repetida,
  completa,
}

class Sticker {

  final String id;
  final String number;
  final String name;
  final String teamName;
  final String categoryName;
  final StickerRarity rarity;
  final int difficultyIndex;

  const Sticker({

    required this.id,

    required this.number,

    required this.name,

    required this.teamName,

    required this.categoryName,

    this.rarity = StickerRarity.comun,

    this.difficultyIndex = 1,

  });

  bool get isCocaCola {

    return id.startsWith('CC');

  }

  bool get isExtraSticker {

    return id.startsWith('EXTRA');

  }

  bool get affectsProgressBar {

    return !isCocaCola &&
           !isExtraSticker;

  }

  String get rarityLabel {

    switch (rarity) {

      case StickerRarity.comun:

        return 'Común';

      case StickerRarity.especial:

        return 'Especial';

      case StickerRarity.paralelaBronce:

        return 'Bronce';

      case StickerRarity.paralelaPlata:

        return 'Plata';

      case StickerRarity.paralelaOro:

        return 'Oro';

    }

  }

}

class UserSticker {

  final String stickerId;

  StickerState state;

  bool isPriority;

  int quantity;

  UserSticker({

    required this.stickerId,

    required this.state,

    this.isPriority = false,

    this.quantity = 1,

  });

}

class TradeMatch {

  final String id;

  final String userName;

  final String whatsapp;

  final String city;

  final double distanceKm;

  final int compatibilityPercent;

  final List<String> stickersIHaveHeNeeds;

  final List<String> stickersHeHasINeed;

  const TradeMatch({

    required this.id,

    required this.userName,

    required this.whatsapp,

    required this.city,

    required this.distanceKm,

    required this.compatibilityPercent,

    required this.stickersIHaveHeNeeds,

    required this.stickersHeHasINeed,

  });

}

class AppUser {

  final String name;

  final String city;

  final String country;

  final String whatsapp;

  const AppUser({

    required this.name,

    required this.city,

    required this.country,

    required this.whatsapp,

  });

}


// ═══════════════════════════════════════════════════════════════════════════
// MODELOS SUPABASE
// Mapean directamente a las tablas del schema.sql.
// Conviven con los modelos Hive de arriba durante la migración.
// ═══════════════════════════════════════════════════════════════════════════

class Usuario {
  final String id;
  final String nombre;
  final String? foto;
  final int? ciudadId;
  final int? paisId;
  final String? whatsapp;
  final String provider;
  final String estado;
  final DateTime createdAt;

  const Usuario({
    required this.id,
    required this.nombre,
    this.foto,
    this.ciudadId,
    this.paisId,
    this.whatsapp,
    this.provider = 'email',
    this.estado = 'activo',
    required this.createdAt,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? '',
        foto: json['foto'] as String?,
        ciudadId: json['ciudad_id'] as int?,
        paisId: json['pais_id'] as int?,
        whatsapp: json['whatsapp'] as String?,
        provider: json['provider'] as String? ?? 'email',
        estado: json['estado'] as String? ?? 'activo',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        if (foto != null) 'foto': foto,
        if (ciudadId != null) 'ciudad_id': ciudadId,
        if (paisId != null) 'pais_id': paisId,
        if (whatsapp != null) 'whatsapp': whatsapp,
        'provider': provider,
        'estado': estado,
        'created_at': createdAt.toIso8601String(),
      };
}

class ConfigUsuario {
  final int id;
  final String usuarioId;
  final bool mostrarCiudad;
  final bool mostrarWhatsapp;
  final bool mostrarPerfil;
  final bool notifMatches;
  final bool notifMensajes;

  const ConfigUsuario({
    required this.id,
    required this.usuarioId,
    this.mostrarCiudad = true,
    this.mostrarWhatsapp = true,
    this.mostrarPerfil = true,
    this.notifMatches = true,
    this.notifMensajes = true,
  });

  factory ConfigUsuario.fromJson(Map<String, dynamic> json) => ConfigUsuario(
        id: json['id'] as int,
        usuarioId: json['usuario_id'] as String,
        mostrarCiudad: json['mostrar_ciudad'] as bool? ?? true,
        mostrarWhatsapp: json['mostrar_whatsapp'] as bool? ?? true,
        mostrarPerfil: json['mostrar_perfil'] as bool? ?? true,
        notifMatches: json['notif_matches'] as bool? ?? true,
        notifMensajes: json['notif_mensajes'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'usuario_id': usuarioId,
        'mostrar_ciudad': mostrarCiudad,
        'mostrar_whatsapp': mostrarWhatsapp,
        'mostrar_perfil': mostrarPerfil,
        'notif_matches': notifMatches,
        'notif_mensajes': notifMensajes,
      };
}

class Figurita {
  final int id;
  final int albumId;
  final int? equipoId;
  final int? categoriaId;
  final String numero;
  final String nombre;
  final String? imagen;
  final String rareza;
  final int dificultad;
  final String? pais;

  const Figurita({
    required this.id,
    required this.albumId,
    this.equipoId,
    this.categoriaId,
    required this.numero,
    required this.nombre,
    this.imagen,
    this.rareza = 'comun',
    this.dificultad = 1,
    this.pais,
  });

  factory Figurita.fromJson(Map<String, dynamic> json) => Figurita(
        id: json['id'] as int,
        albumId: json['album_id'] as int,
        equipoId: json['equipo_id'] as int?,
        categoriaId: json['categoria_id'] as int?,
        numero: json['numero'] as String,
        nombre: json['nombre'] as String,
        imagen: json['imagen'] as String?,
        rareza: json['rareza'] as String? ?? 'comun',
        dificultad: json['dificultad'] as int? ?? 1,
        pais: json['pais'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'album_id': albumId,
        if (equipoId != null) 'equipo_id': equipoId,
        if (categoriaId != null) 'categoria_id': categoriaId,
        'numero': numero,
        'nombre': nombre,
        if (imagen != null) 'imagen': imagen,
        'rareza': rareza,
        'dificultad': dificultad,
        if (pais != null) 'pais': pais,
      };
}

class UsuarioFigurita {
  final int id;
  final String usuarioId;
  final int figuritaId;
  final String estado; // 'necesito' | 'repetida' | 'completa'
  final bool prioridad;
  final int cantidad;
  final DateTime createdAt;

  const UsuarioFigurita({
    required this.id,
    required this.usuarioId,
    required this.figuritaId,
    required this.estado,
    this.prioridad = false,
    this.cantidad = 1,
    required this.createdAt,
  });

  factory UsuarioFigurita.fromJson(Map<String, dynamic> json) => UsuarioFigurita(
        id: json['id'] as int,
        usuarioId: json['usuario_id'] as String,
        figuritaId: json['figurita_id'] as int,
        estado: json['estado'] as String,
        prioridad: json['prioridad'] as bool? ?? false,
        cantidad: json['cantidad'] as int? ?? 1,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'usuario_id': usuarioId,
        'figurita_id': figuritaId,
        'estado': estado,
        'prioridad': prioridad,
        'cantidad': cantidad,
        'created_at': createdAt.toIso8601String(),
      };
}

/// Figurita del catálogo con el estado del usuario superpuesto.
/// estado == null significa que el usuario no la tiene en su colección.
class FiguritaConEstado {
  final Figurita figurita;
  final String? estado;
  final bool prioridad;
  final int cantidad;

  const FiguritaConEstado({
    required this.figurita,
    this.estado,
    this.prioridad = false,
    this.cantidad = 0,
  });

  bool get enColeccion => estado != null;
}

class Match {
  final int id;
  final String usuarioId;
  final String usuarioMatchId;
  final int porcentaje;
  final String estado;

  const Match({
    required this.id,
    required this.usuarioId,
    required this.usuarioMatchId,
    required this.porcentaje,
    this.estado = 'activo',
  });

  factory Match.fromJson(Map<String, dynamic> json) => Match(
        id: json['id'] as int,
        usuarioId: json['usuario_id'] as String,
        usuarioMatchId: json['usuario_match_id'] as String,
        porcentaje: json['porcentaje'] as int? ?? 0,
        estado: json['estado'] as String? ?? 'activo',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'usuario_id': usuarioId,
        'usuario_match_id': usuarioMatchId,
        'porcentaje': porcentaje,
        'estado': estado,
      };
}

/// Match enriquecido con perfil del otro usuario y figuritas en juego.
class MatchConDetalle {
  final Match match;
  final Usuario otroUsuario;
  final List<Figurita> figuritasQueNecesito;   // el otro tiene repetidas, yo las necesito
  final List<Figurita> figuritasQueElNecesita; // yo tengo repetidas, él las necesita

  const MatchConDetalle({
    required this.match,
    required this.otroUsuario,
    this.figuritasQueNecesito = const [],
    this.figuritasQueElNecesita = const [],
  });

  int get porcentaje => match.porcentaje;

  factory MatchConDetalle.fromJson(Map<String, dynamic> json) => MatchConDetalle(
        match: Match.fromJson(json),
        otroUsuario: Usuario.fromJson(
          json['otro_usuario'] as Map<String, dynamic>? ?? {},
        ),
      );
}

class Intercambio {
  final int id;
  final String usuarioEnviaId;
  final String usuarioRecibeId;
  final String estado; // 'pendiente' | 'aceptado' | 'rechazado' | 'completado'
  final String? mensaje;
  final DateTime createdAt;

  const Intercambio({
    required this.id,
    required this.usuarioEnviaId,
    required this.usuarioRecibeId,
    this.estado = 'pendiente',
    this.mensaje,
    required this.createdAt,
  });

  factory Intercambio.fromJson(Map<String, dynamic> json) => Intercambio(
        id: json['id'] as int,
        usuarioEnviaId: json['usuario_envia_id'] as String,
        usuarioRecibeId: json['usuario_recibe_id'] as String,
        estado: json['estado'] as String? ?? 'pendiente',
        mensaje: json['mensaje'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'usuario_envia_id': usuarioEnviaId,
        'usuario_recibe_id': usuarioRecibeId,
        'estado': estado,
        if (mensaje != null) 'mensaje': mensaje,
        'created_at': createdAt.toIso8601String(),
      };
}

class IntercambioConDetalle {
  final Intercambio intercambio;
  final Usuario usuarioEnvia;
  final Usuario usuarioRecibe;
  final List<Figurita> figuritasOfrece;  // lo que envia ofrece
  final List<Figurita> figuritasNecesita; // lo que envia quiere recibir

  const IntercambioConDetalle({
    required this.intercambio,
    required this.usuarioEnvia,
    required this.usuarioRecibe,
    this.figuritasOfrece = const [],
    this.figuritasNecesita = const [],
  });

  factory IntercambioConDetalle.fromJson(Map<String, dynamic> json) {
    final detalles = (json['intercambios_detalle'] as List<dynamic>?) ?? [];
    final ofrece = detalles
        .where((d) => d['tipo'] == 'ofrece')
        .map((d) => Figurita.fromJson(d['figurita'] as Map<String, dynamic>))
        .toList();
    final necesita = detalles
        .where((d) => d['tipo'] == 'recibe')
        .map((d) => Figurita.fromJson(d['figurita'] as Map<String, dynamic>))
        .toList();

    return IntercambioConDetalle(
      intercambio: Intercambio.fromJson(json),
      usuarioEnvia: Usuario.fromJson(
        json['usuario_envia'] as Map<String, dynamic>? ?? {},
      ),
      usuarioRecibe: Usuario.fromJson(
        json['usuario_recibe'] as Map<String, dynamic>? ?? {},
      ),
      figuritasOfrece: ofrece,
      figuritasNecesita: necesita,
    );
  }
}

class Notificacion {
  final int id;
  final String usuarioId;
  final String titulo;
  final String? mensaje;
  final String? tipo; // 'match' | 'propuesta' | 'aceptado' | 'evento'
  final bool leida;
  final DateTime createdAt;

  const Notificacion({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    this.mensaje,
    this.tipo,
    this.leida = false,
    required this.createdAt,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) => Notificacion(
        id: json['id'] as int,
        usuarioId: json['usuario_id'] as String,
        titulo: json['titulo'] as String,
        mensaje: json['mensaje'] as String?,
        tipo: json['tipo'] as String?,
        leida: json['leida'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'usuario_id': usuarioId,
        'titulo': titulo,
        if (mensaje != null) 'mensaje': mensaje,
        if (tipo != null) 'tipo': tipo,
        'leida': leida,
        'created_at': createdAt.toIso8601String(),
      };
}

class Chat {
  final int id;
  final int intercambioId;
  final String usuarioId;
  final String mensaje;
  final DateTime createdAt;

  const Chat({
    required this.id,
    required this.intercambioId,
    required this.usuarioId,
    required this.mensaje,
    required this.createdAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        id: json['id'] as int,
        intercambioId: json['intercambio_id'] as int,
        usuarioId: json['usuario_id'] as String,
        mensaje: json['mensaje'] as String,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'intercambio_id': intercambioId,
        'usuario_id': usuarioId,
        'mensaje': mensaje,
        'created_at': createdAt.toIso8601String(),
      };
}