const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

/**
 * Service to scrape data by "Borrowing" your existing Chrome Session.
 * This bypasses CAPTCHAs and 401s because it acts as YOUR logged-in browser.
 */
class PuppetScraperService {
  constructor() {
    // Path to your actual Chrome User Data (with Linux/Render fallback)
    const isWindows = process.platform === 'win32';
    const baseAppData = process.env.LOCALAPPDATA || process.env.HOME || '/tmp';
    this.chromeUserData = path.join(baseAppData, 'Google/Chrome/User Data');
    this.chromeExecutable = process.env.CHROME_BIN || (isWindows ? 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe' : undefined);
  }

  /**
   * Visits the chart using your logged-in profile.
   */
  async fetchBenchmarks() {
    const url = process.env.GOOGLE_CHART_URL;
    
    console.log('🤖 Launching Robot using your LOCAL Chrome Profile...');
    
    /**
     * IMPORTANT: Puppeteer cannot use a profile that is currently open in Chrome.
     * We use a temporary clone or ask you to close Chrome.
     */
    const launchOptions = {
      headless: "new",
      userDataDir: this.chromeUserData, // PIGGYBACK on your real session
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-extensions',
        '--remote-debugging-port=9222',
      ]
    };
    
    if (this.chromeExecutable) {
      launchOptions.executablePath = this.chromeExecutable;
    }

    const browser = await puppeteer.launch(launchOptions);

    const page = await browser.newPage();
    await page.setViewport({ width: 1920, height: 1080 });

    try {
      console.log(`🌐 Robot (as You) navigating to: ${url}`);
      await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });

      const html = await page.content();
      const jsonMatch = html.match(/'chartJson':\s*'(.*?)'/);

      if (!jsonMatch || !jsonMatch[1]) {
        // Check if we hit a login wall despite the profile
        if (html.includes('accounts.google.com')) {
           throw new Error('Robot Profile Link Failed: Your session may have expired or Google is blocking headless profile access.');
        }
        throw new Error(`Benchmark Extraction Failed at: ${page.url()}`);
      }

      // Decode hex-encoded JSON
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

      console.log(`✅ Success! Data extracted via your profile: ${Object.keys(benchmarks).length} rows found.`);
      return benchmarks;
    } catch (error) {
      console.error('❌ Robot Profile Sync Failed:', error.message);
      
      const errorScreenshot = path.resolve(__dirname, '../../data/profile_error.png');
      await page.screenshot({ path: errorScreenshot });
      
      throw error;
    } finally {
      await browser.close();
    }
  }
}

module.exports = new PuppetScraperService();
