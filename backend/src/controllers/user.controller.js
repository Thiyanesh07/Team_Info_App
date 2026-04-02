const prisma = require('../lib/prisma');
const { validateAndNormalizeUrl } = require('../lib/urlValidation');


const PS_SYNC_COOLDOWN_MS = Number(process.env.PS_SYNC_COOLDOWN_MS || 45000);
const psSyncCooldownByUser = new Map();

const getSyncCooldownRemainingMs = (userId) => {
  const lastSyncMs = psSyncCooldownByUser.get(userId);
  if (!lastSyncMs) return 0;
  return Math.max(0, PS_SYNC_COOLDOWN_MS - (Date.now() - lastSyncMs));
};



const userSelect = {
  id: true, email: true, name: true, regNo: true, department: true,
  year: true, mobile: true, cgpa: true, rewardPoints: true, activityPoints: true,
  psToken: true, groupPoints: true, contributionPercent: true,
  profileImageUrl: true, role: true, primarySkills: true, secondarySkills: true,
  specialSkills: true, programmingLangs: true, linkedinUrl: true, githubUrl: true,
  leetcodeUrl: true, twitterUrl: true, createdAt: true, updatedAt: true,
};

/** GET /api/users - Get all users (leaders & admin) */
const getAllUsers = async (req, res) => {
  try {
    const where = {};
    if (req.user && req.user.role !== 'ADMIN') {
      where.role = { not: 'ADMIN' };
    }

    const users = await prisma.user.findMany({
      where,
      select: userSelect,
      orderBy: { name: 'asc' },
    });
    res.json({ success: true, data: users });
  } catch (error) {
    console.error('GetAllUsers error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch users' });
  }
};

/** GET /api/users/:id */
const getUserById = async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.params.id },
      select: userSelect,
    });
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, data: user });
  } catch (error) {
    console.error('GetUserById error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch user' });
  }
};

/** PUT /api/users/profile - Update own profile */
const updateProfile = async (req, res) => {
  try {
    const { name, regNo, department, year, mobile, cgpa, profileImageUrl,
      primarySkills, secondarySkills, specialSkills, programmingLangs,
      linkedinUrl, githubUrl, leetcodeUrl, twitterUrl,
      rewardPoints, activityPoints } = req.body;

    let normalizedProfileImageUrl = profileImageUrl;
    if (profileImageUrl !== undefined) {
      try {
        normalizedProfileImageUrl = validateAndNormalizeUrl(
          profileImageUrl,
          'profileImageUrl',
        );
      } catch (e) {
        return res.status(400).json({ success: false, message: e.message });
      }
    }

    const user = await prisma.user.update({
      where: { id: req.user.id },
      data: {
        ...(name && { name }),
        ...(regNo !== undefined && { regNo }),
        ...(department !== undefined && { department }),
        ...(year !== undefined && { year }),
        ...(mobile !== undefined && { mobile }),
        ...(cgpa !== undefined && { cgpa: cgpa ? parseFloat(cgpa) : null }),
        ...(profileImageUrl !== undefined && { profileImageUrl: normalizedProfileImageUrl }),
        ...(primarySkills && { primarySkills }),
        ...(secondarySkills && { secondarySkills }),
        ...(specialSkills && { specialSkills }),
        ...(programmingLangs && { programmingLangs }),
        ...(linkedinUrl !== undefined && { linkedinUrl }),
        ...(githubUrl !== undefined && { githubUrl }),
        ...(leetcodeUrl !== undefined && { leetcodeUrl }),
        ...(twitterUrl !== undefined && { twitterUrl }),
        ...(rewardPoints !== undefined && { rewardPoints: parseInt(rewardPoints) }),
        ...(activityPoints !== undefined && { activityPoints: parseInt(activityPoints) }),
      },
      select: userSelect,
    });

    res.json({ success: true, message: 'Profile updated', data: user });
  } catch (error) {
    console.error('UpdateProfile error:', error);
    res.status(500).json({ success: false, message: 'Failed to update profile' });
  }
};

