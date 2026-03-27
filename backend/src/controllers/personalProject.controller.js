const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/** GET /api/personal-projects - Get current user's projects */
const getMyProjects = async (req, res) => {
  try {
    const projects = await prisma.personalProject.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: projects });
  } catch (error) {
    console.error('GetMyProjects error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch projects' });
  }
};

/** GET /api/personal-projects/user/:userId - Get user's projects (leaders) */
const getUserProjects = async (req, res) => {
  try {
    const projects = await prisma.personalProject.findMany({
      where: { userId: req.params.userId },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: projects });
  } catch (error) {
    console.error('GetUserProjects error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch projects' });
  }
};

/** POST /api/personal-projects */
const createProject = async (req, res) => {
  try {
    const { name, description, contribution, githubLink, liveLink, skillsUsed } = req.body;
    if (!name) return res.status(400).json({ success: false, message: 'Project name is required' });

    const project = await prisma.personalProject.create({
      data: {
        userId: req.user.id,
        name, description, contribution, githubLink, liveLink,
        skillsUsed: skillsUsed || [],
      },
    });
    res.status(201).json({ success: true, message: 'Project created', data: project });
  } catch (error) {
    console.error('CreateProject error:', error);
    res.status(500).json({ success: false, message: 'Failed to create project' });
  }
};

/** PUT /api/personal-projects/:id */
const updateProject = async (req, res) => {
  try {
    const project = await prisma.personalProject.findUnique({ where: { id: req.params.id } });
    if (!project) return res.status(404).json({ success: false, message: 'Project not found' });
    if (project.userId !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const updated = await prisma.personalProject.update({
      where: { id: req.params.id },
      data: req.body,
    });
    res.json({ success: true, message: 'Project updated', data: updated });
  } catch (error) {
    console.error('UpdateProject error:', error);
    res.status(500).json({ success: false, message: 'Failed to update project' });
  }
};

/** DELETE /api/personal-projects/:id */
const deleteProject = async (req, res) => {
  try {
    const project = await prisma.personalProject.findUnique({ where: { id: req.params.id } });
    if (!project) return res.status(404).json({ success: false, message: 'Project not found' });
    if (project.userId !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    await prisma.personalProject.delete({ where: { id: req.params.id } });
    res.json({ success: true, message: 'Project deleted' });
  } catch (error) {
    console.error('DeleteProject error:', error);
    res.status(500).json({ success: false, message: 'Failed to delete project' });
  }
};

module.exports = { getMyProjects, getUserProjects, createProject, updateProject, deleteProject };
