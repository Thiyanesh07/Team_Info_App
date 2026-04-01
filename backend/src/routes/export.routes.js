const express = require('express');
const exportController = require('../controllers/export.controller');
const { authenticate, isLeader } = require('../middleware/auth.middleware');

const router = express.Router();

// Apply global authentication
router.use(authenticate);

/** 
 * Export Routes
 * These use query params for filtering: ?scope=SELF|USER|TEAM&userId=uuid
 */

router.get('/activities', exportController.exportActivities);
router.get('/projects', exportController.exportProjects);
router.get('/hackathons', exportController.exportHackathons);
router.get('/skills', exportController.exportSkills);
router.get('/learning', exportController.exportLearning);
router.get('/certifications', exportController.exportCertifications);

module.exports = router;
