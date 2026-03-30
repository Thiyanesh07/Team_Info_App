const express = require('express');
const router = express.Router();
const {
  getMyTasks, getAssignedTasks, getAllTasks,
  createTask, updateTask, updateTaskStatus,
  addReport, getTaskReports, exportReports, deleteTask,
} = require('../controllers/task.controller');
const { authenticate, isLeader, isAdmin } = require('../middleware/auth.middleware');

router.use(authenticate);

// Member routes
router.get('/my', getMyTasks);

// Leader routes
router.get('/assigned', isLeader, getAssignedTasks);
router.post('/', isLeader, createTask);
router.put('/:id', updateTask);
router.patch('/:id/status', updateTaskStatus);

// Reports
router.get('/reports/export', exportReports);
router.post('/:id/reports', addReport);
router.get('/:id/reports', getTaskReports);

// Admin routes
router.get('/all', isAdmin, getAllTasks);

// Delete
router.delete('/:id', deleteTask);

module.exports = router;
