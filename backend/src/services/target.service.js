const prisma = require('../lib/prisma');

const puppetScraperService = require('./puppetScraper.service');

/**
 * Service to manage academic reward targets (benchmarks)
 */
class TargetService {
  /**
   * Syncs targets from the published Google Chart (Robot Browser Scraper V4)
   */
  async syncTargets() {
    try {
      console.log('🔄 Syncing reward benchmarks via Robot Browser...');
      const benchmarks = await puppetScraperService.fetchBenchmarks();
      
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
      console.log('✅ Yearly targets successfully synced from published chart.');
    } catch (error) {
      console.error('⚠️ Could not sync targets from chart scraper:', error.message);
      
      // Update DB with the failure status for all targets
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

      // Ensure we have at least the latest known benchmarks in the DB
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

