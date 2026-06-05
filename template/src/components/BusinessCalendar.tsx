/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import { 
  ChevronLeft, ChevronRight, Calendar, User, Clock, 
  Sparkles, CheckCircle2, FileText, CalendarPlus2
} from 'lucide-react';
import { Task } from '../types';

interface BusinessCalendarProps {
  tasks: Task[];
  onUpdateDates: (id: string, startDate: string | null, dueDate: string | null) => Promise<void>;
  onAddTaskWithDates: (title: string, assignee: string, startDate: string, dueDate: string, runAugmentation: boolean) => Promise<void>;
  onSelectTask: (task: Task) => void;
}

export default function BusinessCalendar({ 
  tasks, 
  onUpdateDates, 
  onAddTaskWithDates, 
  onSelectTask 
}: BusinessCalendarProps) {
  
  // Pivot to June 2026 since metadata points to 2026-06-05
  const [currentYear, setCurrentYear] = useState(2026);
  const [currentMonth, setCurrentMonth] = useState(5); // 0-indexed (5 = June)

  // Creation State from Calendar clicking
  const [showCreatePopup, setShowCreatePopup] = useState(false);
  const [popupStartDate, setPopupStartDate] = useState('');
  const [popupDueDate, setPopupDueDate] = useState('');
  const [popupTitle, setPopupTitle] = useState('');
  const [popupAssignee, setPopupAssignee] = useState('พนักงาน A');
  const [popupAiAugment, setPopupAiAugment] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Drag-and-Drop parameters for rescheduling
  const [draggedTaskId, setDraggedTaskId] = useState<string | null>(null);

  // Helper arrays (Thai months for enterprise look & feel)
  const monthNamesTh = [
    "มกราคม", "กุมภาพันธ์", "มีนาคม", "เมษายน", "พฤษภาคม", "มิถุนายน",
    "กรกฎาคม", "สิงหาคม", "กันยายน", "ตุลาคม", "พฤศจิกายน", "ธันวาคม"
  ];
  
  const daysOfWeek = ["อา.", "จ.", "อ.", "พ.", "พฤ.", "ศ.", "ส."];

  const getDaysInMonth = (year: number, month: number) => {
    return new Date(year, month + 1, 0).getDate();
  };

  const getFirstDayOfMonth = (year: number, month: number) => {
    return new Date(year, month, 1).getDay();
  };

  const totalDays = getDaysInMonth(currentYear, currentMonth);
  const startOffset = getFirstDayOfMonth(currentYear, currentMonth);

  const cells: { dateStr: string | null; dayNum: number | null }[] = [];
  
  for (let i = 0; i < startOffset; i++) {
    cells.push({ dateStr: null, dayNum: null });
  }

  for (let d = 1; d <= totalDays; d++) {
    const pad = (n: number) => n.toString().padStart(2, '0');
    const dateStr = `${currentYear}-${pad(currentMonth + 1)}-${pad(d)}`;
    cells.push({ dateStr, dayNum: d });
  }

  while (cells.length % 7 !== 0) {
    cells.push({ dateStr: null, dayNum: null });
  }

  const handlePrevMonth = () => {
    if (currentMonth === 0) {
      setCurrentMonth(11);
      setCurrentYear(currentYear - 1);
    } else {
      setCurrentMonth(currentMonth - 1);
    }
  };

  const handleNextMonth = () => {
    if (currentMonth === 11) {
      setCurrentMonth(0);
      setCurrentYear(currentYear + 1);
    } else {
      setCurrentMonth(currentMonth + 1);
    }
  };

  const handleCellDragOver = (e: React.DragEvent) => {
    e.preventDefault();
  };

  const handleTaskDragStart = (id: string, e: React.DragEvent) => {
    setDraggedTaskId(id);
    e.dataTransfer.setData("text/plain", id);
  };

  const handleCellDrop = async (dateStr: string) => {
    if (!draggedTaskId) return;

    const task = tasks.find(t => t.id === draggedTaskId);
    if (!task) return;

    let newStart = dateStr;
    let newDue = dateStr;

    if (task.startDate && task.dueDate) {
      const diffMs = new Date(task.dueDate).getTime() - new Date(task.startDate).getTime();
      const diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24));
      
      const newStartDateObj = new Date(dateStr);
      const newDueDateObj = new Date(newStartDateObj.getTime() + (diffDays * 1000 * 60 * 60 * 24));
      
      const pad = (n: number) => n.toString().padStart(2, '0');
      newStart = dateStr;
      newDue = `${newDueDateObj.getFullYear()}-${pad(newDueDateObj.getMonth() + 1)}-${pad(newDueDateObj.getDate())}`;
    }

    await onUpdateDates(draggedTaskId, newStart, newDue);
    setDraggedTaskId(null);
  };

  const handleCellClick = (dateStr: string) => {
    setPopupStartDate(dateStr);
    setPopupDueDate(dateStr);
    setPopupTitle('');
    setShowCreatePopup(true);
  };

  const handlePopupSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!popupTitle.trim() || !popupStartDate || !popupDueDate || isSubmitting) return;

    setIsSubmitting(true);
    try {
      await onAddTaskWithDates(popupTitle, popupAssignee, popupStartDate, popupDueDate, popupAiAugment);
      setShowCreatePopup(false);
    } catch (err) {
      console.error("Failed to create task with calendar dates:", err);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="space-y-6 animate-fadeIn text-[#37352f]" id="calendar-wrapper">
      
      {/* Calendar Header with navigation control row */}
      <div className="bg-white rounded-2xl border border-[#ededeb] p-5 shadow-2xs">
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
          
          <div className="flex items-center space-x-3.5">
            <div className="p-2.5 bg-[#efefe0]/40 text-[#2383e2] border border-[#ededeb] rounded-xl">
              <Calendar className="h-5.5 w-5.5" id="calendar-header-icon" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-[#37352f] tracking-tight flex items-center space-x-2">
                <span>Temporal Calendar</span>
              </h2>
              <p className="text-xs text-[#7c7b77] mt-0.5">
                ลากย้ายกล่องขอบเขตแผนงานวันส่ง (Drag task to reschedule) หรือคลิกกล่องวันว่างเพื่อสั่งจ่ายงานด่วน
              </p>
            </div>
          </div>

          <div className="flex items-center space-x-2 bg-white p-1 rounded-full border border-[#ededeb]">
            <button 
              onClick={handlePrevMonth}
              className="p-1.5 hover:bg-[#efefe0] rounded-full transition text-[#7c7b77] hover:text-[#37352f]"
              title="Previous Month"
            >
              <ChevronLeft className="h-4 w-4" />
            </button>
            
            <span className="font-semibold text-[#37352f] text-xs px-3 min-w-[125px] text-center uppercase tracking-wide">
              {monthNamesTh[currentMonth]} {currentYear}
            </span>

            <button 
              onClick={handleNextMonth}
              className="p-1.5 hover:bg-[#efefe0] rounded-full transition text-[#7c7b77] hover:text-[#37352f]"
              title="Next Month"
            >
              <ChevronRight className="h-4 w-4" />
            </button>
          </div>

        </div>
      </div>

      {/* Primary Calendar Grid */}
      <div className="bg-white rounded-2xl border border-[#ededeb] overflow-hidden shadow-2xs">
        
        {/* Days labels */}
        <div className="grid grid-cols-7 bg-[#fbfbfa] border-b border-[#ededeb] text-center font-bold text-[10px] py-3 tracking-widest text-[#7c7b77] uppercase">
          {daysOfWeek.map((day, i) => (
            <div key={i} className={i === 0 || i === 6 ? 'text-[#a0a0a0]' : 'text-[#7c7b77]'}>
              {day}
            </div>
          ))}
        </div>

        {/* Date cells */}
        <div className="grid grid-cols-7 divide-x divide-y divide-[#ededeb] bg-white">
          {cells.map((cell, idx) => {
            const hasValue = cell.dateStr !== null;
            
            const daysTasks = hasValue 
              ? tasks.filter(t => {
                  if (!t.startDate || !t.dueDate) return false;
                  return t.startDate <= cell.dateStr! && t.dueDate >= cell.dateStr!;
                })
              : [];

            const isToday = cell.dateStr === "2026-06-05";

            return (
              <div
                key={idx}
                onDragOver={hasValue ? handleCellDragOver : undefined}
                onDrop={hasValue ? () => handleCellDrop(cell.dateStr!) : undefined}
                className={`min-h-[110px] p-2 flex flex-col transition-all ${
                  hasValue 
                    ? 'bg-white hover:bg-[#efefe0]/30 cursor-pointer' 
                    : 'bg-[#fbfbfa]/70 cursor-not-allowed opacity-30'
                } ${isToday ? 'bg-[#dfefe4]/10 border-[#dfefe4]' : ''}`}
                onClick={hasValue ? () => handleCellClick(cell.dateStr!) : undefined}
                id={cell.dateStr ? `cell-${cell.dateStr}` : undefined}
              >
                
                {/* Date indicator header */}
                {hasValue && (
                  <div className="flex justify-between items-center mb-1.5">
                    <span className={`text-[10.5px] font-mono font-extrabold flex items-center justify-center w-5 h-5 rounded-full ${
                      isToday 
                        ? 'bg-[#2383e2] text-white shadow-2xs scale-105' 
                        : 'text-[#7c7b77]'
                    }`}>
                      {cell.dayNum}
                    </span>
                    {isToday && (
                      <span className="text-[7.5px] bg-[#2383e2]/10 border border-[#2383e2]/20 text-[#2383e2] px-1.5 rounded-full font-bold uppercase tracking-wide">
                        Today
                      </span>
                    )}
                  </div>
                )}

                {/* Day Tasks stacking blocks */}
                <div className="flex-1 space-y-1 overflow-y-auto max-h-[80px] scrollbar-hide py-0.5 select-none">
                  {daysTasks.map((task) => {
                    const isStart = task.startDate === cell.dateStr;

                    return (
                      <div
                        key={task.id}
                        draggable
                        onDragStart={(e) => handleTaskDragStart(task.id, e)}
                        onClick={(e) => {
                          e.stopPropagation();
                          onSelectTask(task);
                        }}
                        className={`px-1.5 py-0.5 rounded-lg text-[9.5px] truncate transition border ${
                          task.status === 'done' 
                            ? 'bg-[#e3fce1] text-[#006600] border-[#c0ecc0] hover:bg-[#d5ffd1]' 
                            : task.status === 'doing'
                            ? 'bg-[#e0f0ff] text-[#004b99] border-[#b0d4ff] hover:bg-[#cfe6ff]'
                            : 'bg-[#faebcc] text-[#8f6b00] border-[#ecd08a] hover:bg-[#f6dfab]'
                        }`}
                        title={`${task.title} (ผู้ได้รับหมาย: ${task.assignee})`}
                      >
                        <div className="flex items-center space-x-1 font-sans font-medium">
                          {isStart && <Sparkles className="h-2.5 w-2.5 text-amber-500 shrink-0" />}
                          <span className="truncate">{task.title}</span>
                        </div>
                      </div>
                    );
                  })}
                </div>

              </div>
            );
          })}
        </div>

      </div>

      {/* Click-to-Create Dialog Popup styled in gorgeous light preset */}
      {showCreatePopup && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-[#37352f]/30 backdrop-blur-xs p-4">
          <div className="bg-white rounded-2xl border border-[#ededeb] shadow-2xl w-full max-w-md p-6 relative animate-fadeIn">
            
            <h3 className="font-bold text-sm text-[#37352f] flex items-center space-x-2 pb-3 border-b border-[#ededeb]">
              <CalendarPlus2 className="h-4.5 w-4.5 text-[#2383e2]" />
              <span>มอบหมายงานสัญญาวัดผลด่วน</span>
            </h3>

            <form onSubmit={handlePopupSubmit} className="space-y-4 mt-4 text-xs text-[#37352f]">
              
              <div>
                <label className="block font-bold text-[#7c7b77] mb-1">ชื่องาน (Task Title)</label>
                <input
                  type="text"
                  placeholder="เช่น 'ร่วมหารือจัดทำสรุปยอดคัดกรองสินค้าคงคลัง'"
                  value={popupTitle}
                  onChange={(e) => setPopupTitle(e.target.value)}
                  className="w-full text-xs p-2.5 rounded-xl border border-[#ededeb] bg-white text-[#37352f] focus:outline-none focus:border-[#2383e2] font-semibold"
                  required
                  disabled={isSubmitting}
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-[#7c7b77] mb-1">วันเริ่มงาน (Start)</label>
                  <input
                    type="date"
                    value={popupStartDate}
                    onChange={(e) => setPopupStartDate(e.target.value)}
                    className="w-full text-xs p-2 rounded-xl border border-[#ededeb] bg-white text-[#37352f]"
                    required
                  />
                </div>
                <div>
                  <label className="block font-bold text-[#7c7b77] mb-1">ครบกำหนดส่ง (Due)</label>
                  <input
                    type="date"
                    value={popupDueDate}
                    onChange={(e) => setPopupDueDate(e.target.value)}
                    className="w-full text-xs p-2 rounded-xl border border-[#ededeb] bg-white text-[#37352f]"
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block font-bold text-[#7c7b77] mb-1">ผู้ทำงานร่วม (Assignee)</label>
                <select
                  value={popupAssignee}
                  onChange={(e) => setPopupAssignee(e.target.value)}
                  className="w-full text-xs p-2 rounded-xl border border-[#ededeb] bg-white text-[#37352f]"
                >
                  <option value="พนักงาน A">พนักงาน A (ฝ่ายขาย)</option>
                  <option value="พนักงาน B">พนักงาน B (ฝ่ายจัดซื้อ)</option>
                  <option value="คุณสมศักดิ์ (HR)">คุณสมศักดิ์ (HR)</option>
                  <option value="หัวหน้างาน">หัวหน้างาน</option>
                </select>
              </div>

              <label className="flex items-center space-x-2 bg-[#fcfbf9] border border-[#ededeb] rounded-xl p-2.5 cursor-pointer">
                <input
                  type="checkbox"
                  checked={popupAiAugment}
                  onChange={(e) => setPopupAiAugment(e.target.checked)}
                  className="rounded text-[#2383e2] focus:ring-[#2383e2] bg-white border-[#ededeb] h-3.5 w-3.5"
                />
                <span className="text-[10px] text-[#7c7b77] leading-relaxed font-bold">
                  สั่ง AI RAG คัดคู่มือเพื่อประมวลกฎเกณฑ์มาตั้งโครงและสกัดงานย่อยอัตโนมัติ
                </span>
              </label>

              <div className="flex justify-end space-x-2 pt-3 border-t border-[#ededeb]">
                <button
                  type="button"
                  onClick={() => setShowCreatePopup(false)}
                  className="px-3.5 py-1.5 text-xs text-[#37352f] bg-white border border-[#ededeb] hover:bg-[#efefe0] rounded-xl font-bold font-sans"
                >
                  ยกเลิก
                </button>
                <button
                  type="submit"
                  disabled={!popupTitle.trim() || isSubmitting}
                  className="px-4 py-1.5 text-xs text-white bg-[#2383e2] hover:bg-[#1a6ec0] font-bold rounded-xl transition font-sans"
                >
                  {isSubmitting ? "ประมวลผล..." : "ตกลงแจกงาน"}
                </button>
              </div>

            </form>

          </div>
        </div>
      )}

    </div>
  );
}
