const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const TEST_EMAIL_SUFFIX = '.test@bitsathy.ac.in';

function daysAgo(n) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d;
}

function withHour(baseDate, hour, minute = 0) {
  const d = new Date(baseDate);
  d.setHours(hour, minute, 0, 0);
  return d;
}

async function clearExistingSampleData(userIds) {
  // Task data
  await prisma.taskReport.deleteMany({ where: { userId: { in: userIds } } });
  await prisma.taskAssignment.deleteMany({
    where: {
      OR: [
        { assignedById: { in: userIds } },
        { assignedToId: { in: userIds } },
      ],
    },
  });

  // Project data
  const teamProjects = await prisma.teamProject.findMany({
    where: {
      OR: [
        { createdById: { in: userIds } },
        { assignedCaptainId: { in: userIds } },
        { members: { some: { userId: { in: userIds } } } },
      ],
    },
    select: { id: true },
  });
  const teamProjectIds = teamProjects.map((p) => p.id);

  if (teamProjectIds.length > 0) {
    await prisma.projectUpdate.deleteMany({ where: { projectId: { in: teamProjectIds } } });
    await prisma.teamProjectMember.deleteMany({ where: { teamProjectId: { in: teamProjectIds } } });
    await prisma.teamProject.deleteMany({ where: { id: { in: teamProjectIds } } });
  }

  await prisma.personalProject.deleteMany({ where: { userId: { in: userIds } } });

  // Activity / learning / skills / certs
  await prisma.dailyActivity.deleteMany({ where: { userId: { in: userIds } } });
  await prisma.learning.deleteMany({ where: { userId: { in: userIds } } });
  await prisma.psSkill.deleteMany({ where: { userId: { in: userIds } } });
  await prisma.certification.deleteMany({ where: { userId: { in: userIds } } });

  // Hackathons
  const hacks = await prisma.hackathon.findMany({
    where: { userId: { in: userIds } },
    select: { id: true },
  });
  const hackIds = hacks.map((h) => h.id);
  if (hackIds.length > 0) {
    await prisma.hackathonRound.deleteMany({ where: { hackathonId: { in: hackIds } } });
    await prisma.hackathon.deleteMany({ where: { id: { in: hackIds } } });
  }

  // Chat/team messages
  await prisma.teamMessage.deleteMany({ where: { senderId: { in: userIds } } });
  const convs = await prisma.chatConversation.findMany({
    where: { participants: { some: { userId: { in: userIds } } } },
    select: { id: true },
  });
  const convIds = convs.map((c) => c.id);
  if (convIds.length > 0) {
    await prisma.chatMessage.deleteMany({ where: { conversationId: { in: convIds } } });
    await prisma.chatParticipant.deleteMany({ where: { conversationId: { in: convIds } } });
    await prisma.chatConversation.deleteMany({ where: { id: { in: convIds } } });
  }
}

