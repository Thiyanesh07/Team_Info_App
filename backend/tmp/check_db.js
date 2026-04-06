const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkDb() {
  try {
    console.log('--- USER DATA ---');
    const users = await prisma.user.findMany({
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        regNo: true,
        enrollmentNo: true,
        rewardPoints: true,
        activityPoints: true,
      }
    });
    console.table(users);

    console.log('\n--- SYSTEM CONFIG ---');
    const config = await prisma.systemConfig.findFirst();
    console.log(config || 'No config found');

    console.log('\n--- RECENT SYNC ACTIVITIES ---');
    const activities = await prisma.systemActivity.findMany({
      where: { type: 'SYNC' },
      take: 5,
      orderBy: { createdAt: 'desc' },
      select: {
        title: true,
        content: true,
        createdAt: true
      }
    });
    console.table(activities);

    console.log('\n--- YEARLY TARGETS (REWARDS) ---');
    const targets = await prisma.yearlyTarget.findMany();
    console.table(targets);

  } catch (err) {
    console.error('CheckDB Error:', err.message);
  } finally {
    await prisma.$disconnect();
  }
}

checkDb();
