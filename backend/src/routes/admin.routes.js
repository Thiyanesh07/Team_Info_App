const express = require('express');
const router = express.Router();
const { getAdminOverview, getAdminUserDetail, updateUser, updateProject, deleteProject } = require('../controllers/admin.controller');
const { authenticate, isAdmin } = require('../middleware/auth.middleware');

// Protect all admin routes
router.use(authenticate, isAdmin);

/**
 * @route GET /api/admin/overview
 * @desc Get aggregated team-wide stats for dashboard
 */
router.get('/overview', getAdminOverview);

/**
 * @route GET /api/admin/users/:id/detail
 * @desc Get complete user history for deep inspection
 */
router.get('/users/:id/detail', getAdminUserDetail);

/**
 * @route PUT /api/admin/manage/users/:id
 * @desc Administrative updating of user Role or Reward Points
 */
router.put('/manage/users/:id', updateUser);

/**
 * @route PUT /api/admin/manage/projects/:id
 * @desc Administrative updating of team project details
 */
router.put('/manage/projects/:id', updateProject);

/**
 * @route DELETE /api/admin/manage/projects/:id
 * @desc Delete a team project from the database
 */
router.delete('/manage/projects/:id', deleteProject);

module.exports = router;
