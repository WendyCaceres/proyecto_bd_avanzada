import os
import random
import mysql.connector
from mysql.connector import errorcode, IntegrityError
from faker import Faker
from datetime import datetime, timedelta

MYSQL_HOST = "localhost"
MYSQL_PORT = 3306
MYSQL_DB = "lol_juego"
MYSQL_USER = "root"
MYSQL_PASSWORD = "doriandev"

# Configuraciones de cantidad de registros
NUM_USUARIOS = 20000
NUM_VERSIONES = 10
NUM_CAMPEONES = 150
NUM_PARTIDAS = 20000
PARTICIPANTES_POR_PARTIDA = 10  # 5 vs 5
OBJETIVOS_POR_PARTIDA = 3
MAESTRIA_POR_USUARIO = 5
TEMPORADAS = ["2023", "2024", "2025"]

fake = Faker()

# Conexión a MySQL
conn = mysql.connector.connect(
    host=MYSQL_HOST,
    port=MYSQL_PORT,
    database=MYSQL_DB,
    user=MYSQL_USER,
    password=MYSQL_PASSWORD
)
cur = conn.cursor()

# ---- 1) Insertar Usuarios (Juego) ----
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
            VALUES (%s, %s, %s, %s);
            """,
            (nombre_summoner, region, nivel, estado_cuenta)
        )
        usuarios_ids.append(cur.lastrowid)
        conn.commit()
    except IntegrityError:
        conn.rollback()
    except Exception:
        conn.rollback()

# ---- 2) Insertar VersionesJuego ----
cur.execute("DELETE FROM VersionesJuego;")
versiones_ids = []
base_date = datetime(2020, 1, 1)
for i in range(NUM_VERSIONES):
    version_nombre = f"{10 + i//4}.{i%4 + 1}"
    fecha_lanzamiento = base_date + timedelta(days=30 * i)
    descripcion_resumen = fake.sentence(nb_words=6)
    try:
        cur.execute(
            """
            INSERT INTO VersionesJuego (version_nombre, fecha_lanzamiento, descripcion_resumen)
            VALUES (%s, %s, %s);
            """,
            (version_nombre, fecha_lanzamiento.date(), descripcion_resumen)
        )
        versiones_ids.append(cur.lastrowid)
        conn.commit()
    except IntegrityError:
        conn.rollback()
    except Exception:
        conn.rollback()

# ---- 3) Insertar Campeones ----
cur.execute("DELETE FROM Campeones;")
campeones_ids = []
for _ in range(NUM_CAMPEONES):
    nombre_campeon = fake.unique.first_name()[:50]
    rol_principal = random.choice(["Asesino", "Mago", "Luchador", "Tirador", "Soporte", "Tanque"])
    dificultad = random.choice(["Baja", "Media", "Alta"])
    fecha_lanzamiento = base_date + timedelta(days=random.randint(0, 2000))
    try:
        cur.execute(
            """
            INSERT INTO Campeones (nombre_campeon, rol_principal, dificultad, fecha_lanzamiento)
            VALUES (%s, %s, %s, %s);
            """,
            (nombre_campeon, rol_principal, dificultad, fecha_lanzamiento.date())
        )
        campeones_ids.append(cur.lastrowid)
        conn.commit()
    except IntegrityError:
        conn.rollback()
    except Exception:
        conn.rollback()

# ---- 4) Insertar Partidas ----
cur.execute("DELETE FROM Partidas;")
partidas_ids = []
for _ in range(NUM_PARTIDAS):
    fecha_inicio = base_date + timedelta(days=random.randint(0, 1000), hours=random.randint(0, 23), minutes=random.randint(0, 59))
    duracion = random.randint(600, 3600)  # entre 10 min y 60 min
    tipo_cola = random.choice(["Clasificatoria", "Normal", "ARAM"])
    mapa = random.choice(["Summoner's Rift", "Howling Abyss"])
    parche_id = random.choice(versiones_ids) if versiones_ids else 1
    equipo_ganador = random.choice(["Blue", "Red"])
    try:
        cur.execute(
            """
            INSERT INTO Partidas (fecha_inicio, duracion, tipo_cola, mapa, parche_id, equipo_ganador)
            VALUES (%s, %s, %s, %s, %s, %s);
            """,
            (fecha_inicio, duracion, tipo_cola, mapa, parche_id, equipo_ganador)
        )
        partidas_ids.append(cur.lastrowid)
        conn.commit()
    except IntegrityError:
        conn.rollback()
    except Exception:
        conn.rollback()

# ---- 5) Insertar Participantes ----
cur.execute("DELETE FROM Participantes;")
for partida_id in partidas_ids:
    participantes_muestra = random.sample(usuarios_ids, PARTICIPANTES_POR_PARTIDA)
    for usuario_id in participantes_muestra:
        campeon_id = random.choice(campeones_ids) if campeones_ids else 1
        equipo = "Blue" if random.random() < 0.5 else "Red"
        rol_linea = random.choice(["Top", "Jungla", "Mid", "ADC", "Support"])
        kills = random.randint(0, 20)
        deaths = random.randint(0, 20)
        assists = random.randint(0, 30)
        farm_cs = random.randint(0, 300)
        oro_obtenido = random.randint(500, 20000)
        oro_gastado = random.randint(400, oro_obtenido)
        dano_infligido = random.randint(1000, 50000)
        curacion = random.randint(0, 20000)
        wards_colocados = random.randint(0, 20)
        wards_destruidos = random.randint(0, 20)
        try:
            cur.execute(
                """
                INSERT INTO Participantes
                (partida_id, usuario_id, campeon_id, equipo, rol_linea, kills, deaths, assists,
                 farm_cs, oro_obtenido, oro_gastado, dano_infligido, curacion, wards_colocados, wards_destruidos)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
                """,
                (partida_id, usuario_id, campeon_id, equipo, rol_linea, kills, deaths, assists,
                 farm_cs, oro_obtenido, oro_gastado, dano_infligido, curacion, wards_colocados, wards_destruidos)
            )
            conn.commit()
        except IntegrityError:
            conn.rollback()
        except Exception:
            conn.rollback()

# ---- 6) Insertar EstadisticasEquipo ----
cur.execute("DELETE FROM EstadisticasEquipo;")
for partida_id in partidas_ids:
    for equipo in ["Blue", "Red"]:
        torres_destruidas = random.randint(0, 11)
        inhibidores_destruidos = random.randint(0, 3)
        dragones = random.randint(0, 5)
        heraldos = random.randint(0, 1)
        barones = random.randint(0, 1)
        kills_equipo = random.randint(0, 50)
        oro_equipo = random.randint(10000, 80000)
        resultado = "Victoria" if (equipo == random.choice(["Blue", "Red"])) else "Derrota"
        try:
            cur.execute(
                """
                INSERT INTO EstadisticasEquipo
                (partida_id, equipo, torres_destruidas, inhibidores_destruidos, dragones, heraldos,
                 barones, kills_equipo, oro_equipo, resultado)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
                """,
                (partida_id, equipo, torres_destruidas, inhibidores_destruidos, dragones, heraldos,
                 barones, kills_equipo, oro_equipo, resultado)
            )
            conn.commit()
        except IntegrityError:
            conn.rollback()
        except Exception:
            conn.rollback()

# ---- 7) Insertar ObjetivosPartida ----
cur.execute("DELETE FROM ObjetivosPartida;")
for partida_id in partidas_ids:
    for _ in range(OBJETIVOS_POR_PARTIDA):
        tipo_objetivo = random.choice(["Dragón", "Barón", "Torre", "Herald"])
        detalle = random.choice(["Dragón Infernal", "Dragón de Fuego", "Torre Inhibidor Top", "Herald de la Grieta"])
        minuto_partida = random.randint(1, 50)
        equipo_responsable = random.choice(["Blue", "Red"])
        try:
            cur.execute(
                """
                INSERT INTO ObjetivosPartida
                (partida_id, tipo_objetivo, detalle, minuto_partida, equipo_responsable)
                VALUES (%s, %s, %s, %s, %s);
                """,
                (partida_id, tipo_objetivo, detalle, minuto_partida, equipo_responsable)
            )
            conn.commit()
        except IntegrityError:
            conn.rollback()
        except Exception:
            conn.rollback()

# ---- 8) Insertar MaestriaCampeon ----
cur.execute("DELETE FROM MaestriaCampeon;")
maestria_set = set()
while len(maestria_set) < NUM_USUARIOS * MAESTRIA_POR_USUARIO:
    usuario_id = random.choice(usuarios_ids)
    campeon_id = random.choice(campeones_ids) if campeones_ids else 1
    key = (usuario_id, campeon_id)
    if key in maestria_set:
        continue
    nivel_maestria = random.randint(0, 7)
    puntos_maestria = random.randint(0, 100000)
    ultima_fecha_jugado = base_date + timedelta(days=random.randint(0, 1000))
    try:
        cur.execute(
            """
            INSERT INTO MaestriaCampeon
            (usuario_id, campeon_id, nivel_maestria, puntos_maestria, ultima_fecha_jugado)
            VALUES (%s, %s, %s, %s, %s);
            """,
            (usuario_id, campeon_id, nivel_maestria, puntos_maestria, ultima_fecha_jugado.date())
        )
        maestria_set.add(key)
        conn.commit()
    except IntegrityError:
        conn.rollback()
    except Exception:
        conn.rollback()

# ---- 9) Insertar EstadisticasUsuario ----
cur.execute("DELETE FROM EstadisticasUsuario;")
for usuario_id in usuarios_ids:
    for temporada in TEMPORADAS:
        partidas_jugadas = random.randint(0, 500)
        victorias = random.randint(0, partidas_jugadas)
        derrotas = partidas_jugadas - victorias
        winrate = round((victorias / partidas_jugadas * 100), 2) if partidas_jugadas > 0 else 0.00
        kda_promedio = round(random.uniform(1.0, 10.0), 2)
        promedio_oro_por_partida = random.randint(500, 20000)
        promedio_dano_por_partida = random.randint(1000, 50000)
        try:
            cur.execute(
                """
                INSERT INTO EstadisticasUsuario
                (usuario_id, temporada, partidas_jugadas, victorias, derrotas, winrate,
                 kda_promedio, promedio_oro_por_partida, promedio_dano_por_partida)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s);
                """,
                (usuario_id, temporada, partidas_jugadas, victorias, derrotas, winrate,
                 kda_promedio, promedio_oro_por_partida, promedio_dano_por_partida)
            )
            conn.commit()
        except IntegrityError:
            conn.rollback()
        except Exception:
            conn.rollback()

# ---- 10) Insertar HistorialClasificacion ----
cur.execute("DELETE FROM HistorialClasificacion;")
for usuario_id in usuarios_ids:
    for temporada in TEMPORADAS:
        liga_tier = random.choice(["Hierro", "Bronce", "Plata", "Oro", "Platino", "Diamante"])
        division = random.choice(["I", "II", "III", "IV"])
        LP_final = random.randint(0, 100)
        rango_mundial = random.randint(1, 100000)
        try:
            cur.execute(
                """
                INSERT INTO HistorialClasificacion
                (usuario_id, temporada, liga_tier, division, LP_final, rango_mundial)
                VALUES (%s, %s, %s, %s, %s, %s);
                """,
                (usuario_id, temporada, liga_tier, division, LP_final, rango_mundial)
            )
            conn.commit()
        except IntegrityError:
            conn.rollback()
        except Exception:
            conn.rollback()

# Cerrar conexión
cur.close()
conn.close()

print("Población completada:")
print(f"  - Usuarios: {len(usuarios_ids)}")
print(f"  - VersionesJuego: {len(versiones_ids)}")
print(f"  - Campeones: {len(campeones_ids)}")
print(f"  - Partidas: {len(partidas_ids)}")
print(f"  - Participantes: {len(partidas_ids) * PARTICIPANTES_POR_PARTIDA}")
print(f"  - EstadisticasEquipo: {len(partidas_ids) * 2}")
print(f"  - ObjetivosPartida: {len(partidas_ids) * OBJETIVOS_POR_PARTIDA}")
print(f"  - MaestriaCampeon: {len(maestria_set)}")
print(f"  - EstadisticasUsuario: {len(usuarios_ids) * len(TEMPORADAS)}")
print(f"  - HistorialClasificacion: {len(usuarios_ids) * len(TEMPORADAS)}")

