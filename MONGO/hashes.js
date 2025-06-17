// Colección de set para partidas recientes
db.partidas_recientes.find({})
db.createCollection("partidas_recientes");
db.partidas_recientes.insertOne({
  _id: "set_partidas_recientes",
  partidas: [1,2],
  actualizadoEn: ISODate("2025-06-15T00:00:00Z")
});