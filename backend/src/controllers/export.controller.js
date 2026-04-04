const prisma = require('../lib/prisma');
const excelService = require('../services/excel.service');


/**
 * Handle RBAC for exports and determine the target userId list
 */
const getTargetUserIds = async (req) => {
  const { userId, scope } = req.query; // scope: 'SELF', 'USER', 'TEAM'
  const role = req.user.role?.toUpperCase();
  const leaderRoles = ['ADMIN', 'CAPTAIN', 'VICE_CAPTAIN', 'STRATEGIST', 'MANAGER'];
  const isLeaderOrAdmin = leaderRoles.includes(role);

  // CRITICAL: Non-leaders ALWAYS get only their own ID, regardless of requested scope or userId
  if (!isLeaderOrAdmin) {
    return [req.user.id]; 
  }

  // Leaders can choose scope
  if (scope === 'TEAM' || (!userId && scope !== 'SELF')) {
    const allUsers = await prisma.user.findMany({ select: { id: true } });
    return allUsers.map(u => u.id);
  }

  if (scope === 'USER' && userId) {
    return [userId];
  }

  return [req.user.id]; // Default to self
};

const getTimelineRange = (req) => {
  const timelineRaw = req.query?.timeline;
  const timeline = typeof timelineRaw === 'string'
    ? timelineRaw.trim().toUpperCase()
    : '';
  const startDate = req.query?.startDate;
  const endDate = req.query?.endDate;

  // Backward compatibility: old clients sending only startDate/endDate.
  if (!timeline && startDate && endDate) {
    const start = new Date(startDate);
    const end = new Date(`${endDate}T23:59:59.999Z`);
    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
      const err = new Error('Invalid startDate or endDate');
      err.statusCode = 400;
      throw err;
    }
    return { gte: start, lte: end };
  }

  if (!timeline || timeline === 'ALL') {
    return null;
  }

  if (timeline === 'TODAY') {
    const now = new Date();
    const start = new Date(now);
    start.setHours(0, 0, 0, 0);
    const end = new Date(now);
    end.setHours(23, 59, 59, 999);
    return { gte: start, lte: end };
  }

  if (timeline === 'RANGE') {
    if (!startDate || !endDate) {
      const err = new Error('startDate and endDate are required for RANGE timeline');
      err.statusCode = 400;
      throw err;
    }
    const start = new Date(startDate);
    const end = new Date(`${endDate}T23:59:59.999Z`);
    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
      const err = new Error('Invalid startDate or endDate');
      err.statusCode = 400;
      throw err;
    }
    return { gte: start, lte: end };
  }

  const err = new Error('Invalid timeline. Use TODAY, RANGE, or ALL');
  err.statusCode = 400;
  throw err;
};

