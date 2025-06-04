import os
import random
import psycopg2
from psycopg2 import sql, errors
from faker import Faker

PG_HOST = "localhost"
PG_PORT = 5432
PG_DB = "lol_economia"
PG_USER = "postgres"
PG_PASSWORD = "doriandev"

# Configuraciones de cantidad de registros
NUM_USUARIOS = 20000
NUM_METODOS_PAGO = 5
NUM_ITEMS = 200
NUM_TRANSACCIONES = 20000
NUM_COMPRAS = 30000
NUM_INVENTARIO = 20000

fake = Faker()

# Métodos de pago de ejemplo (validos)
METODOS_PAGO = ["Tarjeta Crédito", "PayPal", "Prepago", "Transferencia Bancaria", "Criptomoneda"]

# TIPOS_ITEM exactos según CHECK constraint en ItemsTienda
# Asegúrate que coincidan con la definición de la tabla (mayúsculas/minúsculas, acentos)
TIPOS_ITEM = ["Campeón", "Skin", "Icono", "Pase", "Otro"]

# Conexión a PostgreSQL
conn = psycopg2.connect(
    host=PG_HOST,
    port=PG_PORT,
    dbname=PG_DB,
    user=PG_USER,
    password=PG_PASSWORD
)
conn.autocommit = False
cur = conn.cursor()

# ---- 1) Insertar Métodos de Pago con limpieza previa ----
cur.execute("DELETE FROM MetodosPago;")
for nombre in METODOS_PAGO:
    cur.execute(
        "INSERT INTO MetodosPago (nombre_metodo) VALUES (%s);",
        (nombre,)
    )
conn.commit()

# Obtener IDs de MétodosPago
cur.execute("SELECT metodo_id FROM MetodosPago;")
metodos_ids = [row[0] for row in cur.fetchall()]

# ---- 2) Insertar ItemsTienda con manejo de errores de CHECK ----
cur.execute("DELETE FROM ItemsTienda;")
items_ids = []
attempts = 0
while len(items_ids) < NUM_ITEMS and attempts < NUM_ITEMS * 2:
    attempts += 1
    nombre_item = fake.unique.word().capitalize() + "_" + fake.unique.bothify(text="??-###")
    tipo_item = random.choice(TIPOS_ITEM)  # validamos contra la lista TIPOS_ITEM
    precio_RP = random.randint(100, 1500)
    precio_EA = random.randint(1000, 20000)
    disponibilidad = random.choice([True, True, True, False])
    try:
        cur.execute(
            """
            INSERT INTO ItemsTienda (nombre_item, tipo_item, precio_RP, precio_esenciaAzul, disponibilidad)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING item_id;
            """,
            (nombre_item, tipo_item, precio_RP, precio_EA, disponibilidad)
        )
        items_ids.append(cur.fetchone()[0])
    except errors.CheckViolation:
        # Si se viola el CHECK, lo ignoramos y seguimos intentando
        conn.rollback()
    except Exception as e:
        # Otras excepciones, hacemos rollback y seguimos
        conn.rollback()
    else:
        conn.commit()

# Obtener IDs de ItemsTienda
cur.execute("SELECT item_id FROM ItemsTienda;")
items_ids = [row[0] for row in cur.fetchall()]

# ---- 3) Insertar Usuarios con verificación de unicidad ----
cur.execute("DELETE FROM Usuarios;")
usuarios_ids = []
attempts = 0
while len(usuarios_ids) < NUM_USUARIOS and attempts < NUM_USUARIOS * 1.1:
    attempts += 1
    nombre_summoner = fake.unique.user_name()[:50]
    region = random.choice(["NA", "EUW", "EUNE", "KR", "BR", "LAN", "LAS", "OCE", "RU", "TR"])
    nivel = random.randint(1, 100)
    estado_cuenta = random.choice(["activo", "suspendido", "baneado"])
    try:
        cur.execute(
            """
            INSERT INTO Usuarios (nombre_summoner, region, nivel, estado_cuenta)
            VALUES (%s, %s, %s, %s)
            RETURNING usuario_id;
            """,
            (nombre_summoner, region, nivel, estado_cuenta)
        )
        usuarios_ids.append(cur.fetchone()[0])
    except errors.UniqueViolation:
        # Si nombre_summoner ya existe, revertir y seguir
        conn.rollback()
    except Exception:
        conn.rollback()
    else:
        conn.commit()

