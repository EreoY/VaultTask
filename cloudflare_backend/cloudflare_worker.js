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
          `SELECT * FROM team_boards WHERE owner_uid = ? OR members LIKE ? ORDER BY created_at DESC`,
        )
          .bind(uid, `%${uid}%`)
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

        const absoluteUrl = `https://${url.host}/api/images/${key}`;

        return json({ success: true, key, url: absoluteUrl });
      } catch (err) {
        return json({ error: err.message }, 500);
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
          `INSERT INTO team_tasks (id, board_id, author_uid, title, description, due_date, members, label_ids, status, is_completed, images, updated_at, order_index, comments)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
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
        const { id, board_id, is_completed, members, label_ids, images, comments } = taskData;
        if (!id) return json({ error: "Missing id" }, 400);
        
        const complete = is_completed ? 1 : 0;
        const now = nowMs();
        
        // 🚀 Task 64.1: Perform update with provided fields
        await env.DB.prepare(
          `UPDATE team_tasks SET title=?, description=?, due_date=?, members=?, label_ids=?, status=?, is_completed=?, images=?, updated_at=?, order_index=?, comments=? WHERE id=?`
        ).bind(
          taskData.title, taskData.description, taskData.due_date,
          JSON.stringify(members || []), JSON.stringify(label_ids || []),
          taskData.status, complete, JSON.stringify(images || []), now,
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
        const { model, messages, tools, uid, stream } = body;
        
        console.log(`\n🤖 [AI CHAT] Request received - User: ${uid}`);
        console.log(`🤖 [AI CHAT] Messages count: ${messages ? messages.length : 0}`);
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
            content: `${serverTimeText}\n\n${messagesWithTime[sysIdx].content}` 
          };
        } else {
          messagesWithTime.unshift({ role: "system", content: serverTimeText });
        }

        const actualModel = "google/gemma-4-26b-a4b-it";
        console.log(`🤖 [AI CHAT] Forwarding to OpenRouter (Model: ${actualModel})`);
        
        const geminiResponse = await fetch("https://openrouter.ai/api/v1/chat/completions", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${env.OPENROUTER_API_KEY || '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'}`,
            "HTTP-Referer": "https://calenda.flow",
            "X-Title": "Calenda Flow"
          },
          body: JSON.stringify({
            model: actualModel,
            messages: messagesWithTime,
            tools: (tools && tools.length > 0) ? tools : undefined,
            stream: stream
          })
        });
        
        if (!geminiResponse.ok) {
          const data = await geminiResponse.json();
          console.error(`❌ [AI CHAT] OpenRouter error (Status: ${geminiResponse.status}):`, JSON.stringify(data));
          return json({ error: data }, geminiResponse.status);
        }
        
        if (stream) {
          console.log(`🤖 [AI CHAT] Streaming response started`);
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
        
        // Detailed Logging of Token Usage and Choices
        if (data.usage) {
          console.log(`📊 [AI CHAT] Usage - Prompt: ${data.usage.prompt_tokens}, Completion: ${data.usage.completion_tokens}, Total: ${data.usage.total_tokens}`);
        } else {
          console.log(`📊 [AI CHAT] Usage data not returned`);
        }

        if (data.choices && data.choices.length > 0) {
          const choice = data.choices[0];
          const msg = choice.message;
          if (msg) {
            if (msg.tool_calls && msg.tool_calls.length > 0) {
              console.log(`⚙️ [AI CHAT] Tool Calls requested:`);
              msg.tool_calls.forEach((tc, idx) => {
                console.log(`  [${idx + 1}] Function: ${tc.function.name}`);
                console.log(`      Args: ${tc.function.arguments}`);
              });
            } else if (msg.content) {
              const preview = msg.content.length > 100 ? msg.content.substring(0, 100) + "..." : msg.content;
              console.log(`💬 [AI CHAT] Assistant Response: "${preview.replace(/\n/g, ' ')}"`);
            }
          }
        }
        
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
