const express = require('express');
const multer = require('multer');
const cloudinary = require('cloudinary').v2;
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Multer memory storage
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (req, file, cb) => {
    const allowedMimeTypes = [
      'image/',                  // All image/* types
      'application/pdf',
      'application/msword',      // .doc
      'application/octet-stream', // Generic binary (Flutter file_picker sends this)
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',  // .docx
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',// .pptx
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',        // .xlsx
      'text/',                   // Plain text files
      'video/',                  // Video files for chat
      'audio/',                  // Audio files for chat
    ];

    const isAllowed = allowedMimeTypes.some(mime =>
      file.mimetype.startsWith(mime) || file.mimetype === mime
    );

    if (isAllowed) {
      cb(null, true);
    } else {
      console.warn(`⚠️ Rejected MIME type: ${file.mimetype} for file: ${file.originalname}`);
      cb(new Error(`File type '${file.mimetype}' not supported.`), false);
    }
  },
});

const sanitizeFolderName = (value) => {
  if (!value || typeof value !== 'string') return null;
  const cleaned = value
    .toLowerCase()
    .replace(/[^a-z0-9/_-]/g, '')
    .replace(/\.{2,}/g, '')
    .replace(/^\/+|\/+$/g, '');
  return cleaned || null;
};

const resolveUploadFolder = (req) => {
  const requested = sanitizeFolderName(req.body?.folder);
  const base = 'team_info_app';
  return requested ? `${base}/${requested}` : `${base}/misc`;
};


/** POST /api/upload/image (Now supports any file under 'file' name) */
router.post('/image', authenticate, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No file provided. Make sure field name is "file".' });
    }

    console.log(`📤 Upload attempt: ${req.file.originalname} | type: ${req.file.mimetype} | size: ${req.file.size} bytes`);
    console.log(`☁️ Cloudinary config: cloud=${process.env.CLOUDINARY_CLOUD_NAME} | key=${process.env.CLOUDINARY_API_KEY ? 'SET' : 'MISSING'} | secret=${process.env.CLOUDINARY_API_SECRET ? 'SET' : 'MISSING'}`);

    const folder = resolveUploadFolder(req);

    // Upload to Cloudinary
    const result = await new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        { folder, resource_type: 'auto' },
        (error, result) => {
          if (error) {
            console.error('❌ Cloudinary error:', JSON.stringify(error));
            reject(error);
          } else {
            resolve(result);
          }
        }
      );
      uploadStream.end(req.file.buffer);
    });

    console.log(`✅ Upload success: ${result.secure_url}`);

    res.json({
      success: true,
      data: {
        url: result.secure_url,
        publicId: result.public_id,
        folder,
      },
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to upload file', 
      detail: error.message || error.http_code || 'Unknown error'
    });
  }
});

router.delete('/image', authenticate, async (req, res) => {
  try {
    const { publicId } = req.body || {};

    if (!publicId || typeof publicId !== 'string') {
      return res.status(400).json({ success: false, message: 'publicId is required.' });
    }

    const result = await cloudinary.uploader.destroy(publicId, { resource_type: 'auto' });
    if (result.result === 'ok' || result.result === 'not found') {
      return res.json({ success: true, message: 'File removed from Cloudinary.' });
    }

    return res.status(500).json({ success: false, message: 'Cloudinary delete failed.', detail: result });
  } catch (error) {
    console.error('Cloudinary delete error:', error);
    return res.status(500).json({ success: false, message: 'Failed to delete file.' });
  }
});

module.exports = router;
