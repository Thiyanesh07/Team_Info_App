const express = require('express');
const router = express.Router();
const { getTeamProjects, getTeamProjectById, createTeamProject, updateTeamProject, assignMembers, deleteTeamProject, addProgressUpdate } = require('../controllers/teamProject.controller');
const { authenticate, isLeader } = require('../middleware/auth.middleware');

router.use(authenticate);

router.get('/', getTeamProjects);
router.get('/:id', getTeamProjectById);
router.post('/', isLeader, createTeamProject);
router.put('/:id', isLeader, updateTeamProject);
router.post('/:id/members', isLeader, assignMembers);
router.delete('/:id', isLeader, deleteTeamProject);
router.post('/:id/progress', addProgressUpdate);

module.exports = router;
