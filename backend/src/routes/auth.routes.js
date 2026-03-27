const express = require('express');
const router = express.Router();
const { googleSignIn, getMe, updateFcmToken } = require('../controllers/auth.controller');
const { authenticate } = require('../middleware/auth.middleware');

router.post('/google', googleSignIn);
router.get('/me', authenticate, getMe);
router.put('/fcm-token', authenticate, updateFcmToken);

module.exports = router;
