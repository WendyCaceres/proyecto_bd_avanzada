class MatchSyncService {  
  async syncMatchFromMySQLToMongo(partidaId) {  
    const mysqlConn = await mysql.createConnection(this.mysqlConfig);  
    const mongoClient = new MongoClient(this.mongoUrl);  
      
    try {  
      await mongoClient.connect();  
      const db = mongoClient.db(this.mongoDb);  
        
      const [matchData] = await mysqlConn.execute(`  
        SELECT p.partida_id, p.fecha_inicio, p.duracion, p.tipo_cola,   
               p.mapa, p.equipo_ganador, v.version_nombre  
        FROM Partidas p  
        JOIN VersionesJuego v ON p.parche_id = v.parche_id  
        WHERE p.partida_id = ?  
      `, [partidaId]);  
        
      const [participants] = await mysqlConn.execute(`  
        SELECT pt.usuario_id, pt.campeon_id, pt.equipo, pt.rol_linea,  
               pt.kills, pt.deaths, pt.assists, pt.farm_cs, pt.oro_obtenido,  
               u.nombre_summoner, c.nombre_campeon  
        FROM Participantes pt  
        JOIN Usuarios u ON pt.usuario_id = u.usuario_id  
        JOIN Campeones c ON pt.campeon_id = c.campeon_id  
        WHERE pt.partida_id = ?  
      `, [partidaId]);  
        
      if (matchData.length === 0) return null;  
        
      const match = matchData[0];  
        
      const blueTeam = participants.filter(p => p.equipo === 'Blue');  
      const redTeam = participants.filter(p => p.equipo === 'Red');  
        
      const matchDoc = {  
        _id: match.partida_id,  
        gameMode: match.tipo_cola,  
        duration: match.duracion,  
        map: match.mapa,  
        gameVersion: match.version_nombre,  
        teams: [  
          {  
            teamId: "blue",  
            players: blueTeam.map(p => ({  
              playerId: p.usuario_id,  
              championId: p.campeon_id,  
              role: p.rol_linea,  
              stats: {  
                kills: p.kills,  
                deaths: p.deaths,  
                assists: p.assists,  
                cs: p.farm_cs,  
                gold: p.oro_obtenido  
              }  
            })),  
            outcome: match.equipo_ganador === 'Blue' ? 'Victory' : 'Defeat'  
          },  
          {  
            teamId: "red",   
            players: redTeam.map(p => ({  
              playerId: p.usuario_id,  
              championId: p.campeon_id,  
              role: p.rol_linea,  
              stats: {  
                kills: p.kills,  
                deaths: p.deaths,  
                assists: p.assists,  
                cs: p.farm_cs,  
                gold: p.oro_obtenido  
              }  
            })),  
            outcome: match.equipo_ganador === 'Red' ? 'Victory' : 'Defeat'  
          }  
        ],  
        startTime: match.fecha_inicio,  
        syncedAt: new Date()  
      };  
        
      await db.collection('matches').replaceOne(  
        { _id: match.partida_id },  
        matchDoc,  
        { upsert: true }  
      );  
        
      return matchDoc;  
        
    } finally {  
      await mysqlConn.end();  
      await mongoClient.close();  
    }  
  }  
}