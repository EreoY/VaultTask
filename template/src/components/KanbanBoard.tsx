/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import { 
  Plus, ArrowRight, Sparkles, User, Calendar, FileText, 
  LayoutGrid, CheckCircle2, Trash2, Settings, Palette, Check, 
  MoreVertical 
} from 'lucide-react';
import { Task, TaskStatus, Column } from '../types';

interface KanbanBoardProps {
  tasks: Task[];
  columns: Column[];
  onAddTask: (title: string, assignee: string, runAugmentation: boolean, description?: string, status?: string) => Promise<void>;
  onUpdateStatus: (id: string, newStatus: TaskStatus) => Promise<void>;
  onSelectTask: (task: Task) => void;
  onAddColumn: (title: string, dotColor?: string, textStyle?: string, badgeBg?: string, borderActive?: string) => Promise<void>;
  onUpdateColumn: (columnId: string, updates: Partial<Omit<Column, 'id' | 'boardId'>>) => Promise<void>;
  onDeleteColumn: (columnId: string) => Promise<void>;
  isLoading: boolean;
}

const COLOR_PALETTES = [
  { dotColor: 'bg-indigo-500', textStyle: 'text-indigo-700', badgeBg: 'bg-indigo-50 text-indigo-700 font-semibold', borderActive: 'border-[#818cf8]', label: 'Indigo' },
  { dotColor: 'bg-amber-500', textStyle: 'text-amber-700', badgeBg: 'bg-amber-50 text-amber-700 font-semibold', borderActive: 'border-[#fbbf24]', label: 'Amber' },
  { dotColor: 'bg-emerald-500', textStyle: 'text-[#12805c]', badgeBg: 'bg-[#e3fcef] text-[#12805c] font-semibold', borderActive: 'border-[#34d399]', label: 'Emerald' },
  { dotColor: 'bg-rose-500', textStyle: 'text-rose-700', badgeBg: 'bg-rose-50 text-rose-700 font-semibold', borderActive: 'border-[#f87171]', label: 'Rose' },
  { dotColor: 'bg-sky-500', textStyle: 'text-sky-700', badgeBg: 'bg-sky-50 text-sky-700 font-semibold', borderActive: 'border-[#38bdf8]', label: 'Sky' },
  { dotColor: 'bg-purple-500', textStyle: 'text-purple-700', badgeBg: 'bg-purple-50 text-purple-700 font-semibold', borderActive: 'border-[#c084fc]', label: 'Purple' },
  { dotColor: 'bg-pink-500', textStyle: 'text-pink-700', badgeBg: 'bg-pink-50 text-pink-700 font-semibold', borderActive: 'border-[#f472b6]', label: 'Pink' },
  { dotColor: 'bg-teal-500', textStyle: 'text-teal-700', badgeBg: 'bg-teal-50 text-teal-700 font-semibold', borderActive: 'border-[#2dd4bf]', label: 'Teal' },
];

