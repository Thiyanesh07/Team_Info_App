const psToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6IlRISVlBTkVTSCBEIiwiZW1haWwiOiJ0aGl5YW5lc2hkLmFkMjRAYml0c2F0aHkuYWMuaW4iLCJ1c2VyX2lkIjoiMjAyNFVBRDExMzkiLCJ1c2VyX29mZl9pZCI6IjczNzYyNDJBRDMyOCIsInJvbGVfaWQiOjEzNywiZGVwdCI6IjMiLCJ5ZWFyIjoiSUkiLCJ5ZWFyX2dyb3VwIjoiSUkiLCJleHAiOjE3NzU0OTE5NDh9.xQAgQhjQXUb3mP3IYCe5a1ycOOEvhw5BWKmTdQiCeBU';

const testUsers = [
  { name: 'THIYANESH D', enroll: '2024UAD1139' },
  { name: 'VARSHINI S', enroll: '2024UIT1094' }
];

async function testFetch(user) {
  const url = `https://ps.bitsathy.ac.in/api/ps_v2/activity/rewards/breakdown?id=1&user_id=${user.enroll}`;
  
  console.log(`\n🔍 Fetching for ${user.name} (${user.enroll})...`);
  
  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json, text/plain, */*',
        'Cookie': `PS=${psToken}`,
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }
    });

    if (!response.ok) {
      throw new Error(`HTTP Error: ${response.status}`);
    }

    const json = await response.json();
    
    if (!json.success || !json.data) {
      console.error(`❌ Failed: ${json.message || 'Unknown error'}`);
      return;
    }

    const breakdown = json.data;
    const total = breakdown.reduce((sum, cat) => sum + (cat.total_earned || 0), 0);
    
    console.log(`✅ Success for ${user.name}`);
    console.log(`📊 Breakdown:`);
    breakdown.forEach(cat => {
      if (cat.total_earned > 0) {
        console.log(`   - ${cat.category_name}: ${cat.total_earned} pts`);
      }
    });
    console.log(`🏆 TOTAL CALCULATED: ${total} pts`);

  } catch (error) {
    console.error(`❌ Error for ${user.name}:`, error.message);
  }
}

async function runTest() {
  console.log('🚀 Starting Portal Sync Test...');
  for (const user of testUsers) {
    await testFetch(user);
  }
  console.log('\n🏁 Test Finished.');
}

runTest();
