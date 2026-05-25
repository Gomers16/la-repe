# La Repe — Guía de Desarrollo

## 1. ¿Qué es La Repe?

App móvil para intercambiar figuritas del Mundial 2026.
Los usuarios clasifican sus figuritas (la tengo / la necesito),
el sistema detecta automáticamente quién tiene lo que el otro
necesita y facilita el intercambio por WhatsApp.

---

## 2. Stack tecnológico

| Capa | Tecnología | Para qué |
|------|-----------|---------|
| Frontend | Flutter + Dart | Pantallas y lógica de UI |
| Estado local | Hive + SharedPreferences | Colección offline |
| Backend | Supabase (PostgreSQL) | Base de datos en la nube |
| Autenticación | Supabase Auth | Login con email o Google |
| Tiempo real | Supabase Realtime | Notificaciones en vivo |
| Almacenamiento | Supabase Storage | Imágenes de figuritas |

---

## 3. Requisitos previos

Instalar esto antes de empezar:

| Herramienta | Link | Notas |
|-------------|------|-------|
| Flutter SDK | https://flutter.dev/docs/get-started/install | Versión 3.x o superior |
| Git | https://git-scm.com/downloads | Para clonar el repo |
| Android Studio | https://developer.android.com/studio | Incluye Android SDK |
| VS Code (opcional) | https://code.visualstudio.com | Editor recomendado |

---

## 4. Instalación en Windows — paso a paso

### IMPORTANTE: Flutter NO puede estar en una ruta con espacios

❌ MAL:  C:\Users\Diego Gomez\flutter  
✅ BIEN: C:\flutter

Si Flutter está en una ruta con espacios vas a ver este error:  
`"C:\Users\Diego" no se reconoce como un comando interno...`  
Solución: mover la carpeta flutter a C:\flutter y actualizar el PATH.

### Pasos:

**a) Instalar Flutter**
1. Descargar desde https://flutter.dev/docs/get-started/install/windows
2. Descomprimir en `C:\flutter` (sin espacios en la ruta)
3. Agregar `C:\flutter\bin` al PATH del sistema:
   - Buscar "Variables de entorno" en Windows
   - Variables del sistema → Path → Editar → Nuevo
   - Agregar: `C:\flutter\bin`

**b) Verificar instalación**  
Abrir una terminal nueva y ejecutar:
```
flutter doctor
```
Debe mostrar checkmarks verdes en Flutter y Android toolchain.

**c) Clonar el repositorio**
```
git clone https://github.com/Gomers16/la-repe.git
cd la-repe
```

**d) Instalar dependencias**
```
flutter pub get
```

**e) Configurar credenciales de Supabase**  
Ver sección 5.

---

## 5. Configuración de credenciales

Este archivo NO está en GitHub por seguridad.  
Hay que crearlo manualmente:

Crear el archivo: `lib/config/supabase_config.dart`

```dart
class SupabaseConfig {
  static const supabaseUrl     = 'https://TU-PROYECTO.supabase.co';
  static const supabaseAnonKey = 'sb_publishable_...tu-key...';
  static const redirectUrl     = 'io.supabase.larepe://login-callback/';
}
```

Dónde conseguir los valores:
1. Entrar a https://supabase.com
2. Abrir el proyecto la-repe
3. Ir a Settings → API Keys
4. Copiar:
   - Project URL → `supabaseUrl`
   - Publishable key → `supabaseAnonKey` (empieza con `sb_publishable_`)

---

## 6. Cómo correr el proyecto

### Opción A — Comando directo (recomendado)

En Chrome:
```
flutter run ^
--dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co ^
--dart-define=SUPABASE_ANON_KEY=sb_publishable_... ^
-d chrome
```

En Android (dispositivo conectado por USB):
```
flutter run ^
--dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co ^
--dart-define=SUPABASE_ANON_KEY=sb_publishable_...
```

### Opción B — Archivo run.bat (Windows)
1. Abrir `run.bat` con el Bloc de notas
2. Reemplazar los valores de `SUPABASE_URL` y `SUPABASE_ANON_KEY`
3. Guardar y hacer doble click para ejecutar

### Comandos útiles mientras la app corre:
- `r` → Hot reload (recarga cambios rápido)
- `R` → Hot restart (reinicio completo)
- `q` → Salir

---

## 7. Estructura del proyecto

