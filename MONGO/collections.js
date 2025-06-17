
//use league_of_legends;
db.createCollection("players");

db.players.insertMany([
  {
    _id: 1,
    summonerName: "SummonerOne",
    region: "NA",
    level: 150,
    stats: {
      rankedWins: 200,
      rankedLosses: 180,
      totalKills: 3500,
      totalDeaths: 3200
    },
    matchHistory: [
      ObjectId(1),
      ObjectId(2)
    ],
    createdAt: ISODate("2025-01-01T00:00:00Z")
  },
  {
    _id: 2,
    summonerName: "SummonerTwo",
    region: "EO",
    level: 100,
    stats: {
      rankedWins: 100,
      rankedLosses: 130,
      totalKills: 300,
      totalDeaths: 500
    },
    matchHistory: [
      ObjectId(3),
      ObjectId(4)
    ],
    createdAt: ISODate("2025-04-14T00:00:00Z")
  },
  {
    _id: 3,
    summonerName: "SummonerThree",
    region: "EN",
    level: 180,
    stats: {
      rankedWins: 60,
      rankedLosses: 120,
      totalKills: 200,
      totalDeaths: 400
    },
    matchHistory: [
      ObjectId(5),
      ObjectId(6)
    ],
    createdAt: ISODate("2025-05-23T00:00:00Z")
  }
]);

db.players.insertOne([
    {
        _id: 4,
        summonerName: 'SummonerFour',
        region: 'LN',
        level:10,
        stats:{
            rankedWins: 30,
            rankedLosses: 20,
            totalKills:15,
            totalDeaths:20
        },
        matchHistory:[
            ObjectId(7),
            ObjectId(8)
        ],
        createdAt: ISODate("2025-06-03T00:00:00Z")
    }
])

db.createCollection("champions");
db.champions.insertMany([
  {
    _id: 1,
    name: "Ahri",
    role: ["Mage", "Assassin"],
    abilities: [
      { name: "Orb of Deception", type: "Q", cooldown: 7 },
      { name: "Fox-Fire", type: "W", cooldown: 9 }
    ],
    releaseDate: ISODate("2011-12-14T00:00:00Z")
  },
  {
    _id: 2,
    name: "Hipe",
    role: ["Jungle", "Mage"],
    abilities: [
      { name: "Consuming life", type: "C", cooldown: 7 },
      { name: "Orbe Red", type: "O", cooldown: 9 }
    ],
    releaseDate: ISODate("2025-06-11T00:00:00Z")
  }
]);

db.createCollection("matches");
db.matches.find({})
db.matches.insertMany([
  {
    _id: 3,
    gameMode: "Ranked",
    duration: 1800,
    teams: [
      {
        teamId: "blue",
        players: [
          { playerId: 1, championId:1 },
          { playerId: 3, championId:2}
        ],
        outcome: "Victory"
      },
      {
        teamId: "red",
        players: [
          { playerId: 2, championId: 2 }
        ],
        outcome: "Defeat"
      }
    ],
    startTime: ISODate("2025-06-01T12:00:00Z")
  },
  {
    _id: 4,
    gameMode: "ARAM",
    duration: 1200,
    teams: [
      {
        teamId: "blue",
        players: [
          { playerId: 1, championId: 3 }
        ],
        outcome: "Defeat"
      },
      {
        teamId: "red",
        players: [
          { playerId: 3, championId: 4 }
        ],
        outcome: "Victory"
      }
    ],
    startTime: ISODate("2025-06-02T15:00:00Z")
  }
]);
db.matches.find({})


db.createCollection("items");
db.items.find({})
db.items.insertMany([
  {
    _id: 1,
    name: "Doran's Ring",
    cost: 400,
    stats: { abilityPower: 15, health: 70 },
    createdAt: ISODate("2010-09-01T00:00:00Z")
  },
  {
    _id: 2,
    name: "Long Sword",
    cost: 350,
    stats: { abilityPower: 10, health: 0 },
    createdAt: ISODate("2010-09-02T00:00:00Z")
  },
  {
    _id: 3,
    name: "Blade of the Ruined King",
    cost: 3200,
    stats: { abilityPower: 40, health: 10 },
    createdAt: ISODate("2010-09-03T00:00:00Z")
  }
]);

