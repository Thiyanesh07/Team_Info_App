const express = require('express');
const router = express.Router();
const { getMyHackathons, getUserHackathons, createHackathon, updateHackathon, deleteHackathon } = require('../controllers/hackathon.controller');
const { authenticate, isLeader } = require('../middleware/auth.middleware');

router.use(authenticate);
router.get('/', getMyHackathons);
router.get('/user/:userId', isLeader, getUserHackathons);
router.post('/', createHackathon);
router.put('/:id', updateHackathon);
router.delete('/:id', deleteHackathon);

module.exports = router;
