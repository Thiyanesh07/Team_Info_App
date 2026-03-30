const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { logSystemActivity } = require('./systemActivity.controller');

/** GET /api/team-projects */
const getTeamProjects = async (req, res) => {
  try {
    const leaderRoles = ['ADMIN', 'CAPTAIN', 'VICE_CAPTAIN', 'STRATEGIST', 'MANAGER'];
    let projects;

    if (leaderRoles.includes(req.user.role)) {
      // Leaders see all projects
      projects = await prisma.teamProject.findMany({
        include: {
          createdBy: { select: { id: true, name: true, email: true } },
          assignedCaptain: { select: { id: true, name: true, email: true } },
          members: { include: { user: { select: { id: true, name: true, email: true } } } },
        },
        orderBy: { createdAt: 'desc' },
      });
    } else {
      // Members see only assigned projects
      projects = await prisma.teamProject.findMany({
        where: { members: { some: { userId: req.user.id } } },
        include: {
          createdBy: { select: { id: true, name: true, email: true } },
          assignedCaptain: { select: { id: true, name: true, email: true } },
          members: { include: { user: { select: { id: true, name: true, email: true } } } },
        },
        orderBy: { createdAt: 'desc' },
      });
    }

    res.json({ success: true, data: projects });
  } catch (error) {
    console.error('GetTeamProjects error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch team projects' });
  }
};

/** GET /api/team-projects/:id */
const getTeamProjectById = async (req, res) => {
  try {
    const project = await prisma.teamProject.findUnique({
      where: { id: req.params.id },
      include: {
        createdBy: { select: { id: true, name: true, email: true } },
        assignedCaptain: { select: { id: true, name: true, email: true } },
        members: { include: { user: { select: { id: true, name: true, email: true, role: true } } } },
        updates: {
          include: { user: { select: { id: true, name: true } } },
          orderBy: { createdAt: 'desc' },
        },
      },
    });
    if (!project) return res.status(404).json({ success: false, message: 'Project not found' });

    // Check access for members
    const leaderRoles = ['ADMIN', 'CAPTAIN', 'VICE_CAPTAIN', 'STRATEGIST', 'MANAGER'];
    if (!leaderRoles.includes(req.user.role)) {
      const isMember = project.members.some(m => m.userId === req.user.id);
      if (!isMember) return res.status(403).json({ success: false, message: 'Not authorized to view this project' });
    }

    res.json({ success: true, data: project });
  } catch (error) {
    console.error('GetTeamProjectById error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch project' });
  }
};

/** POST /api/team-projects (leaders only) */
const createTeamProject = async (req, res) => {
  try {
    const { projectName, assignedCaptainId, domain, subDomain, problemStatement, solution, startDate, memberIds } = req.body;
    if (!projectName) return res.status(400).json({ success: false, message: 'Project name is required' });

    const project = await prisma.teamProject.create({
      data: {
        projectName,
        createdById: req.user.id,
        assignedCaptainId,
        domain, subDomain, problemStatement, solution,
        startDate: startDate ? new Date(startDate) : null,
        members: memberIds && memberIds.length > 0 ? {
          create: memberIds.map(userId => ({ userId })),
        } : undefined,
      },
      include: {
        createdBy: { select: { id: true, name: true, email: true } },
        assignedCaptain: { select: { id: true, name: true, email: true } },
        members: { include: { user: { select: { id: true, name: true, email: true } } } },
      },
    });

    res.status(201).json({ success: true, message: 'Team project created', data: project });

    // Log System Activity
    logSystemActivity(
      req.user.id,
      'New Project Created',
      `Launched "${projectName}" for the team.`,
      'PROJECT_CREATED',
      { projectId: project.id }
    );
  } catch (error) {
    console.error('CreateTeamProject error:', error);
    res.status(500).json({ success: false, message: 'Failed to create team project' });
  }
};

/** PUT /api/team-projects/:id */
const updateTeamProject = async (req, res) => {
  try {
    const { projectName, assignedCaptainId, domain, subDomain, problemStatement, solution, startDate, status } = req.body;

    const project = await prisma.teamProject.update({
      where: { id: req.params.id },
      data: {
        ...(projectName && { projectName }),
        ...(assignedCaptainId !== undefined && { assignedCaptainId }),
        ...(domain !== undefined && { domain }),
        ...(subDomain !== undefined && { subDomain }),
        ...(problemStatement !== undefined && { problemStatement }),
        ...(solution !== undefined && { solution }),
        ...(startDate !== undefined && { startDate: startDate ? new Date(startDate) : null }),
        ...(status && { status }),
      },
      include: {
        createdBy: { select: { id: true, name: true, email: true } },
        assignedCaptain: { select: { id: true, name: true, email: true } },
        members: { include: { user: { select: { id: true, name: true, email: true } } } },
      },
    });

    res.json({ success: true, message: 'Project updated', data: project });

    // Log System Activity if completed
    if (status === 'COMPLETED') {
      logSystemActivity(
        req.user.id,
        'Project Milestone Reached',
        `Completed the project: "${project.projectName}"`,
        'PROJECT_COMPLETED',
        { projectId: project.id }
      );
    }
  } catch (error) {
    console.error('UpdateTeamProject error:', error);
    res.status(500).json({ success: false, message: 'Failed to update project' });
  }
};

/** POST /api/team-projects/:id/members - Assign members (Captain/Admin) */
const assignMembers = async (req, res) => {
  try {
    const { memberIds } = req.body;
    if (!memberIds || !Array.isArray(memberIds)) {
      return res.status(400).json({ success: false, message: 'memberIds array is required' });
    }

    // Remove existing + add new
    await prisma.teamProjectMember.deleteMany({ where: { teamProjectId: req.params.id } });
    await prisma.teamProjectMember.createMany({
      data: memberIds.map(userId => ({ teamProjectId: req.params.id, userId })),
    });

    const project = await prisma.teamProject.findUnique({
      where: { id: req.params.id },
      include: {
        members: { include: { user: { select: { id: true, name: true, email: true } } } },
      },
    });

    res.json({ success: true, message: 'Members assigned', data: project });

    // Log System Activity
    logSystemActivity(
      req.user.id,
      'Team Updated',
      `Modified members for project: "${project.projectName}"`,
      'PROJECT_MEMBERS_UPDATED',
      { projectId: project.id, memberCount: memberIds.length }
    );
  } catch (error) {
    console.error('AssignMembers error:', error);
    res.status(500).json({ success: false, message: 'Failed to assign members' });
  }
};

/** DELETE /api/team-projects/:id */
const deleteTeamProject = async (req, res) => {
  try {
    await prisma.teamProject.delete({ where: { id: req.params.id } });
    res.json({ success: true, message: 'Project deleted' });
  } catch (error) {
    console.error('DeleteTeamProject error:', error);
    res.status(500).json({ success: false, message: 'Failed to delete project' });
  }
};

module.exports = { getTeamProjects, getTeamProjectById, createTeamProject, updateTeamProject, assignMembers, deleteTeamProject };
