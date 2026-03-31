const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const userSelect = {
  id: true, email: true, name: true, regNo: true, department: true,
  year: true, mobile: true, cgpa: true, rewardPoints: true, activityPoints: true,
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

    if (rewardPoints !== undefined) {
      const reward = Number(rewardPoints);
      if (!Number.isFinite(reward) || reward <= 0) {
        return res.status(400).json({ success: false, message: 'Reward points must be a positive number' });
      }
    }

    if (activityPoints !== undefined) {
      const activity = Number(activityPoints);
      if (!Number.isFinite(activity) || activity <= 0) {
        return res.status(400).json({ success: false, message: 'Activity points must be a positive number' });
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
        ...(profileImageUrl !== undefined && { profileImageUrl }),
        ...(primarySkills && { primarySkills }),
        ...(secondarySkills && { secondarySkills }),
        ...(specialSkills && { specialSkills }),
        ...(programmingLangs && { programmingLangs }),
        ...(rewardPoints !== undefined && {
          rewardPoints: Number(rewardPoints),
        }),
        ...(activityPoints !== undefined && {
          activityPoints: Number(activityPoints),
        }),
        ...(linkedinUrl !== undefined && { linkedinUrl }),
        ...(githubUrl !== undefined && { githubUrl }),
        ...(leetcodeUrl !== undefined && { leetcodeUrl }),
        ...(twitterUrl !== undefined && { twitterUrl }),
      },
      select: userSelect,
    });

    res.json({ success: true, message: 'Profile updated', data: user });
  } catch (error) {
    console.error('UpdateProfile error:', error);
    res.status(500).json({ success: false, message: 'Failed to update profile' });
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

module.exports = { getAllUsers, getUserById, updateProfile, assignRole, createUser, deleteUser, adminUpdateUser };
