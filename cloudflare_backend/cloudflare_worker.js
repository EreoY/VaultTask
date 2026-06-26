import { DurableObject } from "cloudflare:workers";

const nowMs = () => Date.now();

let schemaChecked = false;
async function ensureSchema(db) {
  if (schemaChecked) return;
  try {
    await db.prepare(`
      CREATE TABLE IF NOT EXISTS team_workspaces (
        id TEXT PRIMARY KEY,
        owner_uid TEXT NOT NULL,
        name TEXT NOT NULL,
        members TEXT DEFAULT '[]',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `).run();

    await db.prepare(`
      CREATE TABLE IF NOT EXISTS chat_sessions (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        task_id TEXT DEFAULT '',
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at INTEGER DEFAULT 0
      )
    `).run();

    await db.prepare(`
      CREATE TABLE IF NOT EXISTS chat_messages (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        text TEXT NOT NULL,
        reasoning TEXT DEFAULT '',
        is_user INTEGER NOT NULL,
        has_draft INTEGER DEFAULT 0,
        pending_call TEXT DEFAULT '',
        tool_calls TEXT DEFAULT '[]',
        attachments TEXT DEFAULT '[]',
        timestamp TEXT NOT NULL
      )
    `).run();

    await db.prepare(`
      CREATE TABLE IF NOT EXISTS task_comment_reads (
        comment_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        read_at INTEGER DEFAULT (strftime('%s','now')*1000),
        PRIMARY KEY (comment_id, user_id)
      )
    `).run();

    await db.prepare(`
      CREATE INDEX IF NOT EXISTS idx_task_comment_reads_user ON task_comment_reads(user_id)
    `).run();

    await db.prepare(`
      CREATE TABLE IF NOT EXISTS team_meetings (
        id TEXT PRIMARY KEY,
        board_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        notes TEXT DEFAULT '',
        start_at TEXT NOT NULL,
        end_at TEXT DEFAULT '',
        role_tags TEXT DEFAULT '[]',
        attachments TEXT DEFAULT '[]',
        transcript TEXT DEFAULT '',
        summary TEXT DEFAULT '',
        updated_at INTEGER DEFAULT (strftime('%s','now')*1000),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `).run();

    await db.prepare(`
      CREATE INDEX IF NOT EXISTS idx_team_meetings_board ON team_meetings(board_id)
    `).run();

    await db.prepare(`
      CREATE TABLE IF NOT EXISTS team_documents (
        id TEXT PRIMARY KEY,
        board_id TEXT NOT NULL,
        title TEXT NOT NULL,
        notes TEXT DEFAULT '',
        summary TEXT DEFAULT '',
        attachments TEXT DEFAULT '[]',
        updated_at INTEGER DEFAULT (strftime('%s','now')*1000),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `).run();

    await db.prepare(`
      CREATE INDEX IF NOT EXISTS idx_team_documents_board ON team_documents(board_id)
    `).run();

    try {
      await db.prepare(`ALTER TABLE team_boards ADD COLUMN workspace_id TEXT DEFAULT ''`).run();
    } catch (e) {
      // column already exists, ignore
    }
    try {
      await db.prepare(`ALTER TABLE team_boards ADD COLUMN documents TEXT DEFAULT '[]'`).run();
    } catch (e) {
      // ignore
    }
    try {
      await db.prepare(`ALTER TABLE team_tasks ADD COLUMN order_index INTEGER DEFAULT 0`).run();
    } catch (e) {
      // ignore
    }
    try {
      await db.prepare(`ALTER TABLE team_tasks ADD COLUMN comments TEXT DEFAULT '[]'`).run();
    } catch (e) {
      // ignore
    }
    try {
      await db.prepare(`ALTER TABLE team_tasks ADD COLUMN checklist TEXT DEFAULT '[]'`).run();
    } catch (e) {
      // ignore
    }
    schemaChecked = true;
  } catch (e) {
    console.error("Migration error:", e);
  }
}

