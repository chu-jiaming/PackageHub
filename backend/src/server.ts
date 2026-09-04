import { createApp } from './app.js'; import { env } from './config/env.js'; import { pool } from './db/pool.js';
async function main(){ if(!env.DATABASE_URL||!pool) throw new Error('DATABASE_URL is required; refusing to start without PostgreSQL'); await pool.query('SELECT 1'); await createApp().listen({port:env.PORT,host:'127.0.0.1'}); }
main().catch(()=>{console.error('server failed: PostgreSQL unavailable or DATABASE_URL missing');process.exitCode=1;});
