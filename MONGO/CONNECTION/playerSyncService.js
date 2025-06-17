const mysql = require('mysql2/promise');  
const { MongoClient } = require('mongodb');  
  
class PlayerSyncService {  
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
  
  async syncPlayerFromMySQLToMongo(usuarioId) {  
    const mysqlConn = await mysql.createConnection(this.mysqlConfig);  
    const mongoClient = new MongoClient(this.mongoUrl);  
      
    try {  
      await mongoClient.connect();  
      const db = mongoClient.db(this.mongoDb);  
        
      const [rows] = await mysqlConn.execute(`  
        SELECT u.usuario_id, u.nombre_summoner, u.region, u.nivel, u.estado_cuenta,  
               COUNT(p.partida_id) as total_partidas,  
               AVG(p.kills) as avg_kills,  
               AVG(p.deaths) as avg_deaths,  
               AVG(p.assists) as avg_assists  
        FROM Usuarios u  
        LEFT JOIN Participantes p ON u.usuario_id = p.usuario_id  
        WHERE u.usuario_id = ?  
        GROUP BY u.usuario_id  
      `, [usuarioId]);  
        
      if (rows.length === 0) return null;  
        
      const userData = rows[0];  
        
      const playerDoc = {  
        _id: userData.usuario_id,  
        summonerName: userData.nombre_summoner,  
        region: userData.region,  
        level: userData.nivel,  
        accountStatus: userData.estado_cuenta,  
        stats: {  
          totalMatches: userData.total_partidas || 0,  
          avgKills: parseFloat(userData.avg_kills) || 0,  
          avgDeaths: parseFloat(userData.avg_deaths) || 0,  
          avgAssists: parseFloat(userData.avg_assists) || 0  
        },  
        lastSyncAt: new Date()  
      };  
        
      await db.collection('players').replaceOne(  
        { _id: userData.usuario_id },  
        playerDoc,  
        { upsert: true }  
      );  
        
      return playerDoc;  
        
    } finally {  
      await mysqlConn.end();  
      await mongoClient.close();  
    }  
  }  
}