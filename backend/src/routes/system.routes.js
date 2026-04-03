const express = require('express');
const router = express.Router();
const systemController = require('../controllers/system.controller');
const { authenticate, isAdmin } = require('../middleware/auth.middleware');

router.get('/config', authenticate, systemController.getSystemConfig);
router.patch('/config', authenticate, isAdmin, systemController.updateSystemConfig);

module.exports = router;
