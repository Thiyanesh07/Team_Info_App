const prisma = require('../lib/prisma');


/** GET /api/hackathons */
const getMyHackathons = async (req, res) => {
  try {
    const hackathons = await prisma.hackathon.findMany({
      where: { userId: req.user.id },
      include: { rounds: true },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: hackathons });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch hackathons' });
  }
};

/** GET /api/hackathons/user/:userId */
const getUserHackathons = async (req, res) => {
  try {
    const hackathons = await prisma.hackathon.findMany({
      where: { userId: req.params.userId },
      include: { rounds: true },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: hackathons });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch hackathons' });
  }
};

/** POST /api/hackathons */
const createHackathon = async (req, res) => {
  try {
    const { hackName, projectName, description, contribution, skillsUsed, date, isTeam, teamMembers, status, rounds } = req.body;
    if (!hackName) return res.status(400).json({ success: false, message: 'Hackathon name is required' });

    const hackathon = await prisma.hackathon.create({
      data: {
        userId: req.user.id,
        hackName, projectName, description, contribution,
        skillsUsed: skillsUsed || [],
        date: date ? new Date(date) : null,
        isTeam: isTeam || false,
        teamMembers: teamMembers || [],
        status: status || 'UPCOMING',
        rounds: rounds && rounds.length > 0 ? {
          create: rounds.map(r => ({ roundName: r.roundName, description: r.description })),
        } : undefined,
      },
      include: { rounds: true },
    });

    res.status(201).json({ success: true, message: 'Hackathon created', data: hackathon });
  } catch (error) {
    console.error('CreateHackathon error:', error);
    res.status(500).json({ success: false, message: 'Failed to create hackathon' });
  }
};

/** PUT /api/hackathons/:id */
const updateHackathon = async (req, res) => {
  try {
    const existing = await prisma.hackathon.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ success: false, message: 'Not found' });
    if (existing.userId !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const { rounds, ...data } = req.body;
    if (data.date) data.date = new Date(data.date);

    // Update rounds if provided
    if (rounds) {
      await prisma.hackathonRound.deleteMany({ where: { hackathonId: req.params.id } });
      await prisma.hackathonRound.createMany({
        data: rounds.map(r => ({ hackathonId: req.params.id, roundName: r.roundName, description: r.description })),
      });
    }

    const hackathon = await prisma.hackathon.update({
      where: { id: req.params.id },
      data,
      include: { rounds: true },
    });

    res.json({ success: true, message: 'Hackathon updated', data: hackathon });
  } catch (error) {
    console.error('UpdateHackathon error:', error);
    res.status(500).json({ success: false, message: 'Failed to update hackathon' });
  }
};

/** DELETE /api/hackathons/:id */
const deleteHackathon = async (req, res) => {
  try {
    const existing = await prisma.hackathon.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ success: false, message: 'Not found' });
    if (existing.userId !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }
    await prisma.hackathon.delete({ where: { id: req.params.id } });
    res.json({ success: true, message: 'Hackathon deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to delete hackathon' });
  }
};

module.exports = { getMyHackathons, getUserHackathons, createHackathon, updateHackathon, deleteHackathon };

