require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const { PrismaClient } = require('@prisma/client');

// Import routes
const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const personalProjectRoutes = require('./routes/personalProject.routes');
const teamProjectRoutes = require('./routes/teamProject.routes');
const projectUpdateRoutes = require('./routes/projectUpdate.routes');
const hackathonRoutes = require('./routes/hackathon.routes');
const learningRoutes = require('./routes/learning.routes');
const activityRoutes = require('./routes/activity.routes');
const certificationRoutes = require('./routes/certification.routes');
const psSkillRoutes = require('./routes/psSkill.routes');
const chatRoutes = require('./routes/chat.routes');
const analyticsRoutes = require('./routes/analytics.routes');
const uploadRoutes = require('./routes/upload.routes');
const taskRoutes = require('./routes/task.routes');

// Import socket handler
const { setupSocketHandlers } = require('./socket/chatSocket');

const app = express();
const server = http.createServer(app);
const prisma = new PrismaClient();

// Socket.io setup
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

// Make prisma and io available globally
app.set('prisma', prisma);
app.set('io', io);

// ──────────────────────────────────────
// MIDDLEWARE
// ──────────────────────────────────────

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ──────────────────────────────────────
// ROUTES
// ──────────────────────────────────────


app.use((req, res, next) => {
  console.log(`[DEBUG] ${req.method} ${req.url}`);
  next();
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/personal-projects', personalProjectRoutes);
app.use('/api/team-projects', teamProjectRoutes);
app.use('/api/project-updates', projectUpdateRoutes);
app.use('/api/hackathons', hackathonRoutes);
app.use('/api/learning', learningRoutes);
app.use('/api/activities', activityRoutes);
app.use('/api/certifications', certificationRoutes);
app.use('/api/ps-skills', psSkillRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/tasks', taskRoutes);

// ──────────────────────────────────────
// ERROR HANDLING
// ──────────────────────────────────────

app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

// ──────────────────────────────────────
// SOCKET.IO
// ──────────────────────────────────────

setupSocketHandlers(io, prisma);

// ──────────────────────────────────────
// START SERVER
// ──────────────────────────────────────

const PORT = process.env.PORT || 3000;

server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server is successfully running on port ${PORT}`);
  console.log(`📡 Socket.io integration ready`);
  console.log(`🔗 Health check available at: http://0.0.0.0:${PORT}/api/health`);
});

// Graceful shutdown
process.on('SIGINT', async () => {
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await prisma.$disconnect();
  process.exit(0);
});
