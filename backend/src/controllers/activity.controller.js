const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/** GET /api/activities - Get activities (own for member, any for leader, all for admin) */
const getMyActivities = async (req, res) => {
  try {
    const { userId, startDate, endDate, type, customType } = req.query;
    const where = {};

    // Determine whose activities to fetch
    if (req.user.role === 'ADMIN') {
      if (userId) where.userId = userId;
      // else where is empty -> all users
    } else if (['CAPTAIN', 'VICE_CAPTAIN', 'STRATEGIST', 'MANAGER'].includes(req.user.role)) {
      where.userId = userId || req.user.id;
    } else {
      where.userId = req.user.id;
    }

    if (type) where.type = type;
    if (customType) where.customType = customType;

    if (startDate && endDate) {
      where.date = { gte: new Date(startDate), lte: new Date(endDate) };
    } else if (startDate) {
      where.date = { gte: new Date(startDate) };
    }

    const activities = await prisma.dailyActivity.findMany({
      where,
      include: { user: { select: { id: true, name: true, profileImageUrl: true } } },
      orderBy: { date: 'desc' },
    });
    res.json({ success: true, data: activities });
  } catch (error) {
    console.error('GetMyActivities error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch activities' });
  }
};

/** GET /api/activities/user/:userId - Leaders view user's activities */
const getUserActivities = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const where = { userId: req.params.userId };
    if (startDate && endDate) {
      where.date = { gte: new Date(startDate), lte: new Date(endDate) };
    }

    const activities = await prisma.dailyActivity.findMany({
      where,
      include: { user: { select: { id: true, name: true, profileImageUrl: true } } },
      orderBy: { date: 'desc' },
    });
    res.json({ success: true, data: activities });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch activities' });
  }
};

/** GET /api/activities/all - All team activities (visible to all) */
const getAllActivities = async (req, res) => {
  try {
    const { date } = req.query;
    const where = {};
    if (date) where.date = new Date(date);

    const activities = await prisma.dailyActivity.findMany({
      where,
      include: { user: { select: { id: true, name: true, profileImageUrl: true } } },
      orderBy: { date: 'desc' },
      take: 100,
    });
    res.json({ success: true, data: activities });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch activities' });
  }
};

/** POST /api/activities */
const createActivity = async (req, res) => {
  try {
    const { type, customType, description, startTime, endTime, date } = req.body;
    if (!type || !startTime || !endTime || !date) {
      return res.status(400).json({ success: false, message: 'Type, startTime, endTime, and date are required' });
    }

    const activity = await prisma.dailyActivity.create({
      data: {
        userId: req.user.id,
        type, customType, description,
        startTime: new Date(startTime),
        endTime: new Date(endTime),
        date: new Date(date),
      },
    });
    res.status(201).json({ success: true, message: 'Activity logged', data: activity });
  } catch (error) {
    console.error('CreateActivity error:', error);
    res.status(500).json({ success: false, message: 'Failed to log activity' });
  }
};

/** PUT /api/activities/:id */
const updateActivity = async (req, res) => {
  try {
    const existing = await prisma.dailyActivity.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ success: false, message: 'Not found' });
    if (existing.userId !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const data = { ...req.body };
    if (data.startTime) data.startTime = new Date(data.startTime);
    if (data.endTime) data.endTime = new Date(data.endTime);
    if (data.date) data.date = new Date(data.date);

    const activity = await prisma.dailyActivity.update({ where: { id: req.params.id }, data });
    res.json({ success: true, message: 'Activity updated', data: activity });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to update activity' });
  }
};

/** DELETE /api/activities/:id */
const deleteActivity = async (req, res) => {
  try {
    const existing = await prisma.dailyActivity.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ success: false, message: 'Not found' });
    if (existing.userId !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }
    await prisma.dailyActivity.delete({ where: { id: req.params.id } });
    res.json({ success: true, message: 'Activity deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to delete activity' });
  }
};

module.exports = { getMyActivities, getUserActivities, getAllActivities, createActivity, updateActivity, deleteActivity };
