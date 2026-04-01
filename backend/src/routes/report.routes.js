const express = require('express');
const router = express.Router();
const reportController = require('../controllers/report.controller');
const { authenticate, isLeader } = require('../middleware/auth.middleware');

// ─── Direct Member Endpoints ───────────────────
// Get reports I am assigned to
router.get('/my-pending', authenticate, reportController.getMyReports);

// Submit or Update my submission
router.post('/submit/:requestId', authenticate, reportController.submitReport);

// Delete my submission
router.delete('/submission/:submissionId', authenticate, reportController.deleteSubmission);


// ─── Leader/Admin Management Endpoints ──────────
// Create a new report request
router.post('/request', authenticate, isLeader, reportController.createRequest);

// Get list of requests created by me (or all for admin)
router.get('/manageable', authenticate, isLeader, reportController.getManageableRequests);

// View all submissions for a request
router.get('/submissions/:requestId', authenticate, isLeader, reportController.getSubmissionsForRequest);

// Review a member's submission (approve/redo)
router.patch('/review/:submissionId', authenticate, isLeader, reportController.reviewSubmission);

// Delete an entire report request
router.delete('/request/:requestId', authenticate, isLeader, reportController.deleteRequest);

module.exports = router;
