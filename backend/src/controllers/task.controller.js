const prisma = require('../lib/prisma');
const { sendPushToUsers } = require('../services/pushNotification.service');

const { logSystemActivity } = require('./systemActivity.controller');

const taskInclude = {
  assignedBy: { select: { id: true, name: true, profileImageUrl: true } },
  assignedTo: { select: { id: true, name: true, profileImageUrl: true } },
  _count: { select: { reports: true } },
};

/** GET /api/tasks/my - Get tasks assigned TO current user */
const getMyTasks = async (req, res) => {
  try {
    const { status } = req.query;
    const where = { assignedToId: req.user.id };
    if (status) where.status = status;

    const tasks = await prisma.taskAssignment.findMany({
      where,
      include: taskInclude,
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: tasks });
  } catch (error) {
    console.error('GetMyTasks error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch tasks' });
  }
};

/** GET /api/tasks/assigned - Get tasks created BY current leader */
const getAssignedTasks = async (req, res) => {
  try {
    const { status } = req.query;
    const where = { assignedById: req.user.id };
    if (status) where.status = status;

    const tasks = await prisma.taskAssignment.findMany({
      where,
      include: taskInclude,
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: tasks });
  } catch (error) {
    console.error('GetAssignedTasks error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch tasks' });
  }
};

/** GET /api/tasks/all - Admin: get all tasks */
const getAllTasks = async (req, res) => {
  try {
    const tasks = await prisma.taskAssignment.findMany({
      include: taskInclude,
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: tasks });
  } catch (error) {
    console.error('GetAllTasks error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch tasks' });
  }
};

/** POST /api/tasks - Leader: create/assign a task */
const createTask = async (req, res) => {
  try {
    const { title, description, assignedToId, deadline, priority } = req.body;

    if (!title || !assignedToId) {
      return res.status(400).json({ success: false, message: 'Title and assignedToId are required' });
    }

    // Verify assignee exists
    const assignee = await prisma.user.findUnique({ where: { id: assignedToId } });
    if (!assignee) {
      return res.status(404).json({ success: false, message: 'Assigned user not found' });
    }

    const task = await prisma.taskAssignment.create({
      data: {
        title,
        description,
        assignedById: req.user.id,
        assignedToId,
        deadline: deadline ? new Date(deadline) : null,
        priority: priority || 'MEDIUM',
      },
      include: taskInclude,
    });

    res.status(201).json({ success: true, message: 'Task assigned', data: task });

    // Log System Activity
    logSystemActivity(
      req.user.id,
      'New Task Assigned',
      `Assigned "${title}" to ${assignee.name}`,
      'TASK_CREATED',
      { taskId: task.id, assignedToId }
    );

    await sendPushToUsers({
      userIds: [assignedToId],
      title: 'New Task Assigned',
      body: title,
      data: {
        type: 'TASK_ASSIGNED',
        taskId: task.id,
      },
    });
  } catch (error) {
    console.error('CreateTask error:', error);
    res.status(500).json({ success: false, message: 'Failed to create task' });
  }
};

/** PUT /api/tasks/:id - Creator: update task details */
const updateTask = async (req, res) => {
  try {
    const existing = await prisma.taskAssignment.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ success: false, message: 'Task not found' });

    if (existing.assignedById !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ success: false, message: 'Only the task creator can edit it' });
    }

    const { title, description, deadline, priority, assignedToId } = req.body;
    const task = await prisma.taskAssignment.update({
      where: { id: req.params.id },
      data: {
        ...(title && { title }),
        ...(description !== undefined && { description }),
        ...(deadline !== undefined && { deadline: deadline ? new Date(deadline) : null }),
        ...(priority && { priority }),
        ...(assignedToId && { assignedToId }),
      },
      include: taskInclude,
    });

    res.json({ success: true, message: 'Task updated', data: task });
  } catch (error) {
    console.error('UpdateTask error:', error);
    res.status(500).json({ success: false, message: 'Failed to update task' });
  }
};

