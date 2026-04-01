const prisma = require('../lib/prisma');

/** GET /api/certifications */
const getMyCertifications = async (req, res) => {
  try {
    const certs = await prisma.certification.findMany({
      where: { userId: req.user.id }, orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: certs });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch certifications' });
  }
};

/** GET /api/certifications/user/:userId */
const getUserCertifications = async (req, res) => {
  try {
    const certs = await prisma.certification.findMany({
      where: { userId: req.params.userId }, orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: certs });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch certifications' });
  }
};

/** POST /api/certifications */
const createCertification = async (req, res) => {
  try {
    const { skill, provider, description, issuedDate, proofUrl } = req.body;
    if (!skill) return res.status(400).json({ success: false, message: 'Skill is required' });

    const cert = await prisma.certification.create({
      data: {
        userId: req.user.id, skill, provider, description, proofUrl,
        issuedDate: issuedDate ? new Date(issuedDate) : null,
      },
    });
    res.status(201).json({ success: true, message: 'Certification added', data: cert });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to create certification' });
  }
};

/** PUT /api/certifications/:id */
const updateCertification = async (req, res) => {
  try {
    const existing = await prisma.certification.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ success: false, message: 'Not found' });
    if (existing.userId !== req.user.id) return res.status(403).json({ success: false, message: 'Not authorized' });

    const data = { ...req.body };
    if (data.issuedDate) data.issuedDate = new Date(data.issuedDate);

    const cert = await prisma.certification.update({ where: { id: req.params.id }, data });
    res.json({ success: true, message: 'Certification updated', data: cert });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to update certification' });
  }
};

/** DELETE /api/certifications/:id */
const deleteCertification = async (req, res) => {
  try {
    const existing = await prisma.certification.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ success: false, message: 'Not found' });
    if (existing.userId !== req.user.id && req.user.role !== 'ADMIN') {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }
    await prisma.certification.delete({ where: { id: req.params.id } });
    res.json({ success: true, message: 'Certification deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to delete certification' });
  }
};

module.exports = { getMyCertifications, getUserCertifications, createCertification, updateCertification, deleteCertification };
