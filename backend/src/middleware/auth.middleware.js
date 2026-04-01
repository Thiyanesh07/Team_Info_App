const jwt = require('jsonwebtoken');
const prisma = require('../lib/prisma');

/**
 * Authentication middleware - verifies JWT token
 */
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'Access token required' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        lastActive: true, // Needed for throttling check
      },
    });

    if (!user) {
      return res.status(401).json({ success: false, message: 'User not found' });
    }

    // Phase 2: Throttle lastActive update (only update if > 5 mins ago)
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
    if (!user.lastActive || user.lastActive < fiveMinutesAgo) {
      prisma.user.update({
        where: { id: user.id },
        data: { lastActive: new Date() },
      }).catch(err => console.error('Presence update error:', err));
    }

    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, message: 'Token expired' });
    }
    return res.status(401).json({ success: false, message: 'Invalid token' });
  }
};

/**
 * Role-based authorization middleware
 * @param  {...string} roles - Allowed roles
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ success: false, message: 'Not authenticated' });
    }
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to perform this action',
      });
    }
    next();
  };
};

/**
 * Check if user is a leader (Admin, Captain, Vice Captain, Strategist, Manager)
 */
const isLeader = (req, res, next) => {
  const leaderRoles = ['ADMIN', 'CAPTAIN', 'VICE_CAPTAIN', 'STRATEGIST', 'MANAGER'];
  if (!leaderRoles.includes(req.user.role)) {
    return res.status(403).json({
      success: false,
      message: 'Only team leaders can perform this action',
    });
  }
  next();
};

/**
 * Check if user is Admin
 */
const isAdmin = (req, res, next) => {
  if (req.user.role !== 'ADMIN') {
    return res.status(403).json({
      success: false,
      message: 'Only admins can perform this action',
    });
  }
  next();
};

module.exports = { authenticate, authorize, isLeader, isAdmin };