db.items.insertMany([
     {
    _id: 4,
    name: "Infinity Edge",
    cost: 3400,
    stats: { attackDamage: 70, criticalStrike: 20 },
    createdAt: ISODate("2010-09-01T00:00:00Z")
  },
  {
    _id: 5,
    name: "Rabadon's Deathcap",
    cost: 3600,
    stats: { abilityPower: 120 },
    createdAt: ISODate("2010-09-01T00:00:00Z")
  },
  {
    _id: 6,
    name: "Guardian Angel",
    cost: 2800,
    stats: { attackDamage: 40, armor: 40 },
    createdAt: ISODate("2010-09-01T00:00:00Z")
  }
])

db.createCollection("builds");
db.builds.find({})
db.builds.insertMany([
  {
    _id: 1,
    playerId: 1,
    championId: 1,
    items: [
      { itemId:2, slot: 1 }
    ],
    createdAt: ISODate("2025-06-01T12:00:00Z")
  },
  {
    _id: 2,
    playerId: 2,
    championId: 2,
    items: [
      { itemId:1, slot: 1 }
    ],
    createdAt: ISODate("2025-06-01T12:00:00Z")
  }
]);

db.builds.insertMany([
    {
    _id: 3,
    playerId: 3,
    championId: 2,
    items: [
      { itemId: 4, slot: 1 },
      { itemId: 5, slot: 2 }
    ],
    createdAt: ISODate("2025-06-01T12:00:00Z")
  },
  {
    _id: 4,
    playerId:3,
    championId: 3,
    items: [
      { itemId: 5, slot: 1 },
      { itemId: 1, slot: 2 }
    ],
    createdAt: ISODate("2025-06-02T15:00:00Z")
  },
  {
    _id: 5,
    playerId: 3,
    championId: 3,
    items: [
      { itemId: 2, slot: 1 }
    ],
    createdAt: ISODate("2025-06-03T10:00:00Z")
  },
  {
    _id: 6,
    playerId: 4,
    championId: 3,
    items: [
      { itemId: 1, slot: 1 },
      { itemId: 3, slot: 2 }
    ],
    createdAt: ISODate("2025-06-04T18:00:00Z")
  }
])

db.createCollection("runes");
db.runes.find({})
db.runes.insertMany([
  {
    _id: 1,
    name: "Electrocute",
    tree: "Domination",
    effects: { bonusDamage: 50 },
    createdAt: ISODate("2017-11-08T00:00:00Z")
  },
  {
    _id: 2,
    name: "Electrocute",
    tree: "Domination",
    effects: { bonusDamage: 50 },
    createdAt: ISODate("2017-11-08T00:00:00Z")
  }
]);
db.runes.find({})
db.runes.insertMany([
  {
    _id: 3,
    name: "Electrocute",
    tree: "Domination",
    effects: { bonusDamage: 50 },
    createdAt: ISODate("2017-11-08T00:00:00Z")
  },
  {
    _id: 4,
    name: "Conqueror",
    tree: "Precision",
    effects: { adaptiveDamage: 10 },
    createdAt: ISODate("2017-11-08T00:00:00Z")
  },
  {
    _id: 5,
    name: "Grasp of the Undying",
    tree: "Resolve",
    effects: { bonusHealth: 5 },
    createdAt: ISODate("2017-11-08T00:00:00Z")
  },
  {
    _id: 6,
    name: "Dark Harvest",
    tree: "Domination",
    effects: { soulDamage: 20 },
    createdAt: ISODate("2017-11-08T00:00:00Z")
  }
]);

