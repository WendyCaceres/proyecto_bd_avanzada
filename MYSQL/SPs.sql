-- SPs
--========================================================================================
DELIMITER $$
CREATE PROCEDURE sp_update_user_level(
  IN p_usuario_id INT,
  IN p_new_level INT
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 'Error: No se pudo actualizar el nivel del usuario.' AS mensaje;
  END;

  START TRANSACTION;

  IF p_new_level < 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nuevo nivel debe ser mayor o igual a 1.';
  END IF;

  UPDATE Usuarios
    SET nivel = p_new_level
  WHERE usuario_id = p_usuario_id;

  COMMIT;
END $$ 
DELIMITER ;
--========================================================================================
DELIMITER $$
CREATE PROCEDURE sp_record_match(
  IN p_fecha_inicio DATETIME,
  IN p_duracion     INT,
  IN p_tipo_cola    VARCHAR(20),
  IN p_mapa         VARCHAR(20),
  IN p_parche_id    INT,
  IN p_equipo_ganador ENUM('Blue','Red')
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 'Error: No se pudo registrar la partida.' AS mensaje;
  END;

  START TRANSACTION;

  IF p_duracion < 600 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La duración mínima de la partida es 600 segundos.';
  END IF;

  INSERT INTO Partidas(
    fecha_inicio, duracion, tipo_cola, mapa, parche_id, equipo_ganador
  ) VALUES (
    p_fecha_inicio, p_duracion, p_tipo_cola, p_mapa, p_parche_id, p_equipo_ganador
  );

  COMMIT;
END $$ 
DELIMITER ;
--========================================================================================
DELIMITER $$
CREATE PROCEDURE sp_add_participant(
  IN p_partida_id     BIGINT,
  IN p_usuario_id     INT,
  IN p_campeon_id     INT,
  IN p_equipo         ENUM('Blue','Red'),
  IN p_rol_linea      VARCHAR(20),
  IN p_kills          INT,
  IN p_deaths         INT,
  IN p_assists        INT,
  IN p_farm_cs        INT,
  IN p_oro_obtenido   INT,
  IN p_oro_gastado    INT,
  IN p_dano_infligido INT,
  IN p_curacion       INT,
  IN p_wards_colocados  INT,
  IN p_wards_destruidos INT
)
BEGIN
  DECLARE v_count INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 'Error: No se pudo agregar participante.' AS mensaje;
  END;

  START TRANSACTION;

  -- Contar cuántos participantes hay ya en esta partida
  SELECT COUNT(*) INTO v_count
    FROM Participantes
   WHERE partida_id = p_partida_id;

  IF v_count >= 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La partida ya tiene 10 participantes.';
  END IF;

  INSERT INTO Participantes(
    partida_id, usuario_id, campeon_id, equipo, rol_linea, kills,
    deaths, assists, farm_cs, oro_obtenido, oro_gastado,
    dano_infligido, curacion, wards_colocados, wards_destruidos
  ) VALUES (
    p_partida_id, p_usuario_id, p_campeon_id, p_equipo, p_rol_linea, p_kills,
    p_deaths, p_assists, p_farm_cs, p_oro_obtenido, p_oro_gastado,
    p_dano_infligido, p_curacion, p_wards_colocados, p_wards_destruidos
  );

  COMMIT;
END $$ 
DELIMITER ;
--========================================================================================
DELIMITER $$
CREATE PROCEDURE sp_update_statsteam(
  IN p_partida_id      BIGINT,
  IN p_equipo          ENUM('Blue','Red'),
  IN p_torres           INT,
  IN p_inhibidores      INT,
  IN p_dragones         INT,
  IN p_heraldos         INT,
  IN p_barones          INT,
  IN p_kills_equipo     INT,
  IN p_oro_equipo       INT,
  IN p_resultado        VARCHAR(10)  -- 'Victoria' o 'Derrota'
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 'Error: No se pudo actualizar estadísticas de equipo.' AS mensaje;
  END;

  START TRANSACTION;

  IF EXISTS (
    SELECT 1 
      FROM EstadisticasEquipo
     WHERE partida_id = p_partida_id
       AND equipo     = p_equipo
  ) THEN
    UPDATE EstadisticasEquipo
      SET torres_destruidas      = p_torres,
          inhibidores_destruidos = p_inhibidores,
          dragones               = p_dragones,
          heraldos               = p_heraldos,
          barones                = p_barones,
          kills_equipo           = p_kills_equipo,
          oro_equipo             = p_oro_equipo,
          resultado              = p_resultado
    WHERE partida_id = p_partida_id
      AND equipo     = p_equipo;
  ELSE
    INSERT INTO EstadisticasEquipo(
      partida_id, equipo, torres_destruidas, inhibidores_destruidos,
      dragones, heraldos, barones, kills_equipo, oro_equipo, resultado
    ) VALUES (
      p_partida_id, p_equipo, p_torres, p_inhibidores,
      p_dragones, p_heraldos, p_barones, p_kills_equipo, p_oro_equipo, p_resultado
    );
  END IF;

  COMMIT;
END $$ 
DELIMITER ;