const { google } = require('googleapis');

/**
 * Service to interact with Google Sheets API
 */
class GoogleSheetsService {
  constructor() {
    this.auth = null;
    this.sheets = null;
    
    // Configure auth using environment variables
    const email = process.env.GOOGLE_SERVICE_ACCOUNT_EMAIL;
    const privateKey = process.env.GOOGLE_PRIVATE_KEY?.replace(/\\n/g, '\n');
    
    if (email && privateKey) {
      console.log(`[GoogleSheetsService] Initializing with: ${email}, Key Length: ${privateKey.length}`);
      try {
        this.auth = new google.auth.JWT(
          email,
          null,
          privateKey,
          ['https://www.googleapis.com/auth/spreadsheets.readonly']
        );
        this.sheets = google.sheets({ version: 'v4', auth: this.auth });
      } catch (authError) {
        console.error('[GoogleSheetsService] Error creating JWT Client:', authError.message);
      }
    } else {
      console.warn('[GoogleSheetsService] MISSING CREDENTIALS. email:', !!email, 'key:', !!privateKey);
    }
  }

  /**
   * Fetches data from a specific sheet range
   * @param {string} spreadsheetId 
   * @param {string} range (e.g., "IT!A7:J")
   */
  async getSheetData(spreadsheetId, range) {
    if (!this.sheets) {
      throw new Error('Google Sheets service not initialized. Check your credentials.');
    }

    try {
      const response = await this.sheets.spreadsheets.values.get({
        spreadsheetId,
        range,
        auth: this.auth, // Explicitly pass auth to ensure identity
      });
      return response.data.values || [];
    } catch (error) {
      console.error(`Error fetching sheet data for range ${range}:`, error);
      throw error;
    }
  }

  /**
   * Fetches data from multiple department tabs and aggregates it
   * @param {string} spreadsheetId 
   * @param {string[]} departmentTabs 
   */
  async fetchAllDepartments(spreadsheetId, departmentTabs) {
    const allPoints = new Map(); // Roll No -> Balance Points

    for (const tab of departmentTabs) {
      try {
        console.log(`Syncing data for department: ${tab}...`);
        const rows = await this.getSheetData(spreadsheetId, `${tab}!A7:J`);
        
        for (const row of rows) {
          const rollNo = row[2]?.toString().trim(); // Column C
          const balancePoints = parseInt(row[9]?.toString().replace(/,/g, '').trim()) || 0; // Column J

          if (rollNo && !isNaN(balancePoints)) {
            allPoints.set(rollNo, balancePoints);
          }
        }
      } catch (error) {
        console.warn(`Failed to fetch data for tab: ${tab}. Skipping...`);
      }
    }

    return allPoints;
  }

  /**
   * Fetches the pre-calculated yearly averages from the '2points' tab
   * @param {string} spreadsheetId 
   */
  async getYearlyAverages(spreadsheetId) {
    try {
      // Range: I, II, III, IV, II L, OVERALL.
      // Assuming Column A is the Year label and Column B is the Average.
      const rows = await this.getSheetData(spreadsheetId, '2points!A1:B7');
      const averages = {};

      for (const row of rows) {
        const year = row[0]?.toString().trim();
        const value = parseFloat(row[1]?.toString().replace(/,/g, '').trim()) || 0;
        
        if (year) {
          averages[year] = value;
        }
      }
      return averages;
    } catch (error) {
      console.error('Error fetching yearly averages:', error);
      throw error;
    }
  }
}

module.exports = new GoogleSheetsService();
