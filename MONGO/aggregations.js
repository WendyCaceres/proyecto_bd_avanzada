
//AGREGACIONES

// 1. Contar partidas por modo de juego
db.matches.aggregate([
  { $group: { _id: "$gameMode", totalMatches: { $sum: 1 } } },
  { $project: { gameMode: "$_id", totalMatches: 1, _id: 0 } }
]);

// 2. Filtrar partidas ranked y su duracion
db.matches.aggregate([
  { $match: { gameMode: "Ranked" } },
  { $project: { duration: 1, startTime: 1, _id: 0 } }
]);

// 3. Buscar que jugador esta en que team       
db.matches.aggregate([
  { $match: { _id: 1 } },
  { $unwind: "$teams" },
  { $unwind: "$teams.players" },
  {
    $lookup: {
      from: "players",
      localField: "teams.players.playerId",
      foreignField: "_id",
      as: "playerDetails"
    }
  },
  { $unwind: "$playerDetails" },
  { $project: { summonerName: "$playerDetails.summonerName", teamId: "$teams.teamId", _id: 0 } }
]);

// 4. Agrupar jugadores por region
db.players.aggregate([
  { $group: { _id: "$region",
      playerCount: { $sum: 1 } } },
  { $project: {
      region: "$_id",
      playerCount: 1, _id: 0 } }
]);

// 5. matchs por jugador
db.players.aggregate([
  { $unwind: "$matchHistory" },
  { $group: { _id: "$summonerName", matchCount: { $sum: 1 } } },
  { $project: { summonerName: "$_id", matchCount: 1, _id: 0 } }
]);

// 6. Detalles de el campeon por builds
db.builds.aggregate([
  {
    $lookup: {
      from: "champions",
      localField: "championId",
      foreignField: "_id",
      as: "champion"
    }
  },
  { $unwind: "$champion" },
  { $project: { championName: "$champion.name", items: 1, _id: 0 } }
]);

// 7. Jugadores top con nivel mayor o igual a 100
db.players.aggregate([
  { $match: { level: { $gte: 100 } } },
  { $project: {
      summonerName: 1, stats: 1, _id: 0 } }
]);

// 8. Agrupar partidas por victorias o derrotas
db.matches.aggregate([
  { $unwind: "$teams" },
  { $group: { _id: "$teams.outcome", matchCount: { $sum: 1 } } },
  { $project: { outcome: "$_id", matchCount: 1, _id: 0 } }
]);

// 9. Unir items en builds
db.builds.aggregate([
  { $unwind: "$items" },
  {
    $lookup: {
      from: "items",
      localField: "items.itemId",
      foreignField: "_id",
      as: "itemDetails"
    }
  },
  { $unwind: "$itemDetails" },
  { $project: { itemName: "$itemDetails.name", slot: "$items.slot", _id: 0 } }
]);

// 10. Contar cantidad de skins por campeon
db.skins.aggregate([
  { $group: { _id: "$championId", skinCount: { $sum: 1 } } },
  {
    $lookup: {
      from: "champions",
      localField: "_id",
      foreignField: "_id",
      as: "champion"
    }
  },
  { $unwind: "$champion" },
  { $project: { championName: "$champion.name", skinCount: 1, _id: 0 } }
]);

// 11. Filtrar torneos por region
db.tournaments.aggregate([
  { $match: { region: "Global" } },
  { $project: { name: 1, matches: 1, _id: 0 } }
]);

// 12. Descomponer abilidades y contar por campeon
db.champions.aggregate([
  { $unwind: "$abilities" },
  { $group: { _id: "$name", abilityCount: { $sum: 1 } } },
  { $project: { championName: "$_id", abilityCount: 1, _id: 0 } }
]);

