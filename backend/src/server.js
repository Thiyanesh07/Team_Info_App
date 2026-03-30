require('dotenv').config();
const express = require('express');
require('express-async-errors'); // Automatically catches unhandled promise rejections
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const morgan = require('morgan');
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
const systemActivityRoutes = require('./routes/systemActivity.routes');
const milestoneRoutes = require('./routes/milestone.routes');

// Import socket handler
const { setupSocketHandlers } = require('./socket/chatSocket');

const app = express();
app.set('trust proxy', 1); // Required for Render load balancer to pass real client IP
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

// 1. Security Headers (Protects against XSS, clickjacking, etc.)
app.use(helmet());

// 2. HTTP Request Logger (Replaces basic console.log)
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// 3. API Rate Limiting (Protects Database from Spam & DDoS)
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes window
  max: 250, // Limit each IP to 250 requests per window
  message: { success: false, message: 'Too many requests from this IP, please try again later.' },
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});

app.use(cors());
app.use(express.json({ limit: '10mb' })); // limits payload to 10mb
app.use(express.urlencoded({ extended: true }));

// Apply Rate Limiter strictly to API routes
app.use('/api', apiLimiter);

// ──────────────────────────────────────
// ROUTES
// ──────────────────────────────────────

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
app.use('/api/activities', systemActivityRoutes); // Mount unified activities at /api/activities/unified
app.use('/api/milestones', milestoneRoutes);

// ──────────────────────────────────────
// ERROR HANDLING
// ──────────────────────────────────────

app.use((err, req, res, next) => {
  console.error('[GLOBAL ERROR HANDLER]:', err);
  
  // Distinguish between handled app errors and severe crashes
  const statusCode = err.statusCode || 500;
  
  res.status(statusCode).json({
    success: false,
    message: statusCode === 500 ? 'Internal Server Error' : err.message,
    error: process.env.NODE_ENV === 'development' ? err.message : undefined,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
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
