const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/** GET /api/learning */
const getMyLearnings = async (req, res) => {
  try {
    const learnings = await prisma.learning.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: learnings });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch learnings' });
  }
};

/** GET /api/learning/user/:userId */
const getUserLearnings = async (req, res) => {
  try {
    const learnings = await prisma.learning.findMany({
      where: { userId: req.params.userId },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: learnings });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch learnings' });
  }
};

/** POST /api/learning */
const createLearning = async (req, res) => {
  try {
    const { skillName, topics, startDate, endDate, level, status } = req.body;
    if (!skillName) return res.status(400).json({ success: false, message: 'Skill name is required' });

    const learning = await prisma.learning.create({
      data: {
        userId: req.user.id,
        skillName, topics: topics || [],
        startDate: startDate ? new Date(startDate) : null,
        endDate: endDate ? new Date(endDate) : null,
        level: level || 'BEGINNER',
        status: status || 'ONGOING',
      },
    });
    res.status(201).json({ success: true, message: 'Learning created', data: learning });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to create learning' });
  }
};

/** PUT /api/learning/:id */
const updateLearning = async (req, res) => {
  try {
    const existing = await prisma.learning.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ success: false, message: 'Not found' });
    if (existing.userId !== req.user.id) return res.status(403).json({ success: false, message: 'Not authorized' });

    const data = { ...req.body };
    if (data.startDate) data.startDate = new Date(data.startDate);
    if (data.endDate) data.endDate = new Date(data.endDate);

    const learning = await prisma.learning.update({ where: { id: req.params.id }, data });
    res.json({ success: true, message: 'Learning updated', data: learning });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to update learning' });
  }
};

/** DELETE /api/learning/:id */
const deleteLearning = async (req, res) => {
  try {
    const existing = await prisma.learning.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ success: false, message: 'Not found' });
    if (existing.userId !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }
    await prisma.learning.delete({ where: { id: req.params.id } });
    res.json({ success: true, message: 'Learning deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to delete learning' });
  }
};

module.exports = { getMyLearnings, getUserLearnings, createLearning, updateLearning, deleteLearning };
