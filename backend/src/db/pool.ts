import pg from 'pg'; import { env } from '../config/env.js';
export const pool = env.DATABASE_URL ? new pg.Pool({connectionString:env.DATABASE_URL}) : null;
