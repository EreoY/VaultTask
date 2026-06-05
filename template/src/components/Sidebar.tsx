/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { 
  ChevronDown, Search, Settings, HelpCircle, 
  Trash, Plus, LogOut, CheckSquare, Sparkles,
  LayoutGrid, Trello, Calendar, BookOpen, MessageSquare, Star, Folder, UserCircle
} from 'lucide-react';

interface SidebarProps {
  currentTab: 'dashboard' | 'kanban' | 'calendar' | 'vault' | 'chat';
  setCurrentTab: (tab: 'dashboard' | 'kanban' | 'calendar' | 'vault' | 'chat') => void;
  tasksCount: { completed: number; active: number; total: number };
  onCloseMobile?: () => void;
}

export default function Sidebar({ currentTab, setCurrentTab, tasksCount, onCloseMobile }: SidebarProps) {
  
  // Custom navigation structure mimicking Notion's directory tree with minimal Lucide icons
  const favoritedPages = [
    { id: 'kanban', name: 'Client Projects', icon: Trello, desc: 'ทีมบอร์ด PSU' },
    { id: 'vault', name: 'Corporate Wiki', icon: BookOpen, desc: 'คู่มือระเบียบบริษัท' },
  ] as const;

  const workspacePages = [
    { id: 'dashboard', name: 'Workspace Dashboard', icon: LayoutGrid, desc: 'ภาพรวมผลดำเนินงาน' },
    { id: 'calendar', name: 'Temporal Calendar', icon: Calendar, desc: 'ปฏิทินแผนงาน' },
    { id: 'chat', name: 'Misty Private AI', icon: MessageSquare, desc: 'ที่ปรึกษางานอัจฉริยะ' },
  ] as const;

  return (
    <aside 
      className="w-60 bg-[#f7f7f5] border-r border-[#ededeb] flex flex-col justify-between shrink-0 h-full font-sans text-[#37352f]"
      id="notion-sidebar"
    >
      <div className="flex flex-col flex-1 overflow-y-auto">
        
        {/* Workspace Selector Segment */}
        <div className="p-4 pt-5 pb-2">
          <div className="flex items-center justify-between p-1.5 hover:bg-[#efefe0]/50 rounded-xl cursor-pointer transition">
            <div className="flex items-center space-x-2.5 min-w-0">
              {/* Ramp-styled minimal logo with custom crescent shape inline SVG */}
              <div className="w-6 h-6 rounded-full bg-black text-white flex items-center justify-center shrink-0 select-none relative">
                <svg viewBox="0 0 100 100" className="w-3.5 h-3.5 fill-current text-white transform -rotate-12">
                  <path d="M20,50 C20,30 35,15 55,15 C40,25 35,45 45,65 C55,85 75,85 80,80 C60,90 35,85 25,70 C20,63 20,56 20,50 Z" />
                </svg>
              </div>
              <div className="min-w-0">
                <span className="text-xs font-semibold text-[#37352f] block truncate">
                  Ramp PSU HQ
                </span>
                <span className="text-[10px] text-[#7c7b77] block truncate">
                  jitkhon1979@gmail.com
                </span>
              </div>
            </div>
            <div className="flex items-center space-x-1">
              <ChevronDown className="h-3.5 w-3.5 text-[#7c7b77] shrink-0" />
              {onCloseMobile && (
                <button
                  type="button"
                  onClick={(e) => {
                    e.stopPropagation();
                    onCloseMobile();
                  }}
                  className="md:hidden text-[#7c7b77] hover:text-[#37352f] hover:bg-[#efefe0] p-1 rounded-lg ml-1 font-bold"
                  title="Close Menu"
                >
                  ✕
                </button>
              )}
            </div>
          </div>
        </div>

        {/* Quick Utilities Link list */}
        <div className="px-2 space-y-0.5 text-xs text-[#37352f] font-normal pb-3">
          <div className="flex items-center space-x-2 px-2.5 py-1.5 hover:bg-[#efefe0]/50 rounded-xl cursor-pointer transition">
            <Search className="h-3.5 w-3.5 text-[#7c7b77]" />
            <span>Search Workspace</span>
            <span className="ml-auto font-mono text-[9px] text-[#7c7b77] bg-[#efefe0] px-1 rounded flex shrink-0">⌘K</span>
          </div>
          <div className="flex items-center space-x-2 px-2.5 py-1.5 hover:bg-[#efefe0]/50 rounded-xl cursor-pointer transition">
            <Settings className="h-3.5 w-3.5 text-[#7c7b77]" />
            <span>Settings & Members</span>
          </div>
        </div>

        {/* Group: FAVORITES */}
        <div className="px-2 pt-2 space-y-0.5">
          <div className="px-2.5 py-1 text-[10px] font-bold text-[#7c7b77] uppercase tracking-wider select-none flex items-center space-x-1">
            <Star className="h-3 w-3 text-[#7c7b77]" />
            <span>Favorites</span>
          </div>
          {favoritedPages.map((page) => {
            const isActive = currentTab === page.id;
            const PageIcon = page.icon;
            return (
              <button
                key={page.id}
                onClick={() => {
                  setCurrentTab(page.id);
                  onCloseMobile?.();
                }}
                className={`w-full flex items-center space-x-2 px-2.5 py-1.5 rounded-xl text-xs transition text-left cursor-pointer ${
                  isActive 
                    ? 'bg-[#efefe0] text-[#37352f] font-bold' 
                    : 'hover:bg-[#efefe0]/50 text-[#7c7b77] hover:text-[#37352f] font-medium'
                }`}
                id={`sidebar-fav-${page.id}`}
              >
                <PageIcon className={`h-3.5 w-3.5 shrink-0 ${isActive ? 'text-[#37352f]' : 'text-[#7c7b77]'}`} />
                <span className="truncate flex-1">{page.name}</span>
                {isActive && <div className="w-1 h-3.5 bg-[#2383e2] rounded-full shrink-0" />}
              </button>
            );
          })}
        </div>

        {/* Group: TEAM WORKSPACES */}
        <div className="px-2 pt-5 space-y-0.5">
          <div className="px-2.5 py-1 text-[10px] font-bold text-[#7c7b77] uppercase tracking-wider select-none flex items-center justify-between">
            <div className="flex items-center space-x-1">
              <Folder className="h-3 w-3 text-[#7c7b77]" />
              <span>Workspace Channels</span>
            </div>
            <Plus className="h-3 w-3 text-[#7c7b77] hover:bg-[#efefe0] rounded cursor-pointer" />
          </div>
          {workspacePages.map((page) => {
            const isActive = currentTab === page.id;
            const PageIcon = page.icon;
            return (
              <button
                key={page.id}
                onClick={() => {
                  setCurrentTab(page.id);
                  onCloseMobile?.();
                }}
                className={`w-full flex items-center space-x-2 px-2.5 py-1.5 rounded-xl text-xs transition text-left cursor-pointer ${
                  isActive 
                    ? 'bg-[#efefe0] text-[#37352f] font-bold' 
                    : 'hover:bg-[#efefe0]/50 text-[#7c7b77] hover:text-[#37352f] font-medium'
                }`}
                id={`sidebar-ws-${page.id}`}
              >
                <PageIcon className={`h-3.5 w-3.5 shrink-0 ${isActive ? 'text-[#37352f]' : 'text-[#7c7b77]'}`} />
                <span className="truncate flex-1">{page.name}</span>
                {isActive && <div className="w-1 h-3.5 bg-[#2383e2] rounded-full shrink-0" />}
              </button>
            );
          })}
        </div>

      </div>

      {/* Sidebar Footer with Task completion stats & User Information card */}
      <div className="p-3 border-t border-[#ededeb] bg-[#fbfbfa]">
        
        {/* Sync Status Banner */}
        <div className="mb-4 p-2.5 bg-[#efefe0]/40 rounded-xl border border-[#ededeb] space-y-1.5 text-[10px]">
          <div className="flex justify-between font-medium text-[#7c7b77]">
            <span>Progress:</span>
            <span className="text-[#2383e2] font-semibold">{tasksCount.completed}/{tasksCount.total} Done</span>
          </div>
          
          <div className="h-1.5 bg-[#ededeb] rounded-full overflow-hidden">
            <div 
              className="bg-[#2383e2] h-full rounded-full transition-all duration-500" 
              style={{ 
                width: `${tasksCount.total ? (tasksCount.completed / tasksCount.total) * 100 : 0}%` 
              }}
            />
          </div>
        </div>

        {/* Minimal User Bar aligned exactly like standard Notion web workspace cards */}
        <div className="flex items-center space-x-2.5 p-1.5 hover:bg-[#efefe0]/50 rounded-xl transition text-xs">
          <div className="relative shrink-0">
            <img 
              src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80" 
              alt="Workspace member avatar" 
              referrerPolicy="no-referrer"
              className="w-7 h-7 rounded-full object-cover border border-[#ededeb]"
            />
            <span className="absolute bottom-0 right-0 w-2 h-2 bg-[#00aa00] border border-[#ffffff] rounded-full"></span>
          </div>
          <div className="min-w-0 flex-1">
            <p className="font-semibold text-[#37352f] truncate leading-tight">Admin J. Kim</p>
            <p className="text-[9px] text-[#7c7b77] truncate">Member Specialist</p>
          </div>
          <button 
            className="text-[#7c7b77] hover:text-[#37352f] p-1 rounded hover:bg-[#efefe0]"
            title="Log out from deck"
          >
            <LogOut className="h-3.5 w-3.5" />
          </button>
        </div>

      </div>
    </aside>
  );
}
