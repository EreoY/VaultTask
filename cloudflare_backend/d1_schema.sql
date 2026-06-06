-- ═══════════════════════════════════════════════════════
-- Calenda D1 Schema — Board-Based Architecture
-- ═══════════════════════════════════════════════════════

-- Users (from Firebase Auth)
CREATE TABLE IF NOT EXISTS users (
  uid TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  display_name TEXT,
  photo_url TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Team Workspaces
CREATE TABLE IF NOT EXISTS team_workspaces (
  id TEXT PRIMARY KEY,
  owner_uid TEXT NOT NULL,
  name TEXT NOT NULL,
  members TEXT DEFAULT '[]',      -- JSON array of Firebase UIDs
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(owner_uid) REFERENCES users(uid)
);

-- Team Boards
CREATE TABLE IF NOT EXISTS team_boards (
  id TEXT PRIMARY KEY,            -- UUID generated client-side
  owner_uid TEXT NOT NULL,
  name TEXT NOT NULL,
  color INTEGER DEFAULT 0,
  members TEXT DEFAULT '[]',      -- JSON array of Firebase UIDs
  member_roles TEXT DEFAULT '{}', -- JSON object mapping UID to role description
  columns TEXT DEFAULT '["todo","doing","done"]', -- JSON array of column names
  labels TEXT DEFAULT '[]',       -- JSON array of tag objects {id, color, name}
  workspace_id TEXT DEFAULT '',
  documents TEXT DEFAULT '[]',    -- JSON array of Document objects
  updated_at INTEGER DEFAULT (strftime('%s','now')*1000),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(owner_uid) REFERENCES users(uid)
);

-- Team Tasks (belong to a board)
CREATE TABLE IF NOT EXISTS team_tasks (
  id TEXT PRIMARY KEY,             -- UUID generated client-side
  board_id TEXT NOT NULL,
  author_uid TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  due_date TEXT NOT NULL,          -- ISO8601 deadline — shown in Calendar & Kanban
  members TEXT DEFAULT '[]',       -- JSON array of assigned UIDs
  label_ids TEXT DEFAULT '[]',     -- JSON array of assigned label IDs
  status TEXT NOT NULL DEFAULT 'todo', -- maps to a column name in team_boards.columns
  is_completed INTEGER DEFAULT 0,  -- 0=false, 1=true
  images TEXT DEFAULT '[]',        -- JSON array of TaskImage objects
  comments TEXT DEFAULT '[]',      -- JSON array of TaskComment objects
  order_index INTEGER DEFAULT 0,   -- Sort order in Kanban column
  updated_at INTEGER DEFAULT (strftime('%s','now')*1000),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(board_id) REFERENCES team_boards(id),
  FOREIGN KEY(author_uid) REFERENCES users(uid)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_team_boards_owner ON team_boards(owner_uid);
CREATE INDEX IF NOT EXISTS idx_team_workspaces_owner ON team_workspaces(owner_uid);
CREATE INDEX IF NOT EXISTS idx_team_tasks_board  ON team_tasks(board_id);
CREATE INDEX IF NOT EXISTS idx_team_tasks_due    ON team_tasks(due_date);

-- Chat Sessions
CREATE TABLE IF NOT EXISTS chat_sessions (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL,
  task_id TEXT DEFAULT '',
  name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at INTEGER DEFAULT 0,
  FOREIGN KEY(uid) REFERENCES users(uid)
);

-- Chat Messages
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
  timestamp TEXT NOT NULL,
  FOREIGN KEY(session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
);

-- Chat Indexes
CREATE INDEX IF NOT EXISTS idx_chat_sessions_uid ON chat_sessions(uid);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_task ON chat_sessions(task_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_session ON chat_messages(session_id);

