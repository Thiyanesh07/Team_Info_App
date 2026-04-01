const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

/**
 * Manual Login Helper for Robot Browser
 * This launches a VISIBLE browser window so you can sign in manually once.
 */
async function manualLogin() {
  const userDataDir = path.resolve(__dirname, '../../data/puppeteer_session');
  const targetUrl = process.env.GOOGLE_CHART_URL || 'https://accounts.google.com';

  console.log('---------------------------------------------------------');
  console.log('🛠️ ROBOT BROWSER - MANUAL LOGIN HELPER');
  console.log('---------------------------------------------------------');
  console.log(`📂 Saving session to: ${userDataDir}`);
  console.log('🚀 Launching visible browser... Please wait.');

  if (!fs.existsSync(userDataDir)) {
    fs.mkdirSync(userDataDir, { recursive: true });
  }

  const browser = await puppeteer.launch({
    headless: false, // VISIBLE browser for you to see
    userDataDir: userDataDir,
    defaultViewport: null,
    args: ['--no-sandbox', '--start-maximized']
  });

  const page = await browser.newPage();
  
  console.log('✅ Browser open! Opening login page...');
  await page.goto(targetUrl, { waitUntil: 'load' });

  console.log('---------------------------------------------------------');
  console.log('👉 INSTRUCTIONS:');
  console.log('1. Log in to your college Google account in the browser window.');
  console.log('2. Once you see the Chart or your Gmail, you are good to go!');
  console.log('3. CLOSE the browser window when you are finished.');
  console.log('---------------------------------------------------------');

  browser.on('disconnected', () => {
    console.log('🏁 Browser closed. Session saved successfully!');
    process.exit(0);
  });
}

manualLogin().catch(err => {
  console.error('❌ Login Helper Error:', err);
  process.exit(1);
});
