const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

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
          select: { name: true, profileImageUrl: true }
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
    const submission = await prisma.reportSubmission.upsert({
      where: {
        reportRequestId_userId: {
          reportRequestId: requestId,
          userId: userId
        }
      },
      update: {
        fileUrl,
        notes,
        status: 'PENDING', // Reset status to pending on update
        updatedAt: new Date()
      },
      create: {
        reportRequestId: requestId,
        userId: userId,
        fileUrl,
        notes,
        status: 'PENDING'
      }
    });

    res.json({ success: true, data: submission, message: 'Report submitted successfully' });
  } catch (error) {
    console.error('submitReport error:', error);
    res.status(500).json({ success: false, message: 'Failed to submit report' });
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
