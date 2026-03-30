const express = require('express');
const router = express.Router();
const { getProjectMilestones, createMilestone, updateMilestoneStatus } = require('../controllers/milestone.controller');
const { authenticate, isLeader } = require('../middleware/auth.middleware');

// Routes nested under projects: /api/team-projects/:projectId/milestones
// But for simplicity in implementation, we can also use top-level routes if preferred.
// I will use a mix to be flexible.

router.get('/project/:projectId', authenticate, getProjectMilestones);
router.post('/project/:projectId', authenticate, isLeader, createMilestone);
router.patch('/:id/status', authenticate, updateMilestoneStatus);

module.exports = router;
