const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkUsers() {
  try {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        email: true,
        name: true,
        regNo: true,
        enrollmentNo: true,
        role: true
      }
    });

    console.log(`Total users: ${users.length}`);
    users.forEach(u => {
      console.log(`- ${u.name} (${u.email}): regNo=${u.regNo || 'NULL'}, enrollmentNo=${u.enrollmentNo || 'NULL'}, role=${u.role}`);
    });
  } catch (error) {
    console.error(error);
  } finally {
    await prisma.$disconnect();
  }
}

checkUsers();
