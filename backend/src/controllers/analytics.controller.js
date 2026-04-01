const prisma = require('../lib/prisma');

const targetService = require('../services/target.service');
const googleSheetsService = require('../services/googleSheets.service');

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
    const dayCounts = {};

    for (const activity of activities) {
      const hours = (new Date(activity.endTime) - new Date(activity.startTime)) / (1000 * 60 * 60);
      totalHours += hours;

      const dayKey = new Date(activity.date).toISOString().split('T')[0];
      activeDaysSet.add(dayKey);
      dayHours[dayKey] = (dayHours[dayKey] || 0) + hours;
      
      // Track counts for velocity
      dayCounts[dayKey] = (dayCounts[dayKey] || 0) + 1;

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
        dailyActivityCount: dayCounts,
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
      where: { role: { not: 'ADMIN' } },
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

/** GET /api/analytics/team-workload */
const getTeamWorkload = async (req, res) => {
  try {
    const now = new Date();
    const startDate = new Date(now);
    startDate.setDate(now.getDate() - 7);
    startDate.setHours(0, 0, 0, 0);

    const users = await prisma.user.findMany({
      where: { role: { not: 'ADMIN' } },
      select: { id: true, name: true, profileImageUrl: true },
    });

    const workload = [];

    for (const user of users) {
      const activities = await prisma.dailyActivity.findMany({
        where: {
          userId: user.id,
          date: { gte: startDate, lte: new Date() },
        },
      });

      const dailyHours = {};
      // Initialize last 7 days with 0
      for (let i = 0; i < 7; i++) {
        const d = new Date(now);
        d.setDate(now.getDate() - i);
        dailyHours[d.toISOString().split('T')[0]] = 0;
      }

      for (const activity of activities) {
        const hours = (new Date(activity.endTime) - new Date(activity.startTime)) / (1000 * 60 * 60);
        const dayKey = new Date(activity.date).toISOString().split('T')[0];
        if (dailyHours[dayKey] !== undefined) {
          dailyHours[dayKey] += hours;
        }
      }

      workload.push({
        user,
        dailyHours,
        totalWeekHours: Object.values(dailyHours).reduce((a, b) => a + b, 0),
      });
    }

    res.json({ success: true, data: workload });
  } catch (error) {
    console.error('GetTeamWorkload error:', error);
    res.status(500).json({ success: false, message: 'Failed to compute workload' });
  }
};

/** GET /api/analytics/reward-status */
const getRewardStatus = async (req, res) => {
  try {
    const spreadsheetId = process.env.GOOGLE_SHEET_ID;
    
    // 1. Fetch yearly averages from Database (maintained by background scheduler)
    let averages = await targetService.getTargets();

    try {
      if (spreadsheetId) {
        const sheetAverages = await googleSheetsService.getYearlyAverages(spreadsheetId);
        if (sheetAverages && Object.keys(sheetAverages).length > 0) {
          averages = { ...averages, ...sheetAverages };
        }
      }
    } catch (sheetError) {
      console.warn('Fallback to default targets: Google Sheets fetch failed.', sheetError.message);
    }
    
    // 2. Fetch all student users (Exclude ADMINs)
    const users = await prisma.user.findMany({
      where: { role: { not: 'ADMIN' } },
      select: {
        id: true,
        name: true,
        regNo: true,
        year: true,
        rewardPoints: true,
        profileImageUrl: true,
        role: true
      },
      orderBy: { name: 'asc' }
    });

    // 3. Process each user's status
    const teamStatus = users.map(user => {
      let yearKey = (user.year || 'OVERALL').toString().trim().toUpperCase();
      
      // Step 3.1: Normalize Numeric years to Roman (or vice versa) to match sheet labels
      const normalizationMap = {
        '1': 'I', 'I': 'I',
        '2': 'II', 'II': 'II',
        '3': 'III', 'III': 'III',
        '4': 'IV', 'IV': 'IV'
      };

      const normalizedYear = normalizationMap[yearKey] || yearKey;
      
      // Fallback to overall average if year-specific average is missing
      // Try normalized first, then original key, then OVERALL
      const target = averages[normalizedYear] !== undefined 
        ? averages[normalizedYear] 
        : (averages[yearKey] !== undefined ? averages[yearKey] : (averages['OVERALL'] || 0));
      
      const diff = user.rewardPoints - target;
      
      return {
        id: user.id,
        name: user.name,
        regNo: user.regNo,
        year: user.year,
        rewardPoints: user.rewardPoints,
        profileImageUrl: user.profileImageUrl,
        role: user.role,
        target,
        isEligible: diff >= 0,
        pointsNeeded: diff < 0 ? Math.abs(Math.round(diff * 100) / 100) : 0
      };
    });

    const belowAverage = teamStatus.filter(s => !s.isEligible);
    const eligibleCount = teamStatus.length - belowAverage.length;

    res.json({
      success: true,
      data: {
        yearlyTargets: averages,
        teamStatus,
        summary: {
          totalUsers: teamStatus.length,
          eligibleCount,
          belowAverageCount: belowAverage.length,
          overallAverage: averages['OVERALL'] || 0
        }
      }
    });

  } catch (error) {
    console.error('GetRewardStatus error:', error);
    res.status(500).json({ success: false, message: 'Failed to compute reward status' });
  }
};

module.exports = { getWeeklyAnalytics, getLeaderboard, getTeamWorkload, getRewardStatus };

