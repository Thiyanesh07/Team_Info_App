const cron = require('node-cron');
const targetService = require('./target.service');
const huggingFaceService = require('./huggingFace.service');
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

