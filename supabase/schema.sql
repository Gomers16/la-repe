-- ============================================================
-- LA REPE — Supabase Schema Completo
-- 16 tablas | MVP → Producción
-- Ejecutar en: Supabase Dashboard → SQL Editor → Run
-- ============================================================


-- ============================================================
-- BLOQUE 1: GEOGRAFÍA
-- ============================================================

CREATE TABLE paises (
  id     bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  nombre varchar    NOT NULL,
  codigo varchar(10) NOT NULL
);

CREATE TABLE ciudades (
  id      bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  pais_id bigint REFERENCES paises(id),
  nombre  varchar NOT NULL
);


-- ============================================================
-- BLOQUE 2: USUARIOS
-- Extiende auth.users de Supabase Auth
-- ============================================================

CREATE TABLE usuarios (
  id         uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre     varchar     NOT NULL,
  foto       text,
  ciudad_id  bigint      REFERENCES ciudades(id),
  pais_id    bigint      REFERENCES paises(id),
  whatsapp   varchar,
  provider   varchar     DEFAULT 'email',   -- 'email' | 'google' | 'phone'
  estado     varchar     DEFAULT 'activo',  -- 'activo' | 'inactivo' | 'baneado'
  created_at timestamptz DEFAULT now()
);

CREATE TABLE config_usuario (
  id                 bigint  PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  usuario_id         uuid    UNIQUE REFERENCES usuarios(id) ON DELETE CASCADE,
  mostrar_ciudad     boolean DEFAULT true,
  mostrar_whatsapp   boolean DEFAULT true,
  mostrar_perfil     boolean DEFAULT true,
  notif_matches      boolean DEFAULT true,
  notif_mensajes     boolean DEFAULT true
);


-- ============================================================
-- BLOQUE 3: CATÁLOGO
-- ============================================================

CREATE TABLE albumes (
  id              bigint  PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  nombre          varchar NOT NULL,
  total_figuritas integer NOT NULL,
  portada         text,
  estado          varchar DEFAULT 'activo'  -- 'activo' | 'archivado'
);

CREATE TABLE equipos (
  id       bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  album_id bigint REFERENCES albumes(id),
  nombre   varchar NOT NULL,
  escudo   text
);

CREATE TABLE categorias (
  id     bigint  PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  nombre varchar NOT NULL,
  color  varchar
);

CREATE TABLE figuritas (
  id           bigint  PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  album_id     bigint  REFERENCES albumes(id),
  equipo_id    bigint  REFERENCES equipos(id),
  categoria_id bigint  REFERENCES categorias(id),
  numero       varchar NOT NULL,
  nombre       varchar NOT NULL,
  imagen       text,
  rareza       varchar DEFAULT 'comun',  -- 'comun' | 'especial' | 'paralela_bronce' | 'paralela_plata' | 'paralela_oro'
  dificultad   integer DEFAULT 1,
  pais         varchar
);


-- ============================================================
-- BLOQUE 4: INVENTARIO
-- Tabla central — cada fila = relación usuario ↔ figurita
-- ============================================================

CREATE TABLE usuarios_figuritas (
  id          bigint      PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  usuario_id  uuid        REFERENCES usuarios(id) ON DELETE CASCADE,
  figurita_id bigint      REFERENCES figuritas(id),
  estado      varchar     NOT NULL,       -- 'necesito' | 'repetida' | 'completa'
  prioridad   boolean     DEFAULT false,
  cantidad    integer     DEFAULT 1,
  created_at  timestamptz DEFAULT now(),
  UNIQUE(usuario_id, figurita_id)
);

CREATE TABLE favoritos (
  id          bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  usuario_id  uuid   REFERENCES usuarios(id) ON DELETE CASCADE,
  figurita_id bigint REFERENCES figuritas(id),
  UNIQUE(usuario_id, figurita_id)
);


-- ============================================================
-- BLOQUE 5: MATCHES E INTERCAMBIOS
-- ============================================================

CREATE TABLE matches (
  id               bigint  PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  usuario_id       uuid    REFERENCES usuarios(id),
  usuario_match_id uuid    REFERENCES usuarios(id),
  porcentaje       integer DEFAULT 0,
  estado           varchar DEFAULT 'activo',  -- 'activo' | 'bloqueado'
  UNIQUE(usuario_id, usuario_match_id)
);

