/// Rutas de assets estáticos de la app.
/// Usar siempre estas constantes en lugar de strings literales.
abstract class AppAssets {

  // ── Branding ──────────────────────────────────────────────────────────────
  /// Logo completo: isotipo + wordmark "La Repe" (PNG con fondo transparente).
  static const String logo    = 'assets/images/app/logo_la_repe.png';

  /// Isotipo solo (swap arrows). Usar en headers, badges y app bar.
  static const String isotipo = 'assets/images/app/isotipo.png';

  /// Imagen de carga / loader animado.
  static const String loader  = 'assets/images/app/loader.png';

  // ── Fondos ────────────────────────────────────────────────────────────────
  /// Foto de estadio de fútbol. Usar con overlay oscuro para mantener legibilidad.
  static const String backgroundStadium = 'assets/images/backgrounds/fondo_estadio.png';

  // ── Stickers ──────────────────────────────────────────────────────────────
  static const String stickerPlaceholder = 'assets/images/stickers/placeholder.svg';

  /// Ruta a la imagen PNG de una figurita. Si no existe, usar [stickerPlaceholder].
  static String stickerImage(String id) =>
      'assets/images/stickers/${id.toLowerCase()}.png';

  // ── Equipos ───────────────────────────────────────────────────────────────
  /// Escudo de equipo identificado por código (ej: 'col', 'bra').
  static String teamImage(String code) =>
      'assets/images/teams/${code.toLowerCase()}.png';

  // ── Íconos ────────────────────────────────────────────────────────────────
  static const String appIcon = 'assets/icons/app_icon.png';
}

/// Nombres de familia de fuente registrados en pubspec.yaml › fonts.
/// Deben coincidir EXACTAMENTE con los values de fontFamily en theme.dart.
abstract class AppFonts {
  /// Bebas Neue — títulos, display, branding.
  static const String display = 'Bebas Neue';

  /// Inter — UI, formularios, texto corrido.
  static const String body = 'Inter';
}
