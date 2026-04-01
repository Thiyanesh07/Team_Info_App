const { PrismaClient } = require('@prisma/client');

/**
 * Prisma Client Singleton
 * Prevents multiple instances and connection exhaustion in serverless/dev environments
 */
const prisma = global.prisma || new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
});

if (process.env.NODE_ENV !== 'production') {
  global.prisma = prisma;
}

module.exports = prisma;
