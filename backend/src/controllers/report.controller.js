const prisma = require('../lib/prisma');
const { sendPushToUsers } = require('../services/pushNotification.service');
const { validateAndNormalizeUrl } = require('../lib/urlValidation');


/**
 * Leader/Admin: Create a new report request
 */
exports.createRequest = async (req, res) => {
  const { title, description, deadline, targetAudience, targetRoles, targetUserIds, allowedFormats } = req.body;
  const assignedById = req.user.id;

  try {
    const reportRequest = await prisma.reportRequest.create({
      data: {
        title,
        description,
        deadline: deadline ? new Date(deadline) : null,
        originalDeadline: deadline ? new Date(deadline) : null,
        assignedById,
        targetAudience,
        targetRoles: targetRoles || [],
        targetUserIds: targetUserIds || [],
        allowedFormats: allowedFormats || [".pdf", ".docx", ".xlsx", ".pptx"]
      }
    });

    res.status(201).json({
      success: true,
      data: reportRequest,
      message: 'Report request created successfully'
    });

    const where = [];
    if (targetAudience === 'TEAM') {
      where.push({ id: { not: assignedById } });
    }
    if (targetAudience === 'ROLE' && Array.isArray(targetRoles) && targetRoles.length > 0) {
      where.push({ role: { in: targetRoles }, id: { not: assignedById } });
    }
    if (targetAudience === 'INDIVIDUAL' && Array.isArray(targetUserIds) && targetUserIds.length > 0) {
      where.push({ id: { in: targetUserIds.filter(Boolean), not: assignedById } });
    }

    if (where.length > 0) {
      const targets = await prisma.user.findMany({
        where: { OR: where },
        select: { id: true },
      });

      await sendPushToUsers({
        userIds: targets.map((u) => u.id),
        title: 'New Submission Task',
        body: title,
        data: {
          type: 'REPORT_REQUEST_CREATED',
          requestId: reportRequest.id,
        },
      });
    }
  } catch (error) {
    console.error('createRequest error:', error);
    res.status(500).json({ success: false, message: 'Failed to create report request' });
  }
};

/**
 * Get reports assigned to the current user
 */
