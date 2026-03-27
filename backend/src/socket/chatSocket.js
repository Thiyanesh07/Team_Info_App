const jwt = require('jsonwebtoken');

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
    socket.on('join-conversation', (conversationId) => {
      socket.join(`conversation-${conversationId}`);
    });

    socket.on('leave-conversation', (conversationId) => {
      socket.leave(`conversation-${conversationId}`);
    });

    // ─── Team Chat ───────────────────────────────
    socket.on('team-message', async (data) => {
      try {
        const msg = await prisma.teamMessage.create({
          data: {
            senderId: socket.userId,
            message: data.message,
            imageUrl: data.imageUrl,
          },
          include: {
            sender: { select: { id: true, name: true, profileImageUrl: true } },
          },
        });

        io.to('team-chat').emit('team-message', msg);
      } catch (error) {
        console.error('Socket team-message error:', error);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // ─── Personal Chat ───────────────────────────
    socket.on('personal-message', async (data) => {
      try {
        const msg = await prisma.chatMessage.create({
          data: {
            conversationId: data.conversationId,
            senderId: socket.userId,
            message: data.message,
            imageUrl: data.imageUrl,
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
      } catch (error) {
        console.error('Socket personal-message error:', error);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // ─── Typing indicators ──────────────────────
    socket.on('typing-team', () => {
      socket.to('team-chat').emit('typing-team', { userId: socket.userId });
    });

    socket.on('typing-personal', (conversationId) => {
      socket.to(`conversation-${conversationId}`).emit('typing-personal', {
        userId: socket.userId,
        conversationId,
      });
    });

    socket.on('disconnect', () => {
      console.log(`🔌 User disconnected: ${socket.userId}`);
    });
  });
};

module.exports = { setupSocketHandlers };
