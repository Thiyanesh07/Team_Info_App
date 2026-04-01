const cron = require('node-cron');
const targetService = require('./target.service');
const prisma = require('../lib/prisma');


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
    
    // 1. Initial manual sync to ensure data is populated on startup
    await targetService.syncTargets();

    // 2. Schedule Reward Benchmarks Update (Every 12 hours)
    // Runs at 00:00 and 12:00
    const benchmarkJob = cron.schedule('0 0,12 * * *', async () => {
      console.log('⏰ Running scheduled reward benchmark update...');
      await targetService.syncTargets();
    });

    this.jobs.push(benchmarkJob);

    // 3. User Activity Cleanup / Auto-sync reward points across users
    // This could trigger a sync for all users who haven't updated in 24 hours
    const rewardRefreshJob = cron.schedule('0 1 * * *', async () => {
      console.log('⏰ Running daily reward refresh for all users...');
      // Logic for mass-sync can be added here
    });
    
    this.jobs.push(rewardRefreshJob);

    console.log('✅ Background scheduler initialized.');
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

