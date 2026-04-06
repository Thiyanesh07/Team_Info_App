const express = require('express');
const authController = require('../controllers/auth.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { validate } = require('../utils/validation.utils');
const { loginSchema, registerSchema, googleLoginSchema } = require('../validations/auth.validation');

const router = express.Router();

router.post('/google-login', validate(googleLoginSchema), authController.googleSignIn);
router.post('/google', validate(googleLoginSchema), authController.googleSignIn); // Alias for Flutter build
router.get('/me', authenticate, authController.getMe);
router.put('/fcm-token', authenticate, authController.updateFcmToken);
router.post('/refresh-token', authController.refreshAccessToken);

module.exports = router;
