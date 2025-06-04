-- TRIGGERS
--========================================================================================
CREATE OR REPLACE FUNCTION trg_before_compras_check_availability_fn()
RETURNS trigger AS $$
DECLARE
  v_disponible BOOLEAN;
BEGIN
  SELECT disponibilidad
    INTO v_disponible
    FROM ItemsTienda
   WHERE item_id = NEW.item_id;

  IF v_disponible IS NULL THEN
    RAISE EXCEPTION 'Ítem % no existe (trigger).', NEW.item_id;
  ELSIF v_disponible = FALSE THEN
    RAISE EXCEPTION 'Ítem % no disponible (trigger).', NEW.item_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_before_compras_check_availability
  BEFORE INSERT ON ComprasContenido
  FOR EACH ROW
  EXECUTE FUNCTION trg_before_compras_check_availability_fn();
--========================================================================================
CREATE OR REPLACE FUNCTION trg_after_compras_add_inventory_fn()
RETURNS trigger AS $$
BEGIN
  -- Solo si NO existe ya en InventarioUsuario
  IF NOT EXISTS (
    SELECT 1
      FROM InventarioUsuario
     WHERE usuario_id = NEW.usuario_id
       AND item_id    = NEW.item_id
  ) THEN
    INSERT INTO InventarioUsuario(usuario_id, item_id, origen)
    VALUES (NEW.usuario_id, NEW.item_id, 'Compra directo trigger');
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_after_compras_add_inventory
  AFTER INSERT ON ComprasContenido
  FOR EACH ROW
  EXECUTE FUNCTION trg_after_compras_add_inventory_fn();
--========================================================================================
CREATE OR REPLACE FUNCTION trg_before_transacciones_check_amount_fn()
RETURNS trigger AS $$
BEGIN
  IF NEW.monto_dinero <= 0 THEN
    RAISE EXCEPTION 'El monto de dinero (% ) debe ser mayor que 0 (trigger).', NEW.monto_dinero;
  END IF;
  IF NEW.monto_RP_obtenido <= 0 THEN
    RAISE EXCEPTION 'El monto de RP obtenido (% ) debe ser mayor que 0 (trigger).', NEW.monto_RP_obtenido;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_before_transacciones_check_amount
  BEFORE INSERT ON TransaccionesFinancieras
  FOR EACH ROW
  EXECUTE FUNCTION trg_before_transacciones_check_amount_fn();
--========================================================================================
CREATE OR REPLACE FUNCTION trg_after_inventario_log_fn()
RETURNS trigger AS $$
BEGIN
  RAISE NOTICE 'Usuario % obtuvo ítem % vía % (trigger).', 
    NEW.usuario_id, NEW.item_id, NEW.origen;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_after_inventario_log
  AFTER INSERT ON InventarioUsuario
  FOR EACH ROW
  EXECUTE FUNCTION trg_after_inventario_log_fn();