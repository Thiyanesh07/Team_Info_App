const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/**
 * Get high-level team overview for Admin Dashboard
 */
const getAdminOverview = async (req, res) => {
  try {
    const [
      totalUsers,
      roleCounts,
      taskStats,
      projectStats,
      hackathonCount,
      learningCount,
      recentActivities,
      topPerformers
    ] = await Promise.all([
      // Total Users
      prisma.user.count(),
      
      // Users by Role
      prisma.user.groupBy({
        by: ['role'],
        _count: { id: true }
      }),
      
      // Task Status Counts
      prisma.taskAssignment.groupBy({
        by: ['status'],
        _count: { id: true }
      }),
      
      // Project Status Counts
      prisma.teamProject.groupBy({
        by: ['status'],
        _count: { id: true }
      }),
      
      // Counts for Hackathons & Learning
      prisma.hackathon.count(),
      prisma.learning.count(),
      
      // Recent System Activities (Top 10)
      prisma.systemActivity.findMany({
        take: 10,
        orderBy: { createdAt: 'desc' },
        include: {
          user: {
            select: { name: true, profileImageUrl: true }
          }
        }
      }),
      
      // Top 5 Performers
      prisma.user.findMany({
        take: 5,
        orderBy: { rewardPoints: 'desc' },
        select: {
          id: true,
          name: true,
          rewardPoints: true,
          role: true,
          profileImageUrl: true
        }
      })
    ]);

    // Format Role Counts
    const roleDistribution = (roleCounts || []).reduce((acc, curr) => {
      if (curr.role) acc[curr.role] = curr._count.id;
      return acc;
    }, {});

    // Format Task Stats
    const tasksByStatus = (taskStats || []).reduce((acc, curr) => {
      if (curr.status) acc[curr.status] = curr._count.id;
      return acc;
    }, {});

    // Format Project Stats
    const projectsByStatus = (projectStats || []).reduce((acc, curr) => {
      if (curr.status) acc[curr.status] = curr._count.id;
      return acc;
    }, {});

    res.json({
      success: true,
      data: {
        totalUsers,
        roleDistribution,
        tasks: {
          total: Object.values(tasksByStatus).reduce((a, b) => a + b, 0),
          byStatus: tasksByStatus
        },
        projects: {
          total: Object.values(projectsByStatus).reduce((a, b) => a + b, 0),
          byStatus: projectsByStatus
        },
        counts: {
          hackathons: hackathonCount,
          learnings: learningCount
        },
        recentActivities,
        topPerformers
      }
    });

  } catch (error) {
    console.error('getAdminOverview error:', error);
    res.status(500).json({ success: false, message: 'Server error fetching overview' });
  }
};

/**
 * Get comprehensive user detail for Admin Inspection
 */
const getAdminUserDetail = async (req, res) => {
  const { id } = req.params;

  try {
    const userDetail = await prisma.user.findUnique({
      where: { id },
      include: {
        personalProjects: true,
        teamMemberships: {
          include: {
            teamProject: true
          }
        },
        hackathons: {
          include: { rounds: true }
        },
        learnings: true,
        dailyActivities: true,
        certifications: true,
        psSkills: true,
        tasksReceived: {
          orderBy: { createdAt: 'desc' }
        },
        taskReports: {
          include: { task: true }
        }
      }
    });

    if (!userDetail) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({
      success: true,
      data: userDetail
    });

  } catch (error) {
    console.error('getAdminUserDetail error:', error);
    res.status(500).json({ success: false, message: 'Server error fetching user detail' });
  }
};

/**
 * Administrative: Update User (Role, Points)
 */
const updateUser = async (req, res) => {
  const { id } = req.params;
  const { role, rewardPoints } = req.body;

  try {
    const updatedUser = await prisma.user.update({
      where: { id },
      data: {
        ...(role && { role }),
        ...(rewardPoints !== undefined && { rewardPoints: Number(rewardPoints) })
      }
    });

    res.json({ success: true, data: updatedUser, message: 'User updated successfully' });
  } catch (error) {
    console.error('updateUser error:', error);
    res.status(500).json({ success: false, message: 'Failed to update user' });
  }
};

/**
 * Administrative: Update Team Project (Status, Captain, etc.)
 */
const updateProject = async (req, res) => {
  const { id } = req.params;
  const { status, projectName, problemStatement, assignedCaptainId } = req.body;

  try {
    const updatedProject = await prisma.teamProject.update({
      where: { id },
      data: {
        ...(status && { status }),
        ...(projectName && { projectName }),
        ...(problemStatement !== undefined && { problemStatement }),
        ...(assignedCaptainId !== undefined && { assignedCaptainId: assignedCaptainId || null })
      }
    });

    res.json({ success: true, data: updatedProject, message: 'Project updated successfully' });
  } catch (error) {
    console.error('updateProject error:', error);
    res.status(500).json({ success: false, message: 'Failed to update project' });
  }
};

/**
 * Administrative: Delete Team Project
 */
const deleteProject = async (req, res) => {
  const { id } = req.params;

  try {
    await prisma.teamProject.delete({
      where: { id }
    });

    res.json({ success: true, message: 'Project deleted successfully' });
  } catch (error) {
    console.error('deleteProject error:', error);
    res.status(500).json({ success: false, message: 'Failed to delete project' });
  }
};

module.exports = {
  getAdminOverview,
  getAdminUserDetail,
  updateUser,
  updateProject,
  deleteProject
};
