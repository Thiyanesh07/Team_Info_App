const express = require('express');
const router = express.Router();
const { getMyProjects, getUserProjects, createProject, updateProject, deleteProject } = require('../controllers/personalProject.controller');
const { authenticate, isLeader } = require('../middleware/auth.middleware');

router.use(authenticate);

router.get('/', getMyProjects);
router.get('/user/:userId', isLeader, getUserProjects);
router.post('/', createProject);
router.put('/:id', updateProject);
router.delete('/:id', deleteProject);

module.exports = router;
