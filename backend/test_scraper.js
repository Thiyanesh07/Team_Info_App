const axios = require('axios');

async function testScraper() {
    const url = 'https://docs.google.com/spreadsheets/d/e/2CAIWO3em3HQZrRGzVdUU7mHdTcBe0gKU1yB-wzrIfkQpSL58Bi8N9fEQJUR3vs4fAaHNRQ9cpp7EkWB-UsQ/gviz/chartiframe?oid=1492100559';
    
    try {
        console.log(`🌐 Testing scraper on: ${url}`);
        const response = await axios.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
            }
        });

        const html = response.data;
        const jsonMatch = html.match(/'chartJson':\s*'(.*?)'/);
        
        if (!jsonMatch || !jsonMatch[1]) {
            console.error('❌ Could not locate chartJson');
            return;
        }

        const decodedJson = jsonMatch[1].replace(/\\x([0-9A-Fa-f]{2})/g, (match, hex) => {
            return String.fromCharCode(parseInt(hex, 16));
        });

        const data = JSON.parse(decodedJson);
        const rows = data.dataTable?.rows || [];
        const benchmarks = {};

        rows.forEach(row => {
            const label = row.c[0]?.v;
            const value = row.c[1]?.v;
            if (label && !isNaN(parseFloat(value))) {
                benchmarks[label] = parseFloat(value);
            }
        });

        console.log('✅ Scraped Benchmarks:', benchmarks);
    } catch (error) {
        console.error('❌ Scraper Test Failed:', error.message);
    }
}

testScraper();
