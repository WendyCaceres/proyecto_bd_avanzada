-- VIEWS
--========================================================================================
CREATE VIEW vw_user_overview AS
SELECT 
  u.usuario_id,
  u.nombre_summoner,
  u.region,
  u.nivel,
  su.temporada,
  su.partidas_jugadas,
  su.victorias,
  su.derrotas,
  su.winrate,
  hc.liga_tier,
  hc.division,
  hc.LP_final
FROM Usuarios u
LEFT JOIN EstadisticasUsuario su 
  ON u.usuario_id = su.usuario_id
LEFT JOIN HistorialClasificacion hc
  ON u.usuario_id = hc.usuario_id
 AND su.temporada  = hc.temporada
--========================================================================================
CREATE VIEW vw_match_details AS
SELECT 
  p.partida_id,
  p.fecha_inicio,
  p.duracion,
  p.tipo_cola,
  p.mapa,
  p.parche_id,
  p.equipo_ganador,
  pa.usuario_id,
  pa.campeon_id,
  pa.equipo        AS equipo_participante,
  pa.rol_linea,
  pa.kills,
  pa.deaths,
  pa.assists,
  pa.farm_cs,
  pa.oro_obtenido,
  pa.oro_gastado,
  pa.dano_infligido,
  pa.curacion,
  pa.wards_colocados,
  pa.wards_destruidos
FROM Partidas p
JOIN Participantes pa 
  ON p.partida_id = pa.partida_id;
--========================================================================================
CREATE VIEW vw_champion_mastery AS
SELECT
  mc.usuario_id,
  mc.campeon_id,
  c.nombre_campeon,
  c.rol_principal,
  c.dificultad,
  mc.nivel_maestria,
  mc.puntos_maestria,
  mc.ultima_fecha_jugado
FROM MaestriaCampeon mc
JOIN Campeones c ON c.campeon_id = mc.campeon_id;