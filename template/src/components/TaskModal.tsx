/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect, useRef } from 'react';
import { 
  X, CheckSquare, Square, Send, Sparkles, BookOpen, User, 
  Calendar, Trash2, ArrowRightLeft, FileCheck2, HelpCircle 
} from 'lucide-react';
import { Task, SubTask, Comment, KnowledgeDoc, Column } from '../types';

interface TaskModalProps {
  task: Task;
  columns?: Column[];
  onClose: () => void;
  onUpdateTask: (updatedTask: Task) => Promise<void>;
  onDeleteTask: (id: string) => Promise<void>;
  allDocs: KnowledgeDoc[];
  onOpenDoc: (docTitle: string) => void;
}

export default function TaskModal({ 
  task, 
  columns = [],
  onClose, 
  onUpdateTask, 
  onDeleteTask, 
  allDocs,
  onOpenDoc 
}: TaskModalProps) {
  const [comments, setComments] = useState<Comment[]>([]);
  const [newCommentText, setNewCommentText] = useState('');
  const [isSendingComment, setIsSendingComment] = useState(false);
  
  // Interactive fields
  const [title, setTitle] = useState(task.title);
  const [assignee, setAssignee] = useState(task.assignee);
  const [status, setStatus] = useState(task.status);
  const [startDate, setStartDate] = useState(task.startDate || '');
  const [dueDate, setDueDate] = useState(task.dueDate || '');
  const [description, setDescription] = useState(task.description);
  const [isEditing, setIsEditing] = useState(false);
  const commentEndRef = useRef<HTMLDivElement>(null);

  const fetchComments = async () => {
    try {
      const res = await fetch(`/api/tasks/${task.id}/comments`);
      if (res.ok) {
        const data = await res.json();
        setComments(data);
      }
    } catch (err) {
      console.error("Failed to load task comments:", err);
    }
  };

  useEffect(() => {
    fetchComments();
    
    setTitle(task.title);
    setAssignee(task.assignee);
    setStatus(task.status);
    setStartDate(task.startDate || '');
    setDueDate(task.dueDate || '');
    setDescription(task.description);
    setIsEditing(false);
  }, [task]);

  useEffect(() => {
    commentEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [comments]);

  const handleSaveChanges = async () => {
    const updated: Task = {
      ...task,
      title: title.trim(),
      assignee: assignee.trim(),
      status,
      startDate: startDate || null,
      dueDate: dueDate || null,
      description: description.trim(),
    };
    await onUpdateTask(updated);
    setIsEditing(false);
  };

  const handleToggleSubtask = async (subtaskId: string) => {
    const updatedSubtasks = task.subtasks.map(s => {
      if (s.id === subtaskId) {
        return { ...s, completed: !s.completed };
      }
      return s;
    });

    const updated: Task = {
      ...task,
      subtasks: updatedSubtasks
    };
    await onUpdateTask(updated);
  };

  const [newSubtaskTitle, setNewSubtaskTitle] = useState('');
  const handleAddSubtask = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newSubtaskTitle.trim()) return;

    const newSub: SubTask = {
      id: "sub-" + Math.random().toString(36).substring(2, 6),
      title: newSubtaskTitle.trim(),
      completed: false
    };

    const updated: Task = {
      ...task,
      subtasks: [...task.subtasks, newSub]
    };
    await onUpdateTask(updated);
    setNewSubtaskTitle('');
  };

  const handleSendComment = async (textToSend: string) => {
    const text = textToSend || newCommentText;
    if (!text.trim() || isSendingComment) return;

    setIsSendingComment(true);
    if (!textToSend) setNewCommentText('');

    try {
      const res = await fetch(`/api/tasks/${task.id}/comments`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          author: assignee || "พนักงานทีม",
          text: text.trim()
        })
      });

      if (res.ok) {
        await fetchComments();
      }
    } catch (err) {
      console.error("Failed to post comment:", err);
    } finally {
      setIsSendingComment(false);
    }
  };

  const quickQuestions = [
    {
      label: "เบิกงบโปรเจกต์นี้ รหัสแบบฟอร์มคืออะไรครับ? @Agent",
      text: "รบกวนสืบค้นให้หน่อยครับว่าในการพิจารณาเบิกงบโปรเจกต์นี้ จำเป็นต้องใช้แบบฟอร์มรหัสอะไร และยื่นล่วงหน้ากี่วัน? @Agent"
    },
    {
      label: "พักร้อนสิทธิ์ลาได้เท่าไหร่และใช้ฟอร์มไหน? @Agent",
      text: "อยากทราบสิทธิ์ยืดหยุ่นโควตาพักร้อนกับรหัสสแกนฟอร์มลาพนักงานประจำปีครับ @Agent"
    },
    {
      label: "ค่าเบี้ยเดินทางต่างจังหวัดจำกัดงบเท่าไหร่คะ? @Agent",
      text: "ช่วยตรวจสอบเบี้ยเลี้ยงไปต่างจังหวัดเฉพาลวงพนักงาน และราคาจำกัดวงเงินรีฟันด์สูงสุดกี่บาทคะ? @Agent"
    }
  ];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-[#37352f]/40 backdrop-blur-xs p-4 overflow-y-auto">
      <div 
        className="relative bg-white w-full max-w-5xl rounded-xl shadow-2xl flex flex-col md:flex-row overflow-hidden border border-[#ededeb] max-h-[90vh] text-[#37352f] animate-fadeIn"
        id={`modal-${task.id}`}
      >
        
        {/* Left Column: Task Details, Subtasks, RAG Refs */}
        <div className="flex-1 p-6 overflow-y-auto border-r border-[#ededeb] divide-y divide-[#ededeb] scrollbar-hide">
          
          {/* Header Info */}
          <div className="pb-5">
            <div className="flex items-center justify-between mb-4">
              <span className={`inline-flex items-center px-2.5 py-0.5 rounded-md text-[10px] font-bold uppercase ${
                task.status === 'todo' ? 'bg-[#faebcc] text-[#8f6b00] border border-[#ecd08a]' :
                task.status === 'doing' ? 'bg-[#e0f0ff] text-[#004b99] border border-[#b0d4ff]' :
                'bg-[#e3fce1] text-[#006600] border border-[#c0ecc0]'
              }`}>
                {task.status === 'todo' ? ' Planning' :
                 task.status === 'doing' ? ' In Progress' :
                 ' Completed'}
              </span>
              
              <div className="flex items-center space-x-2">
                <button
                  onClick={() => setIsEditing(!isEditing)}
                  className="text-[10px] text-[#37352f] hover:bg-[#efefe0]/70 bg-white border border-[#ededeb] px-3 py-1.5 rounded-lg font-bold transition select-none"
                >
                  {isEditing ? 'ยกเลิกแก้ไข' : 'แก้ไขข้อมูล'}
                </button>
                <button
                  onClick={() => {
                    if (confirm("คุณแน่ใจว่าต้องการลบการ์ดงานชิ้นนี้ออกหรือไม่?")) {
                      onDeleteTask(task.id);
                    }
                  }}
                  className="text-[10px] text-[#df1c1c] hover:bg-[#df1c1c]/10 bg-white border border-[#ededeb] px-2.5 py-1.5 rounded-lg font-bold transition flex items-center space-x-1"
                  title="Delete card"
                >
                  <Trash2 className="h-3.5 w-3.5" />
                  <span>ลบการ์ด</span>
                </button>
              </div>
            </div>

            {isEditing ? (
              <div className="space-y-3 bg-[#fbfbfa] p-4 rounded-xl border border-[#ededeb] text-xs text-[#37352f]">
                <div>
                  <label className="block text-[10px] uppercase font-bold text-[#7c7b77] mb-1">ชื่องาน (Task Title)</label>
                  <input
                    type="text"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    className="w-full text-xs font-semibold rounded-lg border-[#ededeb] bg-white border p-2 focus:border-[#2383e2] focus:outline-none"
                  />
                </div>
                
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-[10px] uppercase font-bold text-[#7c7b77] mb-1">ผู้รับผิดชอบ (Assignee)</label>
                    <input
                      type="text"
                      value={assignee}
                      onChange={(e) => setAssignee(e.target.value)}
                      className="w-full text-xs font-semibold rounded-lg border-[#ededeb] bg-white border p-2 focus:border-[#2383e2] focus:outline-none"
                    />
                  </div>
                  <div>
                    <label className="block text-[10px] uppercase font-bold text-[#7c7b77] mb-1">สถานะ (Status)</label>
                    <select
                      value={status}
                      onChange={(e) => setStatus(e.target.value)}
                      className="w-full text-xs font-semibold rounded-lg border-[#ededeb] bg-white border p-2 focus:border-[#2383e2] focus:outline-none"
                    >
                      {columns.length > 0 ? (
                        columns.map(c => (
                          <option key={c.id} value={c.id}>{c.title}</option>
                        ))
                      ) : (
                        <>
                          <option value="todo">Planning</option>
                          <option value="doing">In Progress</option>
                          <option value="done">Completed</option>
                        </>
                      )}
                    </select>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-[10px] uppercase font-bold text-[#7c7b77] mb-1">วันเริ่มงาน (Start Date)</label>
                    <input
                      type="date"
                      value={startDate}
                      onChange={(e) => setStartDate(e.target.value)}
                      className="w-full text-xs rounded-lg border-[#ededeb] bg-white border p-2"
                    />
                  </div>
                  <div>
                    <label className="block text-[10px] uppercase font-bold text-[#7c7b77] mb-1">ครบกำหนดส่ง (Due Date)</label>
                    <input
                      type="date"
                      value={dueDate}
                      onChange={(e) => setDueDate(e.target.value)}
                      className="w-full text-xs rounded-lg border-[#ededeb] bg-white border p-2"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-[10px] uppercase font-bold text-[#7c7b77] mb-1">รายละเอียดขอบเขตงาน (Description)</label>
                  <textarea
                    rows={4}
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    className="w-full text-xs font-medium rounded-lg border-[#ededeb] bg-white border p-2 font-sans focus:outline-none"
                  />
                </div>

                <div className="flex justify-end pt-2">
                  <button
                    onClick={handleSaveChanges}
                    className="bg-[#2383e2] text-white text-xs font-bold px-4 py-2 rounded-lg hover:bg-[#1a6ec0] transition"
                  >
                    บันทึกการอัปเดต
                  </button>
                </div>
              </div>
            ) : (
              <div>
                <h2 className="text-xl font-bold text-[#37352f] tracking-tight" id="task-modal-title">
                  {task.title}
                </h2>
                <div className="flex flex-wrap gap-y-2 mt-2.5 text-xs text-[#7c7b77] space-x-6 font-semibold select-none">
                  <span className="flex items-center space-x-1">
                    <User className="h-3.5 w-3.5 text-[#7c7b77] shrink-0" />
                    <span>ผู้รับสิทธิ์: <strong className="text-[#37352f]">{task.assignee}</strong></span>
                  </span>
                  {(task.startDate || task.dueDate) && (
                    <span className="flex items-center space-x-1">
                      <Calendar className="h-3.5 w-3.5 text-[#7c7b77] shrink-0" />
                      <span>
                        กำหนดส่ง: <strong className="text-[#37352f]">{task.startDate ? task.startDate : "N/A"}</strong> ถึง <strong className="text-[#37352f]">{task.dueDate ? task.dueDate : "N/A"}</strong>
                      </span>
                    </span>
                  )}
                </div>

                {/* Subtask Completion Progress bar */}
                {task.subtasks.length > 0 && (
                  <div className="mt-4 bg-[#fbfbfa] p-3 rounded-2xl border border-[#ededeb]">
                    <div className="flex justify-between items-center text-[10px] text-[#7c7b77] font-bold mb-1.5 select-none">
                      <span>สัดส่วนโครงขั้นตอนปฏิบัติ (Sub-tasks checklist)</span>
                      <span className="font-semibold text-[#00aa00]">
                        {task.subtasks.filter(s => s.completed).length}/{task.subtasks.length} ({Math.round((task.subtasks.filter(s => s.completed).length / task.subtasks.length) * 100)}%)
                      </span>
                    </div>
                    <div className="w-full bg-[#ededeb] rounded-full h-2 overflow-hidden border border-[#ededeb]">
                      <div 
                        className="bg-[#00aa00] h-full rounded-full transition-all duration-300" 
                        style={{ width: `${(task.subtasks.filter(s => s.completed).length / task.subtasks.length) * 100}%` }}
                      />
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Description & Context details */}
          {!isEditing && (
            <div className="py-5">
              <h3 className="text-[10px] font-bold tracking-widest uppercase text-[#7c7b77] mb-2 select-none">
                รายละเอียดการปฏิบัติ (Task Specification)
              </h3>
              <div className="bg-[#fcfbf9] text-[#37352f] text-xs p-4 rounded-2xl border border-[#ededeb] whitespace-pre-line leading-relaxed font-sans font-medium">
                {task.description || "ยังไม่มีรายละเอียดระบุไว้ในขั้นตอนงานชิ้นนี้"}
              </div>
            </div>
          )}

          {/* RAG Context References */}
          {task.references && task.references.length > 0 && (
            <div className="py-4">
              <h3 className="text-[10px] font-bold uppercase tracking-widest text-[#7c7b77] mb-2.5 flex items-center space-x-1.5 select-none">
                <BookOpen className="h-3.5 w-3.5 text-[#2383e2] shrink-0" />
                <span>คู่มือองค์กรที่วิจัยดึงจับมาแนบให้พนักงาน (RAG Ref)</span>
              </h3>
              <div className="grid grid-cols-1 gap-2">
                {task.references.map((refTitle, i) => {
                  const docMatch = allDocs.find(d => d.title.includes(refTitle) || refTitle.includes(d.title));
                  return (
                    <div 
                      key={i} 
                      onClick={() => onOpenDoc(refTitle)}
                      className="flex items-center justify-between text-xs bg-[#e0f0ff] hover:bg-[#cfe6ff] text-[#004b99] p-2.5 rounded-2xl border border-[#b0d4ff] cursor-pointer transition select-none shadow-3xs"
                    >
                      <span className="font-bold flex items-center space-x-1.5 truncate text-[11px]">
                        <FileCheck2 className="h-4 w-4 text-[#004b99] shrink-0" />
                        <span className="truncate">{refTitle}</span>
                      </span>
                      <span className="text-[9px] text-[#004b99] bg-white px-2.5 py-0.5 rounded-full border border-[#b0d4ff] shrink-0 font-bold flex items-center space-x-1">
                        <FileCheck2 className="h-3 w-3 inline text-emerald-500 shrink-0" />
                        <span>{docMatch ? docMatch.source : "AI RAG Reference"} • คลิกดูลายละเอียด</span>
                      </span>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Dynamic Checklist / Subtasks section */}
          <div className="py-5 text-[#37352f]">
            <h3 className="text-[10px] font-bold uppercase tracking-widest text-[#7c7b77] mb-3 flex items-center space-x-1.5 select-none">
              <CheckSquare className="h-3.5 w-3.5 text-[#7c7b77] shrink-0" />
              <span>ขั้นตอนปฏิบัติหลัก (Step lists)</span>
            </h3>
            
            <div className="space-y-2 mb-3 max-h-48 overflow-y-auto pr-1">
              {task.subtasks.length === 0 ? (
                <div className="text-[11px] text-[#7c7b77] italic bg-[#fbfbfa] p-4 text-center rounded-2xl border border-[#ededeb] font-semibold">
                  ยังไม่ได้คัดกรองหรือระบุคำสั่งย่อยในงานนี้ คุณสามารถคีย์ระบุเพิ่มเติมทางด้านล่างได้ทันทีครับ
                </div>
              ) : (
                task.subtasks.map(sub => (
                  <div 
                    key={sub.id} 
                    onClick={() => handleToggleSubtask(sub.id)}
                    className={`flex items-start space-x-3 p-2.5 rounded-xl cursor-pointer transition text-xs ${
                      sub.completed 
                        ? 'bg-[#efefe0]/30 text-[#7c7b77] line-through font-bold' 
                        : 'bg-white hover:bg-[#efefe0]/40 text-[#37352f] border border-[#ededeb] font-semibold shadow-2xs'
                    }`}
                  >
                    <button className="shrink-0 mt-0.5">
                      {sub.completed ? (
                        <CheckSquare className="h-4 w-4 text-[#00aa00]" />
                      ) : (
                        <Square className="h-4 w-4 text-[#7c7b77]" />
                      )}
                    </button>
                    <span className="flex-1 leading-normal">{sub.title}</span>
                  </div>
                ))
              )}
            </div>

            <form onSubmit={handleAddSubtask} className="flex mt-2">
              <input
                type="text"
                placeholder="พิมพ์เขียนขั้นตอนซับงานเพิ่มด้วยตัวคุณเอง..."
                value={newSubtaskTitle}
                onChange={(e) => setNewSubtaskTitle(e.target.value)}
                className="flex-1 text-xs px-3.5 py-2 rounded-l-xl border border-[#ededeb] bg-white text-[#37352f] focus:outline-none focus:border-[#2383e2] font-semibold"
              />
              <button 
                type="submit"
                className="bg-white hover:bg-[#efefe0] border-y border-r border-[#ededeb] text-[#37352f] text-[10px] font-bold tracking-wider uppercase px-4 py-2 rounded-r-xl transition select-none cursor-pointer"
              >
                + ADD STEP
              </button>
            </form>
          </div>

        </div>

        {/* Right Column: Q&A Comments Panel with @Agent */}
        <div className="w-full md:w-96 p-5 flex flex-col bg-[#fbfbfa] border-t md:border-t-0 md:border-l border-[#ededeb] max-h-[90vh]">
          
          <div className="flex items-center justify-between pb-3 border-b border-[#ededeb] shrink-0 select-none">
            <div className="flex items-center space-x-2">
              <Sparkles className="h-4 w-4 text-[#00aa00] animate-pulse shrink-0" />
              <h3 className="font-bold text-xs text-[#37352f]">
                Agent QA Discussion
              </h3>
            </div>
            
            <button 
              onClick={onClose} 
              className="text-[#7c7b77] hover:bg-[#efefe0] p-1 rounded-full hover:text-[#37352f] shrink-0 cursor-pointer"
              title="Close Panel"
            >
              <X className="h-4 w-4" />
            </button>
          </div>

          {/* Quick Click Prompts helper */}
          <div className="py-2.5 bg-[#dfefe4]/30 p-2.5 rounded-2xl border border-[#c0ecc0] mt-3 shrink-0 select-none">
            <span className="text-[9px] uppercase font-bold tracking-wider text-[#006600] block mb-1">
              คลิกส่งเพื่อตรวจวัดระเบียบอ้างอิง RAG:
            </span>
            <div className="space-y-1">
              {quickQuestions.map((q, idx) => (
                <button
                  key={idx}
                  onClick={() => handleSendComment(q.text)}
                  disabled={isSendingComment}
                  className="w-full text-left bg-white hover:bg-[#efefe0]/55 text-[9.5px] font-sans text-[#7c7b77] border border-[#ededeb] hover:border-[#7c7b77] px-3.5 py-1.5 rounded-full transition truncate font-semibold cursor-pointer"
                  title={q.text}
                >
                  {q.label}
                </button>
              ))}
            </div>
          </div>

          {/* Chat Stream View */}
          <div className="flex-1 overflow-y-auto my-3 space-y-3 pr-1 text-xs scrollbar-hide">
            {comments.length === 0 ? (
              <div className="flex flex-col items-center justify-center h-48 text-[#7c7b77] text-center italic space-y-2 select-none">
                <HelpCircle className="h-7 w-7 text-[#7c7b77] opacity-60" />
                <span className="text-[10px] font-bold">ยังไม่มีกระทู้คุยในหน้านี้<br />ลองป้อนคำถามพิมพ์ @Agent ดักที่กล่องด้านล่างครับ</span>
              </div>
            ) : (
              comments.map(c => (
                <div 
                  key={c.id} 
                  className={`flex flex-col ${c.isAgent ? 'items-start' : 'items-end'}`}
                >
                  <span className="text-[8.5px] text-[#7c7b77] mb-0.5 px-1 font-semibold select-none">
                    {c.author} • {new Date(c.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </span>
                  
                  <div className={`p-3 rounded-2xl max-w-[85%] leading-relaxed shadow-3xs ${
                    c.isAgent 
                      ? 'bg-white text-[#37352f] rounded-tl-xs border border-[#ededeb] text-[11px] font-sans font-semibold' 
                      : 'bg-[#2383e2] text-white rounded-tr-xs text-[11px] font-sans font-semibold'
                  }`}>
                    {c.isAgent && (
                      <span className="inline-flex items-center space-x-1 px-2.5 py-0.5 rounded-full bg-[#dfefe4] text-[#006600] font-bold text-[7px] mb-1.5 border border-[#c0ecc0]">
                        <Sparkles className="h-2.5 w-2.5 shrink-0 animate-pulse" />
                        <span>MISTY PRIVATE SECURED</span>
                      </span>
                    )}
                    <p className="whitespace-pre-line font-sans">{c.text}</p>
                  </div>
                </div>
              ))
            )}
            <div ref={commentEndRef} />
          </div>

          {/* Chat Form Footer */}
          <div className="mt-auto shrink-0 pt-2 border-t border-[#ededeb]">
            <div className="flex items-center space-x-1.5 mb-1.5 bg-[#dfefe4]/30 rounded-xl p-1.5 text-[9px] text-[#006600] border border-[#c0ecc0] select-none">
              <Sparkles className="h-3 w-3 text-[#00aa00] shrink-0 animate-pulse" />
              <span className="font-bold">พิมพ์ข้อความแล้วปิดด้วย <strong>@Agent</strong> เพื่อสั่งเปิด RAG วิเคราะห์ระเบียบอัตโนมัติ</span>
            </div>
            <div className="flex space-x-1.5 animate-fadeIn">
              <textarea
                rows={1}
                placeholder="พิมพ์ถกเถียงนโยบาย หรือแจกงาน..."
                value={newCommentText}
                onChange={(e) => setNewCommentText(e.target.value)}
                disabled={isSendingComment}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    handleSendComment('');
                  }
                }}
                className="flex-1 bg-white border border-[#ededeb] rounded-xl p-2 text-xs text-[#37352f] focus:outline-none focus:border-[#2383e2] resize-none max-h-16 font-semibold font-sans placeholder-[#a0a0a0]"
              />
              <button
                onClick={() => handleSendComment('')}
                disabled={!newCommentText.trim() || isSendingComment}
                className="bg-white hover:bg-[#efefe0]/70 disabled:bg-white disabled:border-[#ededeb] border border-[#ededeb] text-[#2383e2] p-2.5 rounded-full flex items-center justify-center transition shrink-0 cursor-pointer shadow-3xs"
              >
                <Send className="h-3.5 w-3.5" />
              </button>
            </div>
          </div>

        </div>

      </div>
    </div>
  );
}
