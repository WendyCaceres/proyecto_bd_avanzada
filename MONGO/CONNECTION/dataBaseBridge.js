class DatabaseBridge {  
  constructor() {  
    this.playerSync = new PlayerSyncService();  
    this.matchSync = new MatchSyncService();  
    this.championSync = new ChampionSyncService();
  }  
    
  async syncPlayerStats(playerId) {  
    const playerDoc = await this.playerSync.syncPlayerFromMySQLToMongo(playerId);  
      
    if (playerDoc) {  
      await this.updateMySQLPlayerStats(playerId, playerDoc.stats);  
    }  
      
    return playerDoc;  
  }  
    
  async updateMySQLPlayerStats(playerId, mongoStats) {  
    const mysqlConn = await mysql.createConnection(this.mysqlConfig);  
      
    try {  
      await mysqlConn.execute(`  
        UPDATE Usuarios   
        SET nivel = GREATEST(nivel, ?)  
        WHERE usuario_id = ?  
      `, [Math.floor(mongoStats.avgKills * 10), playerId]);  
        
    } finally {  
      await mysqlConn.end();  
    }  
  }  
    
  async getPlayerAnalytics(playerId) {  
    const mysqlConn = await mysql.createConnection(this.mysqlConfig);  
    const mongoClient = new MongoClient(this.mongoUrl);  
      
    try {  
      await mongoClient.connect();  
      const db = mongoClient.db(this.mongoDb);  
        
      const [mysqlData] = await mysqlConn.execute(`  
        SELECT nombre_summoner, region, fecha_registro, estado_cuenta  
        FROM Usuarios WHERE usuario_id = ?  
      `, [playerId]);  
        
      const mongoData = await db.collection('players').findOne({ _id: playerId });  
      const matchHistory = await db.collection('matches').find({  
        $or: [  
          { "teams.0.players.playerId": playerId },  
          { "teams.1.players.playerId": playerId }  
        ]  
      }).limit(10).toArray();  
        
      return {  
        profile: mysqlData[0],  
        stats: mongoData?.stats || {},  
        recentMatches: matchHistory  
      };  
        
    } finally {  
      await mysqlConn.end();  
      await mongoClient.close();  
    }  
  }

  async syncChampionStats(championId) {  
    return await this.championSync.syncChampionFromMySQLToMongo(championId);  
  }  
    
  async syncAllChampions() {  
    return await this.championSync.syncAllChampions();  
  }  
    
  async getChampionAnalytics(championId) {  
    return await this.championSync.getChampionAnalytics(championId);  
  } 
}