const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/** GET /api/analytics/weekly?userId=x&startDate=x&endDate=x */
const getWeeklyAnalytics = async (req, res) => {
  try {
    const userId = req.query.userId || req.user.id;
    const now = new Date();
    const startDate = req.query.startDate ? new Date(req.query.startDate) : new Date(now.setDate(now.getDate() - 7));
    const endDate = req.query.endDate ? new Date(req.query.endDate) : new Date();

    const activities = await prisma.dailyActivity.findMany({
      where: {
        userId,
        date: { gte: startDate, lte: endDate },
      },
      orderBy: { date: 'asc' },
    });

    // Compute analytics
    let totalHours = 0;
    let learningHours = 0;
    let projectHours = 0;
    let otherHours = 0;
    const activeDaysSet = new Set();
    const dayHours = {};

    for (const activity of activities) {
      const hours = (new Date(activity.endTime) - new Date(activity.startTime)) / (1000 * 60 * 60);
      totalHours += hours;

      const dayKey = new Date(activity.date).toISOString().split('T')[0];
      activeDaysSet.add(dayKey);
      dayHours[dayKey] = (dayHours[dayKey] || 0) + hours;

      switch (activity.type) {
        case 'LEARNING': learningHours += hours; break;
        case 'PROJECT': projectHours += hours; break;
        default: otherHours += hours; break;
      }
    }

    const activeDays = activeDaysSet.size;
    const consistencyScore = Math.round((activeDays / 7) * 100);

    // Find best day
    let bestDay = null;
    let bestDayHours = 0;
    for (const [day, hours] of Object.entries(dayHours)) {
      if (hours > bestDayHours) {
        bestDay = day;
        bestDayHours = hours;
      }
    }

    res.json({
      success: true,
      data: {
        totalHours: Math.round(totalHours * 100) / 100,
        learningHours: Math.round(learningHours * 100) / 100,
        projectHours: Math.round(projectHours * 100) / 100,
        otherHours: Math.round(otherHours * 100) / 100,
        activeDays,
        consistencyScore,
        bestDay,
        bestDayHours: Math.round(bestDayHours * 100) / 100,
        dailyBreakdown: dayHours,
        totalActivities: activities.length,
      },
    });
  } catch (error) {
    console.error('GetWeeklyAnalytics error:', error);
    res.status(500).json({ success: false, message: 'Failed to compute analytics' });
  }
};

/** GET /api/analytics/leaderboard?startDate=x&endDate=x */
const getLeaderboard = async (req, res) => {
  try {
    const now = new Date();
    const startDate = req.query.startDate ? new Date(req.query.startDate) : new Date(now.setDate(now.getDate() - 7));
    const endDate = req.query.endDate ? new Date(req.query.endDate) : new Date();

    const users = await prisma.user.findMany({
      select: { id: true, name: true, profileImageUrl: true },
    });

    const leaderboard = [];

    for (const user of users) {
      const activities = await prisma.dailyActivity.findMany({
        where: {
          userId: user.id,
          date: { gte: startDate, lte: endDate },
        },
      });

      let totalHours = 0;
      const activeDaysSet = new Set();

      for (const activity of activities) {
        const hours = (new Date(activity.endTime) - new Date(activity.startTime)) / (1000 * 60 * 60);
        totalHours += hours;
        activeDaysSet.add(new Date(activity.date).toISOString().split('T')[0]);
      }

      leaderboard.push({
        user,
        totalHours: Math.round(totalHours * 100) / 100,
        activeDays: activeDaysSet.size,
        consistencyScore: Math.round((activeDaysSet.size / 7) * 100),
        totalActivities: activities.length,
      });
    }

    leaderboard.sort((a, b) => b.totalHours - a.totalHours);

    res.json({ success: true, data: leaderboard });
  } catch (error) {
    console.error('GetLeaderboard error:', error);
    res.status(500).json({ success: false, message: 'Failed to compute leaderboard' });
  }
};

module.exports = { getWeeklyAnalytics, getLeaderboard };
