const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../backend/.env') });
const googleSheetsService = require('../backend/src/services/googleSheets.service');

async function fetchPoints(rollNo) {
  const spreadsheetId = process.env.GOOGLE_SHEET_ID;
  if (!spreadsheetId) {
    console.error('Error: GOOGLE_SHEET_ID not found in .env');
    return;
  }

  // Assuming major departments from common BITS Sathy patterns or the project.
  // The roll No has 'AD', which usually stands for AIDS/ADS (Artificial Intelligence and Data Science)
  const departments = ['ADS', 'AD', 'IT', 'CSE', 'ECE', 'EEE', 'MECH', 'CIVIL', 'BME', 'FT'];
  
  console.log(`Searching for reward points for Roll No: ${rollNo}...`);

  for (const dept of departments) {
    try {
      const range = `${dept}!A7:J`;
      const rows = await googleSheetsService.getSheetData(spreadsheetId, range);
      
      for (const row of rows) {
        const rowRollNo = row[2]?.toString().trim(); // Column C
        if (rowRollNo === rollNo) {
          const balancePoints = row[9]?.toString().replace(/,/g, '').trim(); // Column J
          console.log(`\n✅ FOUND in tab: ${dept}`);
          console.log(`Roll No: ${rowRollNo}`);
          console.log(`Name: ${row[1] || 'N/A'}`); // Assuming B is name
          console.log(`Reward Points: ${balancePoints}`);
          return;
        }
      }
    } catch (error) {
      // Tab might not exist or error fetching, move to next
    }
  }

  console.log('\n❌ Roll No not found in any of the checked department tabs.');
}

const rollNo = process.argv[2] || '7376242AD328';
fetchPoints(rollNo).catch(err => console.error(err));
