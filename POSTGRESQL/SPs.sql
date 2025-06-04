-- SPs
--========================================================================================
CREATE OR REPLACE PROCEDURE sp_top_up_RP(
    p_usuario_id    INTEGER,
    p_metodo_id     INTEGER,
    p_monto_dinero  NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
  v_monto_RP INTEGER;
BEGIN
  IF p_monto_dinero <= 0 THEN
    RAISE EXCEPTION 'El monto de dinero debe ser positivo. Monto: %', p_monto_dinero;
  END IF;

  -- Ejemplo de tasa de conversión: 1 unidad de dinero = 9 RP
  v_monto_RP := FLOOR(p_monto_dinero * 9);

  INSERT INTO TransaccionesFinancieras(
    usuario_id, metodo_id, monto_dinero, monto_RP_obtenido, moneda_fiat
  ) VALUES (
    p_usuario_id, p_metodo_id, p_monto_dinero, v_monto_RP, 'USD'
  );
EXCEPTION
  WHEN foreign_key_violation THEN
    RAISE EXCEPTION 'Usuario o método de pago inválido. Usuario: %, Método: %',
        p_usuario_id, p_metodo_id;
  WHEN CHECK_VIOLATION THEN
    RAISE EXCEPTION 'Violación de CHECK: monto inválido.';
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE EXCEPTION 'Error desconocido al recargar RP: %', SQLERRM;
END;
$$;
--========================================================================================
CREATE OR REPLACE PROCEDURE sp_buy_item(
    p_usuario_id INTEGER,
    p_item_id    INTEGER,
    p_moneda     TEXT  -- 'RP' o 'EA'
)
LANGUAGE plpgsql AS $$
DECLARE
  v_disponible BOOLEAN;
  v_costo       INTEGER;
BEGIN
  -- 1) Verificar que el ítem exista y esté disponible
  SELECT disponibilidad
    INTO v_disponible
    FROM ItemsTienda
   WHERE item_id = p_item_id;

  IF v_disponible IS NULL THEN
    RAISE EXCEPTION 'Ítem % no existe.', p_item_id;
  ELSIF v_disponible = FALSE THEN
    RAISE EXCEPTION 'Ítem % no está disponible para compra.', p_item_id;
  END IF;

  -- 2) Obtener precio según moneda
  IF p_moneda = 'RP' THEN
    SELECT precio_RP INTO v_costo
      FROM ItemsTienda
     WHERE item_id = p_item_id;
  ELSIF p_moneda = 'EA' THEN
    SELECT precio_esenciaAzul INTO v_costo
      FROM ItemsTienda
     WHERE item_id = p_item_id;
  ELSE
    RAISE EXCEPTION 'Moneda desconocida: %', p_moneda;
  END IF;

  -- 3) Insertar en ComprasContenido
  INSERT INTO ComprasContenido(usuario_id, item_id, moneda_usada, costo_moneda)
    VALUES (p_usuario_id, p_item_id, p_moneda, v_costo);

  -- 4) Insertar en InventarioUsuario
  INSERT INTO InventarioUsuario(usuario_id, item_id, origen)
    VALUES (p_usuario_id, p_item_id, 'Compra');
EXCEPTION
  WHEN foreign_key_violation THEN
    RAISE EXCEPTION 'Usuario o ítem inválido en compra. Usuario: %, Ítem: %',
        p_usuario_id, p_item_id;
  WHEN CHECK_VIOLATION THEN
    RAISE EXCEPTION 'Violación de CHECK en compra de contenido.';
  WHEN unique_violation THEN
    RAISE EXCEPTION 'El ítem % ya existe en inventario de usuario %.',
        p_item_id, p_usuario_id;
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
$$;
--========================================================================================
CREATE OR REPLACE PROCEDURE sp_add_item_to_inventory(
    p_usuario_id INTEGER,
    p_item_id    INTEGER,
    p_origen     VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO InventarioUsuario(usuario_id, item_id, origen)
    VALUES (p_usuario_id, p_item_id, p_origen);
EXCEPTION
  WHEN foreign_key_violation THEN
    RAISE EXCEPTION 'Usuario o ítem inválido. Usuario: %, Ítem: %',
        p_usuario_id, p_item_id;
  WHEN unique_violation THEN
    RAISE EXCEPTION 'El ítem % ya existe en inventario de usuario %.',
        p_item_id, p_usuario_id;
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
$$;
--========================================================================================
CREATE OR REPLACE PROCEDURE sp_delete_user(p_usuario_id INTEGER)
LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM Usuarios WHERE usuario_id = p_usuario_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Usuario % no encontrado. No se borró nada.', p_usuario_id;
  END IF;
EXCEPTION
  WHEN foreign_key_violation THEN
    RAISE EXCEPTION 'No se pueden borrar algunas referencias en cascada.';
  WHEN OTHERS THEN
    RAISE;
END;
$$;