CREATE TABLE matches_detalle (
  id          bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  match_id    bigint REFERENCES matches(id) ON DELETE CASCADE,
  fig_necesita bigint REFERENCES figuritas(id),  -- A necesita, B tiene repetida
  fig_ofrece   bigint REFERENCES figuritas(id)   -- A tiene repetida, B necesita
);

CREATE TABLE intercambios (
  id                bigint      PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  usuario_envia_id  uuid        REFERENCES usuarios(id),
  usuario_recibe_id uuid        REFERENCES usuarios(id),
  estado            varchar     DEFAULT 'pendiente',  -- 'pendiente' | 'aceptado' | 'rechazado' | 'completado'
  mensaje           text,
  created_at        timestamptz DEFAULT now()
);

CREATE TABLE intercambios_detalle (
  id              bigint  PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  intercambio_id  bigint  REFERENCES intercambios(id) ON DELETE CASCADE,
  figurita_id     bigint  REFERENCES figuritas(id),
  tipo            varchar NOT NULL  -- 'ofrece' | 'recibe'
);


-- ============================================================
-- BLOQUE 6: COMUNICACIÓN
-- ============================================================

CREATE TABLE notificaciones (
  id         bigint      PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  usuario_id uuid        REFERENCES usuarios(id) ON DELETE CASCADE,
  titulo     varchar     NOT NULL,
  mensaje    text,
  tipo       varchar,    -- 'match' | 'propuesta' | 'aceptado' | 'evento'
  leida      boolean     DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE chats (
  id             bigint      PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  intercambio_id bigint      REFERENCES intercambios(id) ON DELETE CASCADE,
  usuario_id     uuid        REFERENCES usuarios(id),
  mensaje        text        NOT NULL,
  created_at     timestamptz DEFAULT now()
);


-- ============================================================
-- ÍNDICES — performance en queries frecuentes
-- ============================================================

CREATE INDEX ON usuarios_figuritas(usuario_id);
CREATE INDEX ON usuarios_figuritas(figurita_id);
CREATE INDEX ON usuarios_figuritas(estado);
CREATE INDEX ON usuarios_figuritas(usuario_id, estado);      -- filtros combinados frecuentes

CREATE INDEX ON matches(usuario_id);
CREATE INDEX ON matches(usuario_match_id);
CREATE INDEX ON matches(porcentaje DESC);                    -- ordenar por relevancia

CREATE INDEX ON intercambios(usuario_envia_id);
CREATE INDEX ON intercambios(usuario_recibe_id);
CREATE INDEX ON intercambios(estado);

CREATE INDEX ON notificaciones(usuario_id, leida);
CREATE INDEX ON notificaciones(created_at DESC);

CREATE INDEX ON chats(intercambio_id);
CREATE INDEX ON chats(created_at DESC);

CREATE INDEX ON figuritas(album_id);
CREATE INDEX ON figuritas(equipo_id);
CREATE INDEX ON figuritas(rareza);


-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE usuarios          ENABLE ROW LEVEL SECURITY;
ALTER TABLE config_usuario    ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios_figuritas ENABLE ROW LEVEL SECURITY;
ALTER TABLE favoritos         ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches           ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches_detalle   ENABLE ROW LEVEL SECURITY;
ALTER TABLE intercambios      ENABLE ROW LEVEL SECURITY;
ALTER TABLE intercambios_detalle ENABLE ROW LEVEL SECURITY;
ALTER TABLE notificaciones    ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats             ENABLE ROW LEVEL SECURITY;

-- Catálogo público (solo lectura para todos los auth)
ALTER TABLE albumes    ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipos    ENABLE ROW LEVEL SECURITY;
ALTER TABLE categorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE figuritas  ENABLE ROW LEVEL SECURITY;
ALTER TABLE paises     ENABLE ROW LEVEL SECURITY;
ALTER TABLE ciudades   ENABLE ROW LEVEL SECURITY;

CREATE POLICY "catalogo_read_all" ON albumes    FOR SELECT USING (true);
CREATE POLICY "catalogo_read_all" ON equipos    FOR SELECT USING (true);
CREATE POLICY "catalogo_read_all" ON categorias FOR SELECT USING (true);
CREATE POLICY "catalogo_read_all" ON figuritas  FOR SELECT USING (true);
CREATE POLICY "catalogo_read_all" ON paises     FOR SELECT USING (true);
CREATE POLICY "catalogo_read_all" ON ciudades   FOR SELECT USING (true);

-- Usuarios: cada uno solo ve y edita su propio perfil
CREATE POLICY "usuarios_own" ON usuarios
  FOR ALL USING (auth.uid() = id);

CREATE POLICY "config_own" ON config_usuario
  FOR ALL USING (auth.uid() = usuario_id);

-- Inventario: cada usuario maneja el suyo
CREATE POLICY "inventario_own" ON usuarios_figuritas
  FOR ALL USING (auth.uid() = usuario_id);

CREATE POLICY "favoritos_own" ON favoritos
  FOR ALL USING (auth.uid() = usuario_id);

-- Matches: ambos participantes pueden leer
CREATE POLICY "matches_participantes_read" ON matches
  FOR SELECT USING (
    auth.uid() = usuario_id OR auth.uid() = usuario_match_id
  );

CREATE POLICY "matches_own_insert" ON matches
  FOR INSERT WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "matches_detalle_read" ON matches_detalle
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM matches m
      WHERE m.id = match_id
        AND (m.usuario_id = auth.uid() OR m.usuario_match_id = auth.uid())
    )
  );

