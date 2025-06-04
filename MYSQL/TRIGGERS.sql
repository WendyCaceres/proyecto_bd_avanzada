-- TRIGGERS
--========================================================================================
DELIMITER $$
CREATE TRIGGER trg_before_partidas_check_duration
BEFORE INSERT ON Partidas
FOR EACH ROW
BEGIN
  IF NEW.duracion < 600 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Duración mínima de partida es 600 segundos (trigger).';
  END IF;
END $$ 
DELIMITER ;
--========================================================================================
DELIMITER $$
CREATE TRIGGER trg_before_participantes_limit_count
BEFORE INSERT ON Participantes
FOR EACH ROW
BEGIN
  DECLARE v_count INT DEFAULT 0;

  SELECT COUNT(*) INTO v_count
    FROM Participantes
   WHERE partida_id = NEW.partida_id;

  IF v_count >= 10 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La partida ya tiene 10 participantes (trigger).';
  END IF;
END $$ 
DELIMITER ;
--========================================================================================
DELIMITER $$
CREATE TRIGGER trg_after_participantes_update_team_stats
AFTER INSERT ON Participantes
FOR EACH ROW
BEGIN
  DECLARE v_exists INT DEFAULT 0;

  SELECT COUNT(*) INTO v_exists
    FROM EstadisticasEquipo
   WHERE partida_id = NEW.partida_id
     AND equipo     = NEW.equipo;

  IF v_exists = 0 THEN
    -- Insertar fila inicial con valores 0 y luego actualizar
    INSERT INTO EstadisticasEquipo(
      partida_id, equipo, torres_destruidas, inhibidores_destruidos,
      dragones, heraldos, barones, kills_equipo, oro_equipo, resultado
    ) VALUES (
      NEW.partida_id, NEW.equipo, 0, 0, 0, 0, 0,
      NEW.kills, NEW.oro_obtenido, 'Pendiente'
    );
  ELSE
    -- Incrementar kills_equipo y oro_equipo
    UPDATE EstadisticasEquipo
       SET kills_equipo = kills_equipo + NEW.kills,
           oro_equipo   = oro_equipo   + NEW.oro_obtenido
     WHERE partida_id = NEW.partida_id
       AND equipo     = NEW.equipo;
  END IF;
END $$ 
DELIMITER ;
--========================================================================================
DELIMITER $$
CREATE TRIGGER trg_before_maestria_check_level
BEFORE INSERT ON MaestriaCampeon
FOR EACH ROW
BEGIN
  IF NEW.nivel_maestria < 0 OR NEW.nivel_maestria > 7 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Nivel de maestría debe estar entre 0 y 7 (trigger).';
  END IF;
END $$ 
DELIMITER ;