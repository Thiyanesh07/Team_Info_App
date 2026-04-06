const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function fixDuplicates() {
  try {
    console.log('🔍 Locating duplicate Enrollment Numbers...');
    const users = await prisma.user.findMany({
      select: { id: true, name: true, enrollmentNo: true }
    });

    const duplicates = {};
    users.forEach(u => {
      if (!u.enrollmentNo) return;
      if (!duplicates[u.enrollmentNo]) {
        duplicates[u.enrollmentNo] = [];
      }
      duplicates[u.enrollmentNo].push(u.id);
    });

    for (const [enroll, ids] of Object.entries(duplicates)) {
      if (ids.length > 1) {
        console.log(`⚠️ Found ${ids.length} duplicates for ${enroll}. Keeping the first one...`);
        // Keep the first one, null out the rest (or delete if needed, but nulling is safer for data preservation)
        for (let i = 1; i < ids.length; i++) {
          await prisma.user.update({
            where: { id: ids[i] },
            data: { enrollmentNo: null }
          });
          console.log(`   - Nullified [${ids[i]}]`);
        }
      }
    }

    // Also check for empty strings which can sometimes be treated as duplicates in some DBs
    const emptyStringUsers = await prisma.user.findMany({
      where: { enrollmentNo: '' }
    });
    if (emptyStringUsers.length > 0) {
      console.log(`🧹 Clearing ${emptyStringUsers.length} empty string enrollment numbers...`);
      await prisma.user.updateMany({
        where: { enrollmentNo: '' },
        data: { enrollmentNo: null }
      });
    }

    console.log('✅ Duplicate check complete.');
  } catch (err) {
    console.error('❌ Fix error:', err.message);
  } finally {
    await prisma.$disconnect();
  }
}

fixDuplicates();
