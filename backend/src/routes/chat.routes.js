const express = require('express');
const router = express.Router();
const {
  getTeamMessages, sendTeamMessage, togglePinMessage, getPinnedMessages,
  getConversations, createConversation, getConversationMessages, sendConversationMessage,
  toggleConversationPin,
} = require('../controllers/chat.controller');
const { authenticate, isLeader } = require('../middleware/auth.middleware');

router.use(authenticate);

// Team chat
router.get('/team', getTeamMessages);
router.post('/team', sendTeamMessage);
router.put('/team/:id/pin', isLeader, togglePinMessage);
router.get('/team/pinned', getPinnedMessages);

// Personal chat
router.get('/conversations', getConversations);
router.post('/conversations', createConversation);
router.get('/conversations/:id/messages', getConversationMessages);
router.post('/conversations/:id/messages', sendConversationMessage);
router.put('/conversations/:conversationId/messages/:messageId/pin', toggleConversationPin);

module.exports = router;