export default function KanbanBoard({ 
  tasks, 
  columns,
  onAddTask, 
  onUpdateStatus, 
  onSelectTask,
  onAddColumn,
  onUpdateColumn,
  onDeleteColumn,
  isLoading
}: KanbanBoardProps) {
  const [newTitle, setNewTitle] = useState('');
  const [newDescription, setNewDescription] = useState('');
  const [assignee, setAssignee] = useState('พนักงาน A');
  const [aiAugment, setAiAugment] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [draggedTaskId, setDraggedTaskId] = useState<string | null>(null);

  // Column related states
  const [editingColId, setEditingColId] = useState<string | null>(null);
  const [editingText, setEditingText] = useState("");
  const [isAddingColumn, setIsAddingColumn] = useState(false);
  const [newColTitle, setNewColTitle] = useState("");
  const [selectedPaletteIdx, setSelectedPaletteIdx] = useState(0);
  const [openSettingsColId, setOpenSettingsColId] = useState<string | null>(null);

  // Track simple quick titles being typed per column on the board
  const [inlineTitles, setInlineTitles] = useState<Record<string, string>>({});

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTitle.trim() || isSubmitting) return;

    setIsSubmitting(true);
    try {
      const defaultStatus = columns[0]?.id || 'todo';
      await onAddTask(newTitle, assignee, aiAugment, newDescription, defaultStatus);
      setNewTitle('');
      setNewDescription('');
    } catch (err) {
      console.error("Failed to add task:", err);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleInlineSubmit = async (colId: string) => {
    const titleVal = inlineTitles[colId] || "";
    if (!titleVal.trim()) return;

    try {
      setInlineTitles(prev => ({ ...prev, [colId]: "กำลังหมุน RAG AI..." }));
      await onAddTask(titleVal.trim(), "พนักงานส่วนกลาง", true, "", colId);
      setInlineTitles(prev => ({ ...prev, [colId]: "" }));
    } catch (err) {
      console.error("Failed to inline add task:", err);
      setInlineTitles(prev => ({ ...prev, [colId]: titleVal }));
    }
  };

  const handleDragStart = (id: string) => {
    setDraggedTaskId(id);
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
  };

  const handleDrop = async (newStatus: string) => {
    if (!draggedTaskId) return;
    await onUpdateStatus(draggedTaskId, newStatus);
    setDraggedTaskId(null);
  };

  const handleCreateColumn = async () => {
    if (!newColTitle.trim()) return;
    const palette = COLOR_PALETTES[selectedPaletteIdx];
    await onAddColumn(
      newColTitle.trim(), 
      palette.dotColor, 
      palette.textStyle, 
      palette.badgeBg, 
      `border-l-4 ${palette.borderActive}`
    );
    setNewColTitle("");
    setIsAddingColumn(false);
  };

  const handleSaveColumnName = async (colId: string) => {
    if (!editingText.trim()) return;
    await onUpdateColumn(colId, { title: editingText.trim() });
    setEditingColId(null);
  };

  const quickTaskTemplates = [
    { title: "ทำสรุปยอดขายกลุ่มสินค้า Retail ประจำพฤษภาคม", assignee: "พนักงาน A" },
    { title: "ขออนุมัติลางานพักร้อนสิบวันไปต่างประเทศ", assignee: "คุณสมศักดิ์ (HR)" },
    { title: "จัดเตรียมค่าเบี้ยเลี้ยงทัศนศึกษาต่างจังหวัด ฝ่ายจัดซื้อ", assignee: "พนักงาน B" }
  ];

  return (
    <div className="space-y-6 animate-fadeIn text-[#37352f]" id="kanban-wrapper">
      
      {/* Dynamic interactive page header looking precisely like a Notion Database view page */}
      <div className="space-y-1 pb-4 border-b border-[#ededeb]" id="board-team-title">
        <div className="text-4xl font-extrabold text-[#37352f] flex items-center space-x-2 select-none">
          <h2 className="font-sans font-bold hover:bg-[#efefe0]/30 px-2 py-0.5 rounded transition">
            Client Projects
          </h2>
        </div>
        <div className="flex items-center justify-between mt-2 pl-2.5">
          <div className="flex items-center space-x-4 text-xs text-[#7c7b77] font-medium">
            <span className="bg-[#efefe0] px-3 py-1 rounded-full cursor-pointer hover:text-[#37352f] transition">📂 Board view</span>
            <span className="hover:text-[#37352f] cursor-pointer transition">➕ Add view</span>
          </div>
          <button 
            type="button"
            onClick={() => setIsAddingColumn(!isAddingColumn)}
            className="text-xs bg-white border border-[#ededeb] hover:bg-[#efefe0]/50 hover:text-[#37352f] text-[#7c7b77] rounded-xl px-3 py-1.5 font-bold transition flex items-center space-x-1 shadow-3xs cursor-pointer select-none"
          >
            <Plus className="h-3 w-3 shrink-0" />
            <span>เพิ่มคอลัมน์ใหม่ ...</span>
          </button>
        </div>
      </div>

      {/* Creation form styled as clean, friendly client sidebar card input */}
      <div className="bg-[#fcfbf9] rounded-2xl border border-[#ededeb] p-5 shadow-2xs">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 mb-4">
          <div>
            <h3 className="text-xs font-bold text-[#37352f] tracking-wide uppercase flex items-center space-x-1.5">
              <Plus className="h-4 w-4 text-[#7c7b77]" />
              <span>สั่งมอบหมายหรือวางโครงภารกิจใหม่ (Add Task)</span>
            </h3>
            <p className="text-[11.5px] text-[#7c7b77] mt-0.5 font-medium leading-relaxed">
              สุ่มพิมพ์รายละเอียดสัญญางาน หรือคลิกหัวข้อตัวอย่างด่วนด่านล่างเพื่อให้ระบบสืบค้น RAG ไปจัดระเบียบงานให้อย่างรวดเร็ว
            </p>
          </div>
          
          <div className="flex flex-wrap gap-1 text-[10px]">
            <span className="text-[#7c7b77] self-center font-bold">Quick Templates:</span>
            {quickTaskTemplates.map((tpl, i) => (
              <button
                key={i}
                type="button"
                onClick={() => {
                  setNewTitle(tpl.title);
                  setAssignee(tpl.assignee);
                }}
                className="bg-white hover:bg-[#efefe0]/50 border border-[#ededeb] text-[#37352f] px-3 py-1.5 rounded-full transition text-left font-sans font-medium hover:shadow-2xs select-none"
              >
                {tpl.title.slice(0, 24)}...
              </button>
            ))}
          </div>
        </div>

        <form onSubmit={handleSubmit} className="grid grid-cols-1 lg:grid-cols-12 gap-3.5">
          
          {/* Row 1: Title input & Assignee */}
          <div className="lg:col-span-8">
            <label className="block text-[10.5px] font-bold text-[#7c7b77] mb-1">หัวข้องาน (Task Title) *</label>
            <input
              type="text"
              placeholder="พิมพ์ชื่อสั่งงาน เช่น 'สัญญาส่งมอบบริการด้านสถาปัตยกรรมกลุ่มการสื่อสาร'"
              value={newTitle}
              onChange={(e) => setNewTitle(e.target.value)}
              className="w-full h-10 text-xs bg-white border border-[#ededeb] focus:border-[#2383e2] focus:ring-1 focus:ring-[#2383e2] text-[#37352f] focus:outline-none rounded-xl px-3.5 transition font-sans placeholder-[#a0a0a0] font-semibold shadow-3xs"
              required
              disabled={isSubmitting}
            />
          </div>

          <div className="lg:col-span-4">
            <label className="block text-[10.5px] font-bold text-[#7c7b77] mb-1">ผู้รับผิดชอบ (Assignee)</label>
            <select
              value={assignee}
              onChange={(e) => setAssignee(e.target.value)}
              className="w-full h-10 text-xs bg-white border border-[#ededeb] focus:border-[#2383e2] text-[#37352f] rounded-xl px-3.5 focus:outline-none font-sans font-bold shadow-3xs"
              disabled={isSubmitting}
            >
              <option value="พนักงาน A">พนักงาน A (ฝ่ายขาย)</option>
              <option value="พนักงาน B">พนักงาน B (ฝ่ายจัดซื้อ)</option>
              <option value="คุณสมศักดิ์ (HR)">คุณสมศักดิ์ (HR)</option>
              <option value="หัวหน้างาน">หัวหน้างาน</option>
            </select>
          </div>

          {/* Row 2: Manual Description Textarea & AI controls Column */}
          <div className="lg:col-span-8">
            <label className="block text-[10.5px] font-bold text-[#7c7b77] mb-1">รายละเอียดข้อกำหนดเพิ่มเติม (Optional Content Description)</label>
            <input
              type="text"
              placeholder="ระบุข้อความคำอธิบายเพิ่มเติมสำหรับการทำภารกิจที่มอบหมาย..."
              value={newDescription}
              onChange={(e) => setNewDescription(e.target.value)}
              className="w-full h-10 text-xs bg-white border border-[#ededeb] focus:border-[#2383e2] focus:ring-1 focus:ring-[#2383e2] text-[#37352f] focus:outline-none rounded-xl px-3.5 transition font-sans placeholder-[#a0a0a0] font-medium shadow-3xs"
              disabled={isSubmitting}
            />
          </div>

          {/* Toggle and Submit Controls Block */}
          <div className="lg:col-span-4 flex items-end space-x-2">
            
            {/* AI Toggle Option */}
            <label className="flex-1 flex items-center space-x-2 bg-white border border-[#ededeb] rounded-xl h-10 px-3 cursor-pointer hover:bg-[#efefe0]/40 transition select-none shadow-3xs">
              <input
                type="checkbox"
                checked={aiAugment}
                onChange={(e) => setAiAugment(e.target.checked)}
                className="rounded text-[#2383e2] focus:ring-[#2383e2] border-[#ededeb] h-3.5 w-3.5 cursor-pointer"
                disabled={isSubmitting}
              />
              <div className="flex flex-col leading-none">
                <span className="text-[9px] uppercase font-extrabold text-[#2383e2] flex items-center space-x-0.5">
                  <Sparkles className="h-2.5 w-2.5 text-[#2383e2]" />
                  <span>AI Augment</span>
                </span>
                <span className="text-[8px] text-[#7c7b77] font-bold">สแกนระเบียบ</span>
              </div>
            </label>

            <button
              type="submit"
              disabled={!newTitle.trim() || isSubmitting}
              className="h-10 bg-[#2383e2] hover:bg-[#1a6ec0] disabled:bg-[#ededeb] disabled:text-[#a0a0a0] text-white font-bold text-xs px-4 rounded-xl flex items-center justify-center transition shadow-2xs cursor-pointer shrink-0"
            >
              {isSubmitting ? (
                <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
              ) : (
                <span className="flex items-center space-x-1">
                  <span>แจกงาน</span>
                  <ArrowRight className="h-3.5 w-3.5" />
                </span>
              )}
            </button>
          </div>

        </form>
      </div>

      {/* Grid of Kanban Columns - styled matching Notion screens, horizontal scroll enabled for rich column count */}
      <div className="flex gap-6 overflow-x-auto pb-6 pt-2 items-start scrollbar-hide select-none" id="kanban-columns-scroller">
        {columns.map((col) => {
          const colTasks = tasks.filter(t => t.status === col.id);
          
          return (
            <div 
              key={col.id}
              className="flex flex-col w-[300px] shrink-0 min-h-[60vh] bg-[#fbfbfa]/75 rounded-2xl border border-[#ededeb] p-3 transition-all hover:bg-[#fbfbfa] relative"
              onDragOver={handleDragOver}
              onDrop={() => handleDrop(col.id)}
              id={`col-${col.id}`}
            >
              
              {/* Column Title Header - with pastel colored badges exactly like screens */}
              <div className="flex items-center justify-between mb-4 pb-2 border-b border-[#ededeb] relative">
                
                <div className="flex items-center space-x-2 flex-1 min-w-0 pr-2">
                  {editingColId === col.id ? (
                    <div className="flex items-center space-x-1 w-full" onClick={(e) => e.stopPropagation()}>
                      <input
                        type="text"
                        value={editingText}
                        onChange={(e) => setEditingText(e.target.value)}
                        className="text-[11px] font-semibold native-input border border-[#2383e2] focus:outline-none rounded px-1.5 py-0.5 bg-white text-[#37352f] w-full"
                        autoFocus
                      />
                    </div>
                  ) : (
                    <div 
                      className="flex items-center space-x-1.5 cursor-pointer max-w-full hover:bg-[#efefe0]/50 rounded px-1 py-0.5 transition"
                      title="ดับเบิลคลิกหรือคลิกแก้ไขที่ตั้งค่าเพื่อเปลี่ยนชื่อคอลัมน์"
                      onDoubleClick={() => {
                        setEditingColId(col.id);
                        setEditingText(col.title);
                      }}
                    >
                      <span className={`w-2 h-2 rounded-full shrink-0 ${col.dotColor}`} />
                      <span className={`px-2 py-0.5 rounded-xl text-[11px] font-bold truncate ${col.badgeBg} ${col.textStyle}`}>
                        {col.title}
                      </span>
                    </div>
                  )}
                  <span className="text-[10px] text-[#7c7b77] font-extrabold shrink-0">
                    {colTasks.length}
                  </span>
                </div>

                {/* Settings dropdown trigger */}
                <div className="relative shrink-0 flex items-center" onClick={(e) => e.stopPropagation()}>
                  <button 
                    onClick={() => setOpenSettingsColId(openSettingsColId === col.id ? null : col.id)}
                    className="text-[#7c7b77] hover:text-[#37352f] cursor-pointer text-xs font-bold p-1 hover:bg-[#efefe0] rounded-lg transition-colors"
                  >
                    <MoreVertical className="h-3.5 w-3.5" />
                  </button>

                  {openSettingsColId === col.id && (
                    <div className="absolute right-0 top-6 bg-white border border-[#ededeb] rounded-xl shadow-lg p-3.5 z-40 w-48 text-left space-y-2.5 animate-fadeIn">
                      <div className="text-[9px] font-bold text-[#7c7b77] uppercase tracking-wider">โทนสีคอลัมน์ (Tone Color)</div>
                      <div className="grid grid-cols-4 gap-1.5">
                        {COLOR_PALETTES.map((palette, idx) => (
                          <button
                            key={idx}
                            onClick={() => {
                              onUpdateColumn(col.id, {
                                dotColor: palette.dotColor,
                                textStyle: palette.textStyle,
                                badgeBg: palette.badgeBg,
                                borderActive: `border-l-4 ${palette.borderActive}`
                              });
                              setOpenSettingsColId(null);
                            }}
                            className={`h-4.5 w-4.5 rounded-full border border-gray-100 cursor-pointer ${palette.dotColor} flex items-center justify-center hover:scale-110 transition`}
                            title={palette.label}
                          >
                            {col.dotColor === palette.dotColor && <span className="text-[7px] text-white">✓</span>}
                          </button>
                        ))}
                      </div>
                      
                      <div className="pt-2 border-t border-[#ededeb] flex justify-between">
                        <button
                          onClick={() => {
                            setEditingColId(col.id);
                            setEditingText(col.title);
                            setOpenSettingsColId(null);
                          }}
                          className="text-[10px] text-[#2383e2] hover:underline font-bold"
                        >
                          แก้ไขชื่อ
                        </button>
                        
                        <button
                          onClick={() => {
                            if (confirm(`คุณแน่ใจหรือไม่ว่าต้องการลบคอลัมน์ "${col.title}"? การ์ดงานในคอลัมน์นี้จะถูกย้ายไปยังคอลัมน์อื่นโดยอัตโนมัติ`)) {
                              onDeleteColumn(col.id);
                            }
                            setOpenSettingsColId(null);
                          }}
                          disabled={columns.length <= 1}
                          className="text-[10px] text-rose-600 disabled:text-gray-300 hover:underline font-bold"
                        >
                          ลบคอลัมน์
                        </button>
                      </div>
                    </div>
                  )}
                </div>

              </div>

              {/* Inline single title task add form - Hitting Enter will let AI auto-generate description */}
              <div className="mb-3.5">
                <input
                  type="text"
                  placeholder="✍️ พิมพ์สร้างงานด่วนแล้วกด Enter..."
                  value={inlineTitles[col.id] || ""}
                  onChange={(e) => setInlineTitles(prev => ({ ...prev, [col.id]: e.target.value }))}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") {
                      handleInlineSubmit(col.id);
                    }
                  }}
                  className="w-full text-[10.5px] bg-white border border-[#ededeb] hover:border-[#7c7b77]/50 focus:border-[#2383e2] focus:ring-1 focus:ring-[#2383e2] focus:outline-none rounded-xl h-8 px-2.5 transition font-medium placeholder-[#7c7b77]/60 text-[#37352f] shadow-3xs"
                  title="พิมพ์เพียงแค่หัวข้อภารกิจแล้วระบบ AI โค้งมนจะสืบค้นคู่มือ RAG มาสกัดรายละเอียดงานให้อัตโนมัติทันที"
                />
                {inlineTitles[col.id] === "กำลังหมุน RAG AI..." && (
                  <p className="text-[8px] text-[#2383e2] mt-1 pl-1 font-bold animate-pulse">✨ Gemini กำลังสากลระเบียบมาแจกแจงงาน...</p>
                )}
              </div>

              {/* Tasks List */}
              <div className="flex-1 space-y-3">
                {colTasks.length === 0 ? (
                  <div className="h-28 flex items-center justify-center border border-dashed border-[#ededeb] p-4 rounded-xl text-[10px] text-[#7c7b77] font-medium italic text-center bg-white/40 leading-relaxed">
                    ไม่มีการ์ดงานในหน้านี้
                  </div>
                ) : (
                  colTasks.map((task) => (
                    <div
                      key={task.id}
                      draggable
                      onDragStart={() => handleDragStart(task.id)}
                      onClick={() => onSelectTask(task)}
                      className={`bg-white p-4 rounded-2xl border border-[#ededeb] hover:border-[#7c7b77] hover:shadow-2xs transition duration-200 cursor-grab active:cursor-grabbing group relative overflow-hidden ${col.borderActive}`}
                      id={`card-${task.id}`}
                    >
                      {/* Ribbon indicator if task references corporate documents */}
                      {task.references && task.references.length > 0 && (
                        <div 
                          className="absolute top-0 right-0 p-1 bg-[#2383e2] text-white text-[8px] font-bold rounded-bl-xl uppercase tracking-widest leading-none shrink-0" 
                          title="RAG Active"
                        >
                          RAG
                        </div>
                      )}

                      <h4 className="text-[12.5px] font-semibold text-[#37352f] leading-snug group-hover:text-[#2383e2] transition font-sans">
                        {task.title}
                      </h4>

                      {/* Brief description glimpse */}
                      {task.description && (
                        <p className="text-[11px] text-[#7c7b77] line-clamp-2 mt-1.5 font-sans leading-relaxed">
                          {task.description}
                        </p>
                      )}

                      {/* Subtask checklist counting bar */}
                      {task.subtasks && task.subtasks.length > 0 && (
                        <div className="mt-3.5 pt-2 border-t border-[#ededeb] flex items-center justify-between text-[10px] text-[#7c7b77] font-medium bg-[#efefe0]/25 px-2.5 py-1.5 rounded-xl">
                          <span className="flex items-center space-x-1.5 text-[#7c7b77]">
                            <CheckCircle2 className="h-3.5 w-3.5 text-[#00aa00] shrink-0" />
                            <span>สกัดแนวทาง:</span>
                            <strong className="text-[#37352f]">
                              {task.subtasks.filter(s => s.completed).length}/{task.subtasks.length}
                            </strong>
                          </span>
                          
                          <div className="w-12 bg-[#ededeb] h-1.5 rounded-full overflow-hidden">
                            <div 
                              className="bg-[#00aa00] h-full rounded-full transition-all duration-300"
                              style={{ width: `${(task.subtasks.filter(s => s.completed).length / task.subtasks.length) * 100}%` }}
                            />
                          </div>
                        </div>
                      )}

                      {/* Footer: Date and Assignee badge */}
                      <div className="mt-4 flex items-center justify-between text-[10.5px]">
                        <span className="flex items-center space-x-1 px-1.5 py-0.5 rounded-md bg-[#efefe0]/40 text-[#37352f] font-semibold">
                          <User className="h-3 w-3 text-[#7c7b77] shrink-0" />
                          <span className="truncate max-w-[80px] text-[10px]">{task.assignee}</span>
                        </span>

                        {task.dueDate && (
                          <span className="text-[#7c7b77] font-mono text-[9px] bg-[#fbfbfa] border border-[#ededeb] px-1.5 py-0.5 rounded font-bold">
                            📅 {task.dueDate.substring(5)}
                          </span>
                        )}
                      </div>

                    </div>
                  ))
                )}
              </div>

            </div>
          );
        })}

        {/* Dynamic Add Column Card Option matching styling perfectly */}
        <div className="bg-[#fcfbf9]/40 border-2 border-dashed border-[#ededeb] hover:bg-[#efefe0]/10 hover:border-[#7c7b77]/50 rounded-2xl p-4 min-w-[300px] shrink-0 text-center flex flex-col justify-center items-center group cursor-pointer transition min-h-[160px]">
          {isAddingColumn ? (
            <div className="w-full space-y-3.5 text-left" onClick={(e) => e.stopPropagation()}>
              <div>
                <label className="block text-[10.5px] font-bold text-[#7c7b77] mb-1">ชื่อคอลัมน์ใหม่ (Column Title) *</label>
                <input
                  type="text"
                  placeholder="เช่น 'กำลังทดสอบ (QA Test)'"
                  className="w-full text-xs font-semibold bg-white border border-[#ededeb] focus:border-[#2383e2] focus:outline-none rounded-xl px-3 h-9 placeholder-[#a0a0a0] shadow-3xs"
                  value={newColTitle}
                  onChange={(e) => setNewColTitle(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") {
                      handleCreateColumn();
                    }
                  }}
                  autoFocus
                />
              </div>
              
              <div>
                <label className="block text-[10.5px] font-bold text-[#7c7b77] mb-1.5">เลือกเฉดสีคอลัมน์</label>
                <div className="grid grid-cols-4 gap-1.5">
                  {COLOR_PALETTES.map((palette, idx) => (
                    <button
                      key={idx}
                      type="button"
                      onClick={() => setSelectedPaletteIdx(idx)}
                      className={`h-5 w-5 rounded-full border border-gray-100 cursor-pointer ${palette.dotColor} flex items-center justify-center hover:scale-110 transition`}
                      title={palette.label}
                    >
                      {selectedPaletteIdx === idx && <span className="text-[8px] text-white">✓</span>}
                    </button>
                  ))}
                </div>
              </div>

              <div className="flex items-center justify-end space-x-2 pt-1 border-t border-[#ededeb]/70">
                <button
                  type="button"
                  onClick={() => setIsAddingColumn(false)}
                  className="text-[10px] text-[#7c7b77] hover:underline font-bold"
                >
                  ยกเลิก
                </button>
                <button
                  type="button"
                  onClick={handleCreateColumn}
                  disabled={!newColTitle.trim()}
                  className="bg-[#2383e2] hover:bg-[#1a6ec0] disabled:bg-gray-200 disabled:text-gray-400 text-white font-bold text-[10px] px-3.5 py-1.5 rounded-lg transition shadow-2xs cursor-pointer"
                >
                  สร้างเลย
                </button>
              </div>
            </div>
          ) : (
            <div 
              className="flex flex-col items-center space-y-2 select-none w-full h-full justify-center p-6"
              onClick={() => setIsAddingColumn(true)}
            >
              <div className="p-2.5 bg-white rounded-full border border-[#ededeb] group-hover:scale-105 transition shadow-3xs">
                <Plus className="h-4 w-4 text-[#7c7b77]" />
              </div>
              <div className="text-[11.5px] font-bold text-[#7c7b77] group-hover:text-[#37352f] transition">
                + เพิ่มคอลัมน์ใหม่ (Add Column)
              </div>
              <p className="text-[10px] text-[#7c7b77] max-w-[200px] text-center italic font-medium leading-normal">
                สร้างคอลัมน์เพื่อจัดกลุ่มและควบคุม Flow งานเพิ่มเติมให้กับบอร์ดนี้
              </p>
            </div>
          )}
        </div>

      </div>

    </div>
  );
}
