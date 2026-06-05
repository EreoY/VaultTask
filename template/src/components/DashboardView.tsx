/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { 
  Sparkles, CheckCircle2, AlertCircle, Clock, 
  Calendar, Layers, ArrowUpRight, ShieldCheck, Database 
} from 'lucide-react';
import { Task } from '../types';

interface DashboardViewProps {
  tasks: Task[];
  setCurrentTab: (tab: 'dashboard' | 'kanban' | 'calendar' | 'vault' | 'chat') => void;
  onSelectTask: (task: Task) => void;
}

export default function DashboardView({ tasks, setCurrentTab, onSelectTask }: DashboardViewProps) {
  
  // Calculate dynamic stats
  const completedCount = tasks.filter(t => t.status === 'done').length;
  const doingCount = tasks.filter(t => t.status === 'doing').length;
  const todoCount = tasks.filter(t => t.status === 'todo').length;
  const totalCount = tasks.length;

  const completionPercent = totalCount > 0 
    ? Math.round((completedCount / totalCount) * 100) 
    : 46; // Fallback default or real

  return (
    <div className="space-y-8 animate-fadeIn text-[#37352f]" id="dashboard-tab-view bg-white">
      
      {/* Notion Notion display header - with custom emoji and large clean title */}
      <div className="space-y-1 pb-4 border-b border-[#ededeb]" id="dashboard-editorial-header">
        <div className="text-4xl font-black text-[#37352f] flex items-center space-x-2 select-none">
          <h1 className="font-sans font-bold hover:bg-[#efefe0]/30 px-2 py-1 rounded transition duration-200">
            Workspace Dashboard
          </h1>
        </div>
        <p className="text-xs text-[#7c7b77] mt-1 font-sans pl-2 leading-relaxed">
          ยินดีต้อนรับสู่แดชบอร์ดสรุปกิจกรรม PSU Workspace และคัดกรองคู่มือ AI RAG อภิปรายสถานะกลุ่มสินค้าสัญญางานองค์กร
        </p>
      </div>

      {/* Grid Layout containing Daily Overview & Insight Panels */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        
        {/* Left Side: Daily Overview Column */}
        <div className="lg:col-span-8 bg-white border border-[#ededeb] rounded-2xl p-6 shadow-2xs space-y-6">
          
          <div className="flex items-center justify-between border-b border-[#ededeb] pb-3">
            <div className="flex items-center space-x-2 text-[#7c7b77] font-semibold text-xs uppercase tracking-wider">
              <Layers className="h-3.5 w-3.5" />
              <span>Daily Analytics Summary</span>
            </div>
            <span className="text-[10px] text-[#7c7b77] font-mono bg-[#efefe0]/60 px-2.5 py-0.5 rounded-full font-bold">2026-06-05 UTC</span>
          </div>

          {/* Strategic completion progress */}
          <div className="space-y-4">
            <div className="space-y-2">
              <div className="flex justify-between items-center text-xs">
                <span className="font-semibold text-[#37352f]">Overall Strategic Completion progress</span>
                <span className="font-mono font-bold text-[#2383e2]">{completionPercent}%</span>
              </div>
              <div className="w-full bg-[#ededeb] h-2.5 rounded-full overflow-hidden">
                <div 
                  className="bg-[#2383e2] h-full rounded-full transition-all duration-700"
                  style={{ width: `${completionPercent}%` }}
                />
              </div>
            </div>

            <div className="space-y-2">
              <div className="flex justify-between items-center text-xs">
                <span className="font-semibold text-[#37352f]">Active Strategic Clusters Status</span>
                <span className="font-mono font-bold text-amber-600">Active</span>
              </div>
              <div className="w-full bg-[#ededeb] h-2.5 rounded-full overflow-hidden">
                <div className="bg-[#dfab00] h-full rounded-full w-full" />
              </div>
            </div>
          </div>

          {/* Large Metrics Counters row matching screenshots and Notion design */}
          <div className="grid grid-cols-3 gap-4 pt-2">
            
            <div 
              className="bg-white hover:bg-[#efefe0]/30 transition p-4 rounded-2xl border border-[#ededeb] flex flex-col justify-between h-24 cursor-pointer" 
              id="card-metric-completed"
              onClick={() => setCurrentTab('kanban')}
            >
              <div className="text-[#008000] flex items-center justify-between">
                <CheckCircle2 className="h-4 w-4" />
                <span className="text-[9px] font-mono font-extrabold tracking-widest text-[#7c7b77]">DONE</span>
              </div>
              <div>
                <p className="text-3xl font-bold font-sans text-[#37352f] leading-none">{completedCount}</p>
                <p className="text-[10px] tracking-wide text-[#7c7b77] mt-1 font-medium">Completed</p>
              </div>
            </div>

            <div 
              className="bg-white hover:bg-[#efefe0]/30 transition p-4 rounded-2xl border border-[#ededeb] flex flex-col justify-between h-24 cursor-pointer" 
              id="card-metric-doing"
              onClick={() => setCurrentTab('kanban')}
            >
              <div className="text-[#0066cc] flex items-center justify-between">
                <Clock className="h-4 w-4" />
                <span className="text-[9px] font-mono font-extrabold tracking-widest text-[#7c7b77]">DOING</span>
              </div>
              <div>
                <p className="text-3xl font-bold font-sans text-[#37352f] leading-none">{doingCount}</p>
                <p className="text-[10px] tracking-wide text-[#7c7b77] mt-1 font-medium">In Progress</p>
              </div>
            </div>

            <div 
              className="bg-white hover:bg-[#efefe0]/30 transition p-4 rounded-2xl border border-[#ededeb] flex flex-col justify-between h-24 cursor-pointer" 
              id="card-metric-todo"
              onClick={() => setCurrentTab('kanban')}
            >
              <div className="text-amber-600 flex items-center justify-between">
                <Calendar className="h-4 w-4" />
                <span className="text-[9px] font-mono font-extrabold tracking-widest text-[#7c7b77]">TODOS</span>
              </div>
              <div>
                <p className="text-3xl font-bold font-sans text-[#37352f] leading-none">{todoCount}</p>
                <p className="text-[10px] tracking-wide text-[#7c7b77] mt-1 font-medium">Upcoming</p>
              </div>
            </div>

          </div>

        </div>

        {/* Right Side: Aether Insight intelligence card column */}
        <div className="lg:col-span-4 space-y-4">
          
          <div className="bg-white border border-[#ededeb] rounded-2xl p-5 shadow-2xs relative overflow-hidden">
            <div className="absolute right-1 top-1 opacity-5">
              <Sparkles className="w-16 h-16 text-[#2383e2] shrink-0" />
            </div>

            <div className="flex items-center space-x-1 text-[#2383e2] font-semibold text-[10px] uppercase tracking-widest mb-3">
              <Sparkles className="h-3.5 w-3.5 animate-pulse" />
              <span>AI Assistant Insight</span>
            </div>

            <h3 className="text-xs font-semibold text-[#37352f] leading-relaxed">
              Based on your workflow schedules, consider delegating or re-sequencing Thursday activities to keep output high.
            </h3>

            <div className="bg-[#efefe0]/40 border border-[#ededeb] p-3 rounded-xl mt-4 text-[11px]">
              <span className="text-[8px] bg-[#df1c1c]/10 border border-[#df1c1c]/25 text-[#df1c1c] font-mono font-bold uppercase tracking-wider px-1.5 py-0.5 rounded-full">
                CALENDAR CONFLICT WARNING
              </span>
              <p className="text-xs text-[#7c7b77] leading-relaxed font-sans mt-2">
                Thursday afternoon tasks are heavily overlapping. Use the reschedule drag-drop on the Temporal Deck to offset overdue actions.
              </p>
            </div>
          </div>

          {/* Quick RAG stats panel */}
          <div className="bg-[#fcfbf9] border border-[#ededeb] p-5 rounded-2xl space-y-3">
            <h4 className="text-[10px] font-bold uppercase text-[#7c7b77] tracking-wider flex items-center justify-between">
              <span>Private Node Status</span>
              <span className="w-1.5 h-1.5 rounded-full bg-[#00aa00] animate-pulse"></span>
            </h4>
            <div className="space-y-1.5 text-[11px] font-sans text-[#7c7b77]">
              <div className="flex justify-between border-b border-[#ededeb] pb-1">
                <span>RAG DB Node:</span>
                <span className="text-[#37352f] font-semibold">Active & Encrypted</span>
              </div>
              <div className="flex justify-between border-b border-[#ededeb] pb-1">
                <span>AI Core Engine:</span>
                <span className="text-[#37352f] font-semibold">Gemini-3.5-flash</span>
              </div>
              <div className="flex justify-between">
                <span>Memory Sandboxing:</span>
                <span className="text-[#00aa00] font-semibold">Secure Local Isolation</span>
              </div>
            </div>
          </div>

        </div>

      </div>

      {/* Corporate Priority Tasks List Row */}
      <div className="bg-white border border-[#ededeb] rounded-2xl p-6 shadow-2xs space-y-4" id="recent-tasks-row">
        
        <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-3 border-b border-[#ededeb] gap-2">
          <div className="space-y-0.5">
            <h3 className="font-bold text-lg text-[#37352f] flex items-center space-x-1.5">
              <Layers className="h-4.5 w-4.5 text-[#7c7b77]" />
              <span>Recent Workspace Cards</span>
            </h3>
            <p className="text-xs text-[#7c7b77]">สัญญางานและการมอบหมายที่มีอยู่บนกระดานดำเนินงาน ร่วมกับพนักงานในทีม</p>
          </div>
          <button 
            onClick={() => setCurrentTab('kanban')}
            className="flex items-center space-x-1.5 hover:bg-[#efefe0] transition text-xs font-semibold text-[#37352f] bg-white border border-[#ededeb] py-1.5 px-3 rounded-xl shadow-2xs cursor-pointer self-start sm:self-center"
          >
            <span>Open Kanban Board</span>
            <ArrowUpRight className="h-3.5 w-3.5" />
          </button>
        </div>

        {/* Dynamic Task rows inside Dashboard */}
        <div className="space-y-1.5 max-h-80 overflow-y-auto pr-1">
          {tasks.map((task) => (
            <div 
              key={task.id}
              onClick={() => onSelectTask(task)}
              className="bg-white hover:bg-[#efefe0]/40 transition p-3 rounded-xl border border-[#ededeb] flex items-center justify-between cursor-pointer group"
            >
              <div className="flex items-center space-x-3 min-w-0">
                <span className={`w-2 h-2 rounded-full shrink-0 ${
                  task.status === 'done' ? 'bg-[#00aa00]' : task.status === 'doing' ? 'bg-[#0066cc]' : 'bg-[#dfab00]'
                }`} />
                <div className="min-w-0">
                  <h4 className="text-xs font-semibold text-[#37352f] group-hover:text-[#2383e2] transition truncate">
                    {task.title}
                  </h4>
                  <p className="text-[10px] text-[#7c7b77] mt-0.5">
                    ผู้ได้รับหมาย: <strong className="text-[#37352f]">{task.assignee}</strong> • กำหนดส่ง: <strong className="text-[#37352f]">{task.dueDate || "N/A"}</strong>
                  </p>
                </div>
              </div>

              <span className={`text-[9.5px] font-sans px-2.5 py-0.5 rounded-full border uppercase shrink-0 font-semibold ${
                task.status === 'done' 
                  ? 'bg-[#e3fce1] text-[#006600] border-[#c0ecc0]' 
                  : task.status === 'doing' 
                  ? 'bg-[#e0f0ff] text-[#004b99] border-[#b0d4ff]' 
                  : 'bg-[#faebcc] text-[#8f6b00] border-[#ecd08a]'
              }`}>
                {task.status === 'done' ? 'Completed' : task.status === 'doing' ? 'In Progress' : 'To Do'}
              </span>

            </div>
          ))}

          {tasks.length === 0 && (
            <div className="text-center py-6 text-xs text-[#7c7b77] italic">
              ไม่มีข้อมูลมอบหมายงานในขณะนี้
            </div>
          )}
        </div>

      </div>

    </div>
  );
}
