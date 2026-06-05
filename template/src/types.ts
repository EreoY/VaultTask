/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

export interface Company {
  id: string;
  name: string;
}

export interface Department {
  id: string;
  companyId: string;
  name: string;
}

export interface Board {
  id: string;
  companyId: string;
  departmentId: string;
  title: string;
}

export type TaskStatus = string;

export interface Column {
  id: string;
  boardId: string;
  title: string;
  dotColor: string;
  textStyle: string;
  badgeBg: string;
  borderActive: string;
}

export interface SubTask {
  id: string;
  title: string;
  completed: boolean;
}

export interface Task {
  id: string;
  title: string;
  description: string;
  status: TaskStatus;
  startDate: string | null; // YYYY-MM-DD
  dueDate: string | null;   // YYYY-MM-DD
  assignee: string;
  subtasks: SubTask[];
  references: string[]; // names of document references
  createdAt: string;
  updatedAt: string;
  companyId?: string;
  departmentId?: string;
  boardId?: string;
}

export interface Comment {
  id: string;
  taskId: string;
  author: string;
  text: string;
  isAgent: boolean;
  createdAt: string;
}

export interface KnowledgeDoc {
  id: string;
  title: string;
  content: string;
  byteSize: number;
  source: string;
  createdAt: string;
  companyId?: string;     // Scoped to a specific company, or "all"
  departmentId?: string;  // Scoped to a specific department, or "all"
  boardIds?: string[];    // Scoped to specific board IDs, or empty/undefined for "all"
}
