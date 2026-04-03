require('dotenv').config();
const express = require('express');
require('express-async-errors'); // Automatically catches unhandled promise rejections
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const morgan = require('morgan');
const http = require('http');
const { Server } = require('socket.io');
const prisma = require('./lib/prisma');

// Import routes
const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const adminRoutes = require('./routes/admin.routes');
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
const exportRoutes = require('./routes/export.routes');
const reportRoutes = require('./routes/report.routes');
const systemRoutes = require('./routes/system.routes');
const schedulerService = require('./services/scheduler.service');

// Import socket handler
const { setupSocketHandlers } = require('./socket/chatSocket');

const app = express();
app.set('trust proxy', 1); // Required for Render load balancer to pass real client IP
const server = http.createServer(app);

// Socket.io setup
const io = new Server(server, {
  cors: {
    origin: [
      'https://team-info-app.vercel.app', 
      'http://localhost:3000', 
      'http://localhost:5173'
    ],
    methods: ['GET', 'POST'],
    credentials: true
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
  max: 1000, // Increased to 1000 for development to prevent Network Errors on dashboard reloads
  message: { success: false, message: 'Too many requests from this IP, please try again later.' },
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});

app.use(cors({
  origin: [
    'https://team-info-app.vercel.app', 
    'http://localhost:3000', 
    'http://localhost:5173'
  ],
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'x-api-key'],
  credentials: true
}));
app.use(express.json({ limit: '10mb' })); // limits payload to 10mb
app.use(express.urlencoded({ extended: true }));

// Apply Rate Limiter strictly to API routes
app.use('/api', apiLimiter);

// ──────────────────────────────────────
// ROUTES
// ──────────────────────────────────────

app.get('/', (req, res) => {
  res.json({ status: 'ok', name: 'team-info-backend', timestamp: new Date().toISOString() });
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.get('/api/health/db', async (req, res) => {
  try {
    const userCount = await prisma.user.count();
    res.json({ 
      status: 'ok', 
      database: 'connected', 
      userCount, 
      timestamp: new Date().toISOString() 
    });
  } catch (error) {
    console.error('[DATABASE HEALTH CHECK FAILED]:', error);
    res.status(503).json({ 
      status: 'error', 
      database: 'disconnected', 
      message: error.message,
      timestamp: new Date().toISOString() 
    });
  }
});

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/admin', adminRoutes);
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
app.use('/api/system-activities', systemActivityRoutes); // Remapped to /api/system-activities to resolve clash
app.use('/api/milestones', milestoneRoutes);
app.use('/api/export', exportRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/system', systemRoutes);

// ──────────────────────────────────────
// ERROR HANDLING
// ──────────────────────────────────────

app.use((err, req, res, next) => {
  const statusCode = err.statusCode || 500;
  
  // High-fidelity production logging
  console.error(`[SYSTEM ERROR] ${req.method} ${req.path} - Status: ${statusCode}`);
  console.error(`Message: ${err.message}`);
  if (process.env.NODE_ENV === 'production') {
    // In production, we log more but hide internals from the client
    if (statusCode === 500) {
      console.error('Stack Trace:', err.stack);
    }
  } else {
    console.error('Stack:', err.stack);
  }
  
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

server.listen(PORT, '0.0.0.0', async () => {
  console.log(`🚀 Server is successfully running on port ${PORT}`);
  console.log(`📡 Socket.io integration ready`);
  console.log(`🔗 Health check available at: http://0.0.0.0:${PORT}/api/health`);
  
    // Initial DB connection attempt with retry
    try {
      await prisma.$connectWithRetry();
      
      // Start background services after DB is ready
      await schedulerService.init();
    } catch (err) {
      console.error('❌ Database connection via Prisma FATAL ERROR:');
      console.error(err.message);
      // In production we keep the process alive so Render doesn't loop forever,
      // but the health checks will fail.
    }
});

// Graceful shutdown
process.on('SIGINT', async () => {
  await prisma.$disconnect();
  schedulerService.stopAll();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await prisma.$disconnect();
  schedulerService.stopAll();
  process.exit(0);
});