-- Intercambios: solo los participantes
CREATE POLICY "intercambios_participantes" ON intercambios
  FOR ALL USING (
    auth.uid() = usuario_envia_id OR auth.uid() = usuario_recibe_id
  );

CREATE POLICY "intercambios_detalle_participantes" ON intercambios_detalle
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM intercambios i
      WHERE i.id = intercambio_id
        AND (i.usuario_envia_id = auth.uid() OR i.usuario_recibe_id = auth.uid())
    )
  );

-- Notificaciones: solo el destinatario
CREATE POLICY "notif_own" ON notificaciones
  FOR ALL USING (auth.uid() = usuario_id);

-- Chat: solo los participantes del intercambio
CREATE POLICY "chats_participantes" ON chats
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM intercambios i
      WHERE i.id = intercambio_id
        AND (i.usuario_envia_id = auth.uid() OR i.usuario_recibe_id = auth.uid())
    )
  );


-- ============================================================
-- SEED DATA — Mundial 2026
-- ============================================================

INSERT INTO paises (nombre, codigo) VALUES
  ('Colombia',       'COL'),
  ('Argentina',      'ARG'),
  ('Brasil',         'BRA'),
  ('Uruguay',        'URU'),
  ('Ecuador',        'ECU'),
  ('Chile',          'CHI'),
  ('Paraguay',       'PAR'),
  ('Perú',           'PER'),
  ('México',         'MEX'),
  ('Estados Unidos', 'USA'),
  ('Canadá',         'CAN'),
  ('España',         'ESP'),
  ('Francia',        'FRA'),
  ('Alemania',       'ALE'),
  ('Italia',         'ITA'),
  ('Portugal',       'POR'),
  ('Inglaterra',     'ING'),
  ('Holanda',        'HOL'),
  ('Bélgica',        'BEL'),
  ('Croacia',        'CRO'),
  ('Marruecos',      'MAR'),
  ('Senegal',        'SEN'),
  ('Japón',          'JPN'),
  ('Corea del Sur',  'KOR'),
  ('Arabia Saudita', 'KSA');

INSERT INTO ciudades (pais_id, nombre) VALUES
  (1, 'Bogotá'),
  (1, 'Medellín'),
  (1, 'Cali'),
  (1, 'Ibagué'),
  (1, 'Bucaramanga'),
  (1, 'Barranquilla'),
  (1, 'Cartagena'),
  (2, 'Buenos Aires'),
  (2, 'Córdoba'),
  (3, 'São Paulo'),
  (3, 'Río de Janeiro'),
  (9, 'Ciudad de México'),
  (9, 'Guadalajara'),
  (12, 'Madrid'),
  (12, 'Barcelona'),
  (13, 'París'),
  (14, 'Berlín'),
  (16, 'Lisboa');

INSERT INTO albumes (nombre, total_figuritas, estado) VALUES
  ('Mundial 2026', 980, 'activo');

INSERT INTO categorias (nombre, color) VALUES
  ('Jugadores',  '#3b82f6'),
  ('Escudos',    '#f97316'),
  ('Especiales', '#a855f7'),
  ('Estadios',   '#10b981'),
  ('Coca-Cola',  '#ef4444');

