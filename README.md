# proyecto_bd_avanzada

```bash
docker run --name postgresofproject -e POSTGRES_PASSWORD=doriandev -e POSTGRES_USER=doriandev -e POSTGRES_DB=leagueoflegends -p 5432:5432 -d postgres:latest
```

```bash
docker cp backup_dbproject.dump postgresofproject:/backup_dbproject.dump
```

```bash
docker exec -u postgres postgresofproject pg_restore -U doriandev -d leagueoflegends ./backup_dbproject.dump
```