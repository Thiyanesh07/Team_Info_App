const express = require('express');
const router = express.Router();
const { getWeeklyAnalytics, getLeaderboard, getTeamWorkload, getRewardStatus } = require('../controllers/analytics.controller');
const { authenticate } = require('../middleware/auth.middleware');

router.use(authenticate);
router.get('/weekly', getWeeklyAnalytics);
router.get('/leaderboard', getLeaderboard);
router.get('/team-workload', getTeamWorkload);
router.get('/reward-status', getRewardStatus);

module.exports = router;