// 13. Agrupar nombre de runa y el slot
db.loadouts.aggregate([
  { $unwind: "$runes" },
  {
    $lookup: {
      from: "runes",
      localField: "runes.runeId",
      foreignField: "_id",
      as: "runeDetails"
    }
  },
  { $unwind: "$runeDetails" },
  { $project: { runeName: "$runeDetails.name", slot: "$runes.slot", _id: 0 } }
]);

// 14. Agrupar total de jugadores por liga o rango
db.leaderboards.aggregate([
  { $group: { _id: "$stats.tier", playerCount: { $sum: 1 } } },
  { $project: { tier: "$_id", playerCount: 1, _id: 0 } }
]);

// 15. matches recientes y equipos
db.matches.aggregate([
  { $match: { startTime: { $gte: ISODate("2025-06-01T00:00:00Z") } } },
  { $project: { teams: 1, gameMode: 1, _id: 0 } }
]);

// 16. Unit detalles del jugador y lp
db.leaderboards.aggregate([
  {
    $lookup: {
      from: "players",
      localField: "playerId",
      foreignField: "_id",
      as: "player"
    }
  },
  { $unwind: "$player" },
  { $project: { summonerName: "$player.summonerName", rank: 1, lp: "$stats.lp", _id: 0 } }
]);

// 17. Agrupar items por costo por rango
db.items.aggregate([
  {
    $group: {
      _id: {
        $cond: [
          { $lte: ["$cost", 500] },
          "Low",
          { $cond: [{ $lte: ["$cost", 1000] }, "Medium", "High"] }
        ]
      },
      itemCount: { $sum: 1 }
    }
  },
  { $project: { costRange: "$_id", itemCount: 1, _id: 0 } }
]);

// 18. Descomponer teams and contar players por match
db.matches.aggregate([
  { $unwind: "$teams" },
  { $unwind: "$teams.players" },
  { $group: { _id: "$_id", playerCount: { $sum: 1 } } },
  { $project: { matchId: "$_id", playerCount: 1, _id: 0 } }
]);

// 19. Nombre de torneos y modo de juego
db.tournaments.aggregate([
  { $unwind: "$matches" },
  {
    $lookup: {
      from: "matches",
      localField: "matches",
      foreignField: "_id",
      as: "matchDetails"
    }
  },
  { $unwind: "$matchDetails" },
  { $project: { tournamentName: "$name", gameMode: "$matchDetails.gameMode", _id: 0 } }
]);

// 20. Unir costosos items y projectar el nombre y las habilidades
db.items.aggregate([
  { $match: { cost: { $gt: 500 } } },
  { $project: { name: 1, stats: 1, _id: 0 } }
])

// 21. Total de asesinatos por equipo a lo largo de todas las partidas
db.estadisticasEquipo.aggregate([
  { $group: { _id: "$equipoId", totalAsesinatos: { $sum: "$asesinatos" } } },
  { $project: { equipoId: "$_id", totalAsesinatos: 1, _id: 0 } }
]);

// 22. Promedio de winRate para jugadores con más de 400 partidas jugadas
db.estadisticasUsuario.aggregate([
  { $match: { partidasJugadas: { $gt: 400 } } },
  { $group: {
      _id: null,
      winRatePromedio:
          { $avg: "$winRate" }
      } },
  { $project:
      { winRatePromedio: 1, _id: 0 } }
]);

// 23. Listar maestrías de nivel 5 o superior
db.maestriaCampeon.aggregate([
  { $match: { nivelMaestria: { $gte: 5 } } },
  { $project: { jugadorId: 1, campeonId: 1, nivelMaestria: 1, _id: 0 } }
]);

// 24. Conteo de objetivos por tipo en partidas recientes
db.objetivosPartida.aggregate([
  { $match: { horaCaptura: { $gte: ISODate("2025-06-01T00:00:00Z") } } },
  { $group: { _id: "$tipoObjetivo", conteoObjetivos: { $sum: 1 } } },
  { $project: { tipoObjetivo: "$_id", conteoObjetivos: 1, _id: 0 } }
]);
