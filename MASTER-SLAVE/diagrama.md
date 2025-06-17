# Diagrama de Arquitectura PostgreSQL con ReplicaciónAdd commentMore actions

```plaintext

                          +----------------------+
                         |  mysql_exporter       |
                         | (Monitorea Master)    |
                         +----------+-----------+
                                    |
                                    v
                          http://localhost:9104

                         +----------------------+
                         |  mysql_master         |
                         |   (Puerto 3306)       |
                         |   Modo: MASTER        |
                         |   DB: lol_juego       |
                         +----------+-----------+
                                    |
     ------------------------------+-------------------------------
     |                                                         |
     v                                                         v
+---------------------+                          +----------------------+
| mysql_slave1        |                          | mysql_slave2        |
|   (Puerto 3307)     |                          |   (Puerto 3308)     |
|   Modo: SLAVE       |                          |   Modo: SLAVE       |
| Sync desde master   |                          | Sync desde master   |
+---------------------+                          +----------------------+