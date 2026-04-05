const cron = require('node-cron');
const targetService = require('./target.service');
const huggingFaceService = require('./huggingFace.service');
const prisma = require('../lib/prisma');
const { sendPushToUsers } = require('./pushNotification.service');

/**
 * Background Scheduler for Periodic Syncing
 */
class SchedulerService {
  constructor() {
    this.jobs = [];
  }

  /**
   * Initializes the scheduled jobs
   */
  async init() {
    console.log('⏳ Initializing background scheduler...');
    
    // 1. Initial manual sync to ensure targets are populated on startup
    await targetService.syncTargets();

    // 2. Schedule Reward Benchmarks Update (Every 12 hours)
    const benchmarkJob = cron.schedule('0 0,12 * * *', async () => {
      console.log('⏰ Running scheduled reward benchmark update...');
      await targetService.syncTargets();
    });

    this.jobs.push(benchmarkJob);

    // 3. Daily Reward Points Refresh (Every day at 1 AM IST)
    const rewardRefreshJob = cron.schedule('0 1 * * *', async () => {
      console.log('⏰ Running daily reward points mass-sync via Hugging Face...');
      try {
        await huggingFaceService.syncAllUsers();
        console.log('✅ Daily mass-sync completed successfully.');
      } catch (error) {
        console.error('❌ Daily mass-sync FAILED:', error.message);
      }
    });
    
    this.jobs.push(rewardRefreshJob);

    // 4. Deadline Reminders (Every 30 minutes)
    const deadlineJob = cron.schedule('*/30 * * * *', async () => {
      console.log('⏰ Running deadline reminder check...');
      try {
        await this.checkDeadlines();
      } catch (error) {
        console.error('❌ Deadline check FAILED:', error.message);
      }
    });

    this.jobs.push(deadlineJob);

    console.log('✅ Background scheduler initialized.');
  }

