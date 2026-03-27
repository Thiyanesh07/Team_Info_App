const express = require('express');
const router = express.Router();
const { getTeamProjects, getTeamProjectById, createTeamProject, updateTeamProject, assignMembers, deleteTeamProject } = require('../controllers/teamProject.controller');
const { authenticate, isLeader, authorize } = require('../middleware/auth.middleware');

router.use(authenticate);

router.get('/', getTeamProjects);
router.get('/:id', getTeamProjectById);
router.post('/', isLeader, createTeamProject);
router.put('/:id', isLeader, updateTeamProject);
router.post('/:id/members', authorize('ADMIN', 'CAPTAIN'), assignMembers);
router.delete('/:id', authorize('ADMIN', 'CAPTAIN'), deleteTeamProject);

module.exports = router;
