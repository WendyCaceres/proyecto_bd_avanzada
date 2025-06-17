# README: Sharding de Usuarios por Región

## Estructura de ficheros

```text
SHARDING/
├── docker-compose.yml    # Define dos shards PostgreSQL
├── config-server.js      # Script Node.js que enruta inserciones/lecturas
├── shard_lp_data/        # Volumen de datos shard LP
└── shard_lan_data/       # Volumen de datos shard LAN
```

---

## 1. Definir `docker-compose.yml`

```yaml
version: "3.9"

services:
  shard_las:
    image: postgres:latest
    container_name: shard_las
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: shardpass
      POSTGRES_DB: lol_shard_las
    ports:
      - "5432:5432"
    volumes:
      - ./shard_las_data:/var/lib/postgresql/data

  shard_lan:
    image: postgres:latest
    container_name: shard_lan
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: shardpass
      POSTGRES_DB: lol_shard_lan
    ports:
      - "5433:5432"
    volumes:
      - ./shard_lan_data:/var/lib/postgresql/data
```

---

## 2. Levantar los Shards

```bash
# En tu directorio SHARDING
docker-compose -f docker-compose.yml up -d
```

---

## 3. Crear esquema y restaurar backup en cada shard

La tabla `Usuarios` debe existir en ambos shards con la misma estructura:

```sql
CREATE TABLE IF NOT EXISTS Usuarios (
  usuario_id     SERIAL PRIMARY KEY,
  nombre_summoner VARCHAR(50) NOT NULL,
  region          VARCHAR(10) NOT NULL,
  nivel           INTEGER NOT NULL,
  fecha_registro  DATE    NOT NULL DEFAULT CURRENT_DATE,
  estado_cuenta   VARCHAR(20) NOT NULL
);
```

### 3.1 Restaurar backup

Debes copiar e importar tu backup SQL en cada shard. **Nota:** ejecuta el script de restauración **dos veces** para asegurar que las dependencias (esquema y datos) queden consistentes y reemplazar en el script `restoreDb.js` las rutas de conexión a cada shard.

```bash
# Ejecutar script para restarurar en shard_las
node ../POSTGRESQL/scripts/restoreDb.js

# Repetir en shard_lan
node ../POSTGRESQL/scripts/restoreDb.js
```

---

## 4. Configurar el Config Server (Node.js)

Edita `config-server.js` si cambias rutas o credenciales, luego instala dependencias y ejecútalo:

```bash
npm install postgres
node config-server.js
```

El script expondrá funciones:

- `insertUser(data)` para enrutar inserciones a un shard según `region` o hash de `id`.
- `getUsersFrom(region)` para leer de un shard específico.
- `getAllUsers()` para leer todos los shards.

---

## 5. Pruebas de sharding

```js
import { insertUser, getAllUsers } from "./config-server.js";

// Inserciones
await insertUser({
  id: 1,
  nombre_summoner: "Alice",
  region: "LAS",
  nivel: 10,
  estado_cuenta: "activo",
});
await insertUser({
  id: 2,
  nombre_summoner: "Bob",
  region: "LAN",
  nivel: 15,
  estado_cuenta: "activo",
});
await insertUser({
  id: 3,
  nombre_summoner: "Carol",
  region: "NA",
  nivel: 8,
  estado_cuenta: "suspendido",
});

// Lectura global
getAllUsers().then(console.log);
```

---
