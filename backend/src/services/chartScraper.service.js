const axios = require('axios');

/**
 * Service to scrape data from a published Google Sheets Chart
 * This is used as a fallback when direct spreadsheet access is unavailable.
 */
class ChartScraperService {
  /**
   * Fetches the chart HTML and extracts reward benchmarks from the underlying JSON
   */
  async fetchBenchmarks() {
    const url = process.env.GOOGLE_CHART_URL;
    if (!url) {
      throw new Error('GOOGLE_CHART_URL is not configured in .env');
    }

    try {
      console.log(`🌐 Scraping published chart from: ${url}`);
      
      const response = await axios.get(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          'Referer': 'https://docs.google.com/',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache'
        }
      });

      const html = response.data;
      
      /**
       * The data is stored in a JavaScript variable within the HTML.
       * We look for 'chartJson': followed by a hex-encoded string.
       */
      const jsonMatch = html.match(/'chartJson':\s*'(.*?)'/);
      
      if (!jsonMatch || !jsonMatch[1]) {
        throw new Error('Could not locate chartJson in the published chart HTML. The chart might be private or the format changed.');
      }

      // Decode the hex-encoded JSON string (e.g., \x7b -> {)
      const decodedJson = jsonMatch[1].replace(/\\x([0-9A-Fa-f]{2})/g, (match, hex) => {
        return String.fromCharCode(parseInt(hex, 16));
      });

      const data = JSON.parse(decodedJson);
      const rows = data.dataTable?.rows || [];
      const benchmarks = {};

      /**
       * Column 0: Year Label (e.g., 'I', 'II', 'OVERALL')
       * Column 1: Average Reward Points (Number)
       */
      rows.forEach(row => {
        const label = row.c[0]?.v;
        const value = row.c[1]?.v;
        if (label && (typeof value === 'number' || !isNaN(parseFloat(value)))) {
          benchmarks[label] = typeof value === 'number' ? value : parseFloat(value);
        }
      });

      if (Object.keys(benchmarks).length === 0) {
        throw new Error('Scraper found the chart data but no valid benchmark rows were extracted.');
      }

      return benchmarks;
    } catch (error) {
      console.error('❌ Chart Scraping Helper Failed:', error.message);
      throw error;
    }
  }
}

module.exports = new ChartScraperService();
