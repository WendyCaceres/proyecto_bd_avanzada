
// Índice TTL para partidas recientes (expira en 24 horas)
db.partidas_recientes.createIndex({ actualizadoEn: 1 }, { expireAfterSeconds: 86400 });

// TTL para caché de partidas ( esto expira en 1 hora)
db.cache_partidas.createIndex({ creadoEn: 1 }, { expireAfterSeconds: 3600 });

//  TTL para builds (Este expira en 30 días)
db.builds.createIndex({ creadoEn: 1 }, { expireAfterSeconds: 2592000 });

//  TTL para configuraciones (expira en 7 días)
db.configuraciones.createIndex({ creadoEn: 1 }, { expireAfterSeconds: 604800 });