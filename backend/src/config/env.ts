import 'dotenv/config';
import { z } from 'zod';

export const env = z.object({
  DATABASE_URL: z.string().optional(), TEST_DATABASE_URL: z.string().optional(), APPLE_TEAM_ID: z.string().optional(), APPLE_KEY_ID: z.string().optional(),
  APPLE_CLIENT_ID: z.string().default('com.charm1ng.packagehub'), APPLE_PRIVATE_KEY: z.string().optional(),
  SESSION_JWT_SECRET: z.string().min(32).optional(), TOKEN_ENCRYPTION_KEY: z.string().min(32).optional(),
  PORT: z.coerce.number().default(8080),
}).parse(process.env);
