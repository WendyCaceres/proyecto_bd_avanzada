// Colección de caché para estadísticas de partidas (usando hashes/sets)
db.cache_partidas.find({})
db.createCollection("cache_partidas");
db.cache_partidas.insertOne({
  _id: 1,
  partidaId: 1,
  estadisticas: {
    asesinatosTotales: 25,
    oroTotal: 50000,
    estadisticasJugadores: [
      {
        jugadorId: 1,
        asesinatos: 10,
        muertes: 5,
        asistencias: 7
      }
    ]
  },
  creadoEn: ISODate("2025-06-15T00:00:00Z")
});