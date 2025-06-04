-- TABLAS

CREATE TABLE Usuarios (
    usuario_id       SERIAL PRIMARY KEY,
    nombre_summoner  VARCHAR(50) NOT NULL,
    region           VARCHAR(10) NOT NULL,
    nivel            INTEGER NOT NULL CHECK (nivel >= 1),
    fecha_registro   DATE NOT NULL DEFAULT CURRENT_DATE,
    estado_cuenta    VARCHAR(20) NOT null -- baneado, suspendido, activo
);

CREATE TABLE MetodosPago (
    metodo_id    SERIAL PRIMARY KEY,
    nombre_metodo VARCHAR(50) NOT NULL
);

CREATE TABLE ItemsTienda (
    item_id             SERIAL PRIMARY KEY,
    nombre_item         VARCHAR(100) NOT NULL,
    tipo_item           VARCHAR(20)  NOT NULL CHECK (tipo_item IN ('Campeón','Skin','Pase','Otro')),
    precio_RP           INTEGER      NOT NULL CHECK (precio_RP >= 0),
    precio_esenciaAzul  INTEGER      NOT NULL CHECK (precio_esenciaAzul >= 0),
    disponibilidad      BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE TransaccionesFinancieras (
    transaccion_id    SERIAL PRIMARY KEY,
    usuario_id        INTEGER NOT NULL
                       REFERENCES Usuarios(usuario_id)
                       ON DELETE RESTRICT, 
    metodo_id         INTEGER NOT NULL
                       REFERENCES MetodosPago(metodo_id)
                       ON DELETE RESTRICT,
    fecha             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    monto_dinero      NUMERIC(12,2) NOT NULL CHECK (monto_dinero >= 0), 
    monto_RP_obtenido INTEGER       NOT NULL CHECK (monto_RP_obtenido >= 0), 
    moneda_fiat       VARCHAR(10)   NOT NULL
);

CREATE TABLE ComprasContenido (
    compra_id    SERIAL PRIMARY KEY,
    usuario_id   INTEGER NOT NULL
                  REFERENCES Usuarios(usuario_id)
                  ON DELETE CASCADE,
    item_id      INTEGER NOT NULL
                  REFERENCES ItemsTienda(item_id)
                  ON DELETE RESTRICT,
    fecha        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    moneda_usada VARCHAR(10)   NOT NULL  CHECK (moneda_usada IN ('RP','EA')), 
    costo_moneda INTEGER      NOT NULL CHECK (costo_moneda >= 0)
);

CREATE TABLE InventarioUsuario (
    usuario_id      INTEGER NOT NULL
                     REFERENCES Usuarios(usuario_id)
                     ON DELETE CASCADE,
    item_id         INTEGER NOT NULL
                     REFERENCES ItemsTienda(item_id)
                     ON DELETE RESTRICT,
    fecha_obtencion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    origen          VARCHAR(50) NOT NULL  
                     CHECK (origen IN ('Compra','Recompensa','Regalo','Otro')),
    PRIMARY KEY(usuario_id, item_id)
);
