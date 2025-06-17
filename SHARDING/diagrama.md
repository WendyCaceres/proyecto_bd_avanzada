# Arquitectura de Base de Datos Multi-Región para Proyecto LOL

## 🗺️ Descripción General
Este sistema gestiona múltiples bases de datos MySQL organizadas por regiones, permitiendo almacenar jugadores, partidas, transacciones y otros datos según su región (como LAN o LAS) y replicar los datos en una base centralizada (Master). Las réplicas regionales sincronizan con el Master para garantizar consistencia.
 
                           +--------------------+
                           |     mysql_master   |
                           | (Puerto: 3306)     |
                           | DB: lol_juego      |
                           +--------------------+
                                  ▲
   +---------------------------------------------------------------------------------------------+
   |                              │                                |                            |
   ▼                              ▼                                ▼                            ▼
+---------------------+  +---------------------+  +---------------------+  +---------------------+
| Región: LAN         |  | Región: LAS         |  | Región: NA          |  | (Futuras regiones)  |
| mysql_lan           |  | mysql_las           |  | mysql_na            |  | mysql_euw, etc.     |
| Puerto: 3307        |  | Puerto: 3308        |  | Puerto: 3309        |  |                      |
| Modo: SLAVE         |  | Modo: SLAVE         |  | Modo: SLAVE         |  |                      |
| Sync desde master   |  | Sync desde master   |  | Sync desde master   |  |                      |
+---------------------+  +---------------------+  +---------------------+  +---------------------+