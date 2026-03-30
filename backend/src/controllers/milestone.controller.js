const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { logSystemActivity } = require('./systemActivity.controller');

/** GET /api/team-projects/:projectId/milestones */
const getProjectMilestones = async (req, res) => {
  try {
    const milestones = await prisma.projectMilestone.findMany({
      where: { projectId: req.params.projectId },
      orderBy: { order: 'asc' }
    });
    res.json({ success: true, data: milestones });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch milestones' });
  }
};

/** POST /api/team-projects/:projectId/milestones */
const createMilestone = async (req, res) => {
  try {
    const { title, description, deadline, order } = req.body;
    const milestone = await prisma.projectMilestone.create({
      data: {
        projectId: req.params.projectId,
        title,
        description,
        deadline: deadline ? new Date(deadline) : null,
        order: order || 0
      }
    });

    res.status(201).json({ success: true, data: milestone });

    // Log System Activity
    const project = await prisma.teamProject.findUnique({ where: { id: req.params.projectId } });
    logSystemActivity(
      req.user.id,
      'Mission Objective Added',
      `Defined milestone "${title}" for ${project?.projectName}`,
      'MILESTONE_CREATED',
      { projectId: req.params.projectId }
    );
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to create milestone' });
  }
};

/** PATCH /api/milestones/:id/status */
const updateMilestoneStatus = async (req, res) => {
  try {
    const { status } = req.body; // 'PENDING', 'IN_PROGRESS', 'COMPLETED'
    const milestone = await prisma.projectMilestone.update({
      where: { id: req.params.id },
      data: { status }
    });

    res.json({ success: true, data: milestone });

    if (status === 'COMPLETED') {
      logSystemActivity(
        req.user.id,
        'Milestone Achieved',
        `Succesfully reached goal: "${milestone.title}"`,
        'MILESTONE_COMPLETED',
        { projectId: milestone.projectId }
      );
    }
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to update milestone' });
  }
};

module.exports = { getProjectMilestones, createMilestone, updateMilestoneStatus };
