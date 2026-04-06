const { z } = require('zod');

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1, 'Password is required'),
});

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  name: z.string().min(2, 'Name is too short'),
  role: z.enum(['ADMIN', 'CAPTAIN', 'VICE_CAPTAIN', 'STRATEGIST', 'MANAGER', 'MEMBER']).optional(),
  department: z.string().optional(),
  regNo: z.string().optional(),
});

const googleLoginSchema = z.object({
  idToken: z.string().min(1, 'ID Token is required'),
});

module.exports = {
  loginSchema,
  registerSchema,
  googleLoginSchema,
};
