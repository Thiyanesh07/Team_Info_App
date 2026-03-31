const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function cleanup() {
  try {
    const deleted = await prisma.teamProject.deleteMany({
      where: {
        OR: [
          { projectName: { contains: 'Demo', mode: 'insensitive' } },
          { projectName: { contains: 'Demonstration', mode: 'insensitive' } },
          { problemStatement: { contains: 'Demo', mode: 'insensitive' } }
        ]
      }
    });
    console.log(`Successfully deleted ${deleted.count} demonstration projects.`);
  } catch (error) {
    console.error('Cleanup failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

cleanup();
