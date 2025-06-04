-- TABLAS

CREATE TABLE Usuarios (
    usuario_id       INT AUTO_INCREMENT PRIMARY KEY,
    nombre_summoner  VARCHAR(50) NOT NULL,
    region           VARCHAR(10) NOT NULL,
    nivel            INT NOT NULL CHECK (nivel >= 1),
    fecha_registro   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado_cuenta    VARCHAR(20) NOT NULL  -- activo, suspendido, baneado
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COLLATE = utf8mb4_unicode_ci;

CREATE TABLE VersionesJuego (
    parche_id         INT AUTO_INCREMENT PRIMARY KEY,
    version_nombre    VARCHAR(10) NOT NULL UNIQUE,
    fecha_lanzamiento DATE        NOT NULL,
    descripcion_resumen TEXT
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COLLATE = utf8mb4_unicode_ci;

CREATE TABLE Campeones (
    campeon_id        INT AUTO_INCREMENT PRIMARY KEY,
    nombre_campeon    VARCHAR(50) NOT NULL UNIQUE,
    rol_principal     VARCHAR(20) NOT NULL,  -- Asesino, Mago
    dificultad        VARCHAR(20) NOT NULL,  -- Baja, Media, Alta
    fecha_lanzamiento DATE        NOT NULL
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COLLATE = utf8mb4_unicode_ci;

CREATE TABLE Partidas (
    partida_id      BIGINT AUTO_INCREMENT PRIMARY KEY,
    fecha_inicio    DATETIME      NOT NULL,
    duracion        INT           NOT NULL CHECK (duracion >= 0),
    tipo_cola       VARCHAR(20)   NOT NULL,  -- Clasificatoria, Normal, ARAM
    mapa            VARCHAR(20)   NOT NULL,  -- Summoners' Rift, Howling Abyss
    parche_id       INT           NOT NULL,
    equipo_ganador  ENUM('Blue','Red') NOT NULL,
    CONSTRAINT fk_partida_parche
        FOREIGN KEY (parche_id) REFERENCES VersionesJuego(parche_id)
        ON DELETE RESTRICT
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COLLATE = utf8mb4_unicode_ci;

CREATE TABLE Participantes (
    partida_id       BIGINT   NOT NULL,
    usuario_id       INT      NOT NULL,
    campeon_id       INT      NOT NULL,
    equipo           ENUM('Blue','Red')    NOT NULL,
    rol_linea        VARCHAR(20)           NOT NULL,  -- Mid, ADC, Support
    kills            INT      NOT NULL DEFAULT 0 CHECK (kills >= 0),
    deaths           INT      NOT NULL DEFAULT 0 CHECK (deaths >= 0),
    assists          INT      NOT NULL DEFAULT 0 CHECK (assists >= 0),
    farm_cs          INT      NOT NULL DEFAULT 0 CHECK (farm_cs >= 0),
    oro_obtenido     INT      NOT NULL DEFAULT 0 CHECK (oro_obtenido >= 0),
    oro_gastado      INT      NOT NULL DEFAULT 0 CHECK (oro_gastado >= 0),
    dano_infligido   INT      NOT NULL DEFAULT 0 CHECK (dano_infligido >= 0),
    curacion         INT      NOT NULL DEFAULT 0 CHECK (curacion >= 0),
    wards_colocados   INT     NOT NULL DEFAULT 0 CHECK (wards_colocados >= 0),
    wards_destruidos  INT     NOT NULL DEFAULT 0 CHECK (wards_destruidos >= 0),
    PRIMARY KEY (partida_id, usuario_id),
    CONSTRAINT fk_participantes_partida
        FOREIGN KEY (partida_id) REFERENCES Partidas(partida_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_participantes_usuario
        FOREIGN KEY (usuario_id) REFERENCES Usuarios(usuario_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_participantes_campeon
        FOREIGN KEY (campeon_id) REFERENCES Campeones(campeon_id)
        ON DELETE RESTRICT
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COLLATE = utf8mb4_unicode_ci;

CREATE TABLE EstadisticasEquipo (
    partida_id             BIGINT   NOT NULL,
    equipo                 ENUM('Blue','Red') NOT NULL,
    torres_destruidas      INT      NOT NULL DEFAULT 0 CHECK (torres_destruidas >= 0),
    inhibidores_destruidos INT      NOT NULL DEFAULT 0 CHECK (inhibidores_destruidos >= 0),
    dragones               INT      NOT NULL DEFAULT 0 CHECK (dragones >= 0),
    heraldos               INT      NOT NULL DEFAULT 0 CHECK (heraldos >= 0),
    barones                INT      NOT NULL DEFAULT 0 CHECK (barones >= 0),
    kills_equipo           INT      NOT NULL DEFAULT 0 CHECK (kills_equipo >= 0),
    oro_equipo             INT      NOT NULL DEFAULT 0 CHECK (oro_equipo >= 0),
    resultado              VARCHAR(10) NOT NULL 
                           CHECK (resultado IN ('Victoria','Derrota')),
    PRIMARY KEY (partida_id, equipo),
    CONSTRAINT fk_ee_partida
        FOREIGN KEY (partida_id) REFERENCES Partidas(partida_id)
        ON DELETE CASCADE
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COLLATE = utf8mb4_unicode_ci;

CREATE TABLE ObjetivosPartida (
    evento_id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    partida_id         BIGINT NOT NULL,
    tipo_objetivo      VARCHAR(20) NOT NULL,  -- Dragón, Barón, Torre, Herald
    detalle            VARCHAR(50) NOT NULL,  -- Dragón Infernal, Torre Inhibidor Top
    minuto_partida     INT      NOT NULL CHECK (minuto_partida >= 0),
    equipo_responsable ENUM('Blue','Red') NOT NULL,
    CONSTRAINT fk_obj_partida
        FOREIGN KEY (partida_id) REFERENCES Partidas(partida_id)
        ON DELETE CASCADE
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COLLATE = utf8mb4_unicode_ci;

CREATE TABLE MaestriaCampeon (
    usuario_id        INT NOT NULL,
    campeon_id        INT NOT NULL,
    nivel_maestria    INT NOT NULL DEFAULT 0 
                       CHECK (nivel_maestria BETWEEN 0 AND 7),
    puntos_maestria   INT NOT NULL DEFAULT 0 CHECK (puntos_maestria >= 0),
    ultima_fecha_jugado DATE NOT NULL,
    PRIMARY KEY (usuario_id, campeon_id),
    CONSTRAINT fk_maestria_usuario
        FOREIGN KEY (usuario_id) REFERENCES Usuarios(usuario_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_maestria_campeon
        FOREIGN KEY (campeon_id) REFERENCES Campeones(campeon_id)
        ON DELETE RESTRICT
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COLLATE = utf8mb4_unicode_ci;

CREATE TABLE EstadisticasUsuario (
    usuario_id                 INT       NOT NULL,
    temporada                   VARCHAR(10) NOT NULL, -- '2023','13','13-S1'
    partidas_jugadas           INT       NOT NULL DEFAULT 0 CHECK (partidas_jugadas >= 0),
    victorias                  INT       NOT NULL DEFAULT 0 CHECK (victorias >= 0),
    derrotas                   INT       NOT NULL DEFAULT 0 CHECK (derrotas >= 0),
    winrate                    DECIMAL(5,2) NOT NULL CHECK (winrate >= 0.00 AND winrate <= 100.00),
    kda_promedio               DECIMAL(4,2) NOT NULL CHECK (kda_promedio >= 0.00),
    promedio_oro_por_partida   INT       NOT NULL DEFAULT 0 CHECK (promedio_oro_por_partida >= 0),
    promedio_dano_por_partida  INT       NOT NULL DEFAULT 0 CHECK (promedio_dano_por_partida >= 0),
    PRIMARY KEY (usuario_id, temporada),
    CONSTRAINT fk_estadusr_usuario
        FOREIGN KEY (usuario_id) REFERENCES Usuarios(usuario_id)
        ON DELETE CASCADE
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COLLATE = utf8mb4_unicode_ci;

CREATE TABLE HistorialClasificacion (
    usuario_id     INT        NOT NULL,
    temporada       VARCHAR(10) NOT NULL,   -- '2023','13','13-S1'
    liga_tier      VARCHAR(20) NOT NULL,    -- Oro, Platino, Diamante
    division       VARCHAR(10) NOT NULL,    -- I, II, III, IV
    LP_final       INT        NOT NULL DEFAULT 0 CHECK (LP_final >= 0),
    rango_mundial  BIGINT     DEFAULT NULL,  -- posición global al cierre
    PRIMARY KEY (usuario_id, temporada),
    CONSTRAINT fk_histclasi_usuario
        FOREIGN KEY (usuario_id) REFERENCES Usuarios(usuario_id)
        ON DELETE CASCADE
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COLLATE = utf8mb4_unicode_ci;

