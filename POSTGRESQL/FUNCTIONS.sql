-- FUNCTIONS
--========================================================================================
CREATE OR REPLACE FUNCTION fn_get_user_balance(p_usuario_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
  total_comprado INTEGER := 0;
  total_gastado  INTEGER := 0;
BEGIN
  SELECT COALESCE(SUM(monto_RP_obtenido), 0)
    INTO total_comprado
    FROM TransaccionesFinancieras
   WHERE usuario_id = p_usuario_id;

  SELECT COALESCE(SUM(costo_moneda), 0)
    INTO total_gastado
    FROM ComprasContenido
   WHERE usuario_id = p_usuario_id
     AND moneda_usada = 'RP';

  RETURN total_comprado - total_gastado;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
--========================================================================================
CREATE OR REPLACE FUNCTION fn_is_item_available(p_item_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
  v_disponible BOOLEAN;
BEGIN
  SELECT disponibilidad
    INTO v_disponible
    FROM ItemsTienda
   WHERE item_id = p_item_id;

  RETURN COALESCE(v_disponible, FALSE);
END;
$$ LANGUAGE plpgsql IMMUTABLE;
--========================================================================================
CREATE OR REPLACE FUNCTION fn_get_inventory_count(p_usuario_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO v_count
    FROM InventarioUsuario
   WHERE usuario_id = p_usuario_id;

  RETURN v_count;
END;
$$ LANGUAGE plpgsql STABLE;
--========================================================================================
CREATE OR REPLACE FUNCTION fn_get_total_spent(p_usuario_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
  v_total INTEGER;
BEGIN
  SELECT COALESCE(SUM(costo_moneda), 0)
    INTO v_total
    FROM ComprasContenido
   WHERE usuario_id = p_usuario_id;

  RETURN v_total;
END;
$$ LANGUAGE plpgsql STABLE;