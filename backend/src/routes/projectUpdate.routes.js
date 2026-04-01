const express = require('express');
const router = express.Router();
const { getProjectUpdates, createProjectUpdate, updateProjectUpdate, deleteProjectUpdate } = require('../controllers/projectUpdate.controller');
const { authenticate } = require('../middleware/auth.middleware');

router.use(authenticate);

router.get('/:projectId', getProjectUpdates);
router.post('/:projectId', createProjectUpdate);
router.put('/:id', updateProjectUpdate);
router.delete('/:id', deleteProjectUpdate);

module.exports = router;