db.loadouts.find({})
db.createCollection("loadouts");
db.loadouts.insertMany([
  {
    _id: 1,
    playerId: 2,
    runes: [
      { runeId: 1, slot: "Keystone" },
      { runeId: 4, slot: "Secondary" }
    ],
    createdAt: ISODate("2025-06-01T00:00:00Z")
  },
  {
    _id: 2,
    playerId: 2,
    runes: [
      { runeId: 2, slot: "Keystone" }
    ],
    createdAt: ISODate("2025-06-02T00:00:00Z")
  },
  {
    _id: 3,
    playerId: 3,
    runes: [
      { runeId: 3, slot: "Keystone" }
    ],
    createdAt: ISODate("2025-06-03T00:00:00Z")
  },
  {
    _id: 4,
    playerId: 4,
    runes: [
      { runeId: 1, slot: "Keystone" },
      { runeId: 2, slot: "Secondary" }
    ],
    createdAt: ISODate("2025-06-04T00:00:00Z")
  }
]);

db.tournaments.find({})
db.matches.find({})
db.createCollection("tournaments");
db.tournaments.insertMany([
  {
    _id: 1,
    name: "Worlds 2025",
    region: "Global",
    matches: [1,3],
    startDate: ISODate("2025-10-01T00:00:00Z")
  },
  {
    _id: 2,
    name: "LCS Summer 2025",
    region: "NA",
    matches: [2,4],
    startDate: ISODate("2025-07-01T00:00:00Z")
  },
  {
    _id: 3,
    name: "LCK Spring 2025",
    region: "KR",
    matches: [5],
    startDate: ISODate("2025-03-01T00:00:00Z")
  }
]);

db.skins.find({})
db.createCollection("skins");
db.skins.insertMany([
  {
    _id: 1,
    name: "Spirit Blossom Ahri",
    championId: 1,
    cost: 1350,
    releaseDate: ISODate("2020-08-06T00:00:00Z")
  },
  {
    _id: 2,
    name: "High Noon Lee Sin",
    championId:2,
    cost: 1820,
    releaseDate: ISODate("2018-06-14T00:00:00Z")
  },
  {
    _id: 3,
    name: "Elementalist Lux",
    championId: 3,
    cost: 3250,
    releaseDate: ISODate("2016-11-28T00:00:00Z")
  },
  {
    _id: 4,
    name: "Shadow Assassin Zed",
    championId: 4,
    cost: 1350,
    releaseDate: ISODate("2019-04-04T00:00:00Z")
  },
  {
    _id: 5,
    name: "Arcane Ahri",
    championId: 1,
    cost: 1350,
    releaseDate: ISODate("2021-11-10T00:00:00Z")
  }
]);

db.leaderboards.find({})
db.createCollection("leaderboards");
db.leaderboards.insertMany([
  {
    _id: 1,
    region: "NA",
    rank: 1,
    playerId: 1,
    stats: {
      lp: 1200,
      tier: "Challenger"
    },
    updatedAt: ISODate("2025-06-15T00:00:00Z")
  },
  {
    _id: 2,
    region: "EUW",
    rank: 1,
    playerId: 2,
    stats: {
      lp: 1500,
      tier: "Challenger"
    },
    updatedAt: ISODate("2025-06-15T00:00:00Z")
  },
  {
    _id: 3,
    region: "KR",
    rank: 2,
    playerId: 3,
    stats: {
      lp: 800,
      tier: "Grandmaster"
    },
    updatedAt: ISODate("2025-06-15T00:00:00Z")
  },
  {
    _id: 4,
    region: "NA",
    rank: 50,
    playerId: 4,
    stats: {
      lp: 600,
      tier: "Master"
    },
    updatedAt: ISODate("2025-06-15T00:00:00Z")
  }
]);

db.estadisticasEquipo.find({})
db.createCollection("estadisticasEquipo");
db.estadisticasEquipo.insertMany([
  {
    _id: 1,
    partidaId: 1,
    equipoId: "azul",
    asesinatos: 15,
    muertes: 5,
    asistencias: 20,
    oroTotal: 30000,
    registradoEn: ISODate("2025-06-01T12:00:00Z")
  },
  {
    _id: 2,
    partidaId: 1,
    equipoId: "rojo",
    asesinatos: 5,
    muertes: 15,
    asistencias: 10,
    oroTotal: 28000,
    registradoEn: ISODate("2025-06-01T12:00:00Z")
  },
  {
    _id: 3,
    partidaId: 2,
    equipoId: "azul",
    asesinatos: 20,
    muertes: 8,
    asistencias: 25,
    oroTotal: 32000,
    registradoEn: ISODate("2025-06-15T09:00:00Z")
  }
]);