export default {
  async fetch(request, env) {
    await ensureSchema(env.DB);
    const url = new URL(request.url);

    // CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: corsHeaders(),
      });
    }

    // WebSocket entry
    if (url.pathname === "/ws") {
      const boardId = url.searchParams.get("board_id");
      if (!boardId) return json({ error: "Missing board_id" }, 400);
      const upgrade = request.headers.get("Upgrade") || "";
      if (upgrade.toLowerCase() !== "websocket")
        return json({ error: "Expected websocket" }, 400);
      const id = env.BOARD_HUB.idFromName(boardId);
      const stub = env.BOARD_HUB.get(id);
      return stub.fetch(request);
    }
    
    // Deepgram Live STT WebSocket Proxy
    // Deepgram Live STT WebSocket Proxy
    if (url.pathname === "/api/meetings/stream-stt") {
      const upgrade = request.headers.get("Upgrade") || "";
      if (upgrade.toLowerCase() !== "websocket") {
        return json({ error: "Expected websocket" }, 400);
      }

      console.log("Stream-STT: Handshake request received. API Key present:", !!env.DEEPGRAM_API_KEY);
      
      // Use language=th to transcribe Thai accurately, and enable interim_results and low endpointing for real-time responsiveness using model=nova-3
      const deepgramUrl = "https://api.deepgram.com/v1/listen?model=nova-3&diarize=true&language=th&interim_results=true&endpointing=300";
      
      let deepgramResponse;
      try {
        deepgramResponse = await fetch(deepgramUrl, {
          headers: {
            "Upgrade": "websocket",
            "Authorization": `Token ${env.DEEPGRAM_API_KEY || ""}`
          }
        });
      } catch (err) {
        console.error("Stream-STT: Fetch to Deepgram failed:", err.message);
        return new Response("Deepgram handshake fetch failed: " + err.message, { status: 502 });
      }

      console.log("Stream-STT: Deepgram response status:", deepgramResponse.status);

      if (deepgramResponse.status !== 101) {
        const errorText = await deepgramResponse.text().catch(() => "No error details");
        console.error("Stream-STT: Deepgram handshake failed with status:", deepgramResponse.status, "body:", errorText);
        return new Response(`Deepgram handshake failed: ${deepgramResponse.status} - ${errorText}`, { status: 502 });
      }

      const deepgramSocket = deepgramResponse.webSocket;
      if (!deepgramSocket) {
        console.error("Stream-STT: Deepgram response webSocket object is null");
        return new Response("Failed to get Deepgram webSocket", { status: 502 });
      }

      // Keep track of connection close status via local booleans
      let clientClosed = false;
      let deepgramClosed = false;

      // Safe WebSocket closure helper to sanitize close codes and catch errors
      const getValidCloseCode = (code) => {
        const validCodes = [1000, 1001, 1002, 1003, 1008, 1009, 1010, 1011];
        const isCustom = code >= 3000 && code <= 4999;
        return (validCodes.includes(code) || isCustom) ? code : 1000;
      };

      const safeCloseClient = (code, reason) => {
        if (clientClosed) return;
        clientClosed = true;
        const validCode = getValidCloseCode(code);
        try {
          serverSocket.close(validCode, reason || "");
        } catch (e) {
          console.warn("Stream-STT: Error closing serverSocket:", e.message);
        }
      };

      const safeCloseDeepgram = (code, reason) => {
        if (deepgramClosed) return;
        deepgramClosed = true;
        const validCode = getValidCloseCode(code);
        try {
          deepgramSocket.close(validCode, reason || "");
        } catch (e) {
          console.warn("Stream-STT: Error closing deepgramSocket:", e.message);
        }
      };

      // Now create client/server local WebSocketPair
      const [clientSocket, serverSocket] = Object.values(new WebSocketPair());
      serverSocket.binaryType = "arraybuffer";
      deepgramSocket.binaryType = "arraybuffer";
      
      serverSocket.accept();
      deepgramSocket.accept();

      const onClientMessage = (event) => {
        console.log("Stream-STT: Worker received audio packet from client, size:", event.data ? (event.data.byteLength || event.data.size || event.data.length || "unknown") : 0);
        if (!deepgramClosed && event.data) {
          try {
            deepgramSocket.send(event.data);
          } catch (err) {
            console.error("Stream-STT: Failed to send data to Deepgram:", err.message);
            safeCloseDeepgram(1011, "Send failed");
          }
        }
      };
      
      const onDeepgramMessage = (event) => {
        if (!clientClosed && event.data) {
          try {
            serverSocket.send(event.data);
          } catch (err) {
            console.error("Stream-STT: Failed to send data to client:", err.message);
            safeCloseClient(1011, "Send failed");
          }
        }
      };

      const cleanup = () => {
        try {
          serverSocket.removeEventListener("message", onClientMessage);
          deepgramSocket.removeEventListener("message", onDeepgramMessage);
          serverSocket.removeEventListener("close", onClientClose);
          deepgramSocket.removeEventListener("close", onDeepgramClose);
          serverSocket.removeEventListener("error", onClientError);
          deepgramSocket.removeEventListener("error", onDeepgramError);
        } catch (e) {
          console.error("Stream-STT: Error during listener cleanup:", e);
        }
      };
      
      const onClientClose = (event) => {
        console.log("Stream-STT: Client connection closed. Code:", event.code, "Reason:", event.reason);
        cleanup();
        safeCloseClient(event.code, event.reason);
        safeCloseDeepgram(event.code, event.reason);
      };
      
      const onDeepgramClose = (event) => {
        console.log("Stream-STT: Deepgram connection closed. Code:", event.code, "Reason:", event.reason);
        cleanup();
        safeCloseClient(event.code, event.reason);
        safeCloseDeepgram(event.code, event.reason);
      };
      
      const onClientError = (err) => {
        console.error("Stream-STT: Client WebSocket error:", err);
        cleanup();
        safeCloseClient(1011, "Client error");
        safeCloseDeepgram(1011, "Client error");
      };
      
      const onDeepgramError = (err) => {
        console.error("Stream-STT: Deepgram WebSocket error:", err);
        try {
          if (!clientClosed) {
            serverSocket.send(JSON.stringify({ error: "Deepgram error: " + (err.message || "Unknown error") }));
          }
        } catch(e) {}
        cleanup();
        safeCloseClient(1011, "Deepgram error");
        safeCloseDeepgram(1011, "Deepgram error");
      };

      serverSocket.addEventListener("message", onClientMessage);
      deepgramSocket.addEventListener("message", onDeepgramMessage);
      serverSocket.addEventListener("close", onClientClose);
      deepgramSocket.addEventListener("close", onDeepgramClose);
      serverSocket.addEventListener("error", onClientError);
      deepgramSocket.addEventListener("error", onDeepgramError);

      return new Response(null, {
        status: 101,
        webSocket: clientSocket,
        headers: {
          "Upgrade": "websocket",
          "Connection": "Upgrade"
        }
      });
    }

    // CHAT SESSIONS ───────────────────────────
    if (url.pathname === "/api/chat/sessions" && request.method === "GET") {
      try {
        const uid = url.searchParams.get("uid");
        const taskId = url.searchParams.get("task_id") || "";
        if (!uid) return json({ error: "Missing uid" }, 400);
        const { results } = await env.DB.prepare(
          `SELECT * FROM chat_sessions WHERE uid = ? AND task_id = ? ORDER BY updated_at DESC`
        ).bind(uid, taskId).all();
        return json(results);
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/chat/sessions" && request.method === "POST") {
      try {
        const { id, uid, name, task_id } = await request.json();
        if (!id || !uid || !name) return json({ error: "Missing required fields" }, 400);
        const now = nowMs();
        const taskId = task_id || "";
        await env.DB.prepare(
          `INSERT INTO chat_sessions (id, uid, task_id, name, created_at, updated_at)
           VALUES (?, ?, ?, ?, datetime('now'), ?)
           ON CONFLICT(id) DO UPDATE SET name=excluded.name, updated_at=excluded.updated_at`
        ).bind(id, uid, taskId, name, now).run();
        return json({ success: true, id });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/chat/sessions" && request.method === "DELETE") {
      try {
        const id = url.searchParams.get("id");
        if (!id) return json({ error: "Missing id" }, 400);
        await env.DB.prepare(`DELETE FROM chat_messages WHERE session_id = ?`).bind(id).run();
        await env.DB.prepare(`DELETE FROM chat_sessions WHERE id = ?`).bind(id).run();
        return json({ success: true });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    // CHAT MESSAGES ───────────────────────────
    if (url.pathname === "/api/chat/messages" && request.method === "GET") {
      try {
        const sessionId = url.searchParams.get("session_id");
        if (!sessionId) return json({ error: "Missing session_id" }, 400);
        const { results } = await env.DB.prepare(
          `SELECT * FROM chat_messages WHERE session_id = ? ORDER BY timestamp ASC`
        ).bind(sessionId).all();
        return json(results);
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/chat/messages" && request.method === "POST") {
      try {
        const msg = await request.json();
        const { id, session_id, text, reasoning, is_user, has_draft, pending_call, tool_calls, attachments, timestamp } = msg;
        if (!id || !session_id || text === undefined) return json({ error: "Missing fields" }, 400);
        
        await env.DB.prepare(
          `INSERT OR REPLACE INTO chat_messages (id, session_id, text, reasoning, is_user, has_draft, pending_call, tool_calls, attachments, timestamp)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
        ).bind(
          id,
          session_id,
          text,
          reasoning || "",
          is_user ? 1 : 0,
          has_draft ? 1 : 0,
          pending_call || "",
          tool_calls || "[]",
          attachments || "[]",
          timestamp
        ).run();

        // Also update session updated_at
        await env.DB.prepare(
          `UPDATE chat_sessions SET updated_at = ? WHERE id = ?`
        ).bind(nowMs(), session_id).run();

        return json({ success: true });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    // USERS ──────────────────────────────────
    if (url.pathname === "/api/users" && request.method === "POST") {
      try {
        const { uid, email, display_name, photo_url } = await request.json();
        await env.DB.prepare(
          `INSERT INTO users (uid, email, display_name, photo_url)
           VALUES (?, ?, ?, ?)
           ON CONFLICT(uid) DO UPDATE SET email=excluded.email, display_name=excluded.display_name, photo_url=excluded.photo_url`,
        )
          .bind(uid, email, display_name, photo_url || null)
          .run();
        return json({ success: true });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    // PUT /api/users — update display_name or photo_url
    if (url.pathname === "/api/users" && request.method === "PUT") {
      try {
        const { uid, display_name, photo_url } = await request.json();
        if (!uid) return json({ error: "Missing uid" }, 400);
        
        let query = "UPDATE users SET ";
        let params = [];
        if (display_name !== undefined) {
          query += "display_name = ?, ";
          params.push(display_name);
        }
        if (photo_url !== undefined) {
          query += "photo_url = ?, ";
          params.push(photo_url);
        }
        query = query.slice(0, -2) + " WHERE uid = ?";
        params.push(uid);

        await env.DB.prepare(query).bind(...params).run();
        return json({ success: true });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    // GET /api/users?uids=uid1,uid2,...
    if (url.pathname === "/api/users" && request.method === "GET") {
      try {
        const uidsParam = url.searchParams.get("uids");
        if (!uidsParam) return json({ error: "Missing uids" }, 400);
        const uids = uidsParam.split(",").map(u => u.trim()).filter(Boolean);
        if (uids.length === 0) return json([]);
        const placeholders = uids.map(() => "?").join(",");
        const { results } = await env.DB.prepare(
          `SELECT uid, display_name, email, photo_url FROM users WHERE uid IN (${placeholders})`
        ).bind(...uids).all();
        return json(results);
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    // COMMENT READS ───────────────────────────
    if (url.pathname === "/api/comments/reads" && request.method === "GET") {
      try {
        const uid = url.searchParams.get("uid");
        if (!uid) return json({ error: "Missing uid" }, 400);
        const { results } = await env.DB.prepare(
          `SELECT comment_id FROM task_comment_reads WHERE user_id = ?`
        ).bind(uid).all();
        return json(results.map(r => r.comment_id));
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/comments/read" && request.method === "POST") {
      try {
        const { uid, comment_ids } = await request.json();
        if (!uid || !comment_ids || !Array.isArray(comment_ids)) {
          return json({ error: "Missing uid or comment_ids array" }, 400);
        }
        if (comment_ids.length > 0) {
          const stmt = env.DB.prepare(
            `INSERT OR IGNORE INTO task_comment_reads (comment_id, user_id) VALUES (?, ?)`
          );
          const batch = comment_ids.map(id => stmt.bind(id, uid));
          await env.DB.batch(batch);
        }
        return json({ success: true });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    // WORKSPACES ──────────────────────────────
    if (url.pathname === "/api/workspaces" && request.method === "GET") {
      try {
        const uid = url.searchParams.get("uid");
        if (!uid) return json({ error: "Missing uid" }, 400);
        const { results } = await env.DB.prepare(
          `SELECT * FROM team_workspaces WHERE owner_uid = ? OR members LIKE ? ORDER BY created_at DESC`
        ).bind(uid, `%${uid}%`).all();
        return json(results);
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/workspaces" && request.method === "POST") {
      try {
        const { id, owner_uid, name, members } = await request.json();
        if (!id || !owner_uid || !name) return json({ error: "Missing required fields" }, 400);
        await env.DB.prepare(
          `INSERT INTO team_workspaces (id, owner_uid, name, members) VALUES (?, ?, ?, ?)
           ON CONFLICT(id) DO UPDATE SET name=excluded.name, members=excluded.members`
        ).bind(id, owner_uid, name, JSON.stringify(members || [owner_uid])).run();
        return json({ success: true, id }, 201);
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/workspaces" && request.method === "DELETE") {
      try {
        const id = url.searchParams.get("id");
        if (!id) return json({ error: "Missing id" }, 400);
        const { results: boards } = await env.DB.prepare(`SELECT id FROM team_boards WHERE workspace_id = ?`).bind(id).all();
        for (const board of boards) {
          await env.DB.prepare(`DELETE FROM team_tasks WHERE board_id = ?`).bind(board.id).run();
          await env.DB.prepare(`DELETE FROM team_meetings WHERE board_id = ?`).bind(board.id).run();
          await env.DB.prepare(`DELETE FROM team_boards WHERE id = ?`).bind(board.id).run();
        }
        await env.DB.prepare(`DELETE FROM team_workspaces WHERE id = ?`).bind(id).run();
        return json({ success: true });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    // BOARDS ─────────────────────────────────
    if (url.pathname === "/api/boards" && request.method === "GET") {
      try {
        const uid = url.searchParams.get("uid");
        const id = url.searchParams.get("id");
        
        if (id) {
          const board = await env.DB.prepare(`SELECT * FROM team_boards WHERE id = ?`).bind(id).first();
          if (!board) return json({ error: "Board not found" }, 404);
          return json(board);
        }

        if (!uid) return json({ error: "Missing uid" }, 400);
        const { results } = await env.DB.prepare(
          `SELECT * FROM team_boards 
           WHERE owner_uid = ? 
              OR members LIKE ? 
              OR (workspace_id IS NOT NULL AND workspace_id != '' AND workspace_id IN (
                  SELECT id FROM team_workspaces WHERE owner_uid = ? OR members LIKE ?
              ))
           ORDER BY created_at DESC`,
        )
          .bind(uid, `%${uid}%`, uid, `%${uid}%`)
          .all();
        return json(results);
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/boards" && request.method === "POST") {
      try {
        const { id, owner_uid, name, color, members, member_roles, columns, labels, workspace_id, documents } =
          await request.json();
        if (!id || !owner_uid || !name)
          return json({ error: "Missing required fields" }, 400);
        const now = nowMs();
        await env.DB.prepare(
          `INSERT INTO team_boards (id, owner_uid, name, color, members, member_roles, columns, labels, workspace_id, documents, updated_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        )
          .bind(
            id,
            owner_uid,
            name,
            color || 0,
            JSON.stringify(members || [owner_uid]),
            JSON.stringify(member_roles || {}),
            JSON.stringify(columns || ["todo", "doing", "done"]),
            JSON.stringify(labels || []),
            workspace_id || "",
            JSON.stringify(documents || []),
            now,
          )
          .run();
        await notifyBoard(env, id, {
          kind: "board_update",
          boardId: id,
          at: now,
        });
        return json({ success: true, id }, 201);
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/boards" && request.method === "PUT") {
      try {
        const { id, name, color, members, member_roles, columns, labels, workspace_id, documents } =
          await request.json();
        if (!id) return json({ error: "Missing id" }, 400);
        const now = nowMs();
        await env.DB.prepare(
          `UPDATE team_boards SET name=?, color=?, members=?, member_roles=?, columns=?, labels=?, workspace_id=?, documents=?, updated_at=? WHERE id=?`,
        )
          .bind(
            name,
            color,
            JSON.stringify(members || []),
            JSON.stringify(member_roles || {}),
            JSON.stringify(columns || []),
            JSON.stringify(labels || []),
            workspace_id || "",
            JSON.stringify(documents || []),
            now,
            id,
          )
          .run();
        await notifyBoard(env, id, {
          kind: "board_update",
          boardId: id,
          at: now,
        });
        return json({ success: true });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/boards_join" && request.method === "POST") {
      try {
        const { id, uid } = await request.json();
        if (!id || !uid) return json({ error: "Missing id or uid" }, 400);
        const boardRow = await env.DB.prepare(
          `SELECT * FROM team_boards WHERE id = ?`,
        )
          .bind(id)
          .first();
        if (!boardRow) return json({ error: "Board not found" }, 404);

        const members = boardRow.members ? JSON.parse(boardRow.members) : [];
        if (!members.includes(uid)) {
          members.push(uid);
          await env.DB.prepare(
            `UPDATE team_boards SET members=?, updated_at=? WHERE id=?`,
          )
            .bind(JSON.stringify(members), nowMs(), id)
            .run();
        }
        const updated = await env.DB.prepare(
          `SELECT * FROM team_boards WHERE id = ?`,
        )
          .bind(id)
          .first();
        await notifyBoard(env, id, {
          kind: "board_update",
          boardId: id,
          at: nowMs(),
        });
        return json(updated);
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/workspaces_join" && request.method === "POST") {
      try {
        const { id, uid } = await request.json();
        if (!id || !uid) return json({ error: "Missing id or uid" }, 400);
        const wsRow = await env.DB.prepare(
          `SELECT * FROM team_workspaces WHERE id = ?`,
        )
          .bind(id)
          .first();
        if (!wsRow) return json({ error: "Workspace not found" }, 404);

        const members = wsRow.members ? JSON.parse(wsRow.members) : [];
        if (!members.includes(uid)) {
          members.push(uid);
          await env.DB.prepare(
            `UPDATE team_workspaces SET members=? WHERE id=?`,
          )
            .bind(JSON.stringify(members), id)
            .run();
        }
        const updated = await env.DB.prepare(
          `SELECT * FROM team_workspaces WHERE id = ?`,
        )
          .bind(id)
          .first();
        return json(updated);
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }


    if (url.pathname === "/api/boards_remove_member" && request.method === "POST") {
      try {
        const { id, uid } = await request.json();
        if (!id || !uid) return json({ error: "Missing id or uid" }, 400);
        const boardRow = await env.DB.prepare(
          `SELECT * FROM team_boards WHERE id = ?`,
        )
          .bind(id)
          .first();
        if (!boardRow) return json({ error: "Board not found" }, 404);

        let members = boardRow.members ? JSON.parse(boardRow.members) : [];
        if (members.includes(uid)) {
          members = members.filter(m => m !== uid);
          await env.DB.prepare(
            `UPDATE team_boards SET members=?, updated_at=? WHERE id=?`,
          )
            .bind(JSON.stringify(members), nowMs(), id)
            .run();
        }
        await notifyBoard(env, id, {
          kind: "board_update",
          boardId: id,
          at: nowMs(),
        });
        return json({ success: true });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/boards" && request.method === "DELETE") {
      try {
        const id = url.searchParams.get("id");
        if (!id) return json({ error: "Missing id" }, 400);
        await env.DB.prepare(`DELETE FROM team_tasks WHERE board_id = ?`)
          .bind(id)
          .run();
        await env.DB.prepare(`DELETE FROM team_meetings WHERE board_id = ?`)
          .bind(id)
          .run();
        await env.DB.prepare(`DELETE FROM team_boards WHERE id = ?`)
          .bind(id)
          .run();
        await notifyBoard(env, id, {
          kind: "board_update",
          boardId: id,
          at: nowMs(),
        });
        return json({ success: true });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    // IMAGES (R2) ───────────────────────────
    if (url.pathname.startsWith("/api/images/") && request.method === "GET") {
      try {
        const key = url.pathname.replace("/api/images/", "");
        const object = await env.ASSETS.get(key);
        if (!object) return json({ error: "Image not found" }, 404);
        const headers = new Headers();
        object.writeHttpMetadata(headers);
        headers.set("Access-Control-Allow-Origin", "*");
        headers.set("etag", object.httpEtag);
        return new Response(object.body, { headers });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/upload" && request.method === "POST") {
      try {
        const contentType = request.headers.get("content-type");
        if (!contentType || !contentType.includes("multipart/form-data")) {
          return json({ error: "Expected multipart/form-data" }, 400);
        }
        const formData = await request.formData();
        const file = formData.get("file");
        const uid = formData.get("uid");
        const folder = formData.get("folder") || "uploads";
        if (!file || !uid) return json({ error: "Missing file or uid" }, 400);

        const filename = typeof file === "string" ? "image.jpg" : (file.name || "image.jpg");
        const fileContentType = typeof file === "string" ? "image/jpeg" : (file.type || "image/jpeg");
        const extension = filename.split(".").pop();
        const key = `${folder}/${uid}/${crypto.randomUUID()}.${extension}`;

        const buffer = await (typeof file === "string" ? new TextEncoder().encode(file) : file.arrayBuffer());

        await env.ASSETS.put(key, buffer, {
          httpMetadata: { contentType: fileContentType },
        });

        const absoluteUrl = `${url.protocol}//${url.host}/api/images/${key}`;

        return json({ success: true, key, url: absoluteUrl });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    // MEETING TRANSCRIBE (Deepgram pre-recorded) ──────────────
    // POST /api/meetings/transcribe-file  (DEEPGRAM_API_KEY never leaves the worker)
    //  • URL mode   (PRIMARY, large files): Content-Type: application/json
    //                body { url, language, meetingId } → Deepgram fetches R2 itself.
    //  • bytes mode (SECONDARY, small/local): Content-Type: <audio|video mime>
    //                raw binary body, ?language=&meetingId= → worker forwards bytes.
    if (url.pathname === "/api/meetings/transcribe-file" && request.method === "POST") {
      const reqContentType = request.headers.get("content-type") || "";
      const isUrlMode = reqContentType.includes("application/json");
      // bytes-mode guard: keep well under the worker ~100MB request-body cap.
      const MAX_BYTES = 90 * 1024 * 1024;

      try {
        let language = url.searchParams.get("language") || "th";
        let meetingId = url.searchParams.get("meetingId") || "";
        let deepgramBody;
        let deepgramContentType;
        let logUrl = "";
        let logSize = 0;

        if (isUrlMode) {
          let payload;
          try {
            payload = await request.json();
          } catch (e) {
            console.error("[Meeting][Transcribe][Error] Invalid JSON body:", e.message);
            return json({ success: false, error: "Invalid JSON body" }, 400);
          }
          const mediaUrl = payload && payload.url;
          if (!mediaUrl) {
            return json({ success: false, error: "Missing url" }, 400);
          }
          language = payload.language || language;
          meetingId = payload.meetingId || meetingId;
          logUrl = mediaUrl;
          deepgramContentType = "application/json";
          deepgramBody = JSON.stringify({ url: mediaUrl });
          console.log(`[Meeting][Transcribe] mode=url meetingId=${meetingId} language=${language} url=${logUrl}`);
        } else {
          const buffer = await request.arrayBuffer();
          logSize = buffer.byteLength;
          if (logSize === 0) {
            return json({ success: false, error: "Missing audio body" }, 400);
          }
          if (logSize > MAX_BYTES) {
            console.error(`[Meeting][Transcribe][Error] bytes-mode oversized size=${logSize} limit=${MAX_BYTES}`);
            return json({ success: false, error: "File exceeds bytes-mode limit; use URL mode" }, 413);
          }
          deepgramContentType = reqContentType || "application/octet-stream";
          deepgramBody = buffer;
          console.log(`[Meeting][Transcribe] mode=bytes meetingId=${meetingId} language=${language} size=${logSize} contentType=${deepgramContentType}`);
        }

        const deepgramUrl =
          `https://api.deepgram.com/v1/listen?model=nova-3&language=${encodeURIComponent(language || "th")}` +
          `&diarize=true&utterances=true&punctuate=true&smart_format=true`;

        const dgStart = Date.now();
        let dgResponse;
        try {
          dgResponse = await fetch(deepgramUrl, {
            method: "POST",
            headers: {
              "Authorization": `Token ${env.DEEPGRAM_API_KEY || ""}`,
              "Content-Type": deepgramContentType,
            },
            body: deepgramBody,
          });
        } catch (err) {
          console.error(`[Meeting][Transcribe][Error] Deepgram fetch failed: ${err.message}`);
          return json({ success: false, error: "Deepgram request failed: " + err.message }, 502);
        }

        const elapsedMs = Date.now() - dgStart;

        if (!dgResponse.ok) {
          const errBody = await dgResponse.text().catch(() => "no body");
          console.error(`[Meeting][Transcribe][Error] Deepgram status=${dgResponse.status} elapsedMs=${elapsedMs} body=${errBody}`);
          return json({ success: false, error: `Deepgram failed: ${dgResponse.status} ${errBody}` }, 502);
        }

        const result = await dgResponse.json();
        // High-verbosity success log — duration is the billing basis (cost proxy); API key never logged.
        const meta = (result && result.metadata) || {};
        const audioDuration = meta.duration != null ? meta.duration : "n/a";
        const channelCount = meta.channels != null ? meta.channels : "n/a";
        const requestId = meta.request_id || "n/a";
        const utteranceCount =
          result && result.results && Array.isArray(result.results.utterances)
            ? result.results.utterances.length
            : 0;
        console.log(
          `[Meeting][Transcribe] success mode=${isUrlMode ? "url" : "bytes"} elapsedMs=${elapsedMs} ` +
          `audioDuration=${audioDuration}s channels=${channelCount} utterances=${utteranceCount} requestId=${requestId}` +
          `${logUrl ? ` url=${logUrl}` : ""}${logSize ? ` size=${logSize}` : ""}`,
        );

        return json({ success: true, mode: isUrlMode ? "url" : "bytes", result });
      } catch (err) {
        console.error(`[Meeting][Transcribe][Error] Unexpected: ${err.message}`);
        return json({ success: false, error: err.message }, 500);
      }
    }

    // TASKS ──────────────────────────────────
    if (url.pathname === "/api/tasks" && request.method === "GET") {
      try {
        const board_id = url.searchParams.get("board_id");
        if (!board_id) return json({ error: "Missing board_id" }, 400);
        const { results } = await env.DB.prepare(
          `SELECT * FROM team_tasks WHERE board_id = ? ORDER BY order_index ASC, due_date ASC`,
        )
          .bind(board_id)
          .all();
        return json(results);
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/tasks" && request.method === "POST") {
      try {
        const taskData = await request.json();
        const {
          id,
          board_id,
          author_uid,
          title,
          due_date,
          members,
          label_ids,
          status,
          description,
          is_completed,
          checklist,
          images,
          order_index,
          comments,
        } = taskData;
        if (!id || !board_id || !author_uid || !title || !due_date)
          return json({ error: "Missing fields" }, 400);
        const numericId = Number(id);
        const taskId = Number.isFinite(numericId) ? numericId : nowMs();
        const complete = is_completed ? 1 : 0;
        const now = nowMs();
        await env.DB.prepare(
          `INSERT INTO team_tasks (id, board_id, author_uid, title, description, due_date, members, label_ids, status, is_completed, checklist, images, updated_at, order_index, comments)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        )
          .bind(
            taskId,
            board_id,
            author_uid,
            title,
            description || "",
            due_date,
            JSON.stringify(members || []),
            JSON.stringify(label_ids || []),
            status || "todo",
            complete,
            JSON.stringify(checklist || []),
            JSON.stringify(images || []),
            now,
            order_index || 0,
            JSON.stringify(comments || []),
          )
          .run();
        
        // 🚀 Task 60.1/61.3: Instant Payload (Construct from input to avoid DB Round-trip)
        const constructedTask = {
           ...taskData,
           id: taskId,
           is_completed: complete,
           updated_at: now,
           members: members || [],
           label_ids: label_ids || [],
           checklist: checklist || [],
           images: images || [],
           comments: comments || [],
         };
         
        await notifyBoard(env, board_id, {
          kind: "task_update",
          boardId: board_id,
          task: constructedTask,
          at: now,
        });
        return json({ success: true, id: taskId }, 201);
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/tasks" && request.method === "PUT") {
      try {
        const taskData = await request.json();
        const { id, board_id, is_completed, members, label_ids, checklist, images, comments } = taskData;
        if (!id) return json({ error: "Missing id" }, 400);
        
        const complete = is_completed ? 1 : 0;
        const now = nowMs();
        
        // 🚀 Task 64.1: Perform update with provided fields
        await env.DB.prepare(
          `UPDATE team_tasks SET title=?, description=?, due_date=?, members=?, label_ids=?, status=?, is_completed=?, checklist=?, images=?, updated_at=?, order_index=?, comments=? WHERE id=?`
        ).bind(
          taskData.title, taskData.description, taskData.due_date,
          JSON.stringify(members || []), JSON.stringify(label_ids || []),
          taskData.status, complete, JSON.stringify(checklist || []), JSON.stringify(images || []), now,
          taskData.order_index || 0, JSON.stringify(comments || []), id
        ).run();

        // 🚀 Task 64.1: Authoritative WebSocket Broadcast (Zero DB Select)
        const finalBoardId = board_id || taskData.boardId;
        if (finalBoardId) {
          await notifyBoard(env, finalBoardId, {
            kind: "task_update",
            taskId: id,
            boardId: finalBoardId,
            task: { ...taskData, is_completed: complete, updated_at: now, 
                    members: members || [], 
                    label_ids: label_ids || [], 
                    checklist: checklist || [],
                    images: images || [],
                    comments: comments || [] },
            at: now,
          });
        }
        return json({ success: true });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/tasks_order" && request.method === "PUT") {
      try {
        const { board_id, updates } = await request.json();
        if (!board_id || !Array.isArray(updates)) return json({ error: "Missing fields" }, 400);
        
        if (updates.length === 0) return json({ success: true });
        
        let query = `UPDATE team_tasks SET order_index = CASE id `;
        let ids = [];
        updates.forEach(u => {
          query += `WHEN '${u.id}' THEN ${u.order_index} `;
          ids.push(`'${u.id}'`);
        });
        query += `END, updated_at = ${nowMs()} WHERE id IN (${ids.join(',')}) AND board_id = '${board_id}'`;
        
        await env.DB.prepare(query).run();
        
        const { results: updatedTasks } = await env.DB.prepare(
          `SELECT * FROM team_tasks WHERE id IN (${ids.join(',')})`
        ).all();

        await notifyBoard(env, board_id, {
          kind: "task_update_bulk",
          boardId: board_id,
          tasks: updatedTasks,
          at: nowMs(),
        });
        return json({ success: true });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/tasks_status" && request.method === "PUT") {
      try {
        const { id, status, board_id } = await request.json();
        if (!id) return json({ error: "Missing id" }, 400);
        const now = nowMs();
        
        await env.DB.prepare(`UPDATE team_tasks SET status=?, updated_at=? WHERE id=?`)
          .bind(status, now, id).run();

        // 🚀 Task 64.1: Instant Broadcast with specific board_id (No Select)
        if (board_id) {
          await notifyBoard(env, board_id, {
            kind: "task_update",
            taskId: id,
            boardId: board_id,
            task: { id, status, updated_at: now }, // Delta payload
            at: now,
          });
        }
        return json({ success: true });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/tasks" && request.method === "DELETE") {
      try {
        const id = url.searchParams.get("id");
        if (!id) return json({ error: "Missing id" }, 400);
        const row = await env.DB.prepare(
          `SELECT board_id FROM team_tasks WHERE id=?`,
        )
          .bind(id)
          .first();
        await env.DB.prepare(`DELETE FROM team_tasks WHERE id = ?`)
          .bind(id)
          .run();
        if (row?.board_id) {
          await notifyBoard(env, row.board_id, {
            kind: "task_delete",
            taskId: id,
            boardId: row.board_id,
            at: nowMs(),
          });
        }
        return json({ success: true });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/meetings" && request.method === "GET") {
      try {
        const board_id = url.searchParams.get("board_id");
        if (!board_id) return json({ error: "Missing board_id" }, 400);
        const { results } = await env.DB.prepare(
          `SELECT * FROM team_meetings WHERE board_id = ? ORDER BY start_at ASC`,
        )
          .bind(board_id)
          .all();
        return json(results);
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/meetings" && request.method === "POST") {
      try {
        const {
          id,
          board_id,
          title,
          description,
          notes,
          start_at,
          end_at,
          role_tags,
          attachments,
          transcript,
          summary,
        } = await request.json();
        if (!id || !board_id || !title || !start_at)
          return json({ error: "Missing required fields" }, 400);
        const now = nowMs();
        await env.DB.prepare(
          `INSERT INTO team_meetings (id, board_id, title, description, notes, start_at, end_at, role_tags, attachments, transcript, summary, updated_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        )
          .bind(
            id,
            board_id,
            title,
            description || "",
            notes || "",
            start_at,
            end_at || "",
            JSON.stringify(role_tags || []),
            JSON.stringify(attachments || []),
            transcript || "",
            summary || "",
            now,
          )
          .run();
        return json({ success: true, id }, 201);
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/meetings" && request.method === "PUT") {
      try {
        const {
          id,
          title,
          description,
          notes,
          start_at,
          end_at,
          role_tags,
          attachments,
          transcript,
          summary,
        } = await request.json();
        if (!id) return json({ error: "Missing id" }, 400);
        await env.DB.prepare(
          `UPDATE team_meetings SET title=?, description=?, notes=?, start_at=?, end_at=?, role_tags=?, attachments=?, transcript=?, summary=?, updated_at=? WHERE id=?`,
        )
          .bind(
            title,
            description || "",
            notes || "",
            start_at,
            end_at || "",
            JSON.stringify(role_tags || []),
            JSON.stringify(attachments || []),
            transcript || "",
            summary || "",
            nowMs(),
            id,
          )
          .run();
        return json({ success: true });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/meetings" && request.method === "DELETE") {
      try {
        const id = url.searchParams.get("id");
        if (!id) return json({ error: "Missing id" }, 400);
        await env.DB.prepare(`DELETE FROM team_meetings WHERE id = ?`)
          .bind(id)
          .run();
        return json({ success: true });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    // DOCUMENTS ──────────────────────────────
    if (url.pathname === "/api/documents" && request.method === "GET") {
      try {
        const board_id = url.searchParams.get("board_id");
        if (!board_id) return json({ error: "Missing board_id" }, 400);
        const { results } = await env.DB.prepare(
          `SELECT * FROM team_documents WHERE board_id = ? ORDER BY created_at DESC`,
        )
          .bind(board_id)
          .all();
        return json(results);
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/documents" && request.method === "POST") {
      try {
        const { id, board_id, title, notes, attachments, summary } =
          await request.json();
        if (!id || !board_id || !title)
          return json({ error: "Missing required fields" }, 400);
        const now = nowMs();
        await env.DB.prepare(
          `INSERT INTO team_documents (id, board_id, title, notes, summary, attachments, updated_at)
           VALUES (?, ?, ?, ?, ?, ?, ?)`,
        )
          .bind(
            id,
            board_id,
            title,
            notes || "",
            summary || "",
            JSON.stringify(attachments || []),
            now,
          )
          .run();
        return json({ success: true, id }, 201);
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/documents" && request.method === "PUT") {
      try {
        const { id, title, notes, attachments, summary } =
          await request.json();
        if (!id) return json({ error: "Missing id" }, 400);
        await env.DB.prepare(
          `UPDATE team_documents SET title=?, notes=?, summary=?, attachments=?, updated_at=? WHERE id=?`,
        )
          .bind(
            title,
            notes || "",
            summary || "",
            JSON.stringify(attachments || []),
            nowMs(),
            id,
          )
          .run();
        return json({ success: true });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    if (url.pathname === "/api/documents" && request.method === "DELETE") {
      try {
        const id = url.searchParams.get("id");
        if (!id) return json({ error: "Missing id" }, 400);
        await env.DB.prepare(`DELETE FROM team_documents WHERE id = ?`)
          .bind(id)
          .run();
        return json({ success: true });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    // DELTA ──────────────────────────────────
    if (url.pathname === "/api/tasks_delta" && request.method === "GET") {
      try {
        const board_id = url.searchParams.get("board_id");
        const since = parseInt(url.searchParams.get("since") || "0", 10);
        if (!board_id) return json({ error: "Missing board_id" }, 400);
        const { results } = await env.DB.prepare(
          `SELECT * FROM team_tasks WHERE board_id = ? AND updated_at > ? ORDER BY updated_at ASC`,
        )
          .bind(board_id, since)
          .all();
        const maxUpdated = results?.length
          ? Math.max(...results.map((r) => r.updated_at || since))
          : since;
        return json({ tasks: results, maxUpdated });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    // DOWNLOADS ─────────────────────────────
    if (url.pathname === "/api/download" && request.method === "GET") {
      try {
        const platform = url.searchParams.get("platform");
        if (!platform) return json({ error: "Missing platform" }, 400);

        const { results } = await env.DB.prepare(
          `SELECT data FROM app_binaries WHERE platform = ? ORDER BY chunk_index ASC`
        ).bind(platform).all();

        if (!results || results.length === 0) {
          return json({ error: "Binary not found for this platform" }, 404);
        }

        const totalSize = results.reduce((acc, row) => acc + row.data.byteLength, 0);
        const combined = new Uint8Array(totalSize);
        let offset = 0;
        for (const row of results) {
          combined.set(new Uint8Array(row.data), offset);
          offset += row.data.byteLength;
        }

        return new Response(combined, {
          headers: {
            ...corsHeaders(),
            "Content-Type": "application/octet-stream",
            "Content-Disposition": `attachment; filename="calenda-${platform}.zip"`,
          },
        });
      } catch (err) {
        return json({ error: err.message }, 500);
      }
    }

    // AI PROXY ─────────────────────────────
    if (url.pathname === "/api/ai/chat" && request.method === "POST") {
      try {
        const body = await request.json();
        const { model, messages, tools, uid, stream, session_id, assistant_message_id } = body;
        
        let userQuestion = "";
        if (messages && messages.length > 0) {
          for (let i = messages.length - 1; i >= 0; i--) {
            if (messages[i].role === "user") {
              const content = messages[i].content;
              if (typeof content === "string") {
                userQuestion = content;
              } else if (Array.isArray(content)) {
                const textPart = content.find(part => part.type === "text");
                userQuestion = textPart ? textPart.text : "";
              }
              break;
            }
          }
        }

        console.log(`\n🤖 [AI CHAT] Request received - User: ${uid}`);
        console.log(`🤖 [AI CHAT] Messages count: ${messages ? messages.length : 0}`);
        console.log(`🤖 [AI CHAT] User Question: "${userQuestion.trim().replace(/\n/g, ' ')}"`);
        if (tools && tools.length > 0) {
          console.log(`🤖 [AI CHAT] Tools offered: ${tools.map(t => t.function.name).join(", ")}`);
        } else {
          console.log(`🤖 [AI CHAT] No tools offered.`);
        }
        
        if (!uid) {
          console.warn(`⚠️ [AI CHAT] Unauthorized - No UID provided`);
          return json({ error: "Unauthorized" }, 401);
        }
        const user = await env.DB.prepare("SELECT uid FROM users WHERE uid = ?").bind(uid).first();
        if (!user) {
          console.warn(`⚠️ [AI CHAT] Unauthorized - UID ${uid} not found in DB`);
          return json({ error: "Unauthorized" }, 401);
        }

        const serverNow = new Date();
        const serverTimeText = `Current Server ISO Time: ${serverNow.toISOString()}\nToday is: ${serverNow.toDateString()}\nYear: ${serverNow.getFullYear()}`;
        
        const messagesWithTime = [...messages];
        const sysIdx = messagesWithTime.findIndex(m => m.role === "system");
        
        if (sysIdx !== -1) {
          messagesWithTime[sysIdx] = {
            ...messagesWithTime[sysIdx],
            content: `${messagesWithTime[sysIdx].content}\n\n[System Info]\n${serverTimeText}`
          };
        } else {
          messagesWithTime.unshift({
            role: "system",
            content: `[System Info]\n${serverTimeText}`
          });
        }

        // Standardize prompt image payloads
        let normalizedMessages = messagesWithTime;
        if (messagesWithTime && messagesWithTime.length > 0) {
          normalizedMessages = messagesWithTime.map(m => {
            if (m.role === "user" && m.content && typeof m.content === "string") {
              return { ...m, content: [{ type: "text", text: m.content }] };
            }
            return m;
          });
        }

        const actualModel = "google/gemma-4-26b-a4b-it";
        
        const requestBody = {
          model: actualModel,
          messages: normalizedMessages,
          tools: (tools && tools.length > 0) ? tools : undefined,
          stream: stream,
          // [AI CHAT] Defense-in-depth: ask OpenRouter/model to omit reasoning
          // entirely so harmony/channel "thought" markers never reach client.
          reasoning: { exclude: true }
        };

        console.log(`🤖 [AI CHAT] Forwarding to OpenRouter (Model: ${actualModel})`);
        const geminiResponse = await fetch("https://openrouter.ai/api/v1/chat/completions", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${env.OPENROUTER_API_KEY}`,
            "HTTP-Referer": "https://calenda.flow",
            "X-Title": "Calenda Flow"
          },
          body: JSON.stringify(requestBody)
        });

        if (!geminiResponse.ok) {
          let errText = "Failed to fetch response from OpenRouter";
          const status = geminiResponse.status;
          try {
            const errData = await geminiResponse.json();
            errText = errData.error?.message || JSON.stringify(errData);
          } catch (e) {}
          console.error(`❌ [AI CHAT] OpenRouter API Error: Status ${status} - ${errText}`);
          return json({ error: { message: errText } }, status);
        }

        const hasImages = messages.some(m => Array.isArray(m.content) && m.content.some(part => part.type === "image_url"));

        if (stream) {
          console.log(`┌──────────────────────────────────────────────────────────┐`);
          console.log(`│ 🤖 Calenda AI Chat Streaming Started                     │`);
          console.log(`├──────────────────────────────────────────────────────────┤`);
          console.log(`│ User ID   : ${uid.padEnd(44)} │`);
          console.log(`│ Session ID: ${(session_id || "N/A").padEnd(44)} │`);
          console.log(`│ Images    : ${(hasImages ? "Detected" : "None").padEnd(44)} │`);
          console.log(`│ Outcome   : Streaming chunks to client...                │`);
          console.log(`└──────────────────────────────────────────────────────────┘`);

          return new Response(geminiResponse.body, {
            headers: {
              ...corsHeaders(),
              "Content-Type": "text/event-stream",
              "Cache-Control": "no-cache",
              "Connection": "keep-alive",
            }
          });
        }

        const data = await geminiResponse.json();

        // Write assistant response to D1 database for non-streaming calls
        if (session_id && assistant_message_id) {
          const choice = data.choices?.[0];
          const msg = choice?.message;
          if (msg) {
            const responseText = msg.content || "";
            const rawToolCalls = msg.tool_calls;
            
            try {
              await env.DB.prepare(
                `INSERT OR REPLACE INTO chat_messages (id, session_id, text, reasoning, is_user, has_draft, pending_call, tool_calls, attachments, timestamp)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
              ).bind(
                assistant_message_id,
                session_id,
                responseText,
                "", // [Database] reasoning intentionally NOT stored (stripped at source)
                0, // is_user = false
                0, // has_draft = false
                "", // pending_call = empty
                rawToolCalls ? JSON.stringify(rawToolCalls) : "[]",
                "[]", // attachments = empty for assistant
                Date.now()
              ).run();

              // Update session updated_at
              await env.DB.prepare(
                `UPDATE chat_sessions SET updated_at = ? WHERE id = ?`
              ).bind(Date.now(), session_id).run();
              
              console.log(`💾 [AI CHAT] Assistant response persisted to D1 (ID: ${assistant_message_id})`);
            } catch (dbErr) {
              console.error(`❌ [AI CHAT] D1 persistence failed: ${dbErr.message}`);
            }
          }
        }

        // Detailed Logging of Token Usage and Costs
        let promptTokens = 0;
        let completionTokens = 0;
        let totalTokens = 0;
        let costUsd = 0.0;
        
        if (data.usage) {
          promptTokens = data.usage.prompt_tokens || 0;
          completionTokens = data.usage.completion_tokens || 0;
          totalTokens = data.usage.total_tokens || 0;
          costUsd = (promptTokens * 0.07 + completionTokens * 0.34) / 1000000;
        }

        const choice = data.choices?.[0];
        const msg = choice?.message;
        let outcome = "No response";
        if (msg) {
          if (msg.tool_calls && msg.tool_calls.length > 0) {
            outcome = `Tool Calls [${msg.tool_calls.map(tc => tc.function.name).join(", ")}]`;
          } else if (msg.content) {
            const preview = msg.content.length > 60 ? msg.content.substring(0, 60).replace(/\n/g, " ") + "..." : msg.content.replace(/\n/g, " ");
            outcome = `Message: "${preview}"`;
          }
        }

        console.log(`┌──────────────────────────────────────────────────────────┐`);
        console.log(`│ 🤖 Calenda AI Chat Session Summary                       │`);
        console.log(`├──────────────────────────────────────────────────────────┤`);
        console.log(`│ User ID   : ${uid.padEnd(44)} │`);
        console.log(`│ Session ID: ${(session_id || "N/A").padEnd(44)} │`);
        console.log(`│ Images    : ${(hasImages ? "Detected" : "None").padEnd(44)} │`);
        console.log(`│ Tokens    : ${("Prompt: " + promptTokens + " | Completion: " + completionTokens + " | Total: " + totalTokens).padEnd(44)} │`);
        console.log(`│ Est. Cost : $${costUsd.toFixed(6).padEnd(43)} │`);
        console.log(`│ Outcome   : ${outcome.padEnd(44)} │`);
        console.log(`└──────────────────────────────────────────────────────────┘`);
        
        let fullResponse = "No response";
        if (msg) {
          if (msg.tool_calls && msg.tool_calls.length > 0) {
            fullResponse = `Tool Calls:\n${JSON.stringify(msg.tool_calls, null, 2)}`;
          } else if (msg.content) {
            fullResponse = msg.content;
          }
        }
        console.log(`💬 [User Question (Full)]:\n${userQuestion}`);
        console.log(`🤖 [AI Response (Full)]:\n${fullResponse}\n────────────────────────────────────────────────────────────`);
        
        return json({ result: data });
      } catch (err) {
        console.error("❌ [AI CHAT ERROR]:", err.message, err.stack);
        return json({ error: "Internal Server Error" }, 500);
      }
    }

    return json({ error: "Not found" }, 404);
  },
};

// Durable Object: BoardHub (WebSocket fan-out)
export class BoardHub extends DurableObject {
  constructor(ctx, env) {
    super(ctx, env);
    this.env = env;
    this.sessions = new Map();
  }

  async fetch(request) {
    const url = new URL(request.url);

    if (request.method === "POST" && url.pathname === "/broadcast") {
      const body = await request.json();
      this.broadcast(JSON.stringify(body));
      return new Response("ok");
    }

    const upgrade = request.headers.get("Upgrade") || "";
    if (upgrade.toLowerCase() !== "websocket")
      return new Response("Expected websocket", { status: 400 });

    const [client, server] = Object.values(new WebSocketPair());
    this.acceptSession(server);
    
    // 🚀 Task 63.3: Universal Zero-Failure Handshake
    return new Response(null, { 
      status: 101, 
      webSocket: client,
      headers: {
        "Upgrade": "websocket",
        "Connection": "Upgrade",
      }
    });
  }

  acceptSession(ws) {
    ws.accept();
    const id = crypto.randomUUID();
    this.sessions.set(id, ws);

    ws.addEventListener("close", () => this.sessions.delete(id));
    ws.addEventListener("error", () => this.sessions.delete(id));
    ws.addEventListener("message", (evt) => {
      if (evt.data === "ping") ws.send("pong");
    });
  }

  broadcast(message) {
    for (const [id, ws] of this.sessions.entries()) {
      try {
        ws.send(message);
      } catch (_err) {
        this.sessions.delete(id);
      }
    }
  }
}

// Helpers
function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "*",
  };
}

function json(obj, status = 200) {
  const headers = corsHeaders();
  headers["Content-Type"] = "application/json";
  return new Response(JSON.stringify(obj), { status, headers });
}

async function notifyBoard(env, boardId, payload) {
  if (!boardId) return;
  try {
    const id = env.BOARD_HUB.idFromName(boardId);
    const stub = env.BOARD_HUB.get(id);
    await stub.fetch("https://boardhub/broadcast", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  } catch (err) {
    console.log("notify error", err.message || err);
  }
}
