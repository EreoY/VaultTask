/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from 'react';
import Sidebar from './components/Sidebar';
import DashboardView from './components/DashboardView';
import KanbanBoard from './components/KanbanBoard';
import BusinessCalendar from './components/BusinessCalendar';
import AIAgentChat from './components/AIAgentChat';
import KnowledgeVault from './components/KnowledgeVault';
import TaskModal from './components/TaskModal';
import OrgSelector from './components/OrgSelector';
import { Task, TaskStatus, KnowledgeDoc, Company, Department, Board, Column } from './types';
import { Sparkles, Home, LayoutGrid, Trello, Calendar, BookOpen, MessageSquare, Lightbulb, Check, Menu } from 'lucide-react';

export default function App() {
  const [currentTab, setCurrentTab] = useState<'dashboard' | 'kanban' | 'calendar' | 'vault' | 'chat'>('dashboard');
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [tasks, setTasks] = useState<Task[]>([]);
  const [docs, setDocs] = useState<KnowledgeDoc[]>([]);
  const [selectedTask, setSelectedTask] = useState<Task | null>(null);
  const [selectedDocTitleFromTask, setSelectedDocTitleFromTask] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  // States for Multi-Tenancy Organization Structure
  const [companies, setCompanies] = useState<Company[]>([]);
  const [departments, setDepartments] = useState<Department[]>([]);
  const [boards, setBoards] = useState<Board[]>([]);
  const [columns, setColumns] = useState<Column[]>([]);
  
  const [activeCompanyId, setActiveCompanyId] = useState<string>("co-1");
  const [activeDepartmentId, setActiveDepartmentId] = useState<string>("dep-1");
  const [activeBoardId, setActiveBoardId] = useState<string>("board-1-1");

  // Initial Fetching
  const fetchTasks = async () => {
    setIsLoading(true);
    try {
      const res = await fetch("/api/tasks");
      if (res.ok) {
        const data = await res.json();
        setTasks(data);
      }
    } catch (err) {
      console.error("Failed to load tasks from internal on-prem DB:", err);
    } finally {
      setIsLoading(false);
    }
  };

  const fetchDocs = async () => {
    try {
      const res = await fetch("/api/knowledge");
      if (res.ok) {
        const data = await res.json();
        setDocs(data);
      }
    } catch (err) {
      console.error("Failed to load company manuals from internal knowledge DB:", err);
    }
  };

  const fetchCompanies = async () => {
    try {
      const res = await fetch("/api/companies");
      if (res.ok) {
        const data = await res.json();
        setCompanies(data);
      }
    } catch (err) {
      console.error("Failed to fetch companies:", err);
    }
  };

  const fetchDepartments = async () => {
    try {
      const res = await fetch("/api/departments");
      if (res.ok) {
        const data = await res.json();
        setDepartments(data);
      }
    } catch (err) {
      console.error("Failed to fetch departments:", err);
    }
  };

  const fetchBoards = async () => {
    try {
      const res = await fetch("/api/boards");
      if (res.ok) {
        const data = await res.json();
        setBoards(data);
      }
    } catch (err) {
      console.error("Failed to fetch boards:", err);
    }
  };

  const fetchColumns = async () => {
    if (!activeBoardId) return;
    try {
      const res = await fetch(`/api/columns?boardId=${activeBoardId}`);
      if (res.ok) {
        const data = await res.json();
        setColumns(data);
      }
    } catch (err) {
      console.error("Failed to fetch Kanban columns:", err);
    }
  };

  const handleAddColumn = async (title: string, dotColor?: string, textStyle?: string, badgeBg?: string, borderActive?: string) => {
    try {
      const res = await fetch("/api/columns", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          boardId: activeBoardId,
          title,
          dotColor,
          textStyle,
          badgeBg,
          borderActive
        })
      });
      if (res.ok) {
        await fetchColumns();
        await fetchTasks();
      }
    } catch (err) {
      console.error("Failed to add column:", err);
    }
  };

  const handleUpdateColumn = async (columnId: string, updates: Partial<Omit<Column, 'id' | 'boardId'>>) => {
    try {
      const res = await fetch(`/api/columns/${columnId}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(updates)
      });
      if (res.ok) {
        await fetchColumns();
      }
    } catch (err) {
      console.error("Failed to update column:", err);
    }
  };

  const handleDeleteColumn = async (columnId: string) => {
    try {
      const res = await fetch(`/api/columns/${columnId}`, {
        method: "DELETE"
      });
      if (res.ok) {
        await fetchColumns();
        await fetchTasks();
      }
    } catch (err) {
      console.error("Failed to delete column:", err);
    }
  };

  // Unified fetcher passed to OrgSelector
  const handleRefreshOrgData = async () => {
    await Promise.all([
      fetchCompanies(),
      fetchDepartments(),
      fetchBoards(),
      fetchColumns()
    ]);
  };

  useEffect(() => {
    fetchTasks();
    fetchDocs();
    handleRefreshOrgData();
  }, []);

  // Cascade selection when activeCompanyId changes
  useEffect(() => {
    if (activeCompanyId && departments.length > 0) {
      const companyDepts = departments.filter(d => d.companyId === activeCompanyId);
      if (companyDepts.length > 0) {
        const isCurrentActiveValid = companyDepts.some(d => d.id === activeDepartmentId);
        if (!isCurrentActiveValid) {
          setActiveDepartmentId(companyDepts[0].id);
        }
      } else {
        setActiveDepartmentId("");
      }
    }
  }, [activeCompanyId, departments]);

  // Cascade selection when activeDepartmentId changes
  useEffect(() => {
    if (activeDepartmentId && boards.length > 0) {
      const deptBoards = boards.filter(b => b.departmentId === activeDepartmentId);
      if (deptBoards.length > 0) {
        const isCurrentActiveValid = deptBoards.some(b => b.id === activeBoardId);
        if (!isCurrentActiveValid) {
          setActiveBoardId(deptBoards[0].id);
        }
      } else {
        setActiveBoardId("");
      }
    }
  }, [activeDepartmentId, boards]);

  useEffect(() => {
    if (activeBoardId) {
      fetchColumns();
    }
  }, [activeBoardId]);

  // Update selectedTask details dynamically if tasks are updated in background
  useEffect(() => {
    if (selectedTask) {
      const liveVer = tasks.find(t => t.id === selectedTask.id);
      if (liveVer) {
        setSelectedTask(liveVer);
      }
    }
  }, [tasks]);

  // Handle task adding (with optional AI Augmentation, scoped to active company/dept/board)
  const handleAddTask = async (title: string, assignee: string, runAugmentation: boolean, description = "", status = "") => {
    setIsLoading(true);
    try {
      const res = await fetch("/api/tasks", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title,
          assignee,
          runAugmentation,
          description,
          status: status || undefined,
          companyId: activeCompanyId,
          departmentId: activeDepartmentId,
          boardId: activeBoardId
        })
      });

      if (res.ok) {
        await fetchTasks();
      }
    } catch (err) {
      console.error("Failed to post new task:", err);
    } finally {
      setIsLoading(false);
    }
  };

  // Calendar task adding (specifying dates directly, scoped to active company/dept/board)
  const handleAddTaskWithDates = async (
    title: string, 
    assignee: string, 
    startDate: string, 
    dueDate: string, 
    runAugmentation: boolean
  ) => {
    setIsLoading(true);
    try {
      const res = await fetch("/api/tasks", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title,
          assignee,
          startDate,
          dueDate,
          runAugmentation,
          companyId: activeCompanyId,
          departmentId: activeDepartmentId,
          boardId: activeBoardId
        })
      });

      if (res.ok) {
        await fetchTasks();
      }
    } catch (err) {
      console.error("Failed to post new calendar task:", err);
    } finally {
      setIsLoading(false);
    }
  };

  // Handle Kanban drag actions
  const handleUpdateStatus = async (id: string, newStatus: TaskStatus) => {
    try {
      const res = await fetch(`/api/tasks/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: newStatus })
      });

      if (res.ok) {
        await fetchTasks();
      }
    } catch (err) {
      console.error("Failed to update task status:", err);
    }
  };

  // Handle Calendar reschedule actions
  const handleUpdateDates = async (id: string, startDate: string | null, dueDate: string | null) => {
    try {
      const res = await fetch(`/api/tasks/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ startDate, dueDate })
      });

      if (res.ok) {
        await fetchTasks();
      }
    } catch (err) {
      console.error("Failed to update task timeline:", err);
    }
  };

  // Generic Task update (from edit modal details / checklist clicks)
  const handleUpdateTask = async (updatedTask: Task) => {
    try {
      const res = await fetch(`/api/tasks/${updatedTask.id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(updatedTask)
      });

      if (res.ok) {
        await fetchTasks();
      }
    } catch (err) {
      console.error("Failed to sync task changes:", err);
    }
  };

  // Delete Task
  const handleDeleteTask = async (id: string) => {
    try {
      const res = await fetch(`/api/tasks/${id}`, { method: "DELETE" });
      if (res.ok) {
        setSelectedTask(null);
        await fetchTasks();
      }
    } catch (err) {
      console.error("Failed to delete task:", err);
    }
  };

  // Add Document (including multi-tenant accessibility scopes)
  const handleAddDoc = async (
    title: string, 
    content: string, 
    source: string, 
    companyId: string, 
    departmentId: string, 
    boardIds: string[]
  ) => {
    setIsLoading(true);
    try {
      const res = await fetch("/api/knowledge", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ 
          title, 
          content, 
          source,
          companyId,
          departmentId,
          boardIds
        })
      });

      if (res.ok) {
        await fetchDocs();
      }
    } catch (err) {
      console.error("Failed to post news manual:", err);
    } finally {
      setIsLoading(false);
    }
  };

  // Delete Document
  const handleDeleteDoc = async (id: string) => {
    try {
      const res = await fetch(`/api/knowledge/${id}`, { method: "DELETE" });
      if (res.ok) {
        await fetchDocs();
      }
    } catch (err) {
      console.error("Failed to delete manual:", err);
    }
  };

  // Trace references: clicking RAG document links inside Task detail redirects to Vault directly!
  const handleOpenDoc = (docTitle: string) => {
    setSelectedDocTitleFromTask(docTitle);
    setCurrentTab('vault');
    setSelectedTask(null);
  };

  // 1. Filter Tasks for active Board
  const filteredTasks = tasks.filter(t => t.boardId === activeBoardId);

  // 2. Filter Documents matching active company/dept/board visibility rules
  const visibleDocs = docs.filter(doc => {
    // If document is globally public (all company scope) - visible to anyone
    if (!doc.companyId || doc.companyId === 'all') {
      return true;
    }
    // If not matching active company
    if (doc.companyId !== activeCompanyId) {
      return false;
    }
    // If globally visible to all departments inside active company
    if (!doc.departmentId || doc.departmentId === 'all') {
      return true;
    }
    // If not matching active department
    if (doc.departmentId !== activeDepartmentId) {
      return false;
    }
    // If limited to explicit board IDs
    if (doc.boardIds && doc.boardIds.length > 0) {
      return doc.boardIds.includes(activeBoardId);
    }
    // Otherwise open to all boards in this department
    return true;
  });

  return (
    <div className="w-screen h-screen flex bg-white font-sans antialiased text-[#37352f] overflow-hidden" id="main-app-container">
      
      {/* Mobile sidebar overlay backdrop */}
      {isSidebarOpen && (
        <div 
          className="fixed inset-0 bg-black/45 z-50 md:hidden transition-opacity duration-300" 
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      {/* Left Navigation Sidebar Drawer/Persistent Rail */}
      <div 
        className={`
          fixed inset-y-0 left-0 z-50 md:sticky md:z-auto h-full bg-[#f7f7f5] transition-transform duration-300 ease-in-out md:translate-x-0
          ${isSidebarOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0'}
          shrink-0
        `}
      >
        <Sidebar 
          currentTab={currentTab} 
          setCurrentTab={setCurrentTab} 
          onCloseMobile={() => setIsSidebarOpen(false)}
          tasksCount={{
            completed: tasks.filter(t => t.status === 'done').length,
            active: tasks.filter(t => t.status !== 'done').length,
            total: tasks.length
          }}
        />
      </div>

      {/* Main Container viewport */}
      <div className="flex-1 flex flex-col min-w-0 h-full overflow-hidden bg-white text-[#37352f]" id="app-content-area">
      
        {/* Notion top navigation bar - exactly matching screenshots */}
        <div className="flex items-center justify-between px-6 md:px-10 py-3 border-b border-[#ededeb] bg-white text-xs select-none sticky top-0 z-40">
          <div className="flex items-center space-x-1.5 text-[#7c7b77] font-medium min-w-0">
            {/* Hamburger button for mobile */}
            <button 
              type="button"
              onClick={() => setIsSidebarOpen(true)}
              className="md:hidden p-1 bg-[#efefe0]/50 text-[#37352f] hover:bg-[#efefe0] rounded-lg cursor-pointer transition mr-2 focus:outline-none shrink-0 border border-[#ededeb]"
              title="Open Navigation"
            >
              <Menu className="h-4 w-4" />
            </button>

            <span className="hover:bg-[#efefe0]/60 px-1.5 py-1 rounded cursor-pointer transition flex items-center space-x-1.5 shrink-0">
              <Home className="h-3.5 w-3.5 text-[#7c7b77]" />
              <span className="hidden sm:inline">Notion Workspace</span>
            </span>
            <span className="hidden sm:inline">/</span>
            <span className="text-[#37352f] font-semibold hover:bg-[#efefe0]/60 px-1.5 py-1 rounded cursor-pointer transition truncate">
              {currentTab === 'dashboard' ? 'Workspace Dashboard' :
               currentTab === 'kanban' ? 'Client Projects' :
               currentTab === 'calendar' ? 'Temporal Calendar' :
               currentTab === 'chat' ? 'Misty Private AI' :
               'Corporate Wiki'}
            </span>
          </div>
          <div className="flex items-center space-x-2.5 text-[#7c7b77]">
            <span className="hover:bg-[#efefe0]/60 px-2 py-1 rounded cursor-pointer transition text-[11px] hidden sm:inline">Share</span>
            <span className="hover:bg-[#efefe0]/60 px-2 py-1 rounded cursor-pointer transition text-[11px] flex items-center space-x-1">
              <Check className="h-3.5 w-3.5 text-[#7c7b77]" />
              <span className="hidden xs:inline">Updates</span>
            </span>
            <span className="hover:bg-[#efefe0]/60 px-2 py-1 rounded cursor-pointer transition text-[11px] hidden sm:inline">Favorite</span>
            <span className="hover:bg-[#efefe0]/60 px-1.5 py-0.5 rounded cursor-pointer transition font-bold leading-none">•••</span>
          </div>
        </div>

        {/* Scrollable middle container */}
        <div className="flex-1 overflow-y-auto scrollbar-hide flex flex-col justify-between" id="app-scroll-viewport">
          <main className="flex-1 px-4 md:px-10 py-8 max-w-7xl w-full mx-auto space-y-6" id="dashboard-viewport">
            
            {/* OrgSelector Workspace Picker Control Hub */}
            <OrgSelector 
              companies={companies}
              departments={departments}
              boards={boards}
              activeCompanyId={activeCompanyId}
              activeDepartmentId={activeDepartmentId}
              activeBoardId={activeBoardId}
              setActiveCompanyId={setActiveCompanyId}
              setActiveDepartmentId={setActiveDepartmentId}
              setActiveBoardId={setActiveBoardId}
              onRefreshData={handleRefreshOrgData}
            />

            {/* Dynamic tabs router */}
            <section className="transition-all duration-300" id="tabs-section-container">
              {currentTab === 'dashboard' && (
                <DashboardView 
                  tasks={filteredTasks}
                  setCurrentTab={setCurrentTab}
                  onSelectTask={setSelectedTask}
                />
              )}

              {currentTab === 'kanban' && (
                <KanbanBoard 
                  tasks={filteredTasks}
                  columns={columns}
                  onAddTask={handleAddTask}
                  onUpdateStatus={handleUpdateStatus}
                  onSelectTask={setSelectedTask}
                  onAddColumn={handleAddColumn}
                  onUpdateColumn={handleUpdateColumn}
                  onDeleteColumn={handleDeleteColumn}
                  isLoading={isLoading}
                />
              )}

              {currentTab === 'calendar' && (
                <BusinessCalendar
                  tasks={filteredTasks}
                  onUpdateDates={handleUpdateDates}
                  onAddTaskWithDates={handleAddTaskWithDates}
                  onSelectTask={setSelectedTask}
                />
              )}

              {currentTab === 'chat' && (
                <AIAgentChat 
                  allDocs={visibleDocs}
                  activeCompanyId={activeCompanyId}
                  activeDepartmentId={activeDepartmentId}
                  activeBoardId={activeBoardId}
                  companies={companies}
                  departments={departments}
                  boards={boards}
                  onRefreshTasks={fetchTasks}
                />
              )}

              {currentTab === 'vault' && (
                <KnowledgeVault 
                  docs={visibleDocs}
                  onAddDoc={handleAddDoc}
                  onDeleteDoc={handleDeleteDoc}
                  selectedDocTitleFromTask={selectedDocTitleFromTask}
                  setSelectedDocTitleFromTask={setSelectedDocTitleFromTask}
                  companies={companies}
                  departments={departments}
                  boards={boards}
                  activeCompanyId={activeCompanyId}
                  activeDepartmentId={activeDepartmentId}
                  activeBoardId={activeBoardId}
                />
              )}
            </section>

          </main>

          <footer className="py-4 bg-white border-t border-[#ededeb]/70 text-center text-[#7c7b77] font-sans text-[10px] shrink-0 font-medium">
            <p>© 2026 Notion PSU Workspace with Misty Local RAG Node. Optimized for privacy and speed.</p>
          </footer>
        </div>

      </div>

      {/* Single Sliding Detail Screen Modal for task exploration */}
      {selectedTask && (
        <TaskModal 
          task={selectedTask}
          columns={columns}
          onClose={() => setSelectedTask(null)}
          onUpdateTask={handleUpdateTask}
          onDeleteTask={handleDeleteTask}
          allDocs={visibleDocs}
          onOpenDoc={handleOpenDoc}
        />
      )}

    </div>
  );
}
