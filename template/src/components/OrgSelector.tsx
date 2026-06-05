/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import { 
  Building2, Users, Layers, Plus, ChevronDown, Check, Sparkles, FolderDot, X, ArrowRight
} from 'lucide-react';
import { Company, Department, Board } from '../types';

interface OrgSelectorProps {
  companies: Company[];
  departments: Department[];
  boards: Board[];
  
  activeCompanyId: string;
  activeDepartmentId: string;
  activeBoardId: string;
  
  setActiveCompanyId: (id: string) => void;
  setActiveDepartmentId: (id: string) => void;
  setActiveBoardId: (id: string) => void;
  
  onRefreshData: () => Promise<void>;
}

export default function OrgSelector({
  companies,
  departments,
  boards,
  activeCompanyId,
  activeDepartmentId,
  activeBoardId,
  setActiveCompanyId,
  setActiveDepartmentId,
  setActiveBoardId,
  onRefreshData
}: OrgSelectorProps) {

  // UI Control states
  const [showAddCompany, setShowAddCompany] = useState(false);
  const [showAddDept, setShowAddDept] = useState(false);
  const [showAddBoard, setShowAddBoard] = useState(false);
  
  const [newCompanyName, setNewCompanyName] = useState('');
  const [newDeptName, setNewDeptName] = useState('');
  const [newBoardTitle, setNewBoardTitle] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Filter departments for chosen company
  const filteredDepts = departments.filter(d => d.companyId === activeCompanyId);
  // Filter boards for chosen department
  const filteredBoards = boards.filter(b => b.departmentId === activeDepartmentId);

  // Active Objects
  const activeCompany = companies.find(c => c.id === activeCompanyId) || companies[0];
  const activeDepartment = departments.find(d => d.id === activeDepartmentId) || filteredDepts[0];
  const activeBoard = boards.find(b => b.id === activeBoardId) || filteredBoards[0];

  const handleCreateCompany = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newCompanyName.trim() || isSubmitting) return;
    
    setIsSubmitting(true);
    try {
      const res = await fetch("/api/companies", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: newCompanyName.trim() })
      });
      if (res.ok) {
        const created = await res.json();
        setNewCompanyName('');
        setShowAddCompany(false);
        await onRefreshData();
        setActiveCompanyId(created.id);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleCreateDept = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newDeptName.trim() || isSubmitting) return;
    
    setIsSubmitting(true);
    try {
      const res = await fetch("/api/departments", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ 
          name: newDeptName.trim(), 
          companyId: activeCompanyId 
        })
      });
      if (res.ok) {
        const created = await res.json();
        setNewDeptName('');
        setShowAddDept(false);
        await onRefreshData();
        setActiveDepartmentId(created.id);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleCreateBoard = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newBoardTitle.trim() || isSubmitting) return;
    
    setIsSubmitting(true);
    try {
      const res = await fetch("/api/boards", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ 
          title: newBoardTitle.trim(), 
          companyId: activeCompanyId,
          departmentId: activeDepartmentId
        })
      });
      if (res.ok) {
        const created = await res.json();
        setNewBoardTitle('');
        setShowAddBoard(false);
        await onRefreshData();
        setActiveBoardId(created.id);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="bg-white rounded-2xl border border-[#ededeb] p-5 shadow-2xs space-y-4" id="org-selector-container">
      
      {/* Header and Add buttons row */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-[#ededeb] select-none">
        <div className="flex items-center space-x-2">
          <div className="p-1.5 bg-[#f1f1ef] rounded-lg text-[#37352f]">
            <FolderDot className="h-4 w-4" />
          </div>
          <div>
            <h4 className="text-xs font-bold text-[#37352f] uppercase tracking-wider">
              Workspace & Org Hierarchy
            </h4>
            <p className="text-[10px] text-[#7c7b77] font-medium">
              สลับบริษัท แผนก และบอร์ดงาน เพื่อจัดขอบเขตความปลอดภัยให้กับเอกสาร
            </p>
          </div>
        </div>

        {/* Adding Actions */}
        <div className="flex flex-wrap items-center gap-1.5 text-[10px] font-bold">
          <button 
            type="button"
            onClick={() => setShowAddCompany(true)}
            className="px-2.5 py-1.5 rounded-lg border border-[#ededeb] hover:bg-[#efefe0]/50 text-[#37352f] flex items-center space-x-1 cursor-pointer transition"
          >
            <Plus className="h-3 w-3" />
            <span>เพิ่มบริษัท</span>
          </button>
          
          <button 
            type="button"
            onClick={() => setShowAddDept(true)}
            className="px-2.5 py-1.5 rounded-lg border border-[#ededeb] hover:bg-[#efefe0]/50 text-[#37352f] flex items-center space-x-1 cursor-pointer transition"
          >
            <Plus className="h-3 w-3" />
            <span>เพิ่มแผนก</span>
          </button>

          <button 
            type="button"
            onClick={() => setShowAddBoard(true)}
            className="px-2.5 py-1.5 bg-[#e0f0ff] hover:bg-[#b0d4ff]/40 text-[#004b99] rounded-lg border border-[#b0d4ff] flex items-center space-x-1 cursor-pointer transition"
          >
            <Plus className="h-3 w-3" />
            <span>เปิดบอร์ดโปรเจกต์ใหม่</span>
          </button>
        </div>
      </div>

      {/* Selectors grid - Styled like Notion properties */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-xs font-medium">
        
        {/* Company Dropdown Column */}
        <div className="space-y-1">
          <span className="text-[10px] text-[#7c7b77] font-bold uppercase tracking-wide block">
            🏢 เลือกบริษัท (Company)
          </span>
          <div className="relative">
            <select
              value={activeCompanyId}
              onChange={(e) => setActiveCompanyId(e.target.value)}
              className="w-full bg-[#fbfbfa] border border-[#ededeb] text-[#37352f] font-semibold p-2.5 pr-8 rounded-xl appearance-none focus:outline-none focus:border-[#2383e2] transition cursor-pointer relative z-10"
            >
              {companies.map(c => (
                <option key={c.id} value={c.id}>{c.name}</option>
              ))}
            </select>
            <ChevronDown className="h-4 w-4 text-[#7c7b77] absolute right-3.5 top-1/2 -translate-y-1/2 z-20 pointer-events-none" />
          </div>
        </div>

        {/* Department Dropdown Column */}
        <div className="space-y-1">
          <span className="text-[10px] text-[#7c7b77] font-bold uppercase tracking-wide block">
            👥 เลือกแผนก/ทีม (Department)
          </span>
          <div className="relative">
            <select
              value={activeDepartmentId}
              onChange={(e) => setActiveDepartmentId(e.target.value)}
              className="w-full bg-[#fbfbfa] border border-[#ededeb] text-[#37352f] font-semibold p-2.5 pr-8 rounded-xl appearance-none focus:outline-none focus:border-[#2383e2] transition cursor-pointer relative z-10"
              disabled={filteredDepts.length === 0}
            >
              {filteredDepts.length === 0 ? (
                <option value="">-- ยังไม่มีแผนก --</option>
              ) : (
                filteredDepts.map(d => (
                  <option key={d.id} value={d.id}>{d.name}</option>
                ))
              )}
            </select>
            <ChevronDown className="h-4 w-4 text-[#7c7b77] absolute right-3.5 top-1/2 -translate-y-1/2 z-20 pointer-events-none" />
          </div>
        </div>

        {/* Board Dropdown Column */}
        <div className="space-y-1">
          <span className="text-[10px] text-[#7c7b77] font-bold uppercase tracking-wide block">
            🔒 บอร์ดโครงการ/แผนงาน (Active Board)
          </span>
          <div className="relative">
            <select
              value={activeBoardId}
              onChange={(e) => setActiveBoardId(e.target.value)}
              className="w-full bg-[#2383e2] text-white font-bold p-2.5 pr-8 rounded-xl appearance-none focus:outline-none focus:ring-2 focus:ring-[#2383e2]/30 transition cursor-pointer relative z-10"
              disabled={filteredBoards.length === 0}
            >
              {filteredBoards.length === 0 ? (
                <option value="">-- ยังไม่มีโปรเจกต์บอร์ด --</option>
              ) : (
                filteredBoards.map(b => (
                  <option key={b.id} value={b.id}>{b.title}</option>
                ))
              )}
            </select>
            <ChevronDown className="h-4 w-4 text-white absolute right-3.5 top-1/2 -translate-y-1/2 z-20 pointer-events-none" />
          </div>
        </div>

      </div>

      {/* active context breadcrumb status bar */}
      <div className="bg-[#fcfcfb] border border-[#ededeb] rounded-xl px-4 py-2 flex flex-col md:flex-row md:items-center justify-between text-[11px] text-[#7c7b77] gap-2 select-none">
        <div className="flex flex-wrap items-center gap-1 font-semibold text-[#37352f]">
          <span className="text-[#2383e2]">{activeCompany ? activeCompany.name : 'Unknown Company'}</span>
          <span>/</span>
          <span className="text-purple-600">{activeDepartment ? activeDepartment.name : 'No Department'}</span>
          <span>/</span>
          <span className="bg-[#dfefe0] text-emerald-800 px-2 py-0.5 rounded-lg border border-[#cbe4cf] text-[10.5px]">
            🎯 active: {activeBoard ? activeBoard.title : 'No Board'}
          </span>
        </div>
        <div className="flex items-center space-x-1 font-semibold text-[10px] text-[#2cbb5d]">
          <span className="w-1.5 h-1.5 bg-[#2cbb5d] rounded-full animate-pulse" />
          <span>RAG Scope Synchronized (Only matching documents can be searched)</span>
        </div>
      </div>

      {/* ====== Modals for creating new org entries ====== */}
      {showAddCompany && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-3xl border border-[#ededeb] p-6 max-w-sm w-full space-y-4 shadow-2xl animate-scaleUp">
            <div className="flex justify-between items-center pb-2 border-b border-[#ededeb]">
              <h4 className="text-sm font-bold text-[#37352f] flex items-center space-x-2">
                <Building2 className="h-4 w-4 text-[#2383e2]" />
                <span>เพิ่มบริษัทใหม่ (New Company)</span>
              </h4>
              <button 
                onClick={() => setShowAddCompany(false)}
                className="p-1 rounded-lg hover:bg-gray-100 transition text-[#7c7b77]"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
            
            <form onSubmit={handleCreateCompany} className="space-y-4">
              <div className="space-y-1.5 text-xs">
                <label className="block text-[#7c7b77] font-semibold">ชื่อบริษัทอย่างเป็นทางการ</label>
                <input 
                  type="text" 
                  value={newCompanyName}
                  onChange={(e) => setNewCompanyName(e.target.value)}
                  placeholder="เช่น บริษัท เอสซีจี เมคเกอร์ จำกัด"
                  className="w-full text-xs p-2.5 rounded-xl border border-[#ededeb] focus:border-[#2383e2] focus:outline-none text-[#37352f] font-semibold"
                  required
                />
              </div>

              <div className="flex justify-end gap-2 text-xs pt-2">
                <button 
                  type="button" 
                  onClick={() => setShowAddCompany(false)}
                  className="px-3.5 py-2 hover:bg-gray-100 text-[#7c7b77] rounded-xl font-bold cursor-pointer"
                >
                  ยกเลิก
                </button>
                <button 
                  type="submit" 
                  disabled={isSubmitting || !newCompanyName.trim()}
                  className="px-4 py-2 bg-[#2383e2] hover:bg-[#1a6ec0] text-white rounded-xl font-bold flex items-center space-x-1 cursor-pointer"
                >
                  <span>สร้างบริษัท</span>
                  <ArrowRight className="h-3 w-3" />
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {showAddDept && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-3xl border border-[#ededeb] p-6 max-w-sm w-full space-y-4 shadow-2xl animate-scaleUp">
            <div className="flex justify-between items-center pb-2 border-b border-[#ededeb]">
              <h4 className="text-sm font-bold text-[#37352f] flex items-center space-x-2">
                <Users className="h-4 w-4 text-purple-600" />
                <span>เพิ่มแผนกใหม่ (New Department)</span>
              </h4>
              <button 
                onClick={() => setShowAddDept(false)}
                className="p-1 rounded-lg hover:bg-gray-100 transition text-[#7c7b77]"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
            
            <form onSubmit={handleCreateDept} className="space-y-4">
              <div className="space-y-1 md:space-y-1.5 text-xs">
                <p className="text-[11px] text-[#7c7b77] font-semibold bg-[#efefe0]/40 p-2.5 rounded-xl">
                  สร้างสำหรับบริษัท: <strong className="text-[#37352f]">{activeCompany?.name}</strong>
                </p>
                <label className="block text-[#7c7b77] font-semibold pt-2">ชื่อแผนก/ฝ่าย</label>
                <input 
                  type="text" 
                  value={newDeptName}
                  onChange={(e) => setNewDeptName(e.target.value)}
                  placeholder="เช่น ฝ่ายทรัพยากรบุคคล (HR)"
                  className="w-full text-xs p-2.5 rounded-xl border border-[#ededeb] focus:border-[#2383e2] focus:outline-none text-[#37352f] font-semibold"
                  required
                />
              </div>

              <div className="flex justify-end gap-2 text-xs pt-2">
                <button 
                  type="button" 
                  onClick={() => setShowAddDept(false)}
                  className="px-3.5 py-2 hover:bg-gray-100 text-[#7c7b77] rounded-xl font-bold cursor-pointer"
                >
                  ยกเลิก
                </button>
                <button 
                  type="submit" 
                  disabled={isSubmitting || !newDeptName.trim()}
                  className="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-xl font-bold flex items-center space-x-1 cursor-pointer"
                >
                  <span>สร้างแผนก</span>
                  <ArrowRight className="h-3 w-3" />
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {showAddBoard && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-3xl border border-[#ededeb] p-6 max-w-sm w-full space-y-4 shadow-2xl animate-scaleUp">
            <div className="flex justify-between items-center pb-2 border-b border-[#ededeb]">
              <h4 className="text-sm font-bold text-[#37352f] flex items-center space-x-2">
                <Layers className="h-4 w-4 text-emerald-600" />
                <span>เปิดบอร์ดโปรเจกต์งานใหม่</span>
              </h4>
              <button 
                onClick={() => setShowAddBoard(false)}
                className="p-1 rounded-lg hover:bg-gray-100 transition text-[#7c7b77]"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
            
            <form onSubmit={handleCreateBoard} className="space-y-4">
              <div className="bg-[#fcfbf9] border border-[#ededeb] p-3 rounded-xl space-y-1 text-[11px] text-[#7c7b77] font-semibold">
                <div>บริษัท: <span className="text-[#37352f] font-bold">{activeCompany?.name}</span></div>
                <div>แผนก: <span className="text-[#37352f] font-bold">{activeDepartment?.name}</span></div>
              </div>

              <div className="space-y-1.5 text-xs">
                <label className="block text-[#7c7b77] font-semibold">ชื่อบอร์ดแผนงาน/บอร์ดติดตามงาน</label>
                <input 
                  type="text" 
                  value={newBoardTitle}
                  onChange={(e) => setNewBoardTitle(e.target.value)}
                  placeholder="เช่น พัฒนาระเบียบจัดซื้อจัดจ้าง Retail"
                  className="w-full text-xs p-2.5 rounded-xl border border-[#ededeb] focus:border-[#2383e2] focus:outline-none text-[#37352f] font-semibold"
                  required
                />
              </div>

              <div className="flex justify-end gap-2 text-xs pt-2">
                <button 
                  type="button" 
                  onClick={() => setShowAddBoard(false)}
                  className="px-3.5 py-2 hover:bg-gray-100 text-[#7c7b77] rounded-xl font-bold cursor-pointer"
                >
                  ยกเลิก
                </button>
                <button 
                  type="submit" 
                  disabled={isSubmitting || !newBoardTitle.trim()}
                  className="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl font-bold flex items-center space-x-1 cursor-pointer"
                >
                  <span>เปิดบอร์ด</span>
                  <ArrowRight className="h-3 w-3" />
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}
