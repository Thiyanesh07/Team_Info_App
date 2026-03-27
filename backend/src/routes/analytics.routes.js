const express = require('express');
const router = express.Router();
const { getWeeklyAnalytics, getLeaderboard } = require('../controllers/analytics.controller');
const { authenticate } = require('../middleware/auth.middleware');

router.use(authenticate);
router.get('/weekly', getWeeklyAnalytics);
router.get('/leaderboard', getLeaderboard);

module.exports = router;
