const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/** GET /api/project-updates/:projectId */
const getProjectUpdates = async (req, res) => {
  try {
    const updates = await prisma.projectUpdate.findMany({
      where: { projectId: req.params.projectId },
      include: { user: { select: { id: true, name: true, profileImageUrl: true } } },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: updates });
  } catch (error) {
    console.error('GetProjectUpdates error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch updates' });
  }
};

/** POST /api/project-updates/:projectId */
const createProjectUpdate = async (req, res) => {
  try {
    const { title, description, date } = req.body;
    if (!title) return res.status(400).json({ success: false, message: 'Title is required' });

    const update = await prisma.projectUpdate.create({
      data: {
        projectId: req.params.projectId,
        userId: req.user.id,
        title,
        description,
        date: date ? new Date(date) : new Date(),
      },
      include: { user: { select: { id: true, name: true, profileImageUrl: true } } },
    });

    res.status(201).json({ success: true, message: 'Update posted', data: update });
  } catch (error) {
    console.error('CreateProjectUpdate error:', error);
    res.status(500).json({ success: false, message: 'Failed to post update' });
  }
};

/** DELETE /api/project-updates/:id */
const deleteProjectUpdate = async (req, res) => {
  try {
    const update = await prisma.projectUpdate.findUnique({ where: { id: req.params.id } });
    if (!update) return res.status(404).json({ success: false, message: 'Update not found' });
    if (update.userId !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }
    await prisma.projectUpdate.delete({ where: { id: req.params.id } });
    res.json({ success: true, message: 'Update deleted' });
  } catch (error) {
    console.error('DeleteProjectUpdate error:', error);
    res.status(500).json({ success: false, message: 'Failed to delete update' });
  }
};

/** PUT /api/project-updates/:id */
const updateProjectUpdate = async (req, res) => {
  try {
    const { title, description, date } = req.body;
    const update = await prisma.projectUpdate.findUnique({ where: { id: req.params.id } });
    
    if (!update) return res.status(404).json({ success: false, message: 'Update not found' });
    if (update.userId !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const updated = await prisma.projectUpdate.update({
      where: { id: req.params.id },
      data: {
        title: title || update.title,
        description: description !== undefined ? description : update.description,
        date: date ? new Date(date) : update.date,
      },
      include: { user: { select: { id: true, name: true, profileImageUrl: true } } },
    });

    res.json({ success: true, message: 'Update updated', data: updated });
  } catch (error) {
    console.error('UpdateProjectUpdate error:', error);
    res.status(500).json({ success: false, message: 'Failed to update' });
  }
};

module.exports = { getProjectUpdates, createProjectUpdate, updateProjectUpdate, deleteProjectUpdate };
