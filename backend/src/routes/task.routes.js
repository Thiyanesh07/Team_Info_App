const express = require('express');
const taskController = require('../controllers/task.controller');
const { authenticate, isLeader, isAdmin } = require('../middleware/auth.middleware');
const { validate } = require('../utils/validation.utils');
const { createTaskSchema, updateTaskStatusSchema, taskReportSchema } = require('../validations/task.validation');

const router = express.Router();

router.use(authenticate);

// Member routes
router.get('/my', taskController.getMyTasks);

// Leader routes
router.get('/assigned', isLeader, taskController.getAssignedTasks);
router.post('/', isLeader, validate(createTaskSchema), taskController.createTask);
router.put('/:id', taskController.updateTask);
router.patch('/:id/status', validate(updateTaskStatusSchema), taskController.updateTaskStatus);

// Reports
router.get('/reports/export', taskController.exportReports);
router.post('/:id/reports', validate(taskReportSchema), taskController.addReport);
router.get('/:id/reports', taskController.getTaskReports);
router.put('/:id/reports/:reportId', validate(taskReportSchema), taskController.updateTaskReport);

// Admin routes
router.get('/all', isAdmin, taskController.getAllTasks);

// Reopen
router.post('/:id/reopen', isLeader, taskController.reopenTask);

// Delete
router.delete('/:id', taskController.deleteTask);
router.delete('/:id/reports/:reportId', taskController.deleteTaskReport);

module.exports = router;
