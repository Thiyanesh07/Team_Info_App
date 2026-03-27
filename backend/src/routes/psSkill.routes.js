const express = require('express');
const router = express.Router();
const { getMyPsSkills, getUserPsSkills, createPsSkill, updatePsSkill, deletePsSkill } = require('../controllers/psSkill.controller');
const { authenticate, isLeader } = require('../middleware/auth.middleware');

router.use(authenticate);
router.get('/', getMyPsSkills);
router.get('/user/:userId', isLeader, getUserPsSkills);
router.post('/', createPsSkill);
router.put('/:id', updatePsSkill);
router.delete('/:id', deletePsSkill);

module.exports = router;