/** PATCH /api/users/profile/points - Update own AP/RP only */
const updateOwnPoints = async (req, res) => {
  try {
    const hasReward = req.body?.rewardPoints !== undefined;
    const hasActivity = req.body?.activityPoints !== undefined;

    if (!hasReward && !hasActivity) {
      return res.status(400).json({
        success: false,
        message: 'Provide rewardPoints or activityPoints',
      });
    }

    const rewardPoints = hasReward ? Number(req.body.rewardPoints) : undefined;
    const activityPoints = hasActivity
      ? Number(req.body.activityPoints)
      : undefined;

    if (
      (hasReward && (!Number.isFinite(rewardPoints) || rewardPoints < 0)) ||
      (hasActivity && (!Number.isFinite(activityPoints) || activityPoints < 0))
    ) {
      return res.status(400).json({
        success: false,
        message: 'Points must be valid non-negative numbers',
      });
    }

    const user = await prisma.user.update({
      where: { id: req.user.id },
      data: {
        ...(hasReward && { rewardPoints: Math.floor(rewardPoints) }),
        ...(hasActivity && { activityPoints: Math.floor(activityPoints) }),
      },
      select: userSelect,
    });

    return res.json({
      success: true,
      message: 'Points updated',
      data: user,
    });
  } catch (error) {
    console.error('UpdateOwnPoints error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to update points',
    });
  }
};

/** PUT /api/users/:id/role - Admin: assign role */
const assignRole = async (req, res) => {
  try {
    const { role } = req.body;
    const validRoles = ['ADMIN', 'CAPTAIN', 'VICE_CAPTAIN', 'STRATEGIST', 'MANAGER', 'MEMBER'];
    if (!validRoles.includes(role)) {
      return res.status(400).json({ success: false, message: 'Invalid role' });
    }

    const user = await prisma.user.update({
      where: { id: req.params.id },
      data: { role },
      select: userSelect,
    });

    res.json({ success: true, message: 'Role updated', data: user });
  } catch (error) {
    console.error('AssignRole error:', error);
    res.status(500).json({ success: false, message: 'Failed to assign role' });
  }
};

/** POST /api/users/create - Admin: create user (Google-auth compatible, no password) */
const createUser = async (req, res) => {
  try {
    const {
      email,
      name,
      role,
      regNo,
      department,
      year,
      mobile,
      rewardPoints,
      activityPoints,
    } = req.body;

    if (!email || !name) {
      return res.status(400).json({ success: false, message: 'Email and name are required' });
    }

    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      return res.status(409).json({ success: false, message: 'Email already registered' });
    }

    const user = await prisma.user.create({
      data: {
        email, name,
        role: role || 'MEMBER', regNo, department, year, mobile,
        ...(rewardPoints !== undefined && {
          rewardPoints: Number.isFinite(Number(rewardPoints))
              ? Number(rewardPoints)
              : 0,
        }),
        ...(activityPoints !== undefined && {
          activityPoints: Number.isFinite(Number(activityPoints))
              ? Number(activityPoints)
              : 0,
        }),
      },
      select: userSelect,
    });

    res.status(201).json({ success: true, message: 'User created', data: user });
  } catch (error) {
    console.error('CreateUser error:', error);
    res.status(500).json({ success: false, message: 'Failed to create user' });
  }
};

/** DELETE /api/users/:id - Admin: delete user */
const deleteUser = async (req, res) => {
  try {
    await prisma.user.delete({ where: { id: req.params.id } });
    res.json({ success: true, message: 'User deleted' });
  } catch (error) {
    console.error('DeleteUser error:', error);
    res.status(500).json({ success: false, message: 'Failed to delete user' });
  }
};

/** PUT /api/users/:id - Admin: update any user */
const adminUpdateUser = async (req, res) => {
  try {
    const {
      name,
      regNo,
      department,
      year,
      mobile,
      cgpa,
      role,
      rewardPoints,
      activityPoints,
      primarySkills,
      secondarySkills,
      specialSkills,
      programmingLangs,
      linkedinUrl,
      githubUrl,
      leetcodeUrl,
      twitterUrl,
    } = req.body;

    const user = await prisma.user.update({
      where: { id: req.params.id },
      data: {
        ...(name && { name }),
        ...(regNo !== undefined && { regNo }),
        ...(department !== undefined && { department }),
        ...(year !== undefined && { year }),
        ...(mobile !== undefined && { mobile }),
        ...(cgpa !== undefined && { cgpa: cgpa ? parseFloat(cgpa) : null }),
        ...(role && { role }),
        ...(rewardPoints !== undefined && {
          rewardPoints: Number.isFinite(Number(rewardPoints))
              ? Number(rewardPoints)
              : 0,
        }),
        ...(activityPoints !== undefined && {
          activityPoints: Number.isFinite(Number(activityPoints))
              ? Number(activityPoints)
              : 0,
        }),
        ...(primarySkills && { primarySkills }),
        ...(secondarySkills && { secondarySkills }),
        ...(specialSkills && { specialSkills }),
        ...(programmingLangs && { programmingLangs }),
        ...(linkedinUrl !== undefined && { linkedinUrl }),
        ...(githubUrl !== undefined && { githubUrl }),
        ...(leetcodeUrl !== undefined && { leetcodeUrl }),
        ...(twitterUrl !== undefined && { twitterUrl }),
      },
      select: userSelect,
    });

    res.json({ success: true, message: 'User updated successfully', data: user });
  } catch (error) {
    console.error('AdminUpdateUser error:', error);
    res.status(500).json({ success: false, message: 'Failed to update user' });
  }
};

