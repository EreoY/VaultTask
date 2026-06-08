const { DatabaseSync } = require('node:sqlite');
const path = require('node:path');

const dbPath = '/home/kimbiaw/calenda/calenda_flow/cloudflare_backend/.wrangler/state/v3/d1/miniflare-D1DatabaseObject/c101b2ca88decb0e8eba7d191b5f14c33dbcb563a7226f31769c7273a1758018.sqlite';

function main() {
  console.log(`Checking DB at: ${dbPath}\n`);
  try {
    const db = new DatabaseSync(dbPath);
    
    // Check messages with attachments
    const messages = db.prepare("SELECT id, session_id, text, attachments, timestamp FROM chat_messages WHERE attachments != '[]' ORDER BY timestamp DESC;").all();
    console.log('--- Chat Messages with Attachments ---');
    console.log(messages);
  } catch (err) {
    console.error('Error reading DB:', err);
  }
}

main();
