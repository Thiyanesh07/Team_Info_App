const jwt = require('jsonwebtoken');
const { sendPushToUsers } = require('../services/pushNotification.service');
const { validateAndNormalizeUrl } = require('../lib/urlValidation');

/**
 * Socket.io handlers for real-time chat
 */
const setupSocketHandlers = (io, prisma) => {
  // Authenticate socket connections
  io.use((socket, next) => {
    const token = socket.handshake.auth.token;
    if (!token) return next(new Error('Authentication required'));

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.userId = decoded.userId;
      next();
    } catch (err) {
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`🔌 User connected: ${socket.userId}`);

    // Join team chat room
    socket.join('team-chat');

    // Join personal conversation rooms
    socket.on('join-conversation', async (conversationId) => {
      try {
        // Phase 2: Security Hardening (Verify participant)
        const participant = await prisma.chatParticipant.findUnique({
          where: { conversationId_userId: { conversationId, userId: socket.userId } }
        });

        if (participant) {
          socket.join(`conversation-${conversationId}`);
        } else {
          console.warn(`🔒 Unauthorized join attempt to room: conversation-${conversationId} by user: ${socket.userId}`);
          socket.emit('error', { message: 'Unauthorized room access denied' });
        }
      } catch (error) {
        console.error('Socket join-conversation error:', error);
      }
    });

    socket.on('leave-conversation', (conversationId) => {
      socket.leave(`conversation-${conversationId}`);
    });

    // ─── Team Chat ───────────────────────────────
    socket.on('team-message', async (data) => {
      try {
        let normalizedImageUrl;
        let normalizedFileUrl;
        try {
          normalizedImageUrl = validateAndNormalizeUrl(data.imageUrl, 'imageUrl');
          normalizedFileUrl = validateAndNormalizeUrl(data.fileUrl, 'fileUrl');
        } catch (e) {
          socket.emit('error', { message: e.message });
          return;
        }

        const msg = await prisma.teamMessage.create({
          data: {
            senderId: socket.userId,
            message: data.message,
            imageUrl: normalizedImageUrl,
            fileUrl: normalizedFileUrl,
            fileName: data.fileName,
            fileType: data.fileType,
            replyToId: data.replyToId,
            isDelivered: true,
          },
          include: {
            sender: { select: { id: true, name: true, profileImageUrl: true } },
          },
        });

        io.to('team-chat').emit('team-message', msg);

        const members = await prisma.user.findMany({
          where: { id: { not: socket.userId } },
          select: { id: true },
        });
        const bodyPreview =
          msg.message || (msg.fileType === 'VOICE' ? 'Voice message' : 'New attachment');
        await sendPushToUsers({
          userIds: members.map((u) => u.id),
          title: `${msg.sender?.name || 'Team'} in Team Chat`,
          body: bodyPreview,
          data: {
            type: 'TEAM_CHAT_MESSAGE',
            messageId: msg.id,
          },
        });
      } catch (error) {
        console.error('Socket team-message error:', error);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // ─── Personal Chat ───────────────────────────
    socket.on('personal-message', async (data) => {
      try {
        const participant = await prisma.chatParticipant.findUnique({
          where: {
            conversationId_userId: {
              conversationId: data.conversationId,
              userId: socket.userId,
            },
          },
        });

        if (!participant) {
          socket.emit('error', {
            message: 'Not authorized to send in this conversation',
          });
          return;
        }

        let normalizedImageUrl;
        let normalizedFileUrl;
        try {
          normalizedImageUrl = validateAndNormalizeUrl(data.imageUrl, 'imageUrl');
          normalizedFileUrl = validateAndNormalizeUrl(data.fileUrl, 'fileUrl');
        } catch (e) {
          socket.emit('error', { message: e.message });
          return;
        }

        const msg = await prisma.chatMessage.create({
          data: {
            conversationId: data.conversationId,
            senderId: socket.userId,
            message: data.message,
            imageUrl: normalizedImageUrl,
            fileUrl: normalizedFileUrl,
            fileName: data.fileName,
            fileType: data.fileType,
            replyToId: data.replyToId,
            isDelivered: true,
          },
          include: {
            sender: { select: { id: true, name: true, profileImageUrl: true } },
          },
        });

        // Update conversation timestamp
        await prisma.chatConversation.update({
          where: { id: data.conversationId },
          data: { updatedAt: new Date() },
        });

        io.to(`conversation-${data.conversationId}`).emit('personal-message', msg);

        const otherParticipants = await prisma.chatParticipant.findMany({
          where: {
            conversationId: data.conversationId,
            userId: { not: socket.userId },
          },
          select: { userId: true },
        });

        const bodyPreview =
          msg.message || (msg.fileType === 'VOICE' ? 'Voice message' : 'New attachment');
        await sendPushToUsers({
          userIds: otherParticipants.map((p) => p.userId),
          title: `${msg.sender?.name || 'New'} sent a message`,
          body: bodyPreview,
          data: {
            type: 'PERSONAL_CHAT_MESSAGE',
            conversationId: data.conversationId,
            messageId: msg.id,
            senderName: msg.sender?.name || '',
          },
        });
      } catch (error) {
        console.error('Socket personal-message error:', error);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // ─── Reactions ──────────────────────────────
    socket.on('add-reaction', async (data) => {
      try {
        const { messageId, type, emoji } = data; // type: 'personal' or 'team'
        const table = type === 'personal' ? 'chatMessage' : 'teamMessage';
        
        const msg = await prisma[table].findUnique({ where: { id: messageId } });
        let reactions = msg.reactions || {};
        if (typeof reactions === 'string') reactions = JSON.parse(reactions);
        
        // Structure: { emoji: [userId1, userId2] }
        if (!reactions[emoji]) reactions[emoji] = [];
        if (!reactions[emoji].includes(socket.userId)) {
          reactions[emoji].push(socket.userId);
        }
        
        const updated = await prisma[table].update({
          where: { id: messageId },
          data: { reactions },
        });

        const room = type === 'personal' ? `conversation-${updated.conversationId}` : 'team-chat';
        io.to(room).emit('reaction-updated', { messageId, reactions, type });
      } catch (error) {
        console.error('Socket add-reaction error:', error);
      }
    });

    // ─── Read Receipts ──────────────────────────
    socket.on('mark-read', async (data) => {
      try {
        const { conversationId, type } = data; // type: 'personal' or 'team'
        if (type === 'personal') {
          await prisma.chatMessage.updateMany({
            where: { conversationId, senderId: { not: socket.userId }, isRead: false },
            data: { isRead: true },
          });
          io.to(`conversation-${conversationId}`).emit('messages-read', { conversationId, userId: socket.userId });
        } else {
          // Team chat read receipts are usually per-user, skipping for now to keep simple
        }
      } catch (error) {
        console.error('Socket mark-read error:', error);
      }
    });

    // ─── Typing indicators ──────────────────────
    socket.on('typing-team', (isTyping) => {
      socket.to('team-chat').emit('typing-team', { userId: socket.userId, isTyping });
    });

    socket.on('typing-personal', (data) => {
      const { conversationId, isTyping } = data;
      socket.to(`conversation-${conversationId}`).emit('typing-personal', {
        userId: socket.userId,
        conversationId,
        isTyping,
      });
    });

    socket.on('disconnect', () => {
      console.log(`🔌 User disconnected: ${socket.userId}`);
    });
  });
};

module.exports = { setupSocketHandlers };