```
la-repe/
├── lib/
│   ├── config/           ← Credenciales Supabase (NO en git)
│   ├── models/           ← Clases Dart (Usuario, Figurita, Match...)
│   ├── screens/          ← Pantallas de la app (Frontend/UI)
│   │   ├── auth/         ← Login, registro, recuperar contraseña
│   │   ├── home_screen.dart       ← Dashboard principal
│   │   ├── swipe_screen.dart      ← Clasificación rápida
│   │   ├── collection_screen.dart ← Grid completo del álbum
│   │   ├── matches_screen.dart    ← Intercambios y matches
│   │   └── profile_screen.dart   ← Perfil del usuario
│   ├── services/
│   │   └── supabase_service.dart ← TODA la comunicación con Supabase
│   ├── state/
│   │   └── album_state.dart      ← Estado global (Hive local)
│   ├── theme/            ← Colores, fuentes, assets
│   └── utils/            ← Manejo de errores, helpers
├── supabase/
│   └── schema.sql        ← SQL para crear las 16 tablas
├── assets/
│   ├── backgrounds/      ← Fondo del estadio
│   ├── fonts/            ← Tipografías
│   └── images/           ← Logo e imágenes
├── run.bat               ← Script para correr en Windows (NO en git)
├── run_android.bat       ← Script para correr en Android (NO en git)
└── DEVELOPMENT_GUIDE.md  ← Este archivo
```

---

## 8. Base de datos — 16 tablas

### Geografía
| Tabla | Para qué |
|-------|---------|
| paises | Lista de países |
| ciudades | Ciudades por país — para matches cercanos |

### Usuarios
| Tabla | Para qué |
|-------|---------|
| usuarios | Perfil extendido (extiende auth.users de Supabase) |
| config_usuario | Preferencias de privacidad y notificaciones |

### Catálogo
| Tabla | Para qué |
|-------|---------|
| albumes | Álbumes disponibles (ej: Mundial 2026 — 980 figuritas) |
| equipos | Equipos por álbum (Colombia, Argentina, Brasil...) |
| categorias | Tipos: Jugadores, Escudos, Especiales |
| figuritas | Cada figurita con número, nombre, rareza, imagen |

### Inventario — el corazón del sistema
| Tabla | Para qué |
|-------|---------|
| usuarios_figuritas | Estado de cada figurita por usuario: 'necesito' o 'completa' |
| favoritos | Figuritas marcadas como favoritas |

### Intercambios
| Tabla | Para qué |
|-------|---------|
| matches | Compatibilidades detectadas automáticamente |
| matches_detalle | Figuritas específicas de cada match |
| intercambios | Propuestas formales de intercambio |
| intercambios_detalle | Figuritas incluidas en cada intercambio |

### Comunicación
| Tabla | Para qué |
|-------|---------|
| notificaciones | Alertas del sistema |
| chats | Mensajes por intercambio |

---

## 9. Flujo principal de datos

```
Usuario desliza figurita en Swipe
│
├── Hive (local) ← se guarda inmediatamente, funciona offline
│
└── Supabase (background) ← se sincroniza cuando hay internet
        │
        └── Trigger detectar_matches() se ejecuta automáticamente
                │
                └── Aparecen matches en Intercambios
                        │
                        └── Se propone intercambio → WhatsApp
```

---

## 10. Cómo agregar figuritas al catálogo

Directo en Supabase Dashboard:
1. Ir a https://supabase.com → proyecto la-repe → SQL Editor
2. Ejecutar:

```sql
INSERT INTO figuritas (album_id, equipo_id, numero, nombre, rareza, dificultad)
VALUES (1, 1, 'COL-001', 'James Rodríguez', 'especial', 5);
```

O via Table Editor:
1. Supabase Dashboard → Table Editor → figuritas
2. Click en Insert → llenar los campos → Save

---

## 11. Comandos del día a día

```bash
flutter pub get        # Instalar/actualizar dependencias
flutter run -d chrome  # Correr en Chrome
flutter run            # Correr en dispositivo Android conectado
flutter build apk      # Generar APK para instalar en Android
flutter analyze        # Verificar errores de código
flutter clean          # Limpiar caché (usar si hay errores raros)
git add .              # Preparar cambios para commit
git commit -m "msg"    # Hacer commit
git push               # Subir cambios a GitHub
```

---

## 12. Problemas comunes y soluciones

### `"C:\Users\Diego" no se reconoce como comando`
**Causa:** Flutter instalado en ruta con espacios.  
**Solución:** Mover Flutter a `C:\flutter` y actualizar PATH.

### `Building native assets for package:objective_c failed`
**Causa:** Mismo problema de ruta con espacios.  
**Solución:** Misma que arriba.

### `404` en login o registro
**Causa:** Credenciales de Supabase no configuradas.  
**Solución:** Verificar `lib/config/supabase_config.dart`
o correr con `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

### `Cache cargado: 0 figuritas`
**Causa:** La base de datos de Supabase está vacía.  
**Solución:** Ejecutar el SQL del archivo `supabase/schema.sql`
en Supabase Dashboard → SQL Editor.

### `flutter pub get` falla
**Solución:** `flutter clean && flutter pub get`

---

## 13. Repositorio y recursos

- **GitHub:** https://github.com/Gomers16/la-repe
- **Supabase Project ID:** eskomsfbzarahxfpcdbf
- **Supabase Dashboard:** https://supabase.com/dashboard/project/eskomsfbzarahxfpcdbf
