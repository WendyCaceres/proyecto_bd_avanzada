const express = require('express');  
const DatabaseBridge = require('../services/DatabaseBridge');  
  
const router = express.Router();  
const dbBridge = new DatabaseBridge();  
  
router.get('/player/:id/analytics', async (req, res) => {  
  try {  
    const playerId = parseInt(req.params.id);  
    const analytics = await dbBridge.getPlayerAnalytics(playerId);  
    res.json(analytics);  
  } catch (error) {  
    res.status(500).json({ error: error.message });  
  }  
});  
  
router.post('/sync/player/:id', async (req, res) => {  
  try {  
    const playerId = parseInt(req.params.id);  
    const result = await dbBridge.syncPlayerStats(playerId);  
    res.json({ success: true, data: result });  
  } catch (error) {  
    res.status(500).json({ error: error.message });  
  }  
});  
  
module.exports = router;