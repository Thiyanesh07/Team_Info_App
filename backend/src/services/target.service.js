const googleSheetsService = require('./googleSheets.service');
const chartScraperService = require('./chartScraper.service');
const prisma = require('../lib/prisma');

/**
 * Service to manage academic reward targets (benchmarks)
 */
class TargetService {
  /**
   * Syncs targets from the source (API primary, Axios Scraper fallback)
   */
  async syncTargets() {
    try {
      console.log('🔄 Syncing reward benchmarks...');
      const spreadsheetId = process.env.GOOGLE_AVERAGES_SHEET_ID || process.env.GOOGLE_SHEET_ID;
      
      let benchmarks = null;

      // 1. Attempt API Sync (Fastest and Reliable)
      try {
        console.log('📡 Attempting API sync from 2points tab...');
        benchmarks = await googleSheetsService.getYearlyAverages(spreadsheetId);
        console.log('✅ API sync successful.');
      } catch (apiErr) {
        console.warn('⚠️ API sync failed (possibly permissions). Attempting Axios Scraper fallback...', apiErr.message);
      }

      // 2. Attempt Axios Scraper Fallback (Production Safe)
      if (!benchmarks) {
        try {
          console.log('🌐 Fetching data via Chart Scraper (Axios)...');
          benchmarks = await chartScraperService.fetchBenchmarks();
          console.log('✅ Chart Scraper sync successful.');
        } catch (scraperErr) {
          console.error('❌ Chart Scraper failed as well.', scraperErr.message);
          throw new Error('All benchmark sync methods failed.');
        }
      }

      // Update Database
      const years = Object.keys(benchmarks);
      for (const year of years) {
        const target = benchmarks[year];
        if (year && !isNaN(target)) {
          await prisma.yearlyTarget.upsert({
            where: { year },
            update: { 
              target,
              lastSyncStatus: 'SUCCESS',
              lastSyncError: null
            },
            create: { 
              year, 
              target,
              lastSyncStatus: 'SUCCESS'
            }
          });
        }
      }
      console.log('✅ Yearly targets successfully synchronized.');
    } catch (error) {
      console.error('⚠️ Benchmark Sync FAILED:', error.message);
      
      // Update DB with the failure status
      try {
        await prisma.yearlyTarget.updateMany({
          data: {
            lastSyncStatus: 'FAILED',
            lastSyncError: error.message
          }
        });
      } catch (dbErr) {
        console.error('Failed to log sync error to DB:', dbErr.message);
      }

      // Seeding defaults if DB is empty
      await this.seedDefaults();
    }
  }

  /**
   * Seeds the database with the latest benchmarks extracted from the college chart
   */
  async seedDefaults() {
    const count = await prisma.yearlyTarget.count();
    if (count > 0) return; // Only seed if empty

    const defaults = [
      { year: 'I', target: 1479.66 },
      { year: 'II', target: 1199.90 },
      { year: 'III', target: 788.80 },
      { year: 'IV', target: 0.00 },
      { year: 'OVERALL', target: 780.34 }
    ];

    console.log('🌱 Seeding default benchmarks from college chart data...');
    for (const item of defaults) {
      await prisma.yearlyTarget.upsert({
        where: { year: item.year },
        update: {}, 
        create: item
      });
    }
  }

  /**
   * Returns a map of year labels to targets
   */
  async getTargets() {
    const targets = await prisma.yearlyTarget.findMany();
    const map = {};
    targets.forEach(t => {
      map[t.year] = t.target;
    });
    
    // If DB is empty for some reason, return the hardcoded chart values as last resort
    if (targets.length === 0) {
      return {
        'I': 1479.66,
        'II': 1199.90,
        'III': 788.80,
        'IV': 0,
        'OVERALL': 780.34
      };
    }

    return map;
  }
}

module.exports = new TargetService();

