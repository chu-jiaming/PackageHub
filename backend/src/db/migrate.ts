import { readFile, readdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import pg from 'pg';
const url=process.env.TEST_DATABASE_URL||process.env.DATABASE_URL;
if(!url) throw new Error('TEST_DATABASE_URL or DATABASE_URL is required for migrations');
const client=new pg.Client({connectionString:url});
await client.connect();
try { const files=(await readdir(resolve('src/db/migrations'))).filter(f=>f.endsWith('.sql')).sort(); for(const file of files) await client.query(await readFile(resolve('src/db/migrations',file),'utf8')); } finally { await client.end(); }
