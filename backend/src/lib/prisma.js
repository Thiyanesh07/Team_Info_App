const { PrismaClient } = require('@prisma/client');

/**
 * Prisma Client Singleton
 * Prevents multiple instances and connection exhaustion in serverless/dev environments
 */
const prisma = global.prisma || new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
});

/**
 * Connecting with retry logic for production stability
 */
prisma.$connectWithRetry = async (retries = 5, delay = 5000) => {
  for (let i = 0; i < retries; i++) {
    try {
      await prisma.$connect();
      console.log('📦 Database connection via Prisma established');
      return true;
    } catch (err) {
      console.error(`❌ Connection attempt ${i + 1} FAILED: ${err.message}`);
      if (i < retries - 1) {
        console.log(`⏱️ Retrying in ${delay / 1000}s...`);
        await new Promise(res => setTimeout(res, delay));
      } else {
        throw err;
      }
    }
  }
};

if (process.env.NODE_ENV !== 'production') {
  global.prisma = prisma;
}

module.exports = prisma;