/** PATCH /api/tasks/:id/status - Assignee: update task status */
const updateTaskStatus = async (req, res) => {
  try {
    const existing = await prisma.taskAssignment.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ success: false, message: 'Task not found' });

    if (existing.assignedToId !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Only the assignee can update status' });
    }

    const { status } = req.body;
    const validStatuses = ['PENDING', 'IN_PROGRESS', 'COMPLETED'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status' });
    }

    const task = await prisma.taskAssignment.update({
      where: { id: req.params.id },
      data: { status },
      include: taskInclude,
    });

    res.json({ success: true, message: 'Status updated', data: task });

    // Log System Activity if completed
    if (status === 'COMPLETED') {
      logSystemActivity(
        req.user.id,
        'Task Completed',
        `Completed the task: "${task.title}"`,
        'TASK_COMPLETED',
        { taskId: task.id }
      );
    }
  } catch (error) {
    console.error('UpdateTaskStatus error:', error);
    res.status(500).json({ success: false, message: 'Failed to update status' });
  }
};

/** POST /api/tasks/:id/reports - Assignee: submit a report */
const addReport = async (req, res) => {
  try {
    const existing = await prisma.taskAssignment.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ success: false, message: 'Task not found' });

    if (existing.assignedToId !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Only the assignee can submit reports' });
    }

    const { reportText } = req.body;
    if (!reportText) {
      return res.status(400).json({ success: false, message: 'Report text is required' });
    }

    const report = await prisma.taskReport.create({
      data: {
        taskId: req.params.id,
        userId: req.user.id,
        reportText,
      },
      include: { user: { select: { id: true, name: true, profileImageUrl: true } } },
    });

    res.status(201).json({ success: true, message: 'Report submitted', data: report });
  } catch (error) {
    console.error('AddReport error:', error);
    res.status(500).json({ success: false, message: 'Failed to submit report' });
  }
};

/** GET /api/tasks/:id/reports - Creator + Assignee: view reports */
const getTaskReports = async (req, res) => {
  try {
    const existing = await prisma.taskAssignment.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ success: false, message: 'Task not found' });

    // Only creator, assignee, or admin can view reports
    if (existing.assignedById !== req.user.id && existing.assignedToId !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const reports = await prisma.taskReport.findMany({
      where: { taskId: req.params.id },
      include: { user: { select: { id: true, name: true, profileImageUrl: true } } },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ success: true, data: reports });
  } catch (error) {
    console.error('GetTaskReports error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch reports' });
  }
};

/** DELETE /api/tasks/:id - Creator or Admin: delete task */
const deleteTask = async (req, res) => {
  try {
    const existing = await prisma.taskAssignment.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ success: false, message: 'Task not found' });

    if (existing.assignedById !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    await prisma.taskAssignment.delete({ where: { id: req.params.id } });
    res.json({ success: true, message: 'Task deleted' });
  } catch (error) {
    console.error('DeleteTask error:', error);
    res.status(500).json({ success: false, message: 'Failed to delete task' });
  }
};

/** GET /api/tasks/reports/export - Export reports (Leader/Admin for all, Members for self) */
const exportReports = async (req, res) => {
  try {
    const { startDate, endDate, userId } = req.query;
    const isLeaderOrAdmin = req.user.role !== 'MEMBER';

    // Base filter
    let where = {};

    // Date filtering
    if (startDate && endDate) {
      where.createdAt = {
        gte: new Date(startDate),
        lte: new Date(endDate + 'T23:59:59.999Z'),
      };
    }

    // Role-based user filtering
    if (isLeaderOrAdmin) {
      if (userId) {
        where.userId = userId;
      }
    } else {
      // Members can ONLY see their own reports
      where.userId = req.user.id;
    }

    const reports = await prisma.taskReport.findMany({
      where,
      include: { 
        user: { select: { name: true, email: true, department: true } },
        task: { select: { title: true, description: true, status: true, deadline: true } }
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ success: true, data: reports });
  } catch (error) {
    console.error('ExportReports error:', error);
    res.status(500).json({ success: false, message: 'Failed to export reports' });
  }
};

module.exports = {
  getMyTasks, getAssignedTasks, getAllTasks,
  createTask, updateTask, updateTaskStatus,
  addReport, getTaskReports, exportReports, deleteTask,
};

