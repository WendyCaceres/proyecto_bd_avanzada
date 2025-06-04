-- VIEWS
--========================================================================================
CREATE OR REPLACE VIEW vw_user_financial_summary AS
SELECT
  u.usuario_id,
  u.nombre_summoner,
  COALESCE(SUM(tf.monto_RP_obtenido), 0) AS total_RP_comprado,
  COALESCE(SUM(
    CASE WHEN cc.moneda_usada = 'RP' THEN cc.costo_moneda ELSE 0 END
  ), 0) AS total_RP_gastado,
  COALESCE(SUM(tf.monto_RP_obtenido), 0)
    - COALESCE(SUM(CASE WHEN cc.moneda_usada = 'RP' THEN cc.costo_moneda ELSE 0 END), 0)
    AS balance_RP
FROM Usuarios u
LEFT JOIN TransaccionesFinancieras tf
  ON u.usuario_id = tf.usuario_id
LEFT JOIN ComprasContenido cc
  ON u.usuario_id = cc.usuario_id
GROUP BY u.usuario_id, u.nombre_summoner;
--========================================================================================
CREATE OR REPLACE VIEW vw_available_items AS
SELECT 
  item_id,
  nombre_item,
  tipo_item,
  precio_RP,
  precio_esenciaAzul
FROM ItemsTienda
WHERE disponibilidad = TRUE
ORDER BY precio_RP DESC;
--========================================================================================
CREATE OR REPLACE VIEW vw_user_inventory AS
SELECT
  iu.usuario_id,
  u.nombre_summoner,
  iu.item_id,
  it.nombre_item,
  it.tipo_item,
  iu.origen,
  iu.fecha_obtencion
FROM InventarioUsuario iu
JOIN Usuarios u ON u.usuario_id = iu.usuario_id
JOIN ItemsTienda it ON it.item_id = iu.item_id;