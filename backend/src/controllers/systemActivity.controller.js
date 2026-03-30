const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/**
 * GET /api/activities/unified
 * Returns a combined feed of DailyActivity, ProjectUpdate, TaskReport, and SystemActivity
 */
const getUnifiedActivity = async (req, res) => {
  try {
    const { limit = 20, offset = 0 } = req.query;
    
    // Fetch all types of activities
    // Note: In a large-scale app, we would use a more optimized approach (Cursor-based pagination or a single denormalized table)
    const [daily, updates, reports, system] = await Promise.all([
      prisma.dailyActivity.findMany({
        take: parseInt(limit),
        include: { user: { select: { id: true, name: true, profileImageUrl: true } } },
        orderBy: { createdAt: 'desc' }
      }),
      prisma.projectUpdate.findMany({
        take: parseInt(limit),
        include: { 
          user: { select: { id: true, name: true, profileImageUrl: true } },
          project: { select: { id: true, projectName: true } }
        },
        orderBy: { createdAt: 'desc' }
      }),
      prisma.taskReport.findMany({
        take: parseInt(limit),
        include: { 
          user: { select: { id: true, name: true, profileImageUrl: true } },
          task: { select: { id: true, title: true } }
        },
        orderBy: { createdAt: 'desc' }
      }),
      prisma.systemActivity.findMany({
        take: parseInt(limit),
        include: { user: { select: { id: true, name: true, profileImageUrl: true } } },
        orderBy: { createdAt: 'desc' }
      })
    ]);

    // Map to Unified ActivityItem structure
    const unified = [
      ...daily.map(a => ({
        id: a.id,
        userId: a.userId,
        title: `Logged ${a.type}`,
        content: a.description || `Spent time on ${a.type.toLowerCase()}`,
        timestamp: a.createdAt,
        type: 'DAILY_LOG',
        user: a.user
      })),
      ...updates.map(u => ({
        id: u.id,
        userId: u.userId,
        title: `Updated ${u.project.projectName}`,
        content: u.updateText,
        timestamp: u.createdAt,
        type: 'PROJECT_UPDATE',
        user: u.user,
        metadata: JSON.stringify({ projectId: u.projectId })
      })),
      ...reports.map(r => ({
        id: r.id,
        userId: r.userId,
        title: `Reported on ${r.task.title}`,
        content: r.reportText,
        timestamp: r.createdAt,
        type: 'TASK_REPORT',
        user: r.user,
        metadata: JSON.stringify({ taskId: r.taskId })
      })),
      ...system.map(s => ({
        id: s.id,
        userId: s.userId,
        title: s.title,
        content: s.content,
        timestamp: s.createdAt,
        type: 'SYSTEM_EVENT',
        user: s.user,
        metadata: s.metadata ? JSON.stringify(s.metadata) : null
      }))
    ];

    // Sort by timestamp desc and apply limit
    unified.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    const result = unified.slice(parseInt(offset), parseInt(offset) + parseInt(limit));

    res.json({ success: true, data: result });
  } catch (error) {
    console.error('getUnifiedActivity error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch combined activity feed' });
  }
};

/**
 * Utility to log a system activity (internal use)
 */
const logSystemActivity = async (userId, title, content, type, metadata = null) => {
  try {
    await prisma.systemActivity.create({
      data: { userId, title, content, type, metadata }
    });
  } catch (err) {
    console.error('logSystemActivity error:', err);
  }
};

module.exports = { getUnifiedActivity, logSystemActivity };