const exportMethods = {
  /** Export Daily Activities */
  async exportActivities(req, res) {
    try {
      const userIds = await getTargetUserIds(req);
      const dateRange = getTimelineRange(req);
      const data = await prisma.dailyActivity.findMany({
        where: {
          userId: { in: userIds },
          ...(dateRange ? { date: dateRange } : {}),
        },
        include: { user: { select: { name: true, regNo: true, department: true } } },
        orderBy: { date: 'desc' }
      });

      const columns = [
        { header: 'Date', key: 'date', width: 15 },
        { header: 'Name', key: 'userName', width: 25 },
        { header: 'Reg No', key: 'regNo', width: 15 },
        { header: 'Dept', key: 'dept', width: 10 },
        { header: 'Type', key: 'type', width: 15 },
        { header: 'Description', key: 'description', width: 40 },
        { header: 'Duration', key: 'duration', width: 15 }
      ];

      const formattedData = data.map(d => ({
        date: d.date.toISOString().split('T')[0],
        userName: d.user.name,
        regNo: d.user.regNo,
        dept: d.user.department,
        type: d.customType || d.type,
        description: d.description,
        duration: `${Math.round((d.endTime - d.startTime) / (1000 * 60 * 60) * 10) / 10} hrs`
      }));

      const buffer = await excelService.generateSimpleExcel('Daily Activities', columns, formattedData);
      
      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader('Content-Disposition', 'attachment; filename=DailyActivities.xlsx');
      res.send(buffer);
    } catch (error) {
      console.error('ExportActivities error:', error);
      res.status(error.statusCode || 500).json({ success: false, message: error.message || 'Failed to export activities' });
    }
  },

  /** Export Team Projects */
  async exportProjects(req, res) {
    try {
      const userIds = await getTargetUserIds(req);
      const dateRange = getTimelineRange(req);
      // For projects, we might want to export projects where these users are members
      const data = await prisma.teamProject.findMany({
        where: {
          members: { some: { userId: { in: userIds } } },
          ...(dateRange ? { createdAt: dateRange } : {}),
        },
        include: { 
          members: { include: { user: { select: { name: true } } } },
          assignedCaptain: { select: { name: true } }
        },
        orderBy: { createdAt: 'desc' }
      });

      const columns = [
        { header: 'Project Name', key: 'projectName', width: 30 },
        { header: 'Status', key: 'status', width: 15 },
        { header: 'Captain', key: 'captain', width: 20 },
        { header: 'Domain', key: 'domain', width: 15 },
        { header: 'Members', key: 'memberList', width: 40 },
        { header: 'Problem Statement', key: 'problem', width: 50 }
      ];

      const formattedData = data.map(p => ({
        projectName: p.projectName,
        status: p.status,
        captain: p.assignedCaptain?.name || 'Unassigned',
        domain: p.domain,
        memberList: p.members.map(m => m.user.name).join(', '),
        problem: p.problemStatement
      }));

      const buffer = await excelService.generateSimpleExcel('Team Projects', columns, formattedData);
      res.setHeader('Content-Disposition', 'attachment; filename=TeamProjects.xlsx');
      res.send(buffer);
    } catch (error) {
       console.error('ExportProjects error:', error);
       res.status(error.statusCode || 500).json({ success: false, message: error.message || 'Failed to export projects' });
    }
  },

  /** Export Hackathons */
  async exportHackathons(req, res) {
    try {
      const userIds = await getTargetUserIds(req);
      const dateRange = getTimelineRange(req);
      const data = await prisma.hackathon.findMany({
        where: {
          userId: { in: userIds },
          ...(dateRange ? { date: dateRange } : {}),
        },
        include: { user: { select: { name: true, regNo: true } } },
        orderBy: { date: 'desc' }
      });

      const columns = [
        { header: 'Date', key: 'date', width: 15 },
        { header: 'User', key: 'userName', width: 20 },
        { header: 'Hackathon', key: 'hackName', width: 25 },
        { header: 'Project', key: 'projectName', width: 25 },
        { header: 'Status', key: 'status', width: 15 },
        { header: 'Is Team?', key: 'isTeam', width: 10 },
        { header: 'Team Members', key: 'members', width: 30 }
      ];

      const formattedData = data.map(h => ({
        date: h.date ? h.date.toISOString().split('T')[0] : 'N/A',
        userName: h.user.name,
        hackName: h.hackName,
        projectName: h.projectName,
        status: h.status,
        isTeam: h.isTeam ? 'Yes' : 'No',
        members: h.teamMembers.join(', ')
      }));

      const buffer = await excelService.generateSimpleExcel('Hackathons', columns, formattedData);
      res.setHeader('Content-Disposition', 'attachment; filename=Hackathons.xlsx');
      res.send(buffer);
    } catch (error) {
       console.error('ExportHackathons error:', error);
       res.status(error.statusCode || 500).json({ success: false, message: error.message || 'Failed to export hackathons' });
    }
  },

  /** Export P Skills (College Assessments) */
  async exportPSkills(req, res) {
    try {
      const userIds = await getTargetUserIds(req);
      const data = await prisma.psSkill.findMany({
        where: {
          userId: { in: userIds },
          // Filter for completed skills in this section
          completed: true
        },
        include: { user: { select: { name: true, regNo: true, department: true } } },
        orderBy: [
          { userId: 'asc' },
          { type: 'asc' },
          { createdAt: 'desc' }
        ]
      });

      const columns = [
        { header: 'User Name', key: 'userName', width: 25 },
        { header: 'Reg No', key: 'regNo', width: 15 },
        { header: 'Dept', key: 'dept', width: 10 },
        { header: 'Skill Name', key: 'skillName', width: 30 },
        { header: 'Type', key: 'type', width: 15 },
        { header: 'Level', key: 'level', width: 15 },
        { header: 'Completed Date', key: 'completedDate', width: 20 }
      ];

      const formattedData = data.map(s => ({
        userName: s.user.name,
        regNo: s.user.regNo,
        dept: s.user.department,
        skillName: s.skillName,
        type: s.type,
        level: s.level || 'N/A',
        completedDate: s.completedDate ? s.completedDate.toISOString().split('T')[0] : 'N/A'
      }));

      const buffer = await excelService.generateSimpleExcel('P-Skills Assessments', columns, formattedData);
      
      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader('Content-Disposition', 'attachment; filename=PSkillsReport.xlsx');
      res.send(buffer);
    } catch (error) {
      console.error('ExportPSkills error:', error);
      res.status(error.statusCode || 500).json({ success: false, message: error.message || 'Failed to export P-Skills' });
    }
  },

  /** Export Learning */
  async exportLearning(req, res) {
    try {
      const userIds = await getTargetUserIds(req);
      const dateRange = getTimelineRange(req);
      const data = await prisma.learning.findMany({
        where: {
          userId: { in: userIds },
          ...(dateRange ? { createdAt: dateRange } : {}),
        },
        include: { user: { select: { name: true, regNo: true } } },
        orderBy: { createdAt: 'desc' }
      });

      const columns = [
        { header: 'User', key: 'userName', width: 20 },
        { header: 'Skill', key: 'skill', width: 25 },
        { header: 'Topics', key: 'topics', width: 40 },
        { header: 'Level', key: 'level', width: 15 },
        { header: 'Status', key: 'status', width: 15 }
      ];

      const formattedData = data.map(l => ({
        userName: l.user.name,
        skill: l.skillName,
        topics: l.topics.join(', '),
        level: l.level,
        status: l.status
      }));

      const buffer = await excelService.generateSimpleExcel('Learning Logs', columns, formattedData);
      res.setHeader('Content-Disposition', 'attachment; filename=LearningReport.xlsx');
      res.send(buffer);
    } catch (error) {
       console.error('ExportLearning error:', error);
       res.status(error.statusCode || 500).json({ success: false, message: error.message || 'Failed to export learning' });
    }
  },

  /** Export Certifications */
  async exportCertifications(req, res) {
    try {
      const userIds = await getTargetUserIds(req);
      const dateRange = getTimelineRange(req);
      const certificationWhere = {
        userId: { in: userIds },
      };

      if (dateRange) {
        certificationWhere.OR = [
          { issuedDate: dateRange },
          { issuedDate: null, createdAt: dateRange },
        ];
      }

      const data = await prisma.certification.findMany({
        where: certificationWhere,
        include: { user: { select: { name: true, regNo: true } } },
        orderBy: { createdAt: 'desc' }
      });

      const columns = [
        { header: 'User', key: 'userName', width: 20 },
        { header: 'Reg No', key: 'regNo', width: 15 },
        { header: 'Skill', key: 'skill', width: 25 },
        { header: 'Provider', key: 'provider', width: 20 },
        { header: 'Issued Date', key: 'date', width: 15 }
      ];

      const formattedData = data.map(c => ({
        userName: c.user.name,
        regNo: c.user.regNo,
        skill: c.skill,
        provider: c.provider,
        date: c.issuedDate ? c.issuedDate.toISOString().split('T')[0] : 'N/A'
      }));

      const buffer = await excelService.generateSimpleExcel('Certifications', columns, formattedData);
      res.setHeader('Content-Disposition', 'attachment; filename=Certifications.xlsx');
      res.send(buffer);
    } catch (error) {
       console.error('ExportCertifications error:', error);
       res.status(error.statusCode || 500).json({ success: false, message: error.message || 'Failed to export certifications' });
    }
  }
};

module.exports = exportMethods;