INSERT INTO equipos (album_id, nombre) VALUES
  (1, 'Colombia'),
  (1, 'Argentina'),
  (1, 'Brasil'),
  (1, 'Uruguay'),
  (1, 'Ecuador'),
  (1, 'Chile'),
  (1, 'Paraguay'),
  (1, 'Perú'),
  (1, 'México'),
  (1, 'España'),
  (1, 'Francia'),
  (1, 'Alemania'),
  (1, 'Italia'),
  (1, 'Portugal'),
  (1, 'Inglaterra'),
  (1, 'Sedes y Estadios'),
  (1, 'Sección Coca-Cola'),
  (1, 'Extra Stickers');

-- Figuritas de muestra — Colombia
INSERT INTO figuritas (album_id, equipo_id, categoria_id, numero, nombre, rareza, dificultad, pais) VALUES
  (1,  1, 1, 'COL-001', 'James Rodríguez',  'especial',       5, 'Colombia'),
  (1,  1, 1, 'COL-002', 'Luis Díaz',         'especial',       5, 'Colombia'),
  (1,  1, 1, 'COL-003', 'Falcao García',     'comun',          3, 'Colombia'),
  (1,  1, 1, 'COL-004', 'Juan Cuadrado',     'comun',          2, 'Colombia'),
  (1,  1, 1, 'COL-005', 'David Ospina',      'comun',          2, 'Colombia'),
  (1,  1, 1, 'COL-006', 'Rigoberto Rivas',   'comun',          1, 'Colombia'),
  (1,  1, 1, 'COL-007', 'Jhon Durán',        'comun',          2, 'Colombia'),
  (1,  1, 1, 'COL-008', 'Richard Ríos',      'comun',          2, 'Colombia'),
  (1,  1, 1, 'COL-009', 'Jorge Carrascal',   'comun',          1, 'Colombia'),
  (1,  1, 2, 'COL-010', 'Escudo Colombia',   'especial',       4, 'Colombia'),
  -- Argentina
  (1,  2, 1, 'ARG-001', 'Lionel Messi',      'paralela_oro',   5, 'Argentina'),
  (1,  2, 1, 'ARG-002', 'Ángel Di María',    'especial',       4, 'Argentina'),
  (1,  2, 1, 'ARG-003', 'Rodrigo De Paul',   'comun',          3, 'Argentina'),
  (1,  2, 1, 'ARG-004', 'Lautaro Martínez',  'especial',       4, 'Argentina'),
  (1,  2, 2, 'ARG-005', 'Escudo Argentina',  'especial',       4, 'Argentina'),
  -- Brasil
  (1,  3, 1, 'BRA-001', 'Vinícius Jr',       'paralela_oro',   5, 'Brasil'),
  (1,  3, 1, 'BRA-002', 'Rodrygo',           'especial',       4, 'Brasil'),
  (1,  3, 1, 'BRA-003', 'Casemiro',          'comun',          3, 'Brasil'),
  (1,  3, 2, 'BRA-004', 'Escudo Brasil',     'especial',       4, 'Brasil'),
  -- Portugal
  (1, 14, 1, 'POR-001', 'Cristiano Ronaldo', 'paralela_oro',   5, 'Portugal'),
  (1, 14, 1, 'POR-002', 'Bruno Fernandes',   'especial',       4, 'Portugal'),
  (1, 14, 2, 'POR-003', 'Escudo Portugal',   'especial',       4, 'Portugal'),
  -- Francia
  (1, 11, 1, 'FRA-001', 'Kylian Mbappé',     'paralela_oro',   5, 'Francia'),
  (1, 11, 1, 'FRA-002', 'Antoine Griezmann', 'especial',       4, 'Francia'),
  (1, 11, 2, 'FRA-003', 'Escudo Francia',    'especial',       4, 'Francia'),
  -- Estadios (Sede)
  (1, 16, 4, 'SED-001', 'MetLife Stadium',        'especial', 3, NULL),
  (1, 16, 4, 'SED-002', 'Rose Bowl',              'especial', 3, NULL),
  (1, 16, 4, 'SED-003', 'AT&T Stadium',           'especial', 3, NULL),
  (1, 16, 4, 'SED-004', 'Estadio Azteca',         'especial', 3, NULL),
  (1, 16, 4, 'SED-005', 'BC Place Vancouver',     'especial', 3, NULL),
  -- Coca-Cola
  (1, 17, 5, 'CC-001', 'Coca-Cola Promo #1', 'especial', 4, NULL),
  (1, 17, 5, 'CC-002', 'Coca-Cola Promo #2', 'especial', 4, NULL),
  (1, 17, 5, 'CC-003', 'Coca-Cola Promo #3', 'especial', 4, NULL);


