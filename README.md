# Proyecto de Base de Datos Avanzadas - League of Legends

### Creación de contenedores Docker para PostgreSQL y MySQL

```bash
docker run -d --name lol_postgresql -e POSTGRES_PASSWORD=doriandev -e POSTGRES_DB=lol_economia -p 5432:5432 postgres:latest
```

```bash
docker run -d --name lol_mysql -e MYSQL_ROOT_PASSWORD=doriandev -e MYSQL_DATABASE=lol_juego -p 3306:3306 mysql:latest
```

### Scripts
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