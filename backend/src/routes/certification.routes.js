const express = require('express');
const router = express.Router();
const { getMyCertifications, getUserCertifications, createCertification, updateCertification, deleteCertification } = require('../controllers/certification.controller');
const { authenticate, isLeader } = require('../middleware/auth.middleware');

router.use(authenticate);
router.get('/', getMyCertifications);
router.get('/user/:userId', isLeader, getUserCertifications);
router.post('/', createCertification);
router.put('/:id', updateCertification);
router.delete('/:id', deleteCertification);

module.exports = router;