async function createSampleData(users) {
  const leaders = users.filter((u) => ['CAPTAIN', 'VICE_CAPTAIN', 'STRATEGIST', 'MANAGER'].includes(u.role));
  const members = users.filter((u) => u.role === 'MEMBER');

  if (leaders.length < 4 || members.length < 7) {
    throw new Error('Expected at least 4 leaders and 7 members test accounts.');
  }

  // Activities (5 days each user)
  for (const user of users) {
    for (let i = 0; i < 5; i += 1) {
      const d = daysAgo(i);
      const type = i % 3 === 0 ? 'LEARNING' : i % 3 === 1 ? 'PROJECT' : 'OTHERS';
      await prisma.dailyActivity.create({
        data: {
          userId: user.id,
          type,
          description: `${type} activity day-${i + 1} by ${user.name}`,
          startTime: withHour(d, 9 + (i % 2), 0),
          endTime: withHour(d, 11 + (i % 2), 30),
          date: withHour(d, 0, 0),
          customType: type === 'OTHERS' ? 'MEETING' : null,
        },
      });
    }
  }

  // Learnings + skills + certifications
  for (const user of users) {
    await prisma.learning.create({
      data: {
        userId: user.id,
        skillName: user.role === 'MEMBER' ? 'Flutter Fundamentals' : 'System Design',
        topics: user.role === 'MEMBER' ? ['widgets', 'state', 'api'] : ['architecture', 'scaling'],
        level: user.role === 'MEMBER' ? 'BEGINNER' : 'INTERMEDIATE',
        status: 'ONGOING',
        startDate: daysAgo(10),
      },
    });

    await prisma.psSkill.createMany({
      data: [
        {
          userId: user.id,
          type: 'TECHNICAL',
          skillName: user.role === 'MEMBER' ? 'Dart' : 'Leadership',
          completed: true,
        },
        {
          userId: user.id,
          type: 'NON_TECHNICAL',
          skillName: user.role === 'MEMBER' ? 'Communication' : 'Planning',
          completed: false,
        },
      ],
    });

    if (user.role !== 'MEMBER') {
      await prisma.certification.create({
        data: {
          userId: user.id,
          skill: 'Project Management',
          provider: 'Internal Academy',
          description: 'Dummy certification for dashboard testing',
          issuedDate: daysAgo(30),
        },
      });
    }
  }

  // Personal projects for members
  for (const member of members) {
    await prisma.personalProject.create({
      data: {
        userId: member.id,
        name: `${member.name} Portfolio App`,
        description: 'Dummy personal project for CRUD testing',
        contribution: 'Frontend + API integration',
        githubLink: 'https://github.com/example/dummy-portfolio',
        liveLink: 'https://example.com/dummy-portfolio',
        skillsUsed: ['Flutter', 'Riverpod', 'REST API'],
      },
    });
  }

  // Team projects + members + updates
  const tp1 = await prisma.teamProject.create({
    data: {
      projectName: 'Team Productivity Dashboard',
      createdById: leaders[0].id,
      assignedCaptainId: leaders[1].id,
      domain: 'Productivity',
      subDomain: 'Analytics',
      problemStatement: 'Track team effort and output effectively',
      solution: 'Unified dashboard with real-time metrics',
      startDate: daysAgo(20),
      status: 'IN_PROGRESS',
    },
  });

  const tp2 = await prisma.teamProject.create({
    data: {
      projectName: 'Campus Event Management App',
      createdById: leaders[2].id,
      assignedCaptainId: leaders[3].id,
      domain: 'Management',
      subDomain: 'Events',
      problemStatement: 'Manage registrations and updates in one place',
      solution: 'Role-based app for event workflows',
      startDate: daysAgo(14),
      status: 'NOT_STARTED',
    },
  });

  const allMembersForProjects = [...leaders.slice(0, 2), ...members.slice(0, 5)];
  const otherMembers = [...leaders.slice(2), ...members.slice(5)];

  await prisma.teamProjectMember.createMany({
    data: allMembersForProjects.map((u) => ({ teamProjectId: tp1.id, userId: u.id })),
  });
  await prisma.teamProjectMember.createMany({
    data: otherMembers.map((u) => ({ teamProjectId: tp2.id, userId: u.id })),
  });

  await prisma.projectUpdate.createMany({
    data: [
      {
        projectId: tp1.id,
        userId: leaders[0].id,
        updateText: 'Completed dashboard skeleton and API contracts.',
      },
      {
        projectId: tp1.id,
        userId: members[0].id,
        updateText: 'Implemented chart components and responsive layout.',
      },
      {
        projectId: tp2.id,
        userId: leaders[2].id,
        updateText: 'Drafted module plan and task breakdown.',
      },
    ],
  });

  // Hackathons
  for (const user of [leaders[0], members[0], members[1]]) {
    const hack = await prisma.hackathon.create({
      data: {
        userId: user.id,
        hackName: 'InnovateX Dummy Hackathon',
        projectName: 'Smart Team Assistant',
        description: 'Dummy hackathon data for testing timelines',
        contribution: user.role === 'MEMBER' ? 'Feature implementation' : 'Mentoring + architecture',
        skillsUsed: ['Flutter', 'Node.js', 'PostgreSQL'],
        date: daysAgo(25),
        isTeam: true,
        teamMembers: ['Dummy Member A', 'Dummy Member B'],
        status: 'COMPLETED',
      },
    });

    await prisma.hackathonRound.createMany({
      data: [
        { hackathonId: hack.id, roundName: 'Idea Submission', description: 'Qualified' },
        { hackathonId: hack.id, roundName: 'Prototype Demo', description: 'Top 10 finalist' },
      ],
    });
  }

  // Tasks + reports
  const taskPairs = [
    [leaders[0], members[0]],
    [leaders[0], members[1]],
    [leaders[1], members[2]],
    [leaders[1], members[3]],
    [leaders[2], members[4]],
    [leaders[2], members[5]],
    [leaders[3], members[6]],
  ];

  const createdTasks = [];
  for (let i = 0; i < taskPairs.length; i += 1) {
    const [leader, member] = taskPairs[i];
    const task = await prisma.taskAssignment.create({
      data: {
        title: `Dummy Task ${i + 1}`,
        description: `Sample task assigned by ${leader.name} to ${member.name}`,
        assignedById: leader.id,
        assignedToId: member.id,
        priority: i % 3 === 0 ? 'HIGH' : i % 3 === 1 ? 'MEDIUM' : 'LOW',
        status: i % 3 === 0 ? 'IN_PROGRESS' : i % 3 === 1 ? 'PENDING' : 'COMPLETED',
        deadline: daysAgo(-3 + i),
      },
    });
    createdTasks.push({ task, member });
  }

  for (const [idx, item] of createdTasks.entries()) {
    if (idx % 2 === 0) {
      await prisma.taskReport.create({
        data: {
          taskId: item.task.id,
          userId: item.member.id,
          reportText: `Progress report for ${item.task.title}: completed core module and pending QA.`,
        },
      });
    }
  }

  // Team messages + direct chat
  await prisma.teamMessage.createMany({
    data: [
      { senderId: leaders[0].id, message: 'Daily standup at 9:30 AM.', isPinned: true },
      { senderId: members[0].id, message: 'Completed assigned module, raising PR today.' },
      { senderId: leaders[1].id, message: 'Please update your task reports before EOD.' },
    ],
  });

  const conv = await prisma.chatConversation.create({ data: {} });
  await prisma.chatParticipant.createMany({
    data: [
      { conversationId: conv.id, userId: leaders[0].id },
      { conversationId: conv.id, userId: members[0].id },
    ],
  });
  await prisma.chatMessage.createMany({
    data: [
      {
        conversationId: conv.id,
        senderId: leaders[0].id,
        message: 'Can you send the updated API payload format?',
      },
      {
        conversationId: conv.id,
        senderId: members[0].id,
        message: 'Sure, I will share it in 10 minutes.',
      },
    ],
  });
}

