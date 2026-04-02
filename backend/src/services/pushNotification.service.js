const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');
const prisma = require('../lib/prisma');

let initialized = false;

function _resolveServiceAccount() {
  const inlineJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (inlineJson) {
    try {
      return JSON.parse(inlineJson);
    } catch (e) {
      console.error('Invalid FIREBASE_SERVICE_ACCOUNT_JSON:', e.message);
    }
  }

  const configuredPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (configuredPath) {
    const absPath = path.isAbsolute(configuredPath)
      ? configuredPath
      : path.join(process.cwd(), configuredPath);
    if (fs.existsSync(absPath)) {
      try {
        return JSON.parse(fs.readFileSync(absPath, 'utf8'));
      } catch (e) {
        console.error('Invalid Firebase service account file:', e.message);
      }
    }
  }

  const fallback = path.join(process.cwd(), 'team-app-74-cb0ef0cb661c.json');
  if (fs.existsSync(fallback)) {
    try {
      return JSON.parse(fs.readFileSync(fallback, 'utf8'));
    } catch (e) {
      console.error('Invalid fallback service account file:', e.message);
    }
  }

  return null;
}

function ensureFirebaseInitialized() {
  if (initialized) return true;

  try {
    if (!admin.apps.length) {
      const serviceAccount = _resolveServiceAccount();
      if (!serviceAccount) {
        return false;
      }
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }

    initialized = true;
    return true;
  } catch (error) {
    console.error('Firebase admin initialization failed:', error.message);
    return false;
  }
}

async function _getUserTokens(userIds) {
  if (!Array.isArray(userIds) || userIds.length === 0) return [];

  const uniqueIds = [...new Set(userIds.filter(Boolean))];
  if (uniqueIds.length === 0) return [];

  const users = await prisma.user.findMany({
    where: {
      id: { in: uniqueIds },
      fcmToken: { not: null },
    },
    select: { fcmToken: true },
  });

  return users
    .map((u) => u.fcmToken)
    .filter((token) => typeof token === 'string' && token.trim().length > 0)
    .map((token) => token.trim());
}

async function sendPushToUsers({ userIds, title, body, data = {} }) {
  try {
    if (!ensureFirebaseInitialized()) {
      return { sent: 0, reason: 'firebase-not-configured' };
    }

    const tokens = await _getUserTokens(userIds);
    if (tokens.length === 0) {
      return { sent: 0, reason: 'no-tokens' };
    }

    const payload = {
      tokens,
      notification: { title, body },
      data: Object.entries(data).reduce((acc, [k, v]) => {
        acc[k] = v == null ? '' : String(v);
        return acc;
      }, {}),
      android: {
        priority: 'high',
        notification: { channelId: 'default_channel' },
      },
    };

    const response = await admin.messaging().sendEachForMulticast(payload);

    if (response.failureCount > 0) {
      const invalidTokens = [];
      response.responses.forEach((r, idx) => {
        if (!r.success) {
          const code = r.error?.code || '';
          if (
            code.includes('registration-token-not-registered') ||
            code.includes('invalid-argument')
          ) {
            invalidTokens.push(tokens[idx]);
          }
        }
      });

      if (invalidTokens.length > 0) {
        await prisma.user.updateMany({
          where: { fcmToken: { in: invalidTokens } },
          data: { fcmToken: null },
        });
      }
    }

    return { sent: response.successCount, failed: response.failureCount };
  } catch (error) {
    console.error('sendPushToUsers error:', error.message);
    return { sent: 0, failed: 0, reason: 'send-failed' };
  }
}

module.exports = {
  ensureFirebaseInitialized,
  sendPushToUsers,
};
