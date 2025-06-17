const mysql = require('mysql2/promise');  
const { MongoClient } = require('mongodb');  
  
class ChampionSyncService {  
  constructor() {  
    this.mysqlConfig = {  
      host: 'localhost',  
      port: 3306,  
      user: 'user',  
      password: 'password',  
      database: 'lol_juego'  
    };  
      
    this.mongoUrl = 'mongodb://localhost:27017';  
    this.mongoDb = 'lol_analytics';  
  }  
  
  async syncChampionFromMySQLToMongo(campeonId) {  
    const mysqlConn = await mysql.createConnection(this.mysqlConfig);  
    const mongoClient = new MongoClient(this.mongoUrl);  
      
    try {  
      await mongoClient.connect();  
      const db = mongoClient.db(this.mongoDb);  
        
      const [championRows] = await mysqlConn.execute(`  
        SELECT c.campeon_id, c.nombre_campeon, c.rol_principal,   
               c.dificultad, c.fecha_lanzamiento  
        FROM Campeones c  
        WHERE c.campeon_id = ?  
      `, [campeonId]);  
        
      if (championRows.length === 0) return null;  
        
      const championData = championRows[0];  
        
      const [usageStats] = await mysqlConn.execute(`  
        SELECT COUNT(*) as total_picks,  
               AVG(kills) as avg_kills,  
               AVG(deaths) as avg_deaths,  
               AVG(assists) as avg_assists,  
               COUNT(CASE WHEN p.equipo = pt.equipo_ganador THEN 1 END) as wins  
        FROM Participantes pt  
        JOIN Partidas p ON pt.partida_id = p.partida_id  
        WHERE pt.campeon_id = ?  
      `, [campeonId]);  
        
      const [masteryStats] = await mysqlConn.execute(`  
        SELECT AVG(nivel_maestria) as avg_mastery_level,  
               AVG(puntos_maestria) as avg_mastery_points,  
               COUNT(*) as players_with_mastery  
        FROM MaestriaCampeon  
        WHERE campeon_id = ?  
      `, [campeonId]);  
        
      const usage = usageStats[0];  
      const mastery = masteryStats[0];  
        
      const championDoc = {  
        _id: championData.campeon_id,  
        name: championData.nombre_campeon,  
        role: [championData.rol_principal],
        difficulty: championData.dificultad,  
        releaseDate: championData.fecha_lanzamiento,  
        stats: {  
          totalPicks: usage.total_picks || 0,  
          winRate: usage.total_picks > 0 ?   
            ((usage.wins || 0) / usage.total_picks * 100).toFixed(2) : 0,  
          avgKills: parseFloat(usage.avg_kills) || 0,  
          avgDeaths: parseFloat(usage.avg_deaths) || 0,  
          avgAssists: parseFloat(usage.avg_assists) || 0,  
          avgMasteryLevel: parseFloat(mastery.avg_mastery_level) || 0,  
          avgMasteryPoints: parseFloat(mastery.avg_mastery_points) || 0,  
          playersWithMastery: mastery.players_with_mastery || 0  
        },  
        lastSyncAt: new Date()  
      };  
        
      await db.collection('champions').replaceOne(  
        { _id: championData.campeon_id },  
        championDoc,  
        { upsert: true }  
      );  
        
      return championDoc;  
        
    } finally {  
      await mysqlConn.end();  
      await mongoClient.close();  
    }  
  }  
  
  async syncAllChampions() {  
    const mysqlConn = await mysql.createConnection(this.mysqlConfig);  
      
    try {  
      const [championIds] = await mysqlConn.execute(`  
        SELECT campeon_id FROM Campeones ORDER BY campeon_id  
      `);  
        
      const results = [];  
      for (const row of championIds) {  
        const result = await this.syncChampionFromMySQLToMongo(row.campeon_id);  
        if (result) {  
          results.push(result);  
        }  
      }  
        
      return results;  
        
    } finally {  
      await mysqlConn.end();  
    }  
  }  
  
  async getChampionAnalytics(campeonId) {  
    const mysqlConn = await mysql.createConnection(this.mysqlConfig);  
    const mongoClient = new MongoClient(this.mongoUrl);  
      
    try {  
      await mongoClient.connect();  
      const db = mongoClient.db(this.mongoDb);  
        
      const [mysqlData] = await mysqlConn.execute(`  
        SELECT nombre_campeon, rol_principal, dificultad, fecha_lanzamiento  
        FROM Campeones WHERE campeon_id = ?  
      `, [campeonId]);  
        
      const mongoData = await db.collection('champions').findOne({ _id: campeonId });  
        
      const popularBuilds = await db.collection('builds').find({  
        championId: campeonId  
      }).limit(5).toArray();  
        
      return {  
        champion: mysqlData[0],  
        analytics: mongoData?.stats || {},  
        popularBuilds: popularBuilds  
      };  
        
    } finally {  
      await mysqlConn.end();  
      await mongoClient.close();  
    }  
  }  
}