const prisma = require('../lib/prisma');

/** GET /api/system/config */
const getSystemConfig = async (req, res) => {
  try {
    let config = await prisma.systemConfig.findUnique({
      where: { id: 'global_config' },
    });

    // Auto-create if missing
    if (!config) {
      config = await prisma.systemConfig.create({
        data: { id: 'global_config', apSyncEnabled: true },
      });
    }

    res.json({ success: true, data: config });
  } catch (error) {
    console.error('GetSystemConfig error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch system config' });
  }
};

/** PATCH /api/system/config - Admin only */
const updateSystemConfig = async (req, res) => {
  try {
    const { apSyncEnabled } = req.body;

    const config = await prisma.systemConfig.upsert({
      where: { id: 'global_config' },
      update: {
        ...(apSyncEnabled !== undefined && { apSyncEnabled }),
      },
      create: {
        id: 'global_config',
        apSyncEnabled: apSyncEnabled ?? true,
      },
    });

    res.json({ success: true, message: 'System configuration updated', data: config });
  } catch (error) {
    console.error('UpdateSystemConfig error:', error);
    res.status(500).json({ success: false, message: 'Failed to update system config' });
  }
};

module.exports = { getSystemConfig, updateSystemConfig };