  /**
   * Check for upcoming and missed deadlines
   */
  async checkDeadlines() {
    const now = new Date();

    // --- 1. TASK ASSIGNMENTS ---
    const pendingTasks = await prisma.taskAssignment.findMany({
      where: { status: { not: 'COMPLETED' }, deadline: { not: null } },
    });

    for (const task of pendingTasks) {
      const deadline = new Date(task.deadline);
      const diffHrs = (deadline - now) / (1000 * 60 * 60);

      // Proactive Reminders (24h, 2h, 0h)
      if (task.reminderStage === 0 && diffHrs <= 24 && diffHrs > 2) {
        await this._sendDeadlinePush(task.assignedToId, 'Task Due Tomorrow ⏰', `"${task.title}" is due in 24 hours.`, task.id, 'TASK_ASSIGNED', 'reminderStage', 1);
      } else if (task.reminderStage < 2 && diffHrs <= 2 && diffHrs > 0) {
        await this._sendDeadlinePush(task.assignedToId, 'Task Due Soon ⏰', `"${task.title}" is due in 2 hours.`, task.id, 'TASK_ASSIGNED', 'reminderStage', 2);
      } else if (task.reminderStage < 3 && diffHrs <= 0 && diffHrs > -1) {
        await this._sendDeadlinePush(task.assignedToId, 'Task Due Now 🚀', `"${task.title}" is due now. Please submit!`, task.id, 'TASK_ASSIGNED', 'reminderStage', 3);
      }

      // Late Reminders (1h late, 3h late, 6h late)
      const lateHrs = (now - deadline) / (1000 * 60 * 60);
      if (task.lateReminderStage === 0 && lateHrs >= 1 && lateHrs < 3) {
        await this._sendDeadlinePush(task.assignedToId, 'Task Overdue (1h)', `"${task.title}" was due 1 hour ago. Please complete it!`, task.id, 'TASK_ASSIGNED', 'lateReminderStage', 1);
      } else if (task.lateReminderStage < 2 && lateHrs >= 3 && lateHrs < 6) {
        await this._sendDeadlinePush(task.assignedToId, 'Task Overdue (3h)', `"${task.title}" was due 3 hours ago. Critical update needed.`, task.id, 'TASK_ASSIGNED', 'lateReminderStage', 2);
      } else if (task.lateReminderStage < 3 && lateHrs >= 6) {
        await this._sendDeadlinePush(task.assignedToId, 'Task Overdue (6h)', `"${task.title}" is 6 hours late. Final warning.`, task.id, 'TASK_ASSIGNED', 'lateReminderStage', 3);
      }
    }

    // --- 2. REPORT REQUESTS ---
    const pendingReports = await prisma.reportRequest.findMany({
      where: { deadline: { not: null } },
      include: { submissions: true }
    });

    for (const report of pendingReports) {
      const deadline = new Date(report.deadline);
      const diffHrs = (deadline - now) / (1000 * 60 * 60);
      const lateHrs = (now - deadline) / (1000 * 60 * 60);

      // Find who hasn't submitted
      const submittedUserIds = new Set(report.submissions.map(s => s.userId));
      let targetUserIds = [];
      if (report.targetAudience === 'TEAM') {
        const users = await prisma.user.findMany({ where: { id: { not: report.assignedById } }, select: { id: true } });
        targetUserIds = users.map(u => u.id);
      } else if (report.targetAudience === 'ROLE') {
        const users = await prisma.user.findMany({ where: { role: { in: report.targetRoles }, id: { not: report.assignedById } }, select: { id: true } });
        targetUserIds = users.map(u => u.id);
      } else if (report.targetAudience === 'INDIVIDUAL') {
        targetUserIds = report.targetUserIds;
      }
      
      const offenders = targetUserIds.filter(id => !submittedUserIds.has(id));
      if (offenders.length === 0) continue;

      // Proactive
      if (report.reminderStage === 0 && diffHrs <= 24 && diffHrs > 2) {
        await this._sendReportPush(offenders, 'Report Due Tomorrow ⏰', `"${report.title}" is due in 24 hours.`, report.id, 'reminderStage', 1);
      } else if (report.reminderStage < 2 && diffHrs <= 2 && diffHrs > 0) {
        await this._sendReportPush(offenders, 'Report Due Soon ⏰', `"${report.title}" is due in 2 hours.`, report.id, 'reminderStage', 2);
      } else if (report.reminderStage < 3 && diffHrs <= 0 && diffHrs > -1) {
        await this._sendReportPush(offenders, 'Report Due Now 🚀', `"${report.title}" is due now. Please submit!`, report.id, 'reminderStage', 3);
      }

      // Late
      if (report.lateReminderStage === 0 && lateHrs >= 1 && lateHrs < 3) {
        await this._sendReportPush(offenders, 'Report Overdue (1h)', `"${report.title}" was due 1 hour ago. Submit now!`, report.id, 'lateReminderStage', 1);
      } else if (report.lateReminderStage < 2 && lateHrs >= 3 && lateHrs < 6) {
        await this._sendReportPush(offenders, 'Report Overdue (3h)', `"${report.title}" was due 3 hours ago.`, report.id, 'lateReminderStage', 2);
      } else if (report.lateReminderStage < 3 && lateHrs >= 6) {
        await this._sendReportPush(offenders, 'Report Overdue (6h)', `"${report.title}" is 6 hours late. Final notice.`, report.id, 'lateReminderStage', 3);
      }
    }
  }

  async _sendDeadlinePush(userId, title, body, taskId, type, stageField, stageValue) {
    await sendPushToUsers({
      userIds: [userId],
      title,
      body,
      data: { type, taskId }
    });
    await prisma.taskAssignment.update({
      where: { id: taskId },
      data: { [stageField]: stageValue }
    });
  }

  async _sendReportPush(userIds, title, body, requestId, stageField, stageValue) {
    await sendPushToUsers({
      userIds,
      title,
      body,
      data: { type: 'REPORT_REQUEST_CREATED', requestId }
    });
    await prisma.reportRequest.update({
      where: { id: requestId },
      data: { [stageField]: stageValue }
    });
  }

  /**
   * Stops all scheduled jobs
   */
  stopAll() {
    this.jobs.forEach(job => job.stop());
    console.log('🛑 All scheduled jobs stopped.');
  }
}

module.exports = new SchedulerService();

