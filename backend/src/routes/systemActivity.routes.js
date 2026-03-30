const express = require('express');
const router = express.Router();
const { getUnifiedActivity } = require('../controllers/systemActivity.controller');
const { authenticate } = require('../middleware/auth.middleware');

// GET /api/activities/unified
router.get('/unified', authenticate, getUnifiedActivity);

module.exports = router;
