const { z } = require('zod');

/**
 * Middleware to validate request data using Zod
 * @param {z.ZodSchema} schema 
 * @param {'body' | 'query' | 'params'} property 
 */
const validate = (schema, property = 'body') => (req, res, next) => {
  try {
    const validatedData = schema.parse(req[property]);
    // Replace original data with validated/sanitized data
    req[property] = validatedData;
    next();
  } catch (error) {
    if (error instanceof z.ZodError) {
      const errorMessages = error.errors.map((issue) => ({
        path: issue.path.join('.'),
        message: issue.message,
      }));
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errorMessages,
      });
    }
    next(error);
  }
};

module.exports = { validate };
