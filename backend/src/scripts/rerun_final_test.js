const prisma = require('../lib/prisma');
const { sendPushToUsers } = require('../services/pushNotification.service');

async function runTest() {
  const adminId = '799998d1-995f-4a47-8283-cb42972ee161';
  const thiyaneshId = '9da4dfbb-9c42-430b-9839-5011b3cb7fc9'; // Thiyanesh D
  const varshiniId = '93210868-bad0-4b44-b3c8-1ddf54d2adf8'; // Varshini S

  console.log('🚀 Final Rerun Push Test...');

  // 1. Create task for Thiyanesh (You)
  const task1 = await prisma.taskAssignment.create({
    data: {
      title: 'Assign Task for Varshini (Final Test) 📡',
      description: 'System-wide test of Android 15 push notifications. Handled via production bridge.',
      assignedById: adminId,
      assignedToId: thiyaneshId,
      priority: 'HIGH',
      deadline: new Date(Date.now() + 172800000)
    }
  });

  console.log('✅ Created task for Thiyanesh');

  // Trigger push for Thiyanesh
  const tResult = await sendPushToUsers({
    userIds: [thiyaneshId],
    title: 'New Task Assigned 📡',
    body: 'Assign Task for Varshini (Final Test) 📡',
    data: { type: 'TASK_ASSIGNED', taskId: task1.id }
  });
  console.log('📡 Push for Thiyanesh result:', JSON.stringify(tResult));

  // 2. Create task for Varshini
  const task2 = await prisma.taskAssignment.create({
    data: {
      title: 'Pending App Update (Varshini) 🔔',
      description: 'Varshini, please install the latest APK to receive push notifications.',
      assignedById: adminId,
      assignedToId: varshiniId,
      priority: 'MEDIUM',
      deadline: new Date(Date.now() + 172800000)
    }
  });

  console.log('✅ Created task for Varshini');
  console.log('\n🏁 FINISHED. Watch your notification bar!');
  process.exit(0);
}

runTest().catch(err => {
  console.error('💥 Script crashed:', err);
  process.exit(1);
});
