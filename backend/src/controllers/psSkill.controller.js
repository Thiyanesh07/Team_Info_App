const prisma = require('../lib/prisma');

const { logSystemActivity } = require('./systemActivity.controller');

/** GET /api/ps-skills */
const getMyPsSkills = async (req, res) => {
  try {
    const skills = await prisma.psSkill.findMany({
      where: { userId: req.user.id }, orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: skills });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch PS skills' });
  }
};

/** GET /api/ps-skills/user/:userId */
const getUserPsSkills = async (req, res) => {
  try {
    const skills = await prisma.psSkill.findMany({
      where: { userId: req.params.userId }, orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: skills });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch PS skills' });
  }
};

/** POST /api/ps-skills */
const createPsSkill = async (req, res) => {
  try {
    const { type, skillName, level, completedDate, userId } = req.body;
    if (!type || !skillName) return res.status(400).json({ success: false, message: 'Type and skillName are required' });

    // Allow Admin to create for others
    const targetUserId = (req.user.role === 'ADMIN' && userId) ? userId : req.user.id;

    const skill = await prisma.psSkill.create({
      data: { 
        userId: targetUserId, 
        type, 
        skillName,
        level,
        completedDate: completedDate ? new Date(completedDate) : null,
        completed: true // Assessments in this section are considered completed
      },
    });
    res.status(201).json({ success: true, message: 'PS skill added', data: skill });

    // Log System Activity
    logSystemActivity(
      req.user.id,
      'Skill Added',
      `Added a new skill: "${skillName}" (${type})`,
      'SKILL_ADDED',
      { skillId: skill.id }
    );
  } catch (error) {
    console.error('CreatePsSkill error:', error);
    res.status(500).json({ success: false, message: 'Failed to create PS skill' });
  }
};

/** PUT /api/ps-skills/:id */
const updatePsSkill = async (req, res) => {
  try {
    const existing = await prisma.psSkill.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ success: false, message: 'Not found' });
    
    // Auth check
    if (existing.userId !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const { type, skillName, level, completedDate, completed } = req.body;
    const data = {};
    if (type) data.type = type;
    if (skillName) data.skillName = skillName;
    if (level !== undefined) data.level = level;
    if (completedDate !== undefined) {
      data.completedDate = completedDate ? new Date(completedDate) : null;
    }
    if (completed !== undefined) data.completed = completed;

    const skill = await prisma.psSkill.update({ 
      where: { id: req.params.id }, 
      data 
    });
    res.json({ success: true, message: 'PS skill updated', data: skill });

    // Log System Activity if completed
    if (req.body.completed === true && existing.completed !== true) {
      logSystemActivity(
        req.user.id,
        'Skill Achieved',
        `Mastered the skill: "${skill.skillName}"`,
        'SKILL_COMPLETED',
        { skillId: skill.id }
      );
    }
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to update PS skill' });
  }
};

/** DELETE /api/ps-skills/:id */
const deletePsSkill = async (req, res) => {
  try {
    const existing = await prisma.psSkill.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ success: false, message: 'Not found' });
    
    if (existing.userId !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }
    await prisma.psSkill.delete({ where: { id: req.params.id } });
    res.json({ success: true, message: 'PS skill deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to delete PS skill' });
  }
};

module.exports = { getMyPsSkills, getUserPsSkills, createPsSkill, updatePsSkill, deletePsSkill };

