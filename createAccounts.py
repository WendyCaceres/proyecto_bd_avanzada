import psycopg2
from faker import Faker
import random
from datetime import datetime, timedelta
from faker.exceptions import UniquenessException

# Configuración de la conexión a la base de datos
DB_NAME = 'DBNAME'
DB_USER = 'DBUSER'
DB_PASSWORD = 'DBPASSWORD'
DB_HOST = 'localhost'
DB_PORT = '5432'

# Número de registros a insertar
NUM_REGISTROS = 30000
# Tamaño del lote para inserciones por lotes
TAMANIO_LOTE = 1000
fake = Faker()
fake_unique = fake.unique

def generar_datos_accounts():
    datos = []
    intentos_fallidos = 0
    for _ in range(NUM_REGISTROS):
        try:
            username = fake_unique.user_name()
            password_hash = fake.sha256()
            email = fake_unique.email()
            server_id = random.randint(1, 10)
            rp_balance = round(random.uniform(0, 10000), 2)
            last_login = fake.date_time_between(start_date='-1y', end_date='now')
            created_at = fake.date_time_between(start_date='-2y', end_date='-1y')
            datos.append((username, password_hash, email, server_id, rp_balance, last_login, created_at))
        except UniquenessException:
            intentos_fallidos += 1
            if intentos_fallidos > 100:
                fake_unique.clear()
                intentos_fallidos = 0
    return datos

def insertar_datos():
    try:
        # Conectar a la base de datos
        conn = psycopg2.connect(
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT
        )
        cursor = conn.cursor()

        # Generar datos
        datos = generar_datos_accounts()

        # Insertar datos en lotes
        for i in range(0, NUM_REGISTROS, TAMANIO_LOTE):
            lote = datos[i:i+TAMANIO_LOTE]
            args_str = b','.join(cursor.mogrify("(%s, %s, %s, %s, %s, %s, %s)", x) for x in lote)
            cursor.execute(b"INSERT INTO accounts (username, password_hash, email, server_id, rp_balance, last_login, created_at) VALUES " + args_str)
            conn.commit()
            print(f"Lote {i//TAMANIO_LOTE + 1} insertado correctamente.")

        print("Inserción completada exitosamente.")
    except Exception as e:
        print(f"Error al insertar datos: {e}")
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    insertar_datos()