-- ============================================================
-- FUNCIÓN: detectar matches automáticos
-- Calcula el porcentaje de compatibilidad entre usuarios
-- basado en lo que uno necesita y el otro tiene repetido
-- ============================================================

CREATE OR REPLACE FUNCTION detectar_matches(p_usuario_id uuid)
RETURNS void AS $$
BEGIN
  INSERT INTO matches (usuario_id, usuario_match_id, porcentaje)
  SELECT
    p_usuario_id,
    uf2.usuario_id,
    -- porcentaje = figuritas que el otro puede darme / lo que yo necesito
    ROUND(
      COUNT(*) * 100.0 / GREATEST(
        (SELECT COUNT(*) FROM usuarios_figuritas
         WHERE usuario_id = p_usuario_id AND estado = 'necesito'), 1
      )
    )::integer
  FROM usuarios_figuritas uf1
  JOIN usuarios_figuritas uf2
    ON uf1.figurita_id = uf2.figurita_id
  WHERE uf1.usuario_id  = p_usuario_id
    AND uf1.estado      = 'necesito'
    AND uf2.estado      = 'repetida'
    AND uf2.usuario_id != p_usuario_id
  GROUP BY uf2.usuario_id
  ON CONFLICT (usuario_id, usuario_match_id)
  DO UPDATE SET porcentaje = EXCLUDED.porcentaje;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- FUNCIÓN: crear perfil automáticamente al registrarse
-- Se dispara cuando Supabase Auth crea un nuevo usuario
-- ============================================================

CREATE OR REPLACE FUNCTION crear_perfil_nuevo_usuario()
RETURNS trigger AS $$
BEGIN
  INSERT INTO usuarios (id, nombre, provider)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nombre', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'provider', 'email')
  );

  INSERT INTO config_usuario (usuario_id)
  VALUES (NEW.id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION crear_perfil_nuevo_usuario();


-- ============================================================
-- TRIGGER: auto-detectar matches al modificar colección
-- ============================================================

CREATE OR REPLACE FUNCTION trigger_detectar_matches()
RETURNS trigger AS $$
BEGIN
  PERFORM detectar_matches(NEW.usuario_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_coleccion_update
  AFTER INSERT OR UPDATE ON usuarios_figuritas
  FOR EACH ROW EXECUTE FUNCTION trigger_detectar_matches();


-- ============================================================
-- TRIGGER: crear notificación cuando hay nuevo match
-- ============================================================

CREATE OR REPLACE FUNCTION notificar_nuevo_match()
RETURNS trigger AS $$
BEGIN
  -- Notifica al usuario que encontró un match
  IF NEW.porcentaje >= 10 THEN
    INSERT INTO notificaciones (usuario_id, titulo, mensaje, tipo)
    VALUES (
      NEW.usuario_id,
      '¡Nuevo match encontrado!',
      'Encontramos a alguien con figuritas que necesitás. ¡Mirá quién es!',
      'match'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_match_created
  AFTER INSERT OR UPDATE ON matches
  FOR EACH ROW EXECUTE FUNCTION notificar_nuevo_match();


-- ============================================================
-- TRIGGER: notificar intercambio recibido
-- ============================================================

CREATE OR REPLACE FUNCTION notificar_intercambio()
RETURNS trigger AS $$
DECLARE
  nombre_envia varchar;
BEGIN
  SELECT nombre INTO nombre_envia FROM usuarios WHERE id = NEW.usuario_envia_id;

  IF NEW.estado = 'pendiente' THEN
    INSERT INTO notificaciones (usuario_id, titulo, mensaje, tipo)
    VALUES (
      NEW.usuario_recibe_id,
      '¡Nueva propuesta de intercambio!',
      nombre_envia || ' quiere intercambiar figuritas con vos.',
      'propuesta'
    );
  ELSIF NEW.estado = 'aceptado' THEN
    INSERT INTO notificaciones (usuario_id, titulo, mensaje, tipo)
    VALUES (
      NEW.usuario_envia_id,
      'Intercambio aceptado',
      nombre_envia || ' aceptó tu propuesta. ¡Coordiná el canje!',
      'aceptado'
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_intercambio_cambio
  AFTER INSERT OR UPDATE OF estado ON intercambios
  FOR EACH ROW EXECUTE FUNCTION notificar_intercambio();
