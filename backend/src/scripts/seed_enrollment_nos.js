const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const mappings = [
  { name: 'THIYANESH D', enroll: '2024UAD1139', reg: '7376242AD328' },
  { name: 'VARSHINI S', enroll: '2024UIT1094', reg: '7376242IT333' }
];

async function seed() {
  console.log('🌱 Mirroring Enrollment Numbers to Database...');
  
  for (const m of mappings) {
    try {
      const result = await prisma.user.updateMany({
        where: {
          OR: [
            { regNo: m.reg },
            { name: { contains: m.name, mode: 'insensitive' } }
          ]
        },
        data: {
          enrollmentNo: m.enroll,
          regNo: m.reg // Ensure regNo is also synchronized
        }
      });
      
      console.log(`✅ Updated ${m.name}: ${result.count} records affected.`);
    } catch (error) {
      console.error(`❌ Failed to update ${m.name}:`, error.message);
    }
  }
  
  await prisma.$disconnect();
  console.log('🏁 Seeding finished.');
}

seed();
