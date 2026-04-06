const { z } = require('zod');

const createTaskSchema = z.object({
  title: z.string().min(3, 'Title is too short'),
  description: z.string().optional(),
  assignedToId: z.string().uuid('Invalid user ID'),
  deadline: z.string().datetime().optional(),
  priority: z.enum(['LOW', 'MEDIUM', 'HIGH']).optional(),
});

const updateTaskStatusSchema = z.object({
  status: z.enum(['PENDING', 'IN_PROGRESS', 'COMPLETED', 'OVERDUE']),
});

const taskReportSchema = z.object({
  reportText: z.string().min(1, 'Report text cannot be empty'),
});

module.exports = {
  createTaskSchema,
  updateTaskStatusSchema,
  taskReportSchema,
};
