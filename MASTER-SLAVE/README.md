## README: MySQL Master-Slave

## 1. Estructura de ficheros

```text
MASTER-SLAVE/
├── docker-compose.yml
├── master_data/         # volumen de datos del master
├── slave1_data/         # volumen de datos del slave1
└── slave2_data/         # volumen de datos del slave2
```

---

## 2. Definir `docker-compose.yml`

```yaml
version: "3.9"

services:
  mysql_master:
    image: mysql:latest
    container_name: mysql_master
    environment:
      MYSQL_ROOT_PASSWORD: masterpass
      MYSQL_DATABASE: lol_juego
      MYSQL_USER: user
      MYSQL_PASSWORD: password
      MYSQL_ROOT_HOST: "%"
    ports:
      - "3306:3306"
    command: --server-id=1
      --log-bin=mysql-bin
      --binlog-format=ROW
      --gtid-mode=ON
      --enforce-gtid-consistency=ON
    volumes:
      - ./master_data:/var/lib/mysql

  mysql_slave1:
    image: mysql:latest
    container_name: mysql_slave1
    depends_on: [mysql_master]
    environment:
      MYSQL_ROOT_PASSWORD: slavepass
      MYSQL_DATABASE: lol_juego
      MYSQL_USER: user
      MYSQL_PASSWORD: password
    ports:
      - "3307:3306"
    command: --server-id=2
      --relay-log=relay-bin
      --log-bin=mysql-bin
      --binlog-format=ROW
      --gtid-mode=ON
      --enforce-gtid-consistency=ON
    volumes:
      - ./slave1_data:/var/lib/mysql

  mysql_slave2:
    image: mysql:latest
    container_name: mysql_slave2
    depends_on: [mysql_master]
    environment:
      MYSQL_ROOT_PASSWORD: slavepass
      MYSQL_DATABASE: lol_juego
      MYSQL_USER: user
      MYSQL_PASSWORD: password
    ports:
      - "3308:3306"
    command: --server-id=3
      --relay-log=relay-bin
      --log-bin=mysql-bin
      --binlog-format=ROW
      --gtid-mode=ON
      --enforce-gtid-consistency=ON
    volumes:
      - ./slave2_data:/var/lib/mysql
```

---

## 3. Levantar el Master y crear usuario de réplica

1. Arranca solo el master:

   ```bash
   docker-compose up -d mysql_master
   ```

2. Crea el usuario de réplica con permisos:

   ```bash
   docker exec mysql_master mysql -uroot -pmasterpass -e "
     CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY 'replpass';
     GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
     FLUSH PRIVILEGES;
   "
   ```

---

## 4. Importar el backup en el Master

1. Asegúrate de que la base exista:

   ```bash
   docker exec mysql_master mysql -uroot -pmasterpass -e "CREATE DATABASE IF NOT EXISTS lol_juego;"
   ```

2. Copia tu SQL al contenedor:

   ```bash
   docker cp ../MYSQL/backups/backup_lol_juego_2025-06-04.sql mysql_master:/backup.sql
   ```

3. Importa con redirección interna:

   ```bash
   docker exec mysql_master sh -c \
     'mysql -uroot -pmasterpass lol_juego < /backup.sql'
   ```

---

## 5. Preparar Slaves “limpios”

1. Arranca los dos nuevos slaves:

   ```bash
   docker-compose up -d mysql_slave1 mysql_slave2
   ```

2. Crea la base en cada slave:

   ```bash
   docker exec mysql_slave1 mysql -uroot -pslavepass -e "CREATE DATABASE IF NOT EXISTS lol_juego;"
   docker exec mysql_slave2 mysql -uroot -pslavepass -e "CREATE DATABASE IF NOT EXISTS lol_juego;"
   ```

---

## 6. Importar el backup en los Slaves

```bash
# Slave 1
docker cp ../MYSQL/backups/backup_lol_juego_2025-06-04.sql mysql_slave1:/backup.sql
docker exec mysql_slave1 sh -c \
  'mysql -uroot -pslavepass lol_juego < /backup.sql'

# Slave 2
docker cp ../MYSQL/backups/backup_lol_juego_2025-06-04.sql mysql_slave2:/backup.sql
docker exec mysql_slave2 sh -c \
  'mysql -uroot -pslavepass lol_juego < /backup.sql'
```

---

## 7. Obtener coordenadas de binlog del Master

Tras la importación en el master, ejecuta:

```bash
docker exec -it mysql_master mysql -uroot -pmasterpass -e "SHOW BINARY LOGS STATUS;"
```

Anota:

- **File** (ej. `mysql-bin.000005`)
- **Position** (ej. `107`)

---

## 8. Configurar y arrancar la réplica en cada Slave

Sustituye `<FILE>` y `<POS>` por los valores obtenidos:

```bash
docker exec mysql_slave1 mysql -uroot -pslavepass -e "
  CHANGE REPLICATION SOURCE TO
    SOURCE_HOST='mysql_master',
    SOURCE_PORT=3306,
    SOURCE_USER='repl',
    SOURCE_PASSWORD='replpass',
    SOURCE_LOG_FILE='<FILE>',
    SOURCE_LOG_POS=<POS>,
    GET_SOURCE_PUBLIC_KEY=1;
  START REPLICA;
  SHOW REPLICA STATUS\G
"
```

Luego repite en `mysql_slave2`.

---

## 9. Verificación y prueba final

1. Comprueba en cada slave:

   ```bash
   docker exec mysql_slave1 mysql -uroot -pslavepass -e "SHOW REPLICA STATUS\G"
   ```

   Debe mostrar:

   ```
   Replica_IO_Running: Yes
   Replica_SQL_Running: Yes
   ```

2. Inserta un registro de prueba en el master:

   ```bash
   docker exec mysql_master mysql -uroot -pmasterpass -e "
     INSERT INTO Usuarios (nombre_summoner, region, nivel, estado_cuenta)
       VALUES ('ReplicaOK', 'EUW', 1, 'activo');
   "
   ```

3. Verifica en el slave:

   ```bash
   docker exec mysql_slave1 mysql -uroot -pslavepass \
     -e "SELECT * FROM Usuarios WHERE nombre_summoner='ReplicaOK';"
   ```