/** PUT /api/users/ps-sync - Sync Activity Points via token */
const syncPsPoints = async (req, res) => {
  try {
    const rawToken = typeof req.body?.psToken === 'string' ? req.body.psToken : '';
    const psToken = rawToken.trim();
    const tokenPresent = psToken.length > 0;
    const hasManualPoints = Number.isFinite(Number(req.body?.manualActivityPoints));
    const manualActivityPoints = hasManualPoints
      ? Number(req.body.manualActivityPoints)
      : null;
    console.info(
      `[PS_SYNC] user=${req.user.id} tokenPresent=${tokenPresent} tokenLength=${psToken.length} manualPoints=${manualActivityPoints ?? 'none'}`
    );

    const existingUser = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        activityPoints: true,
      },
    });

    const oldPoints = Number(existingUser?.activityPoints || 0);
    const cooldownRemainingMs = getSyncCooldownRemainingMs(req.user.id);
    if (cooldownRemainingMs > 0) {
      const retryAfterSeconds = Math.ceil(cooldownRemainingMs / 1000);
      return res.status(429).json({
        success: false,
        message: `Sync already ran recently. Please retry in ${retryAfterSeconds}s.`,
        data: {
          oldPoints,
          newPoints: oldPoints,
          delta: 0,
          syncedAt: new Date(Date.now() - (PS_SYNC_COOLDOWN_MS - cooldownRemainingMs)).toISOString(),
          retryAfterSeconds,
          idempotent: true,
        },
      });
    }

    if (!tokenPresent && manualActivityPoints === null) {
      return res.status(400).json({
        success: false,
        message: 'Provide PS token or manualActivityPoints to sync.',
      });
    }

    let activityPoints = 0;

    if (manualActivityPoints !== null) {
      activityPoints = Math.max(0, Math.floor(manualActivityPoints));
    } else {
      // Call the external API
      const response = await fetch('https://ps.bitsathy.ac.in/api/ps_v2/dashboard/user-points?filter=overall', {
        method: 'GET',
        headers: {
          'Accept': 'application/json, text/plain, */*',
          'Cookie': `PS=${psToken}`,
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.0.0 Mobile Safari/537.36'
        }
      });
      console.info(`[PS_SYNC] user=${req.user.id} portalStatus=${response.status}`);

      if (!response.ok) {
        return res.status(response.status).json({
          success: false,
          message: 'Failed to authenticate with PS portal. Please login again and retry.',
        });
      }

      const dataObj = await response.json();
      if (!dataObj.success || !dataObj.data) {
          return res.status(400).json({ success: false, message: 'Invalid response from PS portal' });
      }

      if (dataObj.data.points && dataObj.data.points.length > 0) {
          activityPoints = Number(dataObj.data.points[0].total_points || 0);
      }
    }

    const delta = activityPoints - oldPoints;
    const syncedAt = new Date().toISOString();

    // Update user points first, then compute total contribution from all members.
    const updatedUser = await prisma.user.update({
      where: { id: req.user.id },
      data: {
        ...(tokenPresent && { psToken }),
        activityPoints,
      },
      select: userSelect,
    });

    const totals = await prisma.user.aggregate({
      where: { role: { not: 'ADMIN' } },
      _sum: { activityPoints: true },
    });

    const totalActivityPoints = Number(totals._sum.activityPoints || 0);
    const contributionPercent = totalActivityPoints > 0
      ? Number(((activityPoints / totalActivityPoints) * 100).toFixed(2))
      : 0;

    const user = await prisma.user.update({
      where: { id: req.user.id },
      data: {
        groupPoints: totalActivityPoints,
        contributionPercent
      },
      select: userSelect,
    });
    psSyncCooldownByUser.set(req.user.id, Date.now());

    res.json({
      success: true,
      message: 'Points synced successfully',
      data: {
        user,
        oldPoints,
        newPoints: activityPoints,
        delta,
        syncedAt,
      },
    });
  } catch (error) {
    console.error('SyncPsPoints error:', error);
    res.status(500).json({ success: false, message: 'Internal server error while syncing points' });
  }
};

module.exports = {
  getAllUsers,
  getUserById,
  updateProfile,
  updateOwnPoints,
  assignRole,
  createUser,
  deleteUser,
  adminUpdateUser,
  syncPsPoints,
};

