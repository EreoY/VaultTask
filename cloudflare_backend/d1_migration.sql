-- Add updated_at columns (run once; will fail harmlessly if already exist)
ALTER TABLE team_boards ADD COLUMN updated_at INTEGER;
ALTER TABLE team_tasks  ADD COLUMN updated_at INTEGER;
ALTER TABLE team_tasks  ADD COLUMN is_completed INTEGER DEFAULT 0;
ALTER TABLE team_boards ADD COLUMN member_roles TEXT DEFAULT '{}';
ALTER TABLE team_boards ADD COLUMN labels TEXT DEFAULT '[]';

-- Add images & comments columns (will fail harmlessly if already exist)
ALTER TABLE team_tasks ADD COLUMN images TEXT DEFAULT '[]';
ALTER TABLE team_tasks ADD COLUMN comments TEXT DEFAULT '[]';

-- Backfill
UPDATE team_boards SET updated_at = COALESCE(updated_at, strftime('%s','now')*1000);
UPDATE team_tasks  SET updated_at = COALESCE(updated_at, strftime('%s','now')*1000);
UPDATE team_tasks  SET is_completed = COALESCE(is_completed, 0);
UPDATE team_tasks  SET images = COALESCE(images, '[]');
UPDATE team_tasks  SET comments = COALESCE(comments, '[]');

-- ═══════════════════════════════════════════════════════
-- Migration: Drop `time` column, use `due_date` only
-- SQLite does not support DROP COLUMN; recreate table
-- ═══════════════════════════════════════════════════════

-- 1. Create new table without `time`
CREATE TABLE IF NOT EXISTS team_tasks_new (
  id TEXT PRIMARY KEY,
  board_id TEXT NOT NULL,
  author_uid TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  due_date TEXT NOT NULL,
  members TEXT DEFAULT '[]',
  label_ids TEXT DEFAULT '[]',
  status TEXT NOT NULL DEFAULT 'todo',
  is_completed INTEGER DEFAULT 0,
  images TEXT DEFAULT '[]',
  comments TEXT DEFAULT '[]',
  updated_at INTEGER DEFAULT (strftime('%s','now')*1000),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(board_id) REFERENCES team_boards(id),
  FOREIGN KEY(author_uid) REFERENCES users(uid)
);

-- 2. Copy data (migrate time → due_date where due_date is null)
INSERT INTO team_tasks_new (
  id, board_id, author_uid, title, description, due_date,
  members, label_ids, status, is_completed, images, comments, updated_at, created_at
)
SELECT
  id, board_id, author_uid, title, description,
  COALESCE(due_date, time) as due_date,
  members, label_ids, status, is_completed, images, comments, updated_at, created_at
FROM team_tasks;

-- 3. Drop old table
DROP TABLE team_tasks;

-- 4. Rename new table
ALTER TABLE team_tasks_new RENAME TO team_tasks;

-- 5. Recreate indexes
CREATE INDEX idx_team_tasks_board ON team_tasks(board_id);
CREATE INDEX idx_team_tasks_due  ON team_tasks(due_date);
