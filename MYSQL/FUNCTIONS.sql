-- FUNCTIONS
--========================================================================================
DELIMITER $$
CREATE FUNCTION fn_get_user_winrate(
  p_usuario_id INT,
  p_temporada VARCHAR(10)
)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
  DECLARE v_winrate DECIMAL(5,2) DEFAULT 0.00;

  SELECT winrate INTO v_winrate
    FROM EstadisticasUsuario
   WHERE usuario_id = p_usuario_id
     AND temporada = p_temporada
   LIMIT 1;

  RETURN v_winrate;
END $$ 
DELIMITER ;
--========================================================================================
DELIMITER $$
CREATE FUNCTION fn_get_user_rank(
  p_usuario_id INT,
  p_temporada VARCHAR(10)
)
RETURNS VARCHAR(30)
DETERMINISTIC
BEGIN
  DECLARE v_tier VARCHAR(20);
  DECLARE v_division VARCHAR(10);
  DECLARE v_rank VARCHAR(30) DEFAULT 'Sin datos';

  SELECT liga_tier, division
    INTO v_tier, v_division
    FROM HistorialClasificacion
   WHERE usuario_id = p_usuario_id
     AND temporada = p_temporada
   LIMIT 1;

  IF v_tier IS NOT NULL AND v_division IS NOT NULL THEN
    SET v_rank = CONCAT(v_tier, ' ', v_division);
  END IF;

  RETURN v_rank;
END $$ 
DELIMITER ;
--========================================================================================
DELIMITER $$
CREATE FUNCTION fn_get_avg_match_duration()
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE v_avg_duration INT DEFAULT 0;

  SELECT FLOOR(AVG(duracion)) INTO v_avg_duration
    FROM Partidas;

  RETURN v_avg_duration;
END $$ 
DELIMITER ;
--========================================================================================
DELIMITER $$
CREATE FUNCTION fn_count_user_partidas(
  p_usuario_id INT
)
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE v_count INT DEFAULT 0;

  SELECT COUNT(*) INTO v_count
    FROM Participantes
   WHERE usuario_id = p_usuario_id;

  RETURN v_count;
END $$ 
DELIMITER ;