// Colección EstadisticasUsuario
db.estadisticasUsuario.find({})
db.createCollection("estadisticasUsuario");
db.estadisticasUsuario.insertMany([
  {
    _id: 1,
    jugadorId: 1,
    partidasJugadas: 500,
    winRate: 0.65,
    kdaPromedio: 3.2,
    actualizadoEn: ISODate("2025-06-15T00:00:00Z")
  },
  {
    _id: 2,
    jugadorId: 2,
    partidasJugadas: 300,
    winRate: 0.55,
    kdaPromedio: 2.8,
    actualizadoEn: ISODate("2025-06-14T00:00:00Z")
  },
  {
    _id: 3,
    jugadorId: 3,
    partidasJugadas: 700,
    winRate: 0.70,
    kdaPromedio: 4.0,
    actualizadoEn: ISODate("2025-06-16T00:00:00Z")
  }
]);

// Colección HistoralClasificacion
db.historalClasificacion.find({})
db.createCollection("historalClasificacion");
db.historalClasificacion.insertMany([
  {
    _id: 1,
    jugadorId: 1,
    region: "NA",
    division: "Challenger",
    lp: 1200,
    fecha: ISODate("2025-06-01T00:00:00Z")
  },
  {
    _id: 2,
    jugadorId: 1,
    region: "NA",
    division: "Grandmaster",
    lp: 900,
    fecha: ISODate("2025-05-15T00:00:00Z")
  },
  {
    _id: 3,
    jugadorId: 2,
    region: "EUW",
    division: "Master",
    lp: 600,
    fecha: ISODate("2025-06-10T00:00:00Z")
  }
]);

// Colección MaestriaCampeon
db.maestriaCampeon.find({})
db.createCollection("maestriaCampeon");
db.maestriaCampeon.insertMany([
  {
    _id: 1,
    jugadorId: 1,
    campeonId: 1,
    puntosMaestria: 500,
    nivelMaestria: 7,
    ultimoUso: ISODate("2025-06-15T00:00:00Z")
  },
  {
    _id: 2,
    jugadorId: 1,
    campeonId: 2,
    puntosMaestria: 300,
    nivelMaestria: 5,
    ultimoUso: ISODate("2025-06-10T00:00:00Z")
  },
  {
    _id: 3,
    jugadorId: 2,
    campeonId: 1,
    puntosMaestria: 450,
    nivelMaestria: 6,
    ultimoUso: ISODate("2025-06-14T00:00:00Z")
  }
]);

// Colección ObjetivosPartida
db.objetivosPartida.find({})
db.createCollection("objetivosPartida");
db.objetivosPartida.insertMany([
  {
    _id: 1,
    partidaId: 1,
    tipoObjetivo: "Torre",
    equipoId: "azul",
    horaCaptura: ISODate("2025-06-01T12:15:00Z")
  },
  {
    _id: 2,
    partidaId: 1,
    tipoObjetivo: "Dragón",
    equipoId: "azul",
    horaCaptura: ISODate("2025-06-01T12:25:00Z")
  },
  {
    _id: 3,
    partidaId: 2,
    tipoObjetivo: "Torre",
    equipoId: "rojo",
    horaCaptura: ISODate("2025-06-15T09:10:00Z")
  }
]);

// Colección VersionesJuego
db.versionesJuego.find({})
db.createCollection("versionesJuego");
db.versionesJuego.insertMany([
  {
    _id: 1,
    numeroVersion: "14.12",
    fechaLanzamiento: ISODate("2025-06-05T00:00:00Z"),
    notas: "Nuevos campeones y balanceo"
  },
  {
    _id: 2,
    numeroVersion: "14.11",
    fechaLanzamiento: ISODate("2025-05-22T00:00:00Z"),
    notas: "Ajustes a objetos"
  },
  {
    _id: 3,
    numeroVersion: "14.10",
    fechaLanzamiento: ISODate("2025-05-08T00:00:00Z"),
    notas: "Nerfeo a campeones meta"
  }
]);

