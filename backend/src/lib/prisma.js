const { PrismaClient } = require('@prisma/client');

const getRuntimeDatabaseUrl = () => {
  // Always prioritize PRISMA_RUNTIME_URL if present
  if (process.env.PRISMA_RUNTIME_URL) return process.env.PRISMA_RUNTIME_URL;
  
  // Prefer DATABASE_URL, fallback to DIRECT_URL
  const rawUrl = process.env.DATABASE_URL || process.env.DIRECT_URL;
  if (!rawUrl) return rawUrl;

  try {
    const parsed = new URL(rawUrl);
    
    // Log the masked URL to verify exactly what Prisma is trying to use on Render
    const maskedPassword = parsed.password ? '***MASKED***' : 'NONE';
    const maskedUrl = `${parsed.protocol}//${parsed.username}:${maskedPassword}@${parsed.host}${parsed.pathname}${parsed.search}`;
    console.log(`[PRISMA CONFIG] Connecting to: ${maskedUrl}`);
    
    // Auto-append sslmode=require for Supabase if missing
    if (parsed.hostname.includes('supabase.com') || parsed.hostname.includes('supabase.co')) {
      if (!parsed.searchParams.get('sslmode')) {
        parsed.searchParams.set('sslmode', 'require');
      }
    }
    
    return parsed.toString();
  } catch (err) {
    console.error(`[PRISMA CONFIG ERROR] Failed to parse URL: ${err.message}`);
    return rawUrl;
  }
};

/**
 * Prisma Client Singleton
 * Prevents multiple instances and connection exhaustion in serverless/dev environments
 */
const prisma = global.prisma || new PrismaClient({
  datasources: {
    db: {
      url: getRuntimeDatabaseUrl(),
    },
  },
  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
});

const getConnectionHints = () => {
  const hints = [];
  const dbUrl = process.env.DATABASE_URL;

  if (!dbUrl) {
    return ['DATABASE_URL is not set.'];
  }

  try {
    const parsed = new URL(dbUrl);
    const host = parsed.hostname || '';
    const port = parsed.port || '5432';
    const sslMode = parsed.searchParams.get('sslmode');

    if (host.includes('supabase.com')) {
      if (!sslMode) {
        hints.push('For Supabase, add `sslmode=require` to DATABASE_URL.');
      }

      if (host.includes('pooler.supabase.com') && port === '5432') {
        hints.push('If this keeps failing, try the transaction pooler port 6543 for DATABASE_URL.');
      }

      if (!process.env.DIRECT_URL) {
        hints.push('Set DIRECT_URL to the non-pooler direct Postgres URL for migrations.');
      }
    }
  } catch (parseErr) {
    hints.push(`DATABASE_URL appears malformed: ${parseErr.message}`);
  }

  return hints;
};

/**
 * Connecting with retry logic for production stability
 */
prisma.$connectWithRetry = async (
  retries = Number(process.env.DB_CONNECT_RETRIES || 8),
  delay = Number(process.env.DB_CONNECT_DELAY_MS || 3000)
) => {
  let waitMs = delay;

  for (let i = 0; i < retries; i++) {
    try {
      await prisma.$connect();
      console.log('📦 Database connection via Prisma established');
      return true;
    } catch (err) {
      console.error(`❌ Connection attempt ${i + 1}/${retries} FAILED: ${err.message}`);
      if (i < retries - 1) {
        console.log(`⏱️ Retrying in ${Math.round(waitMs / 1000)}s...`);
        await new Promise(res => setTimeout(res, waitMs));
        waitMs = Math.min(Math.round(waitMs * 1.5), 20000);
      } else {
        const hints = getConnectionHints();
        if (hints.length) {
          console.error('💡 Database connection troubleshooting hints:');
          hints.forEach(hint => console.error(`   - ${hint}`));
        }
        throw err;
      }
    }
  }
};

if (process.env.NODE_ENV !== 'production') {
  global.prisma = prisma;
}

module.exports = prisma;
