-- PARTITIONS
ALTER TABLE Partidas RENAME TO Partidas_old;

CREATE TABLE Partidas (
    partida_id      BIGINT PRIMARY KEY,
    fecha_inicio    TIMESTAMP NOT NULL,
    duracion        INT NOT NULL CHECK (duracion >= 0),
    tipo_cola       VARCHAR(20) NOT NULL,
    mapa            VARCHAR(20) NOT NULL,
    parche_id       INT NOT NULL,
    equipo_ganador  VARCHAR(5) NOT NULL
) PARTITION BY RANGE (fecha_inicio);

CREATE TABLE Partidas_2023 PARTITION OF Partidas 
  FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE Partidas_2024 PARTITION OF Partidas 
  FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE Partidas_2025 PARTITION OF Partidas 
  FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE TABLE Partidas_pre2023 PARTITION OF Partidas
  FOR VALUES FROM (MINVALUE) TO ('2023-01-01');

CREATE TABLE Partidas_post2025 PARTITION OF Partidas
  FOR VALUES FROM ('2026-01-01') TO (MAXVALUE);

INSERT INTO Partidas (partida_id, fecha_inicio, duracion, tipo_cola, mapa, parche_id, equipo_ganador)

SELECT partida_id, fecha_inicio, duracion, tipo_cola, mapa, parche_id, equipo_ganador
  FROM Partidas_old;


-- INDEXES
CREATE INDEX idx_partidas_parche_id ON Partidas(parche_id);
CREATE INDEX idx_partidas_tipo_cola ON Partidas(tipo_cola);

-- ANALYZE
EXPLAIN ANALYZE
SELECT *
FROM Partidas
WHERE parche_id = 15
  AND fecha_inicio >= '2024-01-01'
  AND fecha_inicio <  '2025-01-01';
