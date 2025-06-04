-- PARTITIONS
DROP TABLE IF EXISTS Partidas;

CREATE TABLE Partidas (
  partida_id      BIGINT AUTO_INCREMENT PRIMARY KEY,
  fecha_inicio    DATETIME      NOT NULL,
  duracion        INT           NOT NULL CHECK (duracion >= 0),
  tipo_cola       VARCHAR(20)   NOT NULL,
  mapa            VARCHAR(20)   NOT NULL,
  parche_id       INT           NOT NULL,
  equipo_ganador  ENUM('Blue','Red') NOT NULL
)
PARTITION BY RANGE (YEAR(fecha_inicio)) (
  PARTITION p2023 VALUES LESS THAN (2024),
  PARTITION p2024 VALUES LESS THAN (2025),
  PARTITION p2025 VALUES LESS THAN (2026),
  PARTITION p_pre2023 VALUES LESS THAN (2023),
  PARTITION p_post2025 VALUES LESS THAN MAXVALUE
);

-- INDEXES
CREATE INDEX idx_partidas_parche_id ON Partidas(parche_id);
CREATE INDEX idx_partidas_tipo_cola ON Partidas(tipo_cola);
CREATE INDEX idx_partidas_parche_fecha ON Partidas(parche_id, fecha_inicio);

-- ANALIZE
EXPLAIN ANALYZE
SELECT *
FROM Partidas
WHERE parche_id = 15
  AND fecha_inicio >= '2024-01-01'
  AND fecha_inicio <  '2025-01-01'