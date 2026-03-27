const express = require('express');
const router = express.Router();
const { getAllUsers, getUserById, updateProfile, assignRole, createUser, deleteUser } = require('../controllers/user.controller');
const { authenticate, isAdmin, isLeader } = require('../middleware/auth.middleware');

router.use(authenticate);

router.get('/', isLeader, getAllUsers);
router.get('/:id', getUserById);
router.put('/profile', updateProfile);
router.put('/:id/role', isAdmin, assignRole);
router.post('/create', isAdmin, createUser);
router.delete('/:id', isAdmin, deleteUser);

module.exports = router;
