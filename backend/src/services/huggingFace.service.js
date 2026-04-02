const { Client } = require("@gradio/client");
const prisma = require('../lib/prisma');

/**
 * Service to interact with the Hugging Face Space (Gradio)
 * Replacement for the legacy Google Sheets service.
 */
class HuggingFaceService {
  constructor() {
    this.spaceUrl = "PraneshJs/RewardPointsSite";
    this.client = null;
  }

  /**
   * Initializes the Gradio client (Dynamic import for ESM compatibility)
   */
  async getClient() {
    if (this.client) return this.client;
    
    try {
      const { Client } = await import("@gradio/client");
      this.client = await Client.connect(this.spaceUrl);
      console.log(`📡 Connected to Hugging Face Space: ${this.spaceUrl}`);
      return this.client;
    } catch (error) {
      console.error(`❌ Hugging Face Connection Failed:`, error.message);
      throw new Error("Unable to connect to the Reward Points API.");
    }
  }

  /**
   * Synchronizes points for a single user by their Roll Number
   */
  async syncUserByRollNo(regNo) {
    if (!regNo) return null;

    try {
      const client = await this.getClient();
      console.log(`🔍 Fetching points for ${regNo} from Hugging Face...`);
      
      const result = await client.predict("/search_student", { 		
        roll_no: regNo, 
      });

      if (!result || !result.data || !result.data[0]) {
        console.warn(`⚠️ No data returned for ${regNo}`);
        return null;
      }

      const report = result.data[0];
      
      // Improved Regex to handle commas and the specific "BALANCE POINTS" label
      // Example: "BALANCE POINTS         : 2,574.00"
      const balanceMatch = report.match(/BALANCE POINTS\s*:\s*([\d,.]+)/);
      const cumulativeMatch = report.match(/CUMULATIVE REWARD POINTS\s*:\s*([\d,.]+)/);
      const averageMatch = report.match(/Average Points for (Year [IV]+)\s*:\s*(\d+)/);
      const yearMatch = report.match(/YEAR\s*:\s*([IV]+)/);
      
      let points = null;
      if (balanceMatch && balanceMatch[1]) {
        // Remove commas before parsing (e.g., "2,574.00" -> 2574.0)
        points = parseFloat(balanceMatch[1].replace(/,/g, ''));
      }

      // 1. Update the User's Year if found in the report
      if (yearMatch && yearMatch[1]) {
        const year = yearMatch[1].trim();
        // regNo is not unique in Prisma schema, so use updateMany safely.
        await prisma.user.updateMany({
          where: { regNo },
          data: { year }
        });
      }

      // 2. Automatically update Yearly Targets (Benchmarks) if found
      if (averageMatch && averageMatch[1] && averageMatch[2]) {
        const yearLabel = averageMatch[1].replace('Year ', '').trim(); // e.g. "II"
        const targetValue = parseFloat(averageMatch[2]);
        
        await prisma.yearlyTarget.upsert({
          where: { year: yearLabel },
          update: { target: targetValue, lastSyncStatus: 'SUCCESS' },
          create: { year: yearLabel, target: targetValue, lastSyncStatus: 'SUCCESS' }
        });
      }
      
      if (points !== null) {
        console.log(`✅ ${regNo} | Pts: ${points} | Year: ${yearMatch ? yearMatch[1] : '?'}`);
        return points;
      }

      console.warn(`⚠️ Could not parse points from report for ${regNo}`);
      return null;
    } catch (error) {
      console.error(`❌ Sync error for ${regNo}:`, error.message);
      return null;
    }
  }

  /**
   * Synchronizes all registered users in the database
   */
  async syncAllUsers() {
    try {
      const users = await prisma.user.findMany({
        where: { regNo: { not: null } },
        select: { id: true, regNo: true, rewardPoints: true }
      });

      console.log(`🔄 Starting batch sync for ${users.length} users from Hugging Face...`);
      
      let updatedCount = 0;
      let failedCount = 0;

      // Sequential update to avoid rate limits or connection pool exhaustion
      for (const user of users) {
        const newPoints = await this.syncUserByRollNo(user.regNo);
        
        if (newPoints !== null && newPoints !== user.rewardPoints) {
          await prisma.user.update({
            where: { id: user.id },
            data: { rewardPoints: newPoints }
          });
          updatedCount++;
        } else if (newPoints === null) {
          failedCount++;
        }
      }

      return { updatedCount, failedCount, total: users.length };
    } catch (error) {
      console.error(`❌ Batch sync failed:`, error.message);
      throw error;
    }
  }
}

module.exports = new HuggingFaceService();
