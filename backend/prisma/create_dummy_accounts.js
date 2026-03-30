const { PrismaClient, UserRole } = require('@prisma/client');

const prisma = new PrismaClient();

const leaderUsers = [
  {
    email: 'leader.captain.test@bitsathy.ac.in',
    name: 'Leader Captain Test',
    role: UserRole.CAPTAIN,
    regNo: 'LDR001',
    department: 'CSE',
    year: '4',
  },
  {
    email: 'leader.vicecaptain.test@bitsathy.ac.in',
    name: 'Leader Vice Captain Test',
    role: UserRole.VICE_CAPTAIN,
    regNo: 'LDR002',
    department: 'IT',
    year: '4',
  },
  {
    email: 'leader.strategist.test@bitsathy.ac.in',
    name: 'Leader Strategist Test',
    role: UserRole.STRATEGIST,
    regNo: 'LDR003',
    department: 'ECE',
    year: '3',
  },
  {
    email: 'leader.manager.test@bitsathy.ac.in',
    name: 'Leader Manager Test',
    role: UserRole.MANAGER,
    regNo: 'LDR004',
    department: 'EEE',
    year: '3',
  },
];

const memberUsers = Array.from({ length: 7 }, (_, i) => {
  const idx = i + 1;
  return {
    email: `member${idx}.test@bitsathy.ac.in`,
    name: `Member ${idx} Test`,
    role: UserRole.MEMBER,
    regNo: `MBR00${idx}`,
    department: idx % 2 === 0 ? 'CSE' : 'IT',
    year: idx <= 3 ? '2' : '1',
  };
});

const dummyUsers = [...leaderUsers, ...memberUsers];

async function run() {
  console.log('Creating/updating dummy accounts...');

  for (const u of dummyUsers) {
    await prisma.user.upsert({
      where: { email: u.email },
      update: {
        name: u.name,
        role: u.role,
        regNo: u.regNo,
        department: u.department,
        year: u.year,
      },
      create: {
        email: u.email,
        name: u.name,
        role: u.role,
        regNo: u.regNo,
        department: u.department,
        year: u.year,
      },
    });
  }

  const leaders = await prisma.user.findMany({
    where: {
      role: { in: [UserRole.CAPTAIN, UserRole.VICE_CAPTAIN, UserRole.STRATEGIST, UserRole.MANAGER] },
      email: { in: leaderUsers.map((u) => u.email) },
    },
    orderBy: { email: 'asc' },
    select: { email: true, role: true, name: true },
  });

  const members = await prisma.user.findMany({
    where: {
      role: UserRole.MEMBER,
      email: { in: memberUsers.map((u) => u.email) },
    },
    orderBy: { email: 'asc' },
    select: { email: true, role: true, name: true },
  });

  console.log(`Leaders ready: ${leaders.length}`);
  console.table(leaders);
  console.log(`Members ready: ${members.length}`);
  console.table(members);
}

run()
  .catch((err) => {
    console.error('Failed to create dummy accounts:', err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