async function run() {
  console.log('Preparing sample data for dummy users...');

  const users = await prisma.user.findMany({
    where: { email: { contains: TEST_EMAIL_SUFFIX } },
    select: { id: true, email: true, name: true, role: true },
    orderBy: { email: 'asc' },
  });

  if (users.length < 11) {
    throw new Error(
      `Expected at least 11 dummy users with '${TEST_EMAIL_SUFFIX}', found ${users.length}. Run create_dummy_accounts.js first.`
    );
  }

  const userIds = users.map((u) => u.id);
  await clearExistingSampleData(userIds);
  await createSampleData(users);

  const summary = {
    users: users.length,
    activities: await prisma.dailyActivity.count({ where: { userId: { in: userIds } } }),
    personalProjects: await prisma.personalProject.count({ where: { userId: { in: userIds } } }),
    teamProjects: await prisma.teamProject.count({
      where: {
        OR: [
          { createdById: { in: userIds } },
          { assignedCaptainId: { in: userIds } },
          { members: { some: { userId: { in: userIds } } } },
        ],
      },
    }),
    tasks: await prisma.taskAssignment.count({
      where: {
        OR: [
          { assignedById: { in: userIds } },
          { assignedToId: { in: userIds } },
        ],
      },
    }),
    taskReports: await prisma.taskReport.count({ where: { userId: { in: userIds } } }),
    learnings: await prisma.learning.count({ where: { userId: { in: userIds } } }),
    psSkills: await prisma.psSkill.count({ where: { userId: { in: userIds } } }),
    hackathons: await prisma.hackathon.count({ where: { userId: { in: userIds } } }),
    certifications: await prisma.certification.count({ where: { userId: { in: userIds } } }),
  };

  console.log('Sample data generated successfully.');
  console.table(summary);
}

run()
  .catch((err) => {
    console.error('Failed to generate sample data:', err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
