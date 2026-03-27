const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function seed() {
  console.log('🌱 Seeding database...');
  console.log('ℹ️  No seed data required.');
  console.log('   Admin account is auto-created on first Google Sign-In');
  console.log(`   using the SUPER_ADMIN_EMAIL from .env`);
  console.log('   All other accounts must be created by the admin.');
  console.log('🎉 Seeding complete!');
}

seed()
  .catch((e) => {
    console.error('Seed error:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
