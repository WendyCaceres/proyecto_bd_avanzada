# Proyecto de Base de Datos Avanzadas - League of Legends

### Participantes
- Dorian Ticona
- Wendy Caceres
- Ivan Poma

### Creación de contenedores Docker para PostgreSQL y MySQL

```bash
docker run -d --name {contenedor_postgresql} -e POSTGRES_PASSWORD={password} -e POSTGRES_DB={database_name} -p 5432:5432 postgres:latest
```

```bash
docker run -d --name {contenedor_mysql} -e MYSQL_ROOT_PASSWORD={password} -e MYSQL_DATABASE={database_name} -p 3306:3306 mysql:latest
```

>[!IMPORTANT]
> Asegúrate de reemplazar `{contenedor_postgresql}`, `{contenedor_mysql}`, `{password}` y `{database_name}` con los valores correspondientes.

### Scripts para generar y restaurar backups
```bash
MSQL
|---backups
|---scripts/
|----------|---generateBackup.js
|----------|---restoreDb.js
POSTGRESQL
|---backups
|---scripts/
|----------|---generateBackup.js
|----------|---restoreDb.js
```