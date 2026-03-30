const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function run() {
  await prisma.$connect();

  const [users, activities, tasks, projects] = await Promise.all([
    prisma.user.count(),
    prisma.dailyActivity.count(),
    prisma.taskAssignment.count(),
    prisma.teamProject.count(),
  ]);

  const ping = await prisma.$queryRaw`SELECT NOW() as now`;

  console.log('DB connected: yes');
  console.log('Users:', users);
  console.log('DailyActivities:', activities);
  console.log('Tasks:', tasks);
  console.log('TeamProjects:', projects);
  console.log('DB time:', ping[0].now);
}

run()
  .catch((e) => {
    console.error('DB check failed:', e.message);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
