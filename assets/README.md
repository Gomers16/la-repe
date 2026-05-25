# Assets — La Repe

## Estructura

```
assets/
├── fonts/          ← fuentes TTF locales (ver instrucciones abajo)
├── icons/          ← fuentes del ícono de app (PNG de 1024x1024 para generación)
├── images/
│   ├── app/        ← logo.svg, logo_dark.svg
│   ├── backgrounds/← imágenes de fondo opcionales
│   ├── stickers/   ← placeholder.svg + imágenes reales de figuritas (PNG)
│   └── teams/      ← banderas/escudos de equipos (PNG nombrados por código: col.png)
└── README.md
```

## Fuentes — Instrucciones

La app usa `google_fonts` para cargar fuentes automáticamente.
Para usar fuentes locales (sin internet, builds de producción):

### Paso 1 — Descargar

| Fuente | Uso | URL |
|---|---|---|
| **Bebas Neue** | Títulos, display | https://fonts.google.com/specimen/Bebas+Neue |
| **Inter** | Cuerpo, UI | https://fonts.google.com/specimen/Inter |

### Paso 2 — Colocar archivos en `assets/fonts/`

```
assets/fonts/
├── BebasNeue-Regular.ttf
├── Inter-Regular.ttf          (weight 400)
├── Inter-Medium.ttf           (weight 500)
├── Inter-SemiBold.ttf         (weight 600)
└── Inter-Bold.ttf             (weight 700)
```

### Paso 3 — Descomentar en `pubspec.yaml`

```yaml
  fonts:
    - family: BebasNeue
      fonts:
        - asset: assets/fonts/BebasNeue-Regular.ttf

    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

### Paso 4 — Reemplazar en `app_assets.dart`

```dart
abstract class AppFonts {
  static const String display = 'BebasNeue';   // en lugar de GoogleFonts
  static const String body    = 'Inter';
}
```

## Imágenes de figuritas

Nombrar como `{id}.png` en minúsculas. Ejemplo: `col-10.png`, `extra-1-g.png`.
El widget de figurita las carga con `AppAssets.stickerImage(sticker.id)` y
muestra `placeholder.svg` si el archivo no existe.

## Ícono de app

Colocar `app_icon.png` (1024×1024, fondo transparente o sólido) en `assets/icons/`.
Usar `flutter_launcher_icons` para generar íconos de todas las plataformas.
