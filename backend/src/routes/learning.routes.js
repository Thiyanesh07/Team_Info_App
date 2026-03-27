const express = require('express');
const router = express.Router();
const { getMyLearnings, getUserLearnings, createLearning, updateLearning, deleteLearning } = require('../controllers/learning.controller');
const { authenticate, isLeader } = require('../middleware/auth.middleware');

router.use(authenticate);
router.get('/', getMyLearnings);
router.get('/user/:userId', isLeader, getUserLearnings);
router.post('/', createLearning);
router.put('/:id', updateLearning);
router.delete('/:id', deleteLearning);

module.exports = router;
