const { sendPushToUsers } = require('../services/pushNotification.service');
const prisma = require('../lib/prisma');

async function runTest() {
  const userId = 'f15120e1-fab3-4fac-814f-3efe1b10deac';
  
  console.log(`🔍 Checking database for user: ${userId}`);
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, name: true, fcmToken: true }
  });

  if (!user) {
    console.error('❌ User not found in database!');
    process.exit(1);
  }

  if (!user.fcmToken) {
    console.error('❌ User has no FCM token in database!');
    process.exit(1);
  }

  console.log(`✅ Found user: ${user.name}`);
  console.log(`📡 Sending test push to token: ${user.fcmToken.substring(0, 10)}...`);

  const result = await sendPushToUsers({
    userIds: [user.id],
    title: 'Test Push Success 🚀',
    body: 'Congratulations! Your Android 15 notifications are officially working.',
    data: {
      type: 'TEST_PUSH',
      timestamp: new Date().toISOString()
    }
  });

  console.log('🏁 Result:', JSON.stringify(result, null, 2));
  process.exit(0);
}

runTest().catch(err => {
  console.error('💥 Script crashed:', err);
  process.exit(1);
});
