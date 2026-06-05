/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import { 
  BookOpen, Plus, FileText, Upload, Trash2, ShieldCheck, 
  Layers, Database, Calendar, FolderClock, Check
} from 'lucide-react';
import { KnowledgeDoc, Company, Department, Board } from '../types';

interface KnowledgeVaultProps {
  docs: KnowledgeDoc[];
  onAddDoc: (title: string, content: string, source: string, companyId: string, departmentId: string, boardIds: string[]) => Promise<void>;
  onDeleteDoc: (id: string) => Promise<void>;
  selectedDocTitleFromTask: string | null;
  setSelectedDocTitleFromTask: (title: string | null) => void;
  companies: Company[];
  departments: Department[];
  boards: Board[];
  activeCompanyId: string;
  activeDepartmentId: string;
  activeBoardId: string;
}

export default function KnowledgeVault({ 
  docs, 
  onAddDoc, 
  onDeleteDoc,
  selectedDocTitleFromTask,
  setSelectedDocTitleFromTask,
  companies,
  departments,
  boards,
  activeCompanyId,
  activeDepartmentId,
  activeBoardId
}: KnowledgeVaultProps) {
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [source, setSource] = useState('ฝ่ายธุรการองค์กร');
  const [showAddForm, setShowAddForm] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [activeViewDocId, setActiveViewDocId] = useState<string | null>(null);

  // Grouping state for organizing documents by company, team, or board
  const [groupBy, setGroupBy] = useState<'company' | 'board' | 'none'>('company');

  // Document accessibility scoping states
  const [docCompanyId, setDocCompanyId] = useState<string>('all');
  const [docDepartmentId, setDocDepartmentId] = useState<string>('all');
  const [docBoardIds, setDocBoardIds] = useState<string[]>([]);

  // File upload drag-and-drop handling
  const [dragActive, setDragActive] = useState(false);
  
  const handleDrag = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === "dragenter" || e.type === "dragover") {
      setDragActive(true);
    } else if (e.type === "dragleave") {
      setDragActive(false);
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);

    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      const file = e.dataTransfer.files[0];
      handleFileIngestion(file);
    }
  };

  const handleFileInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      handleFileIngestion(file);
    }
  };

  const handleFileIngestion = (file: File) => {
    if (file.type !== "text/plain" && !file.name.endsWith('.txt') && !file.name.endsWith('.md')) {
      alert("ขออภัยครับ ระบบจำลอง RAG ขณะนี้รองรับเอกสารประเภทข้อความทั่วไป (.txt, .md) เพื่อการประมวลผลความปลอดภัยอย่างถูกต้องในระบบ Sandbox");
      return;
    }

    const reader = new FileReader();
    reader.onload = async (event) => {
      if (event.target && event.target.result) {
        setTitle(file.name.replace(/\.[^/.]+$/, "")); // Strip extension for title
        setContent(event.target.result as string);
        setSource("อัปโหลดไฟล์อัตโนมัติ");
        setShowAddForm(true);
      }
    };
    reader.readAsText(file);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !content.trim() || isSubmitting) return;

    setIsSubmitting(true);
    try {
      await onAddDoc(
        title.trim(), 
        content.trim(), 
        source.trim(), 
        docCompanyId, 
        docDepartmentId, 
        docBoardIds
      );
      setTitle('');
      setContent('');
      setSource('ฝ่ายธุรการองค์กร');
      setDocCompanyId('all');
      setDocDepartmentId('all');
      setDocBoardIds([]);
      setShowAddForm(false);
    } catch (err) {
      console.error("Failed to append document:", err);
    } finally {
      setIsSubmitting(false);
    }
  };

  const renderDocCard = (doc: KnowledgeDoc) => {
    const isActiveMatch = selectedDocTitleFromTask && (doc.title.includes(selectedDocTitleFromTask) || selectedDocTitleFromTask.includes(doc.title));
    const isExpanded = activeViewDocId === doc.id;

    return (
      <div 
        key={doc.id}
        className={`bg-white rounded-2xl p-5 border transition-all flex flex-col justify-between ${
          isActiveMatch 
            ? 'border-[#2383e2] ring-2 ring-[#2383e2]/10 shadow-2xs' 
            : 'border-[#ededeb] hover:border-[#7c7b77]/60'
        }`}
        id={`doc-${doc.id}`}
      >
        <div className="space-y-3">
          
          {/* Doc Title & Actions row */}
          <div className="flex items-start justify-between gap-2">
            <div className="flex items-start space-x-2.5 min-w-0">
              <div className="p-2 bg-[#efefe0]/40 text-[#2383e2] rounded-xl mt-0.5 shrink-0 border border-[#ededeb]">
                <FileText className="h-4.5 w-4.5" />
              </div>
              <div className="min-w-0">
                <h4 className="text-xs font-bold text-[#37352f] line-clamp-2 leading-snug">
                  {doc.title}
                </h4>
                <p className="text-[10px] text-[#7c7b77] font-semibold truncate mt-0.5">
                  ผู้ออกระเบียบ: <strong className="text-[#37352f]">{doc.source}</strong>
                </p>
              </div>
            </div>

            <button
              onClick={() => {
                if (confirm("ต้องการลบเอกสารระเบียบชิ้นนี้ออกหรือไม่? (อาจมีผลต่อความแม่นยำในการวิจัย RAG ของบอร์ด AI)")) {
                  onDeleteDoc(doc.id);
                }
              }}
              className="text-[#7c7b77] hover:text-[#df1c1c] hover:bg-[#df1c1c]/10 p-1.5 rounded-full transition shrink-0"
              title="Delete Document"
            >
              <Trash2 className="h-3.5 w-3.5" />
            </button>
          </div>

          {/* Metadata indicators */}
          <div className="flex items-center space-x-3 text-[10px] text-[#7c7b77] bg-[#fbfbfa] px-2.5 py-1.5 rounded-xl border border-[#ededeb] font-sans font-semibold">
            <span className="flex items-center space-x-1">
              <Layers className="h-3 w-3" />
              <span>ขนาด: <strong className="text-[#37352f]">{doc.byteSize} Bytes</strong></span>
            </span>
            <span>•</span>
            <span className="flex items-center space-x-1">
              <Calendar className="h-3 w-3" />
              <span>{new Date(doc.createdAt).toLocaleDateString([], { month: 'short', day: 'numeric' })}</span>
            </span>
          </div>

          {/* Colored Scope Badge Tags */}
          <div className="flex flex-wrap gap-1 py-1 text-[9px] font-sans font-bold">
            <span className="px-2 py-0.5 rounded bg-blue-50 text-blue-700 border border-blue-100 flex items-center space-x-1 shrink-0">
              <span>🏢</span>
              <span>
                {doc.companyId === 'all' 
                  ? 'แชร์ทุกบริษัท (All Co.)' 
                  : (companies.find(c => c.id === doc.companyId)?.name?.split(" (")?.[0] || 'บริษัทเฉพาะกลุ่ม')}
              </span>
            </span>
            <span className="px-2 py-0.5 rounded bg-purple-50 text-purple-700 border border-purple-100 flex items-center space-x-1 shrink-0">
              <span>👥</span>
              <span>
                {doc.departmentId === 'all' 
                  ? 'ทุกแผนก (All Depts)' 
                  : (departments.find(d => d.id === doc.departmentId)?.name?.split(" (")?.[0] || 'แผนกเฉพาะกลุ่ม')}
              </span>
            </span>
            {doc.boardIds && doc.boardIds.length > 0 ? (
              doc.boardIds.map(bid => {
                const boardObj = boards.find(b => b.id === bid);
                return (
                  <span key={bid} className="px-2 py-0.5 rounded bg-amber-50 text-amber-700 border border-amber-100 flex items-center space-x-1 shrink-0">
                    <span>🔒</span>
                    <span>บอร์ด: {boardObj ? boardObj.title?.split(" (")?.[0] : bid}</span>
                  </span>
                );
              })
            ) : (
              <span className="px-2 py-0.5 rounded bg-emerald-50 text-emerald-700 border border-emerald-100 flex items-center space-x-1 shrink-0">
                <span>🔓</span>
                <span>ทุกกระดานงาน (All Boards)</span>
              </span>
            )}
          </div>

          {/* Dynamic expansion toggle */}
          <div className="border-t border-[#ededeb] pt-2 text-xs">
            {isExpanded ? (
              <div className="space-y-2">
                <p className="text-[#37352f] bg-[#fbfbfa] p-2.5 rounded-xl border border-[#ededeb] whitespace-pre-line text-[11px] leading-relaxed font-sans font-medium">
                  {doc.content}
                </p>
                <button
                  type="button"
                  onClick={() => setActiveViewDocId(null)}
                  className="text-[10px] text-[#7c7b77] font-bold hover:underline block cursor-pointer"
                >
                  ซ่อนรายละเอียด ▲
                </button>
              </div>
            ) : (
              <div className="flex items-center justify-between">
                <p className="text-[#7c7b77] truncate max-w-[190px] text-[10.5px] font-medium">
                  {doc.content.slice(0, 45)}...
                </p>
                <button
                  type="button"
                  onClick={() => setActiveViewDocId(doc.id)}
                  className="text-[10px] text-[#2383e2] font-semibold hover:underline cursor-pointer"
                >
                  อ่านระเบียบกฎเกณฑ์ v
                </button>
              </div>
            )}
          </div>

        </div>

      </div>
    );
  };

  const renderGroupedDocs = () => {
    if (groupBy === 'company') {
      const globalDocs = docs.filter(d => !d.companyId || d.companyId === 'all');
      return (
        <div className="space-y-6 animate-fadeIn">
          {/* Global Group */}
          {globalDocs.length > 0 && (
            <div className="space-y-3">
              <div className="flex items-center space-x-2 pb-1.5 border-b border-[#ededeb]">
                <span className="text-xs font-bold text-[#2383e2] uppercase tracking-wider">🌐 เอกสารร่วมของทุกบริษัท (Global Shared Policies)</span>
                <span className="bg-[#e0f0ff] text-[#004b99] text-[10px] px-2 py-0.5 rounded-full font-bold">
                  {globalDocs.length} ฉบับ
                </span>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {globalDocs.map(doc => renderDocCard(doc))}
              </div>
            </div>
          )}

          {/* Company Groups */}
          {companies.map(company => {
            const companyDocs = docs.filter(d => d.companyId === company.id);
            if (companyDocs.length === 0) return null;

            // Group by department inside company 
            const companyDepts = departments.filter(d => d.companyId === company.id);
            
            return (
              <div key={company.id} className="space-y-4 bg-[#fbfbfa]/60 p-5 rounded-2xl border border-[#ededeb]">
                <div className="flex items-center justify-between border-b border-[#ededeb] pb-2">
                  <h3 className="text-xs font-bold text-[#37352f] uppercase tracking-wider flex items-center space-x-1.5">
                    <span>🏢</span>
                    <span>{company.name}</span>
                  </h3>
                  <span className="bg-[#efefe0] text-[#37352f] text-[10px] px-2.5 py-0.5 rounded-full font-bold font-mono">
                    {companyDocs.length} ฉบับ
                  </span>
                </div>

                {/* All-Dept Docs in this Company */}
                {companyDocs.filter(d => d.departmentId === 'all').length > 0 && (
                  <div className="space-y-2.5">
                    <h4 className="text-[11px] font-bold text-[#7c7b77] pl-1 flex items-center space-x-1">
                      <span>👥</span>
                      <span>ระเบียบปฏิบัติทั่วไปประจำองค์กร (All Departments)</span>
                    </h4>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {companyDocs.filter(d => d.departmentId === 'all').map(doc => renderDocCard(doc))}
                    </div>
                  </div>
                )}

                {/* Specific Depts Docs in this Company */}
                {companyDepts.map(dept => {
                  const deptDocs = companyDocs.filter(d => d.departmentId === dept.id);
                  if (deptDocs.length === 0) return null;

                  return (
                    <div key={dept.id} className="space-y-2.5 pt-2">
                      <h4 className="text-[11px] font-bold text-[#7c7b77] pl-1 flex items-center space-x-1">
                        <span>•</span>
                        <span>{dept.name}</span>
                      </h4>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {deptDocs.map(doc => renderDocCard(doc))}
                      </div>
                    </div>
                  );
                })}
              </div>
            );
          })}
        </div>
      );
    } else if (groupBy === 'board') {
      const generalDocs = docs.filter(d => !d.boardIds || d.boardIds.length === 0);
      return (
        <div className="space-y-6 animate-fadeIn">
          {/* General/Policy Documents */}
          {generalDocs.length > 0 && (
            <div className="space-y-3">
              <div className="flex items-center space-x-2 pb-1.5 border-b border-[#ededeb]">
                <span className="text-xs font-bold text-emerald-700 uppercase tracking-wider">🍀 นโยบายภาพรวมแผนกและบริษัททั่วไป (General Policies)</span>
                <span className="bg-emerald-50 text-emerald-700 text-[10px] px-2 py-0.5 rounded-full font-bold border border-emerald-100">
                  {generalDocs.length} ฉบับ
                </span>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {generalDocs.map(doc => renderDocCard(doc))}
              </div>
            </div>
          )}

          {/* Board Groups */}
          {boards.map(board => {
            const boardDocs = docs.filter(d => d.boardIds && d.boardIds.includes(board.id));
            if (boardDocs.length === 0) return null;

            return (
              <div key={board.id} className="space-y-4 bg-[#fbfbfa]/60 p-5 rounded-2xl border border-[#ededeb]">
                <div className="flex items-center justify-between border-b border-[#ededeb] pb-2">
                  <h3 className="text-xs font-bold text-[#37352f] uppercase tracking-wider flex items-center space-x-1.5">
                    <span>🔒</span>
                    <span>กระดานงาน: {board.title}</span>
                  </h3>
                  <span className="bg-amber-50 text-amber-700 border border-amber-100 text-[10px] px-2.5 py-0.5 rounded-full font-bold font-mono">
                    {boardDocs.length} ฉบับ
                  </span>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {boardDocs.map(doc => renderDocCard(doc))}
                </div>
              </div>
            );
          })}
        </div>
      );
    } else {
      // Flat list (no grouping)
      return (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 animate-fadeIn">
          {docs.map(doc => renderDocCard(doc))}
        </div>
      );
    }
  };

  return (
    <div className="space-y-6 animate-fadeIn text-[#37352f] bg-white" id="vault-wrapper">
      
      {/* Informative Header with Department controls - Notion style */}
      <div className="bg-white rounded-2xl border border-[#ededeb] p-6 text-[#37352f] shadow-2xs relative overflow-hidden">
        <div className="absolute right-0 bottom-0 opacity-5 pointer-events-none select-none">
          <Database className="w-56 h-56 text-[#2383e2]" />
        </div>

        <div className="flex flex-col md:flex-row md:items-center justify-between gap-5 relative z-10">
          <div className="space-y-2 max-w-2xl">
            <div className="inline-flex items-center space-x-1.5 bg-[#e0f0ff] text-[#004b99] px-3 py-1 rounded-full text-[10px] font-bold border border-[#b0d4ff]">
              <ShieldCheck className="h-3.5 w-3.5" />
              <span>100% Secure Private Memory</span>
            </div>
            
            <h2 className="text-2xl font-bold text-[#37352f] flex items-center space-x-1.5">
              <span>Corporate Wiki</span>
            </h2>
            <p className="text-[#7c7b77] text-xs leading-relaxed font-sans mt-1 font-medium">
              ศูนย์รวมคู่มือระเบียบการและขอบเขตกฎเกณฑ์นโยบายบริษัท (Knowledge Vault) สำหรับ RAG AI ดึงสืบค้นมาจัดระเบียบสัญญางาน เพื่อการรักษาความปลอดภัยของข้อมูลสูงสุด
            </p>
          </div>

          <button
            onClick={() => setShowAddForm(!showAddForm)}
            className="bg-[#2383e2] hover:bg-[#1a6ec0] text-white font-bold text-xs px-4 py-2.5 rounded-xl transition shadow-2xs cursor-pointer flex items-center space-x-1.5 self-start md:self-center shrink-0"
          >
            <Plus className="h-4 w-4" />
            <span>{showAddForm ? 'ปิดหน้าต่างแก้ไข' : 'เขียนข้อกำหนดเพิ่ม'}</span>
          </button>
        </div>
      </div>

      {selectedDocTitleFromTask && (
        <div className="bg-[#faebcc]/30 border border-[#ecd08a] p-4 rounded-2xl flex items-center justify-between animate-pulse">
          <div className="flex items-center space-x-2 text-xs text-[#8f6b00] font-bold">
            <BookOpen className="h-4 w-4 shrink-0" />
            <span>กำลังส่องดูระเบียบอ้างอิงจากงาน: <strong>"{selectedDocTitleFromTask}"</strong></span>
          </div>
          <button 
            onClick={() => setSelectedDocTitleFromTask(null)}
            className="text-[#8f6b00] hover:text-[#37352f] font-bold text-[10.5px] bg-[#faebcc] py-1 px-3 rounded-full border border-[#ecd08a]"
          >
            ปลดล็อก
          </button>
        </div>
      )}

      {/* Grid: Document creation panel OR drag-dropper & existing manuals list */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        
        {/* Create Manual Panel - styled beautifully in light colors */}
        {showAddForm && (
          <div className="lg:col-span-4 bg-[#fbfbfa]/90 rounded-2xl border border-[#ededeb] p-5 shadow-2xs space-y-4 max-h-[75vh] overflow-y-auto">
            <h3 className="font-bold text-xs text-[#37352f] pb-2 border-b border-[#ededeb] flex items-center space-x-1.5 uppercase tracking-wide">
              <Plus className="h-4 w-4 text-[#7c7b77]" />
              <span>เขียนนโยบายใหม่ (Add Rule)</span>
            </h3>

            <form onSubmit={handleSubmit} className="space-y-3.5 text-xs text-[#37352f]">
              <div>
                <label className="block font-bold text-[#7c7b77] mb-1">หัวข้อคู่มือ (Document Title)</label>
                <input
                  type="text"
                  placeholder="เช่น 'นโยบายจัดทำใบเสร็จและการเบิกค่าเบี้ยซ่อม'"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="w-full text-xs p-2.5 rounded-xl border border-[#ededeb] bg-white text-[#37352f] focus:border-[#2383e2] focus:outline-none font-semibold"
                  required
                />
              </div>

              <div>
                <label className="block font-bold text-[#7c7b77] mb-1">แผนกผู้ดูแล (Department Issuer)</label>
                <input
                  type="text"
                  value={source}
                  onChange={(e) => setSource(e.target.value)}
                  className="w-full text-xs p-2.5 rounded-xl border border-[#ededeb] bg-white text-[#37352f] focus:border-[#2383e2] focus:outline-none font-semibold"
                  placeholder="เช่น ฝ่ายธุรการ, ฝ่ายบัญชีการเงิน"
                  required
                />
              </div>

               <div>
                <label className="block font-bold text-[#7c7b77] mb-1">รายละเอียดข้อกำหนด (Content Policy)</label>
                <textarea
                  rows={8}
                  placeholder={`เขียนรายละเอียดระเบียบที่นี่ เช่น:\n- การซ่อมบำรุงในเครือมีงบเบิกสูงสุด 500 บาทต่อครั้ง\n- ต้องยื่นฟอร์ม IT-REPAIR และแนบรูปประกอบ\n- แจ้งฝ่ายจัดซื้อล่วงหน้า 2 วัน`}
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  className="w-full text-xs p-2.5 rounded-xl border border-[#ededeb] bg-white text-[#37352f] focus:border-[#2383e2] focus:outline-none font-medium leading-relaxed font-sans"
                  required
                />
              </div>

              {/* Company, Department, and Board Accessibility Visibility Restrictions */}
              <div className="border-t border-b border-[#ededeb] py-3.5 my-2 space-y-3">
                <span className="text-[10px] uppercase font-semibold text-[#7c7b77] tracking-wider block">
                  🔒 ขอบเขตสิทธิ์ความปลอดภัย (Security Access Scope)
                </span>
                
                {/* Select Company Scope */}
                <div className="space-y-1">
                  <label className="block text-[#7c7b77] font-semibold">ขอบเขตบริษัท (Company Access)</label>
                  <select
                    value={docCompanyId}
                    onChange={(e) => {
                      setDocCompanyId(e.target.value);
                      setDocDepartmentId('all');
                      setDocBoardIds([]);
                    }}
                    className="w-full text-xs p-1.5 rounded-lg border border-[#ededeb] bg-white text-[#37352f] font-semibold"
                  >
                    <option value="all">🌐 ทุกบริษัท (แชร์คู่มือร่วมแกนกลาง)</option>
                    {companies.map(c => (
                      <option key={c.id} value={c.id}>{c.name}</option>
                    ))}
                  </select>
                </div>

                {/* Select Department Scope */}
                {docCompanyId !== 'all' && (
                  <div className="space-y-1 animate-fadeIn">
                    <label className="block text-[#7c7b77] font-semibold">ขอบเขตแผนก (Department Access)</label>
                    <select
                      value={docDepartmentId}
                      onChange={(e) => {
                        setDocDepartmentId(e.target.value);
                        setDocBoardIds([]);
                      }}
                      className="w-full text-xs p-1.5 rounded-lg border border-[#ededeb] bg-white text-[#37352f] font-semibold"
                    >
                      <option value="all">👥 ทุกแผนกในบริษัท</option>
                      {departments.filter(d => d.companyId === docCompanyId).map(d => (
                        <option key={d.id} value={d.id}>{d.name}</option>
                      ))}
                    </select>
                  </div>
                )}

                {/* Multiselect Board Scope */}
                {docCompanyId !== 'all' && docDepartmentId !== 'all' && (
                  <div className="space-y-1 animate-fadeIn">
                    <label className="block text-[#7c7b77] font-semibold">จำกัดเฉพาะบอร์ดงาน (Board Access)</label>
                    <div className="max-h-24 overflow-y-auto border border-[#ededeb] rounded-lg p-2 bg-white space-y-1">
                      {boards.filter(b => b.departmentId === docDepartmentId).length === 0 ? (
                        <p className="text-[10px] text-[#7c7b77]">ไม่มีรายงานบอร์ดในแผนกนี้</p>
                      ) : (
                        boards.filter(b => b.departmentId === docDepartmentId).map(b => {
                          const isChecked = docBoardIds.includes(b.id);
                          return (
                            <label key={b.id} className="flex items-center space-x-2 cursor-pointer select-none py-0.5">
                              <input
                                type="checkbox"
                                checked={isChecked}
                                onChange={() => {
                                  if (isChecked) {
                                    setDocBoardIds(docBoardIds.filter(id => id !== b.id));
                                  } else {
                                    setDocBoardIds([...docBoardIds, b.id]);
                                  }
                                }}
                                className="rounded text-[#2383e2] focus:ring-[#2383e2]"
                              />
                              <span className="text-[10.5px] text-[#37352f] font-medium">{b.title}</span>
                            </label>
                          );
                        })
                      )}
                    </div>
                  </div>
                )}
              </div>

              <button
                type="submit"
                disabled={isSubmitting || !title.trim() || !content.trim()}
                className="w-full py-2.5 text-xs bg-[#2383e2] hover:bg-[#1a6ec0] disabled:bg-[#ededeb] disabled:text-[#a0a0a0] text-white font-bold rounded-xl transition cursor-pointer"
              >
                {isSubmitting ? 'กำลังบันทึก...' : 'บันทึกแนบคู่มือกระดาน RAG'}
              </button>
            </form>
          </div>
        )}

        {/* Existing Documents and Drag Dropper column */}
        <div className={`${showAddForm ? 'lg:col-span-8' : 'lg:col-span-12'} space-y-4`}>
          
          {/* Drag & Drop Upload Space - Notion light styled */}
          <div 
            onDragEnter={handleDrag}
            onDragOver={handleDrag}
            onDragLeave={handleDrag}
            onDrop={handleDrop}
            className={`border border-dashed rounded-2xl p-5 flex flex-col items-center justify-center text-center transition ${
              dragActive 
                ? 'border-[#2383e2] bg-[#e0f0ff]/40 text-[#2383e2]' 
                : 'border-[#ededeb] bg-[#fbfbfa] hover:bg-[#efefe0]/40 text-[#7c7b77]'
            }`}
          >
            <input 
              type="file" 
              id="file-vault-upload" 
              multiple={false} 
              accept=".txt,.md"
              onChange={handleFileInput}
              className="hidden" 
            />
            
            <Upload className={`h-8 w-8 mb-2 shrink-0 ${dragActive ? 'text-[#2383e2] animate-bounce' : 'text-[#7c7b77]'}`} />
            
            <p className="text-xs font-semibold text-[#37352f]">
              ลากวางไฟล์เอกสารคู่มือ หรือ <label htmlFor="file-vault-upload" className="text-[#2383e2] underline cursor-pointer hover:text-[#1a6ec0] font-bold">เลือกคลิกเพื่ออัปโหลดตรงนี้</label>
            </p>
            <p className="text-[10px] text-[#7c7b77] mt-1 font-medium">
              จำลองระบบ RAG สแกนรองรับเอกสารนามสกุลข้อความทั่วไป เช่น .txt และ .md เท่านั้น
            </p>
          </div>

          {/* Grouping Selection Tabs */}
          <div className="flex flex-wrap items-center justify-between border-b border-[#ededeb] pb-3 gap-2.5">
            <div className="flex items-center space-x-1 bg-[#efefe0]/50 p-1 rounded-xl border border-[#ededeb]">
              <button
                type="button"
                onClick={() => setGroupBy('company')}
                className={`text-[10.5px] font-bold px-3 py-1.5 rounded-lg transition-all cursor-pointer ${
                  groupBy === 'company' 
                    ? 'bg-white text-[#2383e2] shadow-2xs' 
                    : 'text-[#7c7b77] hover:text-[#37352f]'
                }`}
              >
                🏢 แยกตามบริษัท & แผนก
              </button>
              <button
                type="button"
                onClick={() => setGroupBy('board')}
                className={`text-[10.5px] font-bold px-3 py-1.5 rounded-lg transition-all cursor-pointer ${
                  groupBy === 'board' 
                    ? 'bg-white text-[#2383e2] shadow-2xs' 
                    : 'text-[#7c7b77] hover:text-[#37352f]'
                }`}
              >
                🔒 แยกตามโปรเจกต์บอร์ด
              </button>
              <button
                type="button"
                onClick={() => setGroupBy('none')}
                className={`text-[10.5px] font-bold px-3 py-1.5 rounded-lg transition-all cursor-pointer ${
                  groupBy === 'none' 
                    ? 'bg-white text-[#2383e2] shadow-2xs' 
                    : 'text-[#7c7b77] hover:text-[#37352f]'
                }`}
              >
                📂 แสดงทั้งหมด
              </button>
            </div>
            <div className="text-[10px] text-[#7c7b77] font-semibold">
              แสดงเอกสารของระบบทั้งหมด: <strong className="text-[#37352f]">{docs.length} ฉบับ</strong>
            </div>
          </div>

          {/* Grouped Lists or Flat Grid of Documents */}
          <div className="space-y-4">
            {renderGroupedDocs()}
          </div>

        </div>

      </div>

    </div>
  );
}
