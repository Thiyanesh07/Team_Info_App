const CLOUDINARY_CONSOLE_HOST = 'console.cloudinary.com';
const CLOUDINARY_DELIVERY_HOST = 'res.cloudinary.com';

const validateAndNormalizeUrl = (value, fieldName = 'url') => {
  if (value === undefined || value === null) return value;

  if (typeof value !== 'string') {
    throw new Error(`${fieldName} must be a valid URL string`);
  }

  const normalized = value.trim();
  if (!normalized) return normalized;

  let parsed;
  try {
    parsed = new URL(normalized);
  } catch (_) {
    throw new Error(`${fieldName} must be a valid absolute URL`);
  }

  if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') {
    throw new Error(`${fieldName} must use http or https`);
  }

  const host = parsed.hostname.toLowerCase();

  if (host === CLOUDINARY_CONSOLE_HOST) {
    throw new Error(
      `${fieldName} cannot be a Cloudinary console URL. Use res.cloudinary.com delivery URL.`,
    );
  }

  if (host.endsWith('cloudinary.com') && host !== CLOUDINARY_DELIVERY_HOST) {
    throw new Error(
      `${fieldName} must be a direct Cloudinary delivery URL (res.cloudinary.com).`,
    );
  }

  return normalized;
};

module.exports = { validateAndNormalizeUrl };
