import 'dotenv/config';
import { z } from 'zod';

export const env = z.object({
  DATABASE_URL: z.string().optional(), TEST_DATABASE_URL: z.string().optional(), APPLE_TEAM_ID: z.string().optional(), APPLE_KEY_ID: z.string().optional(),
  APPLE_CLIENT_ID: z.string().default('com.charm1ng.packagehub'), APPLE_PRIVATE_KEY: z.string().optional(),
  SESSION_JWT_SECRET: z.string().min(32).optional(), TOKEN_ENCRYPTION_KEY: z.string().min(32).optional(),
  APP_STORE_ISSUER_ID: z.string().optional(), APP_STORE_KEY_ID: z.string().optional(), APP_STORE_PRIVATE_KEY: z.string().optional(),
  APP_STORE_BUNDLE_ID: z.string().default('com.charm1ng.packagehub'), APP_STORE_APP_APPLE_ID: z.coerce.number().optional(), APP_STORE_ROOT_CA_CERTS: z.string().optional(), APP_STORE_ENVIRONMENT: z.enum(['Sandbox','Production']).default('Sandbox'),
  PACKAGEHUB_PRO_PRODUCT_ID: z.string().default('packagehub.pro'), ENTITLEMENT_SIGNING_PRIVATE_KEY: z.string().optional(), ENTITLEMENT_SIGNING_KEY_ID: z.string().default('packagehub-entitlement'), ENTITLEMENT_TTL_HOURS: z.coerce.number().min(24).max(72).default(48),
  PORT: z.coerce.number().default(8080),
}).parse(process.env);
