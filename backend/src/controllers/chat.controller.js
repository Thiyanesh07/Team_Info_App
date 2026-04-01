const prisma = require('../lib/prisma');

const isConversationParticipant = async (conversationId, userId) => {
  const participant = await prisma.chatParticipant.findUnique({
    where: { conversationId_userId: { conversationId, userId } },
    select: { id: true },
  });
  return Boolean(participant);
};

// ────────────────────────────────────────
// TEAM CHAT
// ────────────────────────────────────────

/** GET /api/chat/team - Get team messages */
const getTeamMessages = async (req, res) => {
  try {
    const { limit = 50, before } = req.query;
    const where = {};
    if (before) where.timestamp = { lt: new Date(before) };

    const messages = await prisma.teamMessage.findMany({
      where,
      include: { sender: { select: { id: true, name: true, profileImageUrl: true } } },
      orderBy: { timestamp: 'desc' },
      take: parseInt(limit),
    });
    res.json({ success: true, data: messages.reverse() });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch team messages' });
  }
};

/** POST /api/chat/team - Send team message */
const sendTeamMessage = async (req, res) => {
  try {
    const { message, imageUrl } = req.body;
    if (!message && !imageUrl) return res.status(400).json({ success: false, message: 'Message or image required' });

    const msg = await prisma.teamMessage.create({
      data: { senderId: req.user.id, message, imageUrl },
      include: { sender: { select: { id: true, name: true, profileImageUrl: true } } },
    });

    res.status(201).json({ success: true, data: msg });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to send message' });
  }
};

/** PUT /api/chat/team/:id/pin - Toggle pin */
const togglePinMessage = async (req, res) => {
  try {
    const msg = await prisma.teamMessage.findUnique({ where: { id: req.params.id } });
    if (!msg) return res.status(404).json({ success: false, message: 'Message not found' });

    const updated = await prisma.teamMessage.update({
      where: { id: req.params.id },
      data: { isPinned: !msg.isPinned },
      include: { sender: { select: { id: true, name: true, profileImageUrl: true } } },
    });
    res.json({ success: true, data: updated });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to toggle pin' });
  }
};

/** GET /api/chat/team/pinned - Get pinned messages */
const getPinnedMessages = async (req, res) => {
  try {
    const messages = await prisma.teamMessage.findMany({
      where: { isPinned: true },
      include: { sender: { select: { id: true, name: true, profileImageUrl: true } } },
      orderBy: { timestamp: 'desc' },
    });
    res.json({ success: true, data: messages });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch pinned messages' });
  }
};

// ────────────────────────────────────────
// PERSONAL CHAT (1-to-1)
// ────────────────────────────────────────

/** GET /api/chat/conversations - Get user's conversations */
const getConversations = async (req, res) => {
  try {
    const conversations = await prisma.chatConversation.findMany({
      where: { participants: { some: { userId: req.user.id } } },
      include: {
        participants: { include: { user: { select: { id: true, name: true, profileImageUrl: true } } } },
        messages: { orderBy: { timestamp: 'desc' }, take: 1 },
      },
      orderBy: { updatedAt: 'desc' },
    });
    res.json({ success: true, data: conversations });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch conversations' });
  }
};

/** POST /api/chat/conversations - Create or get existing 1-to-1 conversation */
const createConversation = async (req, res) => {
  try {
    const { otherUserId } = req.body;
    if (!otherUserId) return res.status(400).json({ success: false, message: 'otherUserId is required' });

    // Check if conversation exists
    const existing = await prisma.chatConversation.findFirst({
      where: {
        AND: [
          { participants: { some: { userId: req.user.id } } },
          { participants: { some: { userId: otherUserId } } },
        ],
      },
      include: {
        participants: { include: { user: { select: { id: true, name: true, profileImageUrl: true } } } },
      },
    });

    if (existing) return res.json({ success: true, data: existing });

    const conversation = await prisma.chatConversation.create({
      data: {
        participants: {
          create: [{ userId: req.user.id }, { userId: otherUserId }],
        },
      },
      include: {
        participants: { include: { user: { select: { id: true, name: true, profileImageUrl: true } } } },
      },
    });

    res.status(201).json({ success: true, data: conversation });
  } catch (error) {
    console.error('CreateConversation error:', error);
    res.status(500).json({ success: false, message: 'Failed to create conversation' });
  }
};

/** GET /api/chat/conversations/:id/messages */
const getConversationMessages = async (req, res) => {
  try {
    const allowed = await isConversationParticipant(req.params.id, req.user.id);
    if (!allowed) {
      return res.status(403).json({ success: false, message: 'Not authorized for this conversation' });
    }

    const { limit = 50, before } = req.query;
    const where = { conversationId: req.params.id };
    if (before) where.timestamp = { lt: new Date(before) };

    const messages = await prisma.chatMessage.findMany({
      where,
      include: { sender: { select: { id: true, name: true, profileImageUrl: true } } },
      orderBy: { timestamp: 'desc' },
      take: parseInt(limit, 10),
    });
    res.json({ success: true, data: messages.reverse() });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch messages' });
  }
};

/** POST /api/chat/conversations/:id/messages */
const sendConversationMessage = async (req, res) => {
  try {
    const allowed = await isConversationParticipant(req.params.id, req.user.id);
    if (!allowed) {
      return res.status(403).json({ success: false, message: 'Not authorized for this conversation' });
    }

    const { message, imageUrl, fileUrl, fileName, fileType, replyToId } = req.body;
    if (!message && !imageUrl && !fileUrl) return res.status(400).json({ success: false, message: 'Message, image, or file required' });

    const msg = await prisma.chatMessage.create({
      data: {
        conversationId: req.params.id,
        senderId: req.user.id,
        message, 
        imageUrl,
        fileUrl,
        fileName,
        fileType,
        replyToId
      },
      include: { sender: { select: { id: true, name: true, profileImageUrl: true } } },
    });

    // Update conversation timestamp
    await prisma.chatConversation.update({
      where: { id: req.params.id },
      data: { updatedAt: new Date() },
    });

    res.status(201).json({ success: true, data: msg });
  } catch (error) {
    console.error('sendConversationMessage error:', error);
    res.status(500).json({ success: false, message: 'Failed to send message' });
  }
};

/** PUT /api/chat/conversations/:conversationId/messages/:messageId/pin */
const toggleConversationPin = async (req, res) => {
  try {
    const { conversationId, messageId } = req.params;
    const allowed = await isConversationParticipant(conversationId, req.user.id);
    if (!allowed) {
      return res.status(403).json({ success: false, message: 'Not authorized for this conversation' });
    }

    const message = await prisma.chatMessage.findFirst({
      where: { id: messageId, conversationId },
    });
    if (!message) {
      return res.status(404).json({ success: false, message: 'Message not found' });
    }

    const updated = await prisma.chatMessage.update({
      where: { id: messageId },
      data: { isPinned: !message.isPinned },
      include: { sender: { select: { id: true, name: true, profileImageUrl: true } } },
    });
    res.json({ success: true, data: updated });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to toggle pin' });
  }
};

module.exports = {
  getTeamMessages, sendTeamMessage, togglePinMessage, getPinnedMessages,
  getConversations, createConversation, getConversationMessages, sendConversationMessage,
  toggleConversationPin,
};