exports.getMyReports = async (req, res) => {
  const userId = req.user.id;
  const userRole = req.user.role;

  try {
    // 1. Fetch all requests that might apply to this user
    const requests = await prisma.reportRequest.findMany({
      where: {
        OR: [
          { targetAudience: 'TEAM' },
          { 
            AND: [
              { targetAudience: 'ROLE' },
              { targetRoles: { has: userRole } }
            ]
          },
          {
            AND: [
              { targetAudience: 'INDIVIDUAL' },
              { targetUserIds: { has: userId } }
            ]
          }
        ]
      },
      include: {
        assignedBy: {
          select: { name: true, profileImageUrl: true, role: true }
        },
        submissions: {
          where: { userId }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({ success: true, data: requests });
  } catch (error) {
    console.error('getMyReports error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch your reports' });
  }
};

/**
 * Submit or update a report submission
 */
exports.submitReport = async (req, res) => {
  const { requestId } = req.params;
  const { fileUrl, notes } = req.body;
  const userId = req.user.id;

  try {
    const request = await prisma.reportRequest.findUnique({ where: { id: requestId } });
    if (!request) return res.status(404).json({ success: false, message: 'Request not found' });

    if (request.deadline && new Date() > new Date(request.deadline)) {
      return res.status(403).json({ 
        success: false, 
        message: 'Submission closed. The deadline has passed. Please contact your leader to reopen it.' 
      });
    }

    if (!fileUrl) {
      return res.status(400).json({ success: false, message: 'File URL is required. Please upload a file first.' });
    }

    let normalizedFileUrl;
    try {
      normalizedFileUrl = validateAndNormalizeUrl(fileUrl, 'fileUrl');
    } catch (e) {
      return res.status(400).json({ success: false, message: e.message });
    }

    const submission = await prisma.reportSubmission.upsert({
      where: {
        reportRequestId_userId: {
          reportRequestId: requestId,
          userId: userId
        }
      },
      update: {
        fileUrl: normalizedFileUrl,
        notes,
        status: 'PENDING',
        updatedAt: new Date()
      },
      create: {
        reportRequestId: requestId,
        userId: userId,
        fileUrl: normalizedFileUrl,
        notes,
        status: 'PENDING'
      }
    });

    res.json({ success: true, data: submission, message: 'Report submitted successfully' });
  } catch (error) {
    console.error('submitReport detailed error:', {
      message: error.message,
      stack: error.stack,
      requestId,
      userId
    });
    
    // Check for specific Prisma errors
    if (error.code === 'P2003') {
        return res.status(400).json({ success: false, message: 'Invalid Report Request ID. The request may have been deleted.' });
    }

    res.status(500).json({ success: false, message: 'Internal Server Error: ' + error.message });
  }
};

/**
 * Delete a submission (if permitted)
 */
exports.deleteSubmission = async (req, res) => {
  const { submissionId } = req.params;
  const userId = req.user.id;

  try {
    const submission = await prisma.reportSubmission.findUnique({
      where: { id: submissionId }
    });

    if (!submission) {
      return res.status(404).json({ success: false, message: 'Submission not found' });
    }

    if (submission.userId !== userId && req.user.role !== 'ADMIN') {
      return res.status(403).json({ success: false, message: 'Unauthorized to delete this submission' });
    }

    await prisma.reportSubmission.delete({ where: { id: submissionId } });
    res.json({ success: true, message: 'Submission deleted' });
  } catch (error) {
    console.error('deleteSubmission error:', error);
    res.status(500).json({ success: false, message: 'Failed to delete submission' });
  }
};

/**
 * Leader/Admin: Get all requests they created
 */
exports.getManageableRequests = async (req, res) => {
  const userId = req.user.id;

  try {
    const requests = await prisma.reportRequest.findMany({
      where: req.user.role === 'ADMIN' ? {} : { assignedById: userId },
      include: {
        _count: {
          select: { submissions: true }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({ success: true, data: requests });
  } catch (error) {
    console.error('getManageableRequests error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch manageable requests' });
  }
};

/**
 * Leader/Admin: Get all submissions for a specific request
 */
exports.getSubmissionsForRequest = async (req, res) => {
  const { requestId } = req.params;

  try {
    const submissions = await prisma.reportSubmission.findMany({
      where: { reportRequestId: requestId },
      include: {
        user: {
          select: { name: true, regNo: true, profileImageUrl: true }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({ success: true, data: submissions });
  } catch (error) {
    console.error('getSubmissionsForRequest error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch submissions' });
  }
};

/**
 * Leader/Admin: Review a submission (Complete/Redo)
 */
exports.reviewSubmission = async (req, res) => {
  const { submissionId } = req.params;
  const { status, reviewerNotes } = req.body;

  try {
    const submission = await prisma.reportSubmission.update({
      where: { id: submissionId },
      data: {
        status,
        reviewerNotes,
        updatedAt: new Date()
      }
    });

    res.json({ success: true, data: submission, message: `Report marked as ${status}` });
  } catch (error) {
    console.error('reviewSubmission error:', error);
    res.status(500).json({ success: false, message: 'Failed to review submission' });
  }
};

/**
 * Leader/Admin: Delete a report request and all its submissions
 */
exports.deleteRequest = async (req, res) => {
  const { requestId } = req.params;
  const userId = req.user.id;

  try {
    const request = await prisma.reportRequest.findUnique({
      where: { id: requestId }
    });

    if (!request) {
      return res.status(404).json({ success: false, message: 'Request not found' });
    }

    if (request.assignedById !== userId && req.user.role !== 'ADMIN') {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    await prisma.reportRequest.delete({ where: { id: requestId } });
    res.json({ success: true, message: 'Report request and submissions deleted' });
  } catch (error) {
    console.error('deleteRequest error:', error);
    res.status(500).json({ success: false, message: 'Failed to delete request' });
  }
};

/**
 * Leader/Admin: Update report request
 */
exports.updateRequest = async (req, res) => {
  const { requestId } = req.params;
  const { title, description, deadline, targetAudience, targetRoles, targetUserIds, allowedFormats } = req.body;

  try {
    const existing = await prisma.reportRequest.findUnique({ where: { id: requestId } });
    if (!existing) return res.status(404).json({ success: false, message: 'Request not found' });

    if (existing.assignedById !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    const updated = await prisma.reportRequest.update({
      where: { id: requestId },
      data: {
        ...(title && { title }),
        ...(description !== undefined && { description }),
        ...(deadline !== undefined && { deadline: deadline ? new Date(deadline) : null }),
        ...(targetAudience && { targetAudience }),
        ...(targetRoles && { targetRoles }),
        ...(targetUserIds && { targetUserIds }),
        ...(allowedFormats && { allowedFormats }),
      }
    });

    res.json({ success: true, data: updated, message: 'Request updated' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to update request' });
  }
};

/**
 * Leader/Admin: Reopen submission and set new deadline
 */
exports.reopenRequest = async (req, res) => {
  const { requestId } = req.params;
  const { newDeadline } = req.body;

  try {
    const existing = await prisma.reportRequest.findUnique({ where: { id: requestId } });
    if (!existing) return res.status(404).json({ success: false, message: 'Request not found' });

    if (existing.assignedById !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    const updated = await prisma.reportRequest.update({
      where: { id: requestId },
      data: {
        deadline: new Date(newDeadline),
        // Reset late reminders so they can trigger again for the new deadline if needed
        lateReminderStage: 0, 
      }
    });

    res.json({ success: true, data: updated, message: 'Submission reopened with new deadline' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to reopen submission' });
  }
};

/**
 * Leader/Admin: Get detailed analytics for a report card
 */
exports.getDetailedAnalytics = async (req, res) => {
  const { requestId } = req.params;

  try {
    const request = await prisma.reportRequest.findUnique({
      where: { id: requestId },
      include: {
        submissions: {
          include: {
            user: { select: { id: true, name: true, regNo: true, profileImageUrl: true } }
          }
        }
      }
    });

    if (!request) return res.status(404).json({ success: false, message: 'Request not found' });

    // Authorization: Only the creator or an ADMIN can see the detailed analytics
    if (request.assignedById !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ success: false, message: 'Unauthorized access to analytics' });
    }

    // Determine target users
    let targetUsers = [];
    if (request.targetAudience === 'TEAM') {
      targetUsers = await prisma.user.findMany({
        where: { id: { not: request.assignedById } },
        select: { id: true, name: true, regNo: true, profileImageUrl: true }
      });
    } else if (request.targetAudience === 'ROLE') {
      targetUsers = await prisma.user.findMany({
        where: { role: { in: request.targetRoles }, id: { not: request.assignedById } },
        select: { id: true, name: true, regNo: true, profileImageUrl: true }
      });
    } else if (request.targetAudience === 'INDIVIDUAL') {
      targetUsers = await prisma.user.findMany({
        where: { id: { in: request.targetUserIds } },
        select: { id: true, name: true, regNo: true, profileImageUrl: true }
      });
    }

    const submissionsMap = new Map(
      request.submissions.map(s => [s.userId, s])
    );

    const analytics = targetUsers.map(user => {
      const submission = submissionsMap.get(user.id);
      const isLate = submission && request.originalDeadline && 
                     new Date(submission.createdAt) > new Date(request.originalDeadline);

      return {
        userId: user.id,
        name: user.name,
        regNo: user.regNo,
        profileImageUrl: user.profileImageUrl,
        isSubmitted: !!submission,
        submittedAt: submission?.createdAt || null,
        isLate: !!isLate,
        status: submission?.status || 'PENDING'
      };
    });

    res.json({
      success: true,
      data: {
        title: request.title,
        deadline: request.deadline,
        originalDeadline: request.originalDeadline,
        totalAssigned: targetUsers.length,
        totalSubmitted: request.submissions.length,
        pendingCount: targetUsers.length - request.submissions.length,
        members: analytics
      }
    });
  } catch (error) {
    console.error('getDetailedAnalytics error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch analytics' });
  }
};
