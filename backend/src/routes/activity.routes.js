const express = require('express');
const router = express.Router();
const { getMyActivities, getUserActivities, getAllActivities, createActivity, updateActivity, deleteActivity } = require('../controllers/activity.controller');
const { getUnifiedActivity } = require('../controllers/systemActivity.controller');
const { authenticate, isLeader } = require('../middleware/auth.middleware');

router.use(authenticate);
router.get('/unified', getUnifiedActivity); // Added to resolve 404 from frontend
router.get('/', getMyActivities);
router.get('/all', isLeader, getAllActivities);
router.get('/user/:userId', isLeader, getUserActivities);
router.post('/', createActivity);
router.put('/:id', updateActivity);
router.delete('/:id', deleteActivity);

module.exports = router;
