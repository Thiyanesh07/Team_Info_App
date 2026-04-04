const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const prisma = require('../lib/prisma');
const { OAuth2Client } = require('google-auth-library');


const configuredClientIds = (
  process.env.GOOGLE_CLIENT_ID || process.env['GOOGLE_CLIENT_ID '] || ''
)
  .split(',')
  .map((id) => id.trim())
  .filter(Boolean);
const client = new OAuth2Client(configuredClientIds[0] || undefined);

const isDatabaseUnavailableError = (error) => {
  const message = error?.message || '';
  return (
    error?.name === 'PrismaClientInitializationError' ||
    message.includes("Can't reach database server") ||
    message.includes('ECONNREFUSED') ||
    message.includes('ETIMEDOUT')
  );
};

/**
 * Validate email domain
 */
const isValidDomain = (email) => {
  const allowedDomains = (process.env.ALLOWED_DOMAINS || '').split(',').map(d => d.trim());
  if (allowedDomains.length === 0 || allowedDomains[0] === '') return true;
  const domain = email.split('@')[1];
  return allowedDomains.includes(domain);
};

/**
 * Generate JWT token
 */
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
};

/**
 * POST /api/auth/google
 */
const googleSignIn = async (req, res) => {
  try {
    const { idToken } = req.body;
    
    if (!idToken) {
      return res.status(400).json({ success: false, message: 'Google ID token is required' });
    }

    let payload;
    try {
      const verifyOptions = configuredClientIds.length > 0
        ? { idToken, audience: configuredClientIds }
        : { idToken };
      const ticket = await client.verifyIdToken(verifyOptions);
      payload = ticket.getPayload();
    } catch (error) {
      console.error('Google token verification failed:', error);
      return res.status(401).json({ success: false, message: 'Invalid or expired Google token' });
    }

    const { email, name, picture } = payload;

    // Check super admin email
    const isSuperAdmin =
      process.env.SUPER_ADMIN_EMAIL &&
      email.toLowerCase() === process.env.SUPER_ADMIN_EMAIL.toLowerCase();

    // Validate domain (super admin can bypass domain restriction)
    if (!isSuperAdmin && !isValidDomain(email)) {
      const domains = process.env.ALLOWED_DOMAINS || 'college.edu';
      return res.status(400).json({
        success: false,
        message: `Only @${domains} email addresses are allowed`,
      });
    }

    // Find user by email
    let user = await prisma.user.findUnique({ where: { email } });

    if (!user) {
      // Only auto-create account for super admin
      if (!isSuperAdmin) {
        return res.status(403).json({
          success: false,
          message: 'Account not found. Please contact your admin to create your account.',
        });
      }
      user = await prisma.user.create({
        data: {
          email,
          name: name || 'Google User',
          profileImageUrl: picture,
          role: 'ADMIN',
        },
      });
    } else {
      // Update missing profile picture and enforce admin role if needed
      user = await prisma.user.update({
        where: { id: user.id },
        data: { 
          ...(picture && !user.profileImageUrl && { profileImageUrl: picture }),
          ...(isSuperAdmin && user.role !== 'ADMIN' && { role: 'ADMIN' })
        },
      });
    }

    const token = generateToken(user.id);

    // Return user without password
    const { password: _, ...userWithoutPassword } = user;

    res.json({
      success: true,
      message: 'Login successful',
      data: { user: userWithoutPassword, token },
    });
  } catch (error) {
    console.error('Google Sign-In error:', error);
    
    // Log full error stack in non-production to identify detailed Prisma causes
    if (process.env.NODE_ENV !== 'production') {
      console.error(error.stack);
    }

    if (isDatabaseUnavailableError(error)) {
      return res.status(503).json({
        success: false,
        message:
            'Authentication service is temporarily unavailable (database connection failed). Please try again shortly.',
        details: process.env.NODE_ENV === 'development' ? error.message : undefined,
      });
    }
    res.status(500).json({ success: false, message: 'Google Sign-In failed' });
  }
};

/**
 * GET /api/auth/me
 */
const getMe = async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true, email: true, name: true, regNo: true, department: true,
        year: true, mobile: true, cgpa: true, rewardPoints: true, activityPoints: true,
        profileImageUrl: true, role: true, primarySkills: true, secondarySkills: true,
        specialSkills: true, programmingLangs: true, linkedinUrl: true, githubUrl: true,
        leetcodeUrl: true, twitterUrl: true, createdAt: true, updatedAt: true,
      },
    });

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({ success: true, data: user });
  } catch (error) {
    console.error('GetMe error:', error);
    if (isDatabaseUnavailableError(error)) {
      return res.status(503).json({
        success: false,
        message:
            'User profile service is temporarily unavailable (database connection failed).',
      });
    }
    res.status(500).json({ success: false, message: 'Failed to get user profile' });
  }
};

/**
 * PUT /api/auth/update-fcm-token
 */
const updateFcmToken = async (req, res) => {
  try {
    const { fcmToken } = req.body;
    console.log(`📡 Updating FCM Token for user ${req.user.id}: ${fcmToken ? fcmToken.substring(0, 10) + '...' : 'NULL'}`);

    await prisma.user.update({
      where: { id: req.user.id },
      data: { fcmToken },
    });
    res.json({ success: true, message: 'FCM token updated' });
  } catch (error) {
    console.error('FCM token error:', error);
    if (isDatabaseUnavailableError(error)) {
      return res.status(503).json({
        success: false,
        message:
            'Notification service is temporarily unavailable (database connection failed).',
      });
    }
    res.status(500).json({ success: false, message: 'Failed to update FCM token' });
  }
};

module.exports = { googleSignIn, getMe, updateFcmToken };
