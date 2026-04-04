const prisma = require('../lib/prisma');
const { sendPushToUsers } = require('../services/pushNotification.service');

async function runTest() {
  const adminId = '799998d1-995f-4a47-8283-cb42972ee161';
  const userId = 'f15120e1-fab3-4fac-814f-3efe1b10deac';
  const varshiniId = '93210868-bad0-4b44-b3c8-1ddf54d2adf8';

  console.log('🚀 Starting Final Push Test...');

  // 1. Create task for YOU (The one with the token)
  const task1 = await prisma.taskAssignment.create({
    data: {
      title: 'TMA_A74 System Test (You) 🚀',
      description: 'Verifying Android 15 Push Notifications. If you see this as a banner, it works!',
      assignedById: adminId,
      assignedToId: userId,
      priority: 'HIGH',
      deadline: new Date(Date.now() + 86400000)
    }
  });
  console.log('✅ Created task for You');

  // Trigger push for You
  await sendPushToUsers({
    userIds: [userId],
    title: 'New Task Assigned 📡',
    body: 'TMA_A74 System Test (You) 🚀',
    data: { type: 'TASK_ASSIGNED', taskId: task1.id }
  });
  console.log('📡 Push command sent to your device');

  // 2. Create task for VARSHINI (The one without the token)
  const task2 = await prisma.taskAssignment.create({
    data: {
      title: 'Varshini Task Assignment 📡',
      description: 'Assigned for Varshini. (Note: Push will not arrive until she updates app)',
      assignedById: adminId,
      assignedToId: varshiniId,
      priority: 'MEDIUM',
      deadline: new Date(Date.now() + 86400000)
    }
  });
  console.log('✅ Created task for Varshini');

  // Trigger push for Varshini (Will fail silently or log "no-tokens")
  const vResult = await sendPushToUsers({
    userIds: [varshiniId],
    title: 'New Task Assigned 📡',
    body: 'Varshini Task Assignment 📡',
    data: { type: 'TASK_ASSIGNED', taskId: task2.id }
  });
  console.log('📡 Push attempt for Varshini result:', JSON.stringify(vResult));

  console.log('\n🏁 FINISHED. Check your phone now!');
  process.exit(0);
}

runTest().catch(err => {
  console.error('💥 Script crashed:', err);
  process.exit(1);
});