# ---- 4) Insertar TransaccionesFinancieras validando FK usuario/metodo ----
cur.execute("DELETE FROM TransaccionesFinancieras;")
for _ in range(NUM_TRANSACCIONES):
    usuario_id = random.choice(usuarios_ids)
    metodo_id = random.choice(metodos_ids)
    monto_dinero = round(random.uniform(5.0, 200.0), 2)
    monto_RP_obtenido = int(monto_dinero * random.uniform(8, 10))
    moneda_fiat = random.choice(["USD", "EUR", "GBP", "BRL"])
    try:
        cur.execute(
            """
            INSERT INTO TransaccionesFinancieras (usuario_id, metodo_id, monto_dinero, monto_RP_obtenido, moneda_fiat)
            VALUES (%s, %s, %s, %s, %s);
            """,
            (usuario_id, metodo_id, monto_dinero, monto_RP_obtenido, moneda_fiat)
        )
    except Exception:
        conn.rollback()
    else:
        conn.commit()

# ---- 5) Insertar ComprasContenido validando FK y disponibilidad de precio ----
cur.execute("DELETE FROM ComprasContenido;")
for _ in range(NUM_COMPRAS):
    usuario_id = random.choice(usuarios_ids)
    item_id = random.choice(items_ids)
    moneda_usada = random.choice(["RP", "EA"])
    cur.execute(
        "SELECT precio_RP, precio_esenciaAzul FROM ItemsTienda WHERE item_id = %s;",
        (item_id,)
    )
    precio_RP_db, precio_EA_db = cur.fetchone()
    costo_moneda = precio_RP_db if moneda_usada == "RP" else precio_EA_db
    try:
        cur.execute(
            """
            INSERT INTO ComprasContenido (usuario_id, item_id, moneda_usada, costo_moneda)
            VALUES (%s, %s, %s, %s);
            """,
            (usuario_id, item_id, moneda_usada, costo_moneda)
        )
    except Exception:
        conn.rollback()
    else:
        conn.commit()

# ---- 6) Insertar InventarioUsuario evitando duplicados ----
cur.execute("DELETE FROM InventarioUsuario;")
inventario_set = set()
attempts = 0
while len(inventario_set) < NUM_INVENTARIO and attempts < NUM_INVENTARIO * 1.2:
    attempts += 1
    usuario_id = random.choice(usuarios_ids)
    item_id = random.choice(items_ids)
    key = (usuario_id, item_id)
    if key in inventario_set:
        continue
    origen = random.choice(["Compra", "Recompensa", "Regalo", "Otro"])
    try:
        cur.execute(
            """
            INSERT INTO InventarioUsuario (usuario_id, item_id, origen)
            VALUES (%s, %s, %s);
            """,
            (usuario_id, item_id, origen)
        )
        inventario_set.add(key)
    except errors.UniqueViolation:
        conn.rollback()
    except Exception:
        conn.rollback()
    else:
        conn.commit()

# Cerrar conexión
cur.close()
conn.close()

print("Población completada:")
print(f"  - Usuarios: {len(usuarios_ids)}")
print(f"  - Métodos de pago: {len(METODOS_PAGO)}")
print(f"  - Items en tienda: {len(items_ids)}")
print(f"  - Transacciones financieras: {NUM_TRANSACCIONES}")
print(f"  - Compras de contenido: {NUM_COMPRAS}")
print(f"  - Registros de inventario: {len(inventario_set)}")

