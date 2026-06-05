/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import express from "express";
import path from "path";
import { createServer as createViteServer } from "vite";
import { GoogleGenAI, Type } from "@google/genai";
import dotenv from "dotenv";

// Load environment variables
dotenv.config();

// Ensure state is maintained.
// Since this simulates a local container system, we persist these tables in server-side memory.
interface SubTask {
  id: string;
  title: string;
  completed: boolean;
}

interface Task {
  id: string;
  title: string;
  description: string;
  status: string;
  startDate: string | null;
  dueDate: string | null;
  assignee: string;
  subtasks: SubTask[];
  references: string[];
  createdAt: string;
  updatedAt: string;
  companyId?: string;
  departmentId?: string;
  boardId?: string;
}

interface Column {
  id: string;
  boardId: string;
  title: string;
  dotColor: string;
  textStyle: string;
  badgeBg: string;
  borderActive: string;
}

let columnsDB: Column[] = [];

function getBoardColumns(boardId: string): Column[] {
  const activeBoardId = boardId || "board-1-1";
  const boardCols = columnsDB.filter(c => c.boardId === activeBoardId);
  if (boardCols.length > 0) {
    return boardCols;
  }
  
  const defaults: Column[] = [
    { 
      id: "todo", 
      boardId: activeBoardId,
      title: "To Do", 
      dotColor: "bg-indigo-500", 
      textStyle: "text-indigo-700", 
      badgeBg: "bg-indigo-50 text-indigo-700 font-semibold", 
      borderActive: "border-l-4 border-l-indigo-400"
    },
    { 
      id: "doing", 
      boardId: activeBoardId,
      title: "In Progress", 
      dotColor: "bg-amber-500", 
      textStyle: "text-amber-700", 
      badgeBg: "bg-amber-50 text-amber-700 font-semibold", 
      borderActive: "border-l-4 border-l-amber-400"
    },
    { 
      id: "done", 
      boardId: activeBoardId,
      title: "Complete", 
      dotColor: "bg-emerald-500", 
      textStyle: "text-[#12805c]", 
      badgeBg: "bg-[#e3fcef] text-[#12805c] font-semibold", 
      borderActive: "border-l-4 border-l-emerald-400"
    }
  ];
  columnsDB.push(...defaults);
  return defaults;
}

interface Comment {
  id: string;
  taskId: string;
  author: string;
  text: string;
  isAgent: boolean;
  createdAt: string;
}

interface KnowledgeDoc {
  id: string;
  title: string;
  content: string;
  byteSize: number;
  source: string;
  createdAt: string;
  companyId?: string;     // Scoped to specific company, or "all"
  departmentId?: string;  // Scoped to specific department, or "all"
  boardIds?: string[];    // Scoped to specific board IDs, or empty/undefined for "all"
}

interface Company {
  id: string;
  name: string;
}

interface Department {
  id: string;
  companyId: string;
  name: string;
}

interface Board {
  id: string;
  companyId: string;
  departmentId: string;
  title: string;
}

// Global In-Memory Databases - Multi-Organization Structure
let companiesDB: Company[] = [
  { id: "co-1", name: "บริษัท สยาม มีเดีย จำกัด (Siam Media)" },
  { id: "co-2", name: "บจก. เทคสตาร์ต โซลูชั่น (TechStart)" }
];

let departmentsDB: Department[] = [
  // For Siam Media
  { id: "dep-1", companyId: "co-1", name: "ฝ่ายขายและบริการ (Sales)" },
  { id: "dep-2", companyId: "co-1", name: "ฝ่ายไอทีและพัฒนาระบบ (IT)" },
  { id: "dep-3", companyId: "co-1", name: "ฝ่ายบัญชีและการเงิน (Finance)" },
  // For TechStart
  { id: "dep-4", companyId: "co-2", name: "ฝ่ายทรัพยากรบุคคล (HR)" },
  { id: "dep-5", companyId: "co-2", name: "ทีมวิจัยและพัฒนา (R&D)" }
];

let boardsDB: Board[] = [
  // under Siam Media Sales
  { id: "board-1-1", companyId: "co-1", departmentId: "dep-1", title: "แคมเปญกระตุ้นยอดค้าปลีก (Retail Q2)" },
  { id: "board-1-2", companyId: "co-1", departmentId: "dep-1", title: "โครงการบุกตลาดท่องเที่ยวปริมณฑล" },
  // under Siam Media IT
  { id: "board-2-1", companyId: "co-1", departmentId: "dep-2", title: "พัฒนาระบบหลังบ้าน ERP" },
  // under Siam Media Finance
  { id: "board-3-1", companyId: "co-1", departmentId: "dep-3", title: "จัดการเอกสารเบิกจ่ายเดินทาง" },
  // under TechStart HR
  { id: "board-4-1", companyId: "co-2", departmentId: "dep-4", title: "กระดานปฐมนิเทศพนักงานใหม่" }
];

let knowledgeDB: KnowledgeDoc[] = [
  {
    id: "doc-1",
    title: "คู่มือปฏิบัติงานฝ่ายขายกลุ่มลูกค้า Retail (Retail Sales Policy & Pricing Specs v2.4)",
    content: `ข้อนำแนะในการจัดทำรายงานยอดขายและการเบิกงบประมาณของลูกค้ากลุ่ม Retail:
1. การสรุปรายงานยอดขายจำต้องแนบแบบฟอร์ม 'RT-SALES-SUM-2026' และจำแนกประเภทสินค้าออกเป็น หมวดย่อยสินค้าอุปโภค (Consumer) และ หมวดย่อยสินค้าบริโภค (Grocery) เพื่อให้สอดรับระบบภาษี
2. หากยอดขายรวมไม่ถึงเป้าที่กำหนด พนักงานต้องส่งรายงานบทวิเคราะห์ความแตกต่างเชิงลึก (Retail Gap Analysis) เพิ่มเติมภายใน 3 วันทำการ
3. การเบิกจ่ายงบประมาณโปรเจกต์ของลูกค้ากลุ่ม Retail: สำหรับค่าสื่อโฆษณาและการส่งเสริมการขาย ณ จุดสั่งซื้อ (POSM) ต้องเขียนคำขออนุมัติเบิกเงินด้วยรหัสฟอร์ม 'RETAIL-EXP-F09' เท่านั้น โดยส่งเรื่องอนุมัติล่วงหน้าในรอบกุมภาพันธ์/พฤษภาคม หรือก่อนเริ่มกิจกรรมอย่างน้อย 14 วันเพื่อการจัดซื้อที่ถูกต้อง`,
    byteSize: 840,
    source: "แผนกขาย (Sales Dept)",
    createdAt: "2026-06-01T08:00:00Z",
    companyId: "co-1",
    departmentId: "dep-1",
    boardIds: ["board-1-1"]
  },
  {
    id: "doc-2",
    title: "ระเบียบการเบิกค่าเดินทางและการจัดหาจัดซื้อ (Travel Reimbursement & Procurement Rules)",
    content: `ข้อปฏิบัติและข้อบังคับในการเดินทางออกไปทำงานนอกสถานที่และการเบิกงบเดินทาง:
1. ค่าเบี้ยเลี้ยงการปฏิบัติงานต่างจังหวัดคิดในอัตรา 400 บาทต่อวัน สำหรับพนักงานทั่วไป และ 600 บาทต่อวันสำหรับพนักงานระดับผู้จัดการขึ้นไป
2. สำหรับค่าเดินทางเร่งด่วนในเขตกรุงเทพฯ ด้วยรถไฟฟ้าหรือระบบแท็กซี่ ให้ทำการขออนุมัติผ่านระบบไอทีพร้อมระบุรหัสจัดซื้อบัญชี 'e-Travel-Claim' และลงรหัสค่าใช้จ่าย 'EXP-TRAVEL-501'
3. สิทธิการเบิกที่พักในจังหวัดที่ปฏิบัติงานจำกัดไม่เกิน 1,500 บาทต่อคืน สำหรับพื้นที่ต่างจังหวัด และสูงสุดไม่เกิน 2,500 บาทต่อคืนสำหรับพนักงานที่เดินทางปฏิบัติงานในพื้นที่กรุงเทพมหานคร`,
    byteSize: 760,
    source: "ฝ่ายบัญชีและการเงิน (Finance Dept)",
    createdAt: "2026-06-02T10:00:00Z",
    companyId: "co-1",
    departmentId: "dep-3",
    boardIds: [] // Visible to all boards in co-1 and dep-3
  },
  {
    id: "doc-3",
    title: "คู่มือสวัสดิการพนักงานใหม่ประจำปี 2026 (Employee Handbook & Benefits Manual 2026)",
    content: `สรุปนโยบายการทำงาน สวัสดิการ และการลาของพนักงานประจำปี 2026:
1. เวลาปฏิบัติงานปกติคือ 09:00 น. ถึง 18:00 น. (จันทร์ - ศุกร์) มีระบบสแกนนิ้วยืดหยุ่นได้ถึงเวลา 09:30 น.
2. พนักงานทุกคนที่ผ่านทดลองงานแล้ว มีสิทธิลาพักร้อนประจำปี (Annual Leave) ได้ทั้งหมด 10 วันทำการต่อปี โดยจำเป็นต้องกรอกคำสั่งขอล่วงหน้าผ่านฟอร์ม 'HR-LEAVE-ONLINE' ทางอินทราเน็ตอย่างน้อย 3 วันทำการ
3. สวัสดิการค่ารักษาพยาบาลผู้ป่วยนอก (OPD) ครอบคลุมวงเงินสูงสุด 2,000 บาทต่อครั้ง บัญชีสิทธิจำกัดให้เบิกได้ไม่เกิน 15 ครั้งต่อรอบปีปฏิทิน และมีประกันสุขภาพกลุ่มครอบคลุมทันตกรรมเพิ่มเติม`,
    byteSize: 810,
    source: "ฝ่ายทรัพยากรบุคคล (HR Dept)",
    createdAt: "2026-06-01T09:00:00Z",
    companyId: "co-2",
    departmentId: "dep-4",
    boardIds: [] // Visible to all boards in co-2 and dep-4
  }
];

let tasksDB: Task[] = [
  {
    id: "task-1",
    title: "ทำรายงานสรุปยอดขายกลุ่มลูกค้า Retail",
    description: "สรุปงบการขายของกลุ่มแคมเปญอัญมณีและค้าปลีกรวม สำหรับลูกค้ารายใหญ่ พร้อมแจกแจงรายการตามที่ระเบียบขององค์กรระบุไว้",
    status: "doing",
    startDate: "2026-06-05",
    dueDate: "2026-06-12",
    assignee: "พนักงาน A",
    subtasks: [
      { id: "sub-1-1", title: "เตรียมเอกสารฟอร์ม RT-SALES-SUM-2026 และแยกหมวดหมู่ Consumer/Grocery", completed: false },
      { id: "sub-1-2", title: "เช็กยอดขายรวมว่าผ่านเกณฑ์เป้าจำหน่ายหรือไม่", completed: true }
    ],
    references: ["คู่มือปฏิบัติงานฝ่ายขายกลุ่มลูกค้า Retail (Retail Sales Policy & Pricing Specs v2.4)"],
    createdAt: "2026-06-03T12:00:00Z",
    updatedAt: "2026-06-05T02:00:00Z",
    companyId: "co-1",
    departmentId: "dep-1",
    boardId: "board-1-1"
  },
  {
    id: "task-2",
    title: "จัดหาไฟล์ประเมินและสไลด์ปฐมนิเทศพนักงานใหม่",
    description: "เตรียมสไลด์ต้อนรับเพื่อนร่วมงานท่านใหม่ โดยเฉพาะอย่างยิ่งชี้แจงกฎเกณฑ์พื้นฐานสำหรับการเบิกประกัน OPD และการลากิจลาพักร้อน",
    status: "todo",
    startDate: "2026-06-15",
    dueDate: "2026-06-18",
    assignee: "คุณสมศักดิ์ (HR)",
    subtasks: [
      { id: "sub-2-1", title: "ใส่เงื่อนไขสแกนนิ้วเข้างานก่อน 09:30 น. ลงสไลด์", completed: true },
      { id: "sub-2-2", title: "สลักข้อมูลแบบฟอร์ม HR-LEAVE-ONLINE สำหรับการลากิจสิทธิลาพักร้อน 10 วันต่อปี", completed: false },
      { id: "sub-2-3", title: "ระบุวงเงินค่ารักษาพยาบาลฉุกเฉิน OPD 2,000 บาท/ครั้ง", completed: false }
    ],
    references: ["คู่มือสวัสดิการพนักงานใหม่ประจำปี 2026 (Employee Handbook & Benefits Manual 2026)"],
    createdAt: "2026-06-04T09:00:00Z",
    updatedAt: "2026-06-04T09:00:00Z",
    companyId: "co-2",
    departmentId: "dep-4",
    boardId: "board-4-1"
  },
  {
    id: "task-3",
    title: "ส่งเรื่องเคลมทริปต่างจังหวัดฝ่ายการตลาด",
    description: "พิจารณาเบิกค่าเบี้ยเลี้ยงการพานักวิเคราะห์การตลาดเดินทางสำรวจคลังสินค้ารองเมือง",
    status: "done",
    startDate: "2026-06-02",
    dueDate: "2026-06-04",
    assignee: "พนักงาน B",
    subtasks: [
      { id: "sub-3-1", title: "กรอกรหัส 'e-Travel-Claim' บัญชีค่าใช่จ่าย 'EXP-TRAVEL-501'", completed: true },
      { id: "sub-3-2", title: "เช็กเกณฑ์เบิกที่พักจำกัดไม่เกิน 1,500 บาทต่อคืน สำหรับต่างจังหวัด", completed: true }
    ],
    references: ["ระเบียบการเบิกค่าเดินทางและการจัดหาจัดซื้อ (Travel Reimbursement & Procurement Rules)"],
    createdAt: "2026-06-01T15:00:00Z",
    updatedAt: "2026-06-04T16:00:00Z",
    companyId: "co-1",
    departmentId: "dep-3",
    boardId: "board-3-1"
  }
];

let commentsDB: Comment[] = [
  {
    id: "comment-1",
    taskId: "task-1",
    author: "หัวหน้างาน",
    text: "รบกวนส่งรายงานให้ทันตามระเบียบกำหนดส่งนะพนักงาน A อย่าลืมแนบเอกสารฟอร์มให้ถูกต้องด้วยนะครับ",
    isAgent: false,
    createdAt: "2026-06-05T01:10:00Z"
  },
  {
    id: "comment-2",
    taskId: "task-1",
    author: "AI Agent",
    text: "สวัสดีครับพนักงาน A ตามคู่มือฝ่ายขายกลุ่ม Retail ข้อระบุเบิกงบประมาณและการสรุปรายงานยอดขาย จำเป็นต้องแนบไฟล์แบบฟอร์มหลักชื่อ รหัสบัญชี 'RT-SALES-SUM-2026' และจำแนกตามประเภท Consumer/Grocery นะครับ",
    isAgent: true,
    createdAt: "2026-06-05T01:15:00Z"
  }
];

// Lazy-initialized Gemini AI SDK Instance
let aiClientInstance: GoogleGenAI | null = null;
function getAiClient(): GoogleGenAI {
  if (!aiClientInstance) {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error("GEMINI_API_KEY is not defined. Please add Gemini API Key in 'Settings > Secrets' panel.");
    }
    aiClientInstance = new GoogleGenAI({
      apiKey: apiKey,
      httpOptions: {
        headers: {
          "User-Agent": "aistudio-build",
        }
      }
    });
  }
  return aiClientInstance;
}

// Highly robust local text retrieval matching / keyword scorer representing on-premise localized RAG
function executeRAGSearch(
  query: string, 
  companyId?: string, 
  departmentId?: string, 
  boardId?: string
): { matchedDocs: KnowledgeDoc[]; matchedContentDump: string } {
  // Scoped filtering of manuals based on active context permissions
  const accessibleDocs = knowledgeDB.filter(doc => {
    if (companyId) {
      if (doc.companyId && doc.companyId !== "all" && doc.companyId !== companyId) {
        return false;
      }
    }
    if (departmentId) {
      if (doc.departmentId && doc.departmentId !== "all" && doc.departmentId !== departmentId) {
        return false;
      }
    }
    if (boardId && doc.boardIds && doc.boardIds.length > 0) {
      if (!doc.boardIds.includes(boardId)) {
        return false;
      }
    }
    return true;
  });

  const normalizedQuery = query.toLowerCase();
  
  // Calculate a keyword relevance score for each doc from accessible list
  const scoredDocs = accessibleDocs.map(doc => {
    let score = 0;
    
    // exact phrase search
    const words = normalizedQuery.split(/[\s,.\-\/@]+/);
    words.forEach(word => {
      if (word.length < 2) return;
      
      // matches in title get 10 points
      if (doc.title.toLowerCase().includes(word)) {
        score += 10;
      }
      
      // matches in content get 2 points per occurrence
      const regex = new RegExp(word.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&'), 'gi');
      const matches = doc.content.match(regex);
      if (matches) {
        score += matches.length * 2;
      }
    });

    // Also custom business keyword triggers for realistic Thailand Enterprise demo
    if (normalizedQuery.includes("retail") && doc.title.includes("Retail")) score += 30;
    if (normalizedQuery.includes("ยอดขาย") && doc.title.includes("Retail")) score += 20;
    if (normalizedQuery.includes("งบประมาณ") && doc.title.includes("Retail")) score += 15;
    if (normalizedQuery.includes("posm") && doc.title.includes("Retail")) score += 30;
    if (normalizedQuery.includes("เบิก") && doc.title.includes("Travel")) score += 15;
    if (normalizedQuery.includes("เดินทาง") && doc.title.includes("Travel")) score += 30;
    if (normalizedQuery.includes("ต่างจังหวัด") && doc.title.includes("Travel")) score += 25;
    if (normalizedQuery.includes("พักร้อน") && doc.title.includes("Handbook")) score += 30;
    if (normalizedQuery.includes("สวัสดิการ") && doc.title.includes("Handbook")) score += 20;
    if (normalizedQuery.includes("opd") && doc.title.includes("Handbook")) score += 30;
    if (normalizedQuery.includes("พนักงานใหม่") && doc.title.includes("Handbook")) score += 30;
    if (normalizedQuery.includes("ลา") && doc.title.includes("Handbook")) score += 15;

    return { doc, score };
  });

  // Sort by score desc, filter scores > 0
  const topDocsObj = scoredDocs
    .filter(item => item.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, 2); // Select top-2 documents

  const matchedDocs = topDocsObj.map(item => item.doc);

  let matchedContentDump = "";
  if (matchedDocs.length > 0) {
    matchedContentDump = matchedDocs.map(d => `--- DOCUMENT REFERENCE: [${d.title}] ---\n${d.content}`).join("\n\n");
  } else {
    // Fallback: If no custom trigger, we send previews of our top 2 docs so the model understands the enterprise scope
    matchedContentDump = "Available corporate database manuals:\n" + accessibleDocs.map(d => `- ${d.title}: ${d.content.slice(0, 150)}...`).join("\n");
  }

  return { matchedDocs, matchedContentDump };
}

async function startServer() {
  const app = express();
  const PORT = 3000;

  // Body parser limit expanded for rich docs
  app.use(express.json({ limit: '10mb' }));

  // --- API Endpoints ---

  // 1. Health Status check
  app.get("/api/health", (req, res) => {
    res.json({ status: "ok", time: new Date().toISOString() });
  });

  // Companies Management Endpoints
  app.get("/api/companies", (req, res) => {
    res.json(companiesDB);
  });
  app.post("/api/companies", (req, res) => {
    const { name } = req.body;
    if (!name) return res.status(400).json({ error: "Company name is required." });
    const newCompany: Company = {
      id: "co-" + Math.random().toString(36).substring(2, 6),
      name: name.trim()
    };
    companiesDB.push(newCompany);
    res.status(201).json(newCompany);
  });

  // Departments Management Endpoints
  app.get("/api/departments", (req, res) => {
    const { companyId } = req.query;
    if (companyId) {
      return res.json(departmentsDB.filter(d => d.companyId === companyId));
    }
    res.json(departmentsDB);
  });
  app.post("/api/departments", (req, res) => {
    const { name, companyId } = req.body;
    if (!name || !companyId) return res.status(400).json({ error: "Name and companyId are required." });
    const newDept: Department = {
      id: "dep-" + Math.random().toString(36).substring(2, 6),
      companyId,
      name: name.trim()
    };
    departmentsDB.push(newDept);
    res.status(201).json(newDept);
  });

  // Boards Management Endpoints
  app.get("/api/boards", (req, res) => {
    const { companyId, departmentId } = req.query;
    let filtered = boardsDB;
    if (companyId) filtered = filtered.filter(b => b.companyId === companyId);
    if (departmentId) filtered = filtered.filter(b => b.departmentId === departmentId);
    res.json(filtered);
  });
  app.post("/api/boards", (req, res) => {
    const { title, companyId, departmentId } = req.body;
    if (!title || !companyId || !departmentId) {
      return res.status(400).json({ error: "title, companyId, and departmentId are required." });
    }
    const newBoard: Board = {
      id: "board-" + Math.random().toString(36).substring(2, 6),
      companyId,
      departmentId,
      title: title.trim()
    };
    boardsDB.push(newBoard);
    res.status(201).json(newBoard);
  });

  // 2. Knowledge Documents Vault API
  app.get("/api/knowledge", (req, res) => {
    res.json(knowledgeDB);
  });

  app.post("/api/knowledge", (req, res) => {
    const { title, content, source, companyId, departmentId, boardIds } = req.body;
    if (!title || !content) {
      return res.status(400).json({ error: "Title and content are required parameters." });
    }
    const newDoc: KnowledgeDoc = {
      id: "doc-" + Math.random().toString(36).substring(2, 11),
      title: title.trim(),
      content: content.trim(),
      byteSize: Buffer.byteLength(content, 'utf8'),
      source: source ? source.trim() : "Admin Upload",
      createdAt: new Date().toISOString(),
      companyId: companyId || "all",
      departmentId: departmentId || "all",
      boardIds: boardIds || []
    };
    knowledgeDB.push(newDoc);
    res.status(201).json(newDoc);
  });

  app.delete("/api/knowledge/:id", (req, res) => {
    const { id } = req.params;
    const initialLength = knowledgeDB.length;
    knowledgeDB = knowledgeDB.filter(d => d.id !== id);
    if (knowledgeDB.length === initialLength) {
      return res.status(404).json({ error: "Document not found." });
    }
    res.json({ message: "Document deleted successfully." });
  });

  // 2.5. Kanban Board Columns API
  app.get("/api/columns", (req, res) => {
    const { boardId } = req.query;
    const activeBoardId = (boardId as string) || "board-1-1";
    const cols = getBoardColumns(activeBoardId);
    res.json(cols);
  });

  app.post("/api/columns", (req, res) => {
    const { boardId, title, dotColor, textStyle, badgeBg, borderActive } = req.body;
    if (!title) {
      return res.status(400).json({ error: "Column title is required." });
    }
    const activeBoardId = boardId || "board-1-1";
    const newCol: Column = {
      id: "col-" + Math.random().toString(36).substring(2, 9),
      boardId: activeBoardId,
      title: title.trim(),
      dotColor: dotColor || "bg-indigo-500",
      textStyle: textStyle || "text-indigo-700",
      badgeBg: badgeBg || "bg-indigo-50 text-indigo-700 font-semibold",
      borderActive: borderActive || "border-l-4 border-l-indigo-400"
    };
    columnsDB.push(newCol);
    res.status(201).json(newCol);
  });

  app.put("/api/columns/:id", (req, res) => {
    const { id } = req.params;
    const { title, dotColor, textStyle, badgeBg, borderActive } = req.body;
    
    const colIndex = columnsDB.findIndex(c => c.id === id);
    if (colIndex === -1) {
      return res.status(404).json({ error: "Column not found." });
    }

    columnsDB[colIndex] = {
      ...columnsDB[colIndex],
      title: title !== undefined ? title.trim() : columnsDB[colIndex].title,
      dotColor: dotColor !== undefined ? dotColor : columnsDB[colIndex].dotColor,
      textStyle: textStyle !== undefined ? textStyle : columnsDB[colIndex].textStyle,
      badgeBg: badgeBg !== undefined ? badgeBg : columnsDB[colIndex].badgeBg,
      borderActive: borderActive !== undefined ? borderActive : columnsDB[colIndex].borderActive,
    };

    res.json(columnsDB[colIndex]);
  });

  app.delete("/api/columns/:id", (req, res) => {
    const { id } = req.params;
    const colIndex = columnsDB.findIndex(c => c.id === id);
    if (colIndex === -1) {
      return res.status(404).json({ error: "Column not found." });
    }
    
    const deletingCol = columnsDB[colIndex];
    // Filter it out
    columnsDB = columnsDB.filter(c => c.id !== id);

    // Dynamic clean-up action: if there are tasks currently in this column, move them to another column of the same board
    const activeBoardCols = columnsDB.filter(c => c.boardId === deletingCol.boardId);
    if (activeBoardCols.length > 0) {
      const fallbackColId = activeBoardCols[0].id;
      tasksDB.forEach(t => {
        if (t.boardId === deletingCol.boardId && t.status === id) {
          t.status = fallbackColId;
        }
      });
    }

    res.json({ message: "Column deleted, and task references mapped forward.", fallbackColumnId: activeBoardCols[0]?.id });
  });

  // 3. Tasks REST API
  app.get("/api/tasks", (req, res) => {
    res.json(tasksDB);
  });

  // Automatic Agent task creation and augmentation
  app.post("/api/tasks", async (req, res) => {
    const { title, assignee, status, startDate, dueDate, runAugmentation, companyId, departmentId, boardId, description: manualDescription } = req.body;
    if (!title) {
      return res.status(400).json({ error: "Task title is required." });
    }

    const taskId = "task-" + Math.random().toString(36).substring(2, 11);
    
    let description = manualDescription || "ได้รับมอบหมายการจัดทำงาน";
    let subtasks: SubTask[] = [];
    let references: string[] = [];

    const activeCompanyId = companyId || "co-1";
    const activeDeptId = departmentId || "dep-1";
    const activeBoardId = boardId || "board-1-1";

    // Trigger full RAG task description and subtasks analysis with Gemini if requested
    if (runAugmentation) {
      try {
        const ai = getAiClient();
        // 1. Execute Local RAG search inside corporate manuals database with active constraints
        const { matchedDocs, matchedContentDump } = executeRAGSearch(title, activeCompanyId, activeDeptId, activeBoardId);
        
        // Save references matching documents to list in UI
        references = matchedDocs.map(d => d.title);

        // 2. Draft structured query instructions for Gemini
        const ragPrompt = `คุณคือผู้ช่วย AI ฝ่ายวางแผนงานขององค์กร (Corporate Flow Agent)
เรามีงานชื่อหัวข้อ: "${title}"
พนักงานที่ได้รับมอบหมาย: "${assignee || "ไม่ได้ระบุ"}"

กรุณาศึกษาเนื้อหาคู่มืออ้างอิงของบริษัทต่อไปนี้ (ผลลัพธ์ RAG ในบริบทปัจจุบัน) เพื่อนำมาวิเคราะห์และสกัดกรอบงานที่เหมาะสมและเจาะลึก:
${matchedContentDump}

หน้าที่ของคุณ:
1. เขียนรายละเอียดคำอธิบายภารกิจเชิงลึกในช่อง 'description' (เป็นภาษาไทย) อ้างอิงเงื่อนไข แบบฟอร์ม รหัสจัดซื้อ และกฎเกณฑ์ที่ดึงมาจากคู่มือบริษัทข้างต้นอย่างเคร่งครัด อธิบายบริบทภารกิจให้พนักงานเข้าใจแจ่มแจ้งและไม่มีทางทำพลาด (ห้ามสมมติเรื่องอื่นขึ้นมานอกเหนือจากระเบียบที่มีอยู่)
2. สกัดขั้นตอนย่อยๆ (Subtasks) ที่ต้องทำตามขั้นตอนกฎระเบียบขององค์กร เช่น ดาวน์โหลดแบบฟอร์ม ส่งการขออนุมัติล่วงหน้า ตรวจสอบวงเงินเกณฑ์เบิก เป็นภาษาไทยที่กระชับและปฏิบัติงานได้จริง (Actionable Subtasks)
3. ตรวจสอบว่ามีเอกสารระเบียบการใดบ้างที่อ้างอิงตรงกับงานนี้ ให้ใส่ชื่อหัวข้อคู่มือกลับมาใน 'referencedDocs'

ข้อมูลส่งกลับต้องสอดคล้องกับ JSON schema โดยตรงแบบเป๊ะสุดๆ`;

        const responseObj = await ai.models.generateContent({
          model: "gemini-3.5-flash",
          contents: ragPrompt,
          config: {
            systemInstruction: "You are an automated corporate planning agent that augments company tasks using corporate manuals and returns highly detailed structured business instructions.",
            responseMimeType: "application/json",
            responseSchema: {
              type: Type.OBJECT,
              properties: {
                description: {
                  type: Type.STRING,
                  description: "คำอธิบายภารกิจงานที่ละเอียดและเชื่อมโยงกับระเบียบองค์กรโดยตรง เป็นภาษาไทย"
                },
                subtasks: {
                  type: Type.ARRAY,
                  items: { type: Type.STRING },
                  description: "ขั้นตอนย่อยที่จำเป็นและต้องทำเพื่อให้ผ่านเงื่อนไขระเบียบ เป็นภาษาไทย"
                },
                referencedDocs: {
                  type: Type.ARRAY,
                  items: { type: Type.STRING },
                  description: "รายชื่อคู่มือปฏิบัติงานของบริษัทที่ใช้เป็นอ้างอิง"
                }
              },
              required: ["description", "subtasks", "referencedDocs"]
            }
          }
        });

        const rawText = responseObj.text;
        if (rawText) {
          const payload = JSON.parse(rawText.trim());
          description = payload.description || `งานเกี่ยวกับดีเทล: ${title}`;
          
          if (payload.subtasks && Array.isArray(payload.subtasks)) {
            subtasks = payload.subtasks.map((st: string) => ({
              id: "sub-" + Math.random().toString(36).substring(2, 6),
              title: st,
              completed: false
            }));
          }

          if (payload.referencedDocs && Array.isArray(payload.referencedDocs)) {
            // merge matched docs automatically
            const allRefs = new Set([...references, ...payload.referencedDocs]);
            references = Array.from(allRefs);
          }
        }
      } catch (err: any) {
        console.error("Gemini Task Augmentation failed:", err);
        // Fallback simple keyword match extraction if Gemini isn't fully configured
        description = `กรุณาเริ่มดำเนินงานในหัวข้อ "${title}" โดยยึดปฏิบัติตามมาตรฐานและกฎเกณฑ์กลางของแผนกอย่างเคร่งครัด`;
        const { matchedDocs } = executeRAGSearch(title, activeCompanyId, activeDeptId, activeBoardId);
        references = matchedDocs.map(d => d.title);
        
        // Simple procedural dummy subtasks fallback
        subtasks = [
          { id: "sub-f-1", title: "ทบทวนข้อกำหนดและคู่มือองค์กรที่เกี่ยวข้อง", completed: false },
          { id: "sub-f-2", title: "จัดเตรียมเอกสารและแบบฟอร์มที่ระบุในระเบียบการ", completed: false },
          { id: "sub-f-3", title: "ยื่นเรื่องเสนออนุมัติพิจารณาผลกับหัวหน้าสายงาน", completed: false }
        ];
      }
    }

    const newTask: Task = {
      id: taskId,
      title: title.trim(),
      description,
      status: status || "todo",
      startDate: startDate || null,
      dueDate: dueDate || null,
      assignee: assignee ? assignee.trim() : "พนักงานส่วนกลาง",
      subtasks,
      references,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      companyId: activeCompanyId,
      departmentId: activeDeptId,
      boardId: activeBoardId
    };

    tasksDB.push(newTask);

    // Auto-reply a welcoming agent comment on task board creation
    if (runAugmentation) {
      commentsDB.push({
        id: "comm-" + Math.random().toString(36).substring(2, 9),
        taskId: newTask.id,
        author: "AI Agent",
        text: `สวัสดีครับ บอร์ดได้รับฟังและสร้างการ์ดงานชิ้นนี้แล้วครับ! 🕵️‍♂️ ทางผมได้สกัดคู่มือระเบียบจาก Knowledge Vault ของแผนกที่แอปกำหนด และแนบขั้นตอนสำคัญของโปรเจกต์นี้ไว้ในช่อง Sub-tasks และรายละเอียดเรียบร้อยแล้ว หากติดขัดหรือมีปัญหาสอบถามระเบียบบริษัทเพิ่มเติมสามารถพิมพ์ถามพร้อมแท็ก @Agent ได้เลยครับ!`,
        isAgent: true,
        createdAt: new Date().toISOString()
      });
    }

    res.status(201).json(newTask);
  });

  app.put("/api/tasks/:id", (req, res) => {
    const { id } = req.params;
    const { title, description, status, startDate, dueDate, assignee, subtasks, references, companyId, departmentId, boardId } = req.body;
    
    const taskIndex = tasksDB.findIndex(t => t.id === id);
    if (taskIndex === -1) {
      return res.status(404).json({ error: "Task not found." });
    }

    const updatedTask = {
      ...tasksDB[taskIndex],
      title: title !== undefined ? title : tasksDB[taskIndex].title,
      description: description !== undefined ? description : tasksDB[taskIndex].description,
      status: status !== undefined ? status : tasksDB[taskIndex].status,
      startDate: startDate !== undefined ? startDate : tasksDB[taskIndex].startDate,
      dueDate: dueDate !== undefined ? dueDate : tasksDB[taskIndex].dueDate,
      assignee: assignee !== undefined ? assignee : tasksDB[taskIndex].assignee,
      subtasks: subtasks !== undefined ? subtasks : tasksDB[taskIndex].subtasks,
      references: references !== undefined ? references : tasksDB[taskIndex].references,
      companyId: companyId !== undefined ? companyId : tasksDB[taskIndex].companyId,
      departmentId: departmentId !== undefined ? departmentId : tasksDB[taskIndex].departmentId,
      boardId: boardId !== undefined ? boardId : tasksDB[taskIndex].boardId,
      updatedAt: new Date().toISOString()
    };

    tasksDB[taskIndex] = updatedTask;
    res.json(updatedTask);
  });

  app.delete("/api/tasks/:id", (req, res) => {
    const { id } = req.params;
    const initialLength = tasksDB.length;
    tasksDB = tasksDB.filter(t => t.id !== id);
    commentsDB = commentsDB.filter(c => c.taskId !== id);
    if (tasksDB.length === initialLength) {
      return res.status(404).json({ error: "Task not found." });
    }
    res.json({ message: "Task and its associated comments deleted successfully." });
  });

  // 4. Task Comments & Q&A Board API
  app.get("/api/tasks/:taskId/comments", (req, res) => {
    const { taskId } = req.params;
    const taskComments = commentsDB.filter(c => c.taskId === taskId);
    res.json(taskComments);
  });

  app.post("/api/tasks/:taskId/comments", async (req, res) => {
    const { taskId } = req.params;
    const { author, text } = req.body;

    if (!text) {
      return res.status(400).json({ error: "Comment text cannot be empty." });
    }

    const task = tasksDB.find(t => t.id === taskId);
    if (!task) {
      return res.status(404).json({ error: "Task code not found." });
    }

    // Save direct user comment
    const newComment: Comment = {
      id: "comm-" + Math.random().toString(36).substring(2, 11),
      taskId,
      author: author ? author.trim() : "พนักงาน",
      text: text.trim(),
      isAgent: false,
      createdAt: new Date().toISOString()
    };
    commentsDB.push(newComment);

    const lowercaseText = text.toLowerCase();
    
    // Check if user tagged "@Agent" or typed a query implying they want the assistant's feedback
    const mentionsAgent = lowercaseText.includes("@agent") || lowercaseText.includes("@ai") || lowercaseText.includes("ถามแชท");
    
    if (mentionsAgent) {
      try {
        const ai = getAiClient();
        
        // 1. Local RAG Retrieval with Scoping
        const { matchedDocs, matchedContentDump } = executeRAGSearch(
          text + " " + task.title,
          task.companyId,
          task.departmentId,
          task.boardId
        );

        const promptText = `คุณคือ Agent อัจฉริยะฝ่ายกฎระเบียบและให้ข้อมูลแก่พนักงานในบอร์ดงานของบริษัท (Corporate Agent Helper)

ข้อมูลของงานปัจจุบันที่กำลังทำอยู่:
- ชื่องาน: "${task.title}"
- รายละเอียดงาน: "${task.description}"
- สถานะงาน: ${task.status}
- ขั้นตอนย่อยในงาน (Subtasks): ${task.subtasks.map(s => `${s.title} (สถานะ: ${s.completed ? 'เสร็จแล้ว' : 'ยังไม่เสร็จ'})`).join(", ")}

เนื้อหาจากคู่มือหรือเอกสารกฎระเบียบบริษัทที่ได้รับการค้นหาและดึงมาเสริมการตอบคำถามภายใต้สิทธิ์แผนกปัจจุบัน (RAG Result):
${matchedContentDump}

ข้อความของเพื่อนร่วมงานที่ถามคุณในบอร์ด:
"${text}"

หน้าที่ของคุณ:
1. ตอบกลับเพื่อนร่วมงานอย่างเป็นมิตร สุภาพ รวดเร็ว และกระชับ เป็นภาษาไทย
2. ไขข้อข้องใจหรือตอบคำถามโดยอ้างอิงจากกฎเกณฑ์หรือแบบฟอร์มที่ระบุใน RAG Result โดยตรง (เช่น ชื่อรหัสฟอร์ม วงเงิน วันล่วงหน้า) เพื่อให้เขาทำรายการเบิกจ่ายหรือจัดทำรายงานได้ถูกต้องทันที
3. ชี้แจงชัดเจนว่าอ้างอิงจากบทบัญญัติใด (อย่างเป็นทางการ) หากไม่พบข้อมูลคำตอบแน่ชัดในเอกสาร ให้บอกข้อมูลตามตรง และแนะนำให้พนักงานติอต่อฝ่ายที่ดูแลรับผิดชอบ (เช่น ติดต่อ HR สำหรับ OPD เป็นต้น)
4. อย่านำเสนอสิ่งสมมติที่ไม่มีจริงในระเบียบคำสั่งข้างต้นเด็ดขาด`;

        const replyResponse = await ai.models.generateContent({
          model: "gemini-3.5-flash",
          contents: promptText,
          config: {
            systemInstruction: "You are an on-premise helpful corporate agent that answers employee task questions using company documents."
          }
        });

        const agentText = replyResponse.text || "ขออภัยครับ ทาง AI ติดขัดปัญหาในระบบฐานข้อมูลชั่วคราว ไม่สามารถดึงระเบียบอ้างอิงได้ในขณะนี้";
        
        const agentComment: Comment = {
          id: "comm-" + Math.random().toString(36).substring(2, 11),
          taskId,
          author: "AI Agent",
          text: agentText.trim(),
          isAgent: true,
          createdAt: new Date().toISOString()
        };
        
        commentsDB.push(agentComment);
      } catch (err: any) {
        console.error("Gemini comment reply helper error:", err);
        
        // Nice dynamic deterministic fallback helper
        let fallbackText = "ได้รับทราบคำถามแล้วครับพนักงาน ขณะนี้เครือข่าย AI ระบบปิดออฟไลน์อยู่ แต่จากสถิติข้อมูลองค์กร: ";
        if (lowercaseText.includes("เบิก") || lowercaseText.includes("งบ") || lowercaseText.includes("ฟอร์ม")) {
          fallbackText += "สำหรับโครงการกลุ่ม Retail กรุณาแนบแบบฟอร์ม RT-SALES-SUM-2026 หรือใช้สิทธิเบิกจ่าย POSM ผ่านรหัสเอกสาร RETAIL-EXP-F09 ล่วงหน้าอย่างน้อย 14 วันครับ";
        } else if (lowercaseText.includes("เดินทาง") || lowercaseText.includes("ค่าที่พัก") || lowercaseText.includes("แท็กซี่")) {
          fallbackText += "การเบิกเดินทางนอกสถานที่ให้ยื่นผ่านคำขอระบบ 'e-Travel-Claim' รหัสระเบียบบัญชี EXP-TRAVEL-501 อัตรารีฟันด์ต่างจังหวัดจำกัดที่พัก 1,500 บาท/คืนครับ";
        } else if (lowercaseText.includes("ลา") || lowercaseText.includes("วันหยุด") || lowercaseText.includes("พักร้อน") || lowercaseText.includes("opd")) {
          fallbackText += "สิทธิการลาพักร้อนทำรายการล่วงหน้า 3 วันด้วยแบบฟอร์ม 'HR-LEAVE-ONLINE' วงเงินสิทธิเบิก OPD ผู้ป่วยนอกอยู่ที่สูงสุด 2,000 บาท/รอบบิลครั้งครับ";
        } else {
          fallbackText += "กรุณาทบทวนเอกสารในหน้า Knowledge Vault หรือทิ้งโน้ตสอบถาม Admin ไว้ครับ";
        }

        commentsDB.push({
          id: "comm-" + Math.random().toString(36).substring(2, 11),
          taskId,
          author: "AI Agent",
          text: fallbackText,
          isAgent: true,
          createdAt: new Date().toISOString()
        });
      }
    }

    res.status(201).json(newComment);
  });

  // 5. General Chat proxy with on-prem RAG retrieval and multi-task creation capability!
  app.post("/api/chat", async (req, res) => {
    const { message, companyId, departmentId, boardId } = req.body;
    if (!message) {
      return res.status(400).json({ error: "Message content is required." });
    }

    const activeCompanyId = companyId || "co-1";
    const activeDeptId = departmentId || "dep-1";
    const activeBoardId = boardId || "board-1-1";

    try {
      const ai = getAiClient();
      const { matchedDocs, matchedContentDump } = executeRAGSearch(message, activeCompanyId, activeDeptId, activeBoardId);

      const promptText = `คุณคือ Agent อัจฉริยะฝ่ายกฎระเบียบและสแกนกระดานจัดการวางแผนงานของบริษัท (Corporate Automated Agent) ชื่อ "Misty AI"

เนื้อหาจากคู่มือหรือเอกสารกฎระเบียบบริษัทที่ได้รับการค้นหาและดึงมาเสริมการตอบคำถามภายใต้สิทธิ์แผนกปัจจุบัน (RAG Result):
${matchedContentDump}

ข้อความของเพื่อนพนักงานในแชท:
"${message}"

หน้าที่ของคุณ:
1. ตอบกลับเพื่อนพนักงานด้วยความสุภาพ อ้อมน้อม และรวดเร็ว ใส่ลงในช่อง 'reply' (เป็นภาษาไทย)
2. หากเพื่อนพนักงานสั่งให้คุณ "สร้างงาน" "สร้างภารกิจ" หรือ "กำหนดแผนปฏิบัติงานหลายๆ ขั้นพร้อมกัน" (เช่น: "ช่วยสร้างงาน 3 งานนี้ลงบอร์ดที: งาน A, งาน B และงาน C" หรือระเบียบการเบิกจ่ายภารกิจร่วม) ให้คุณสกัดรายละเอียดชื่องานลงในรายการ 'tasksToCreate' โดยกำหนดชื่องานให้เข้าใจง่าย มีความยาวกระชับ และระบุผู้เดินทางหรือผู้รับผิดชอบงาน (Assignee) หรือเลือกจากกลุ่ม: "พนักงาน A", "พนักงาน B", "คุณสมศักดิ์ (HR)", "หัวหน้างาน" (หรือให้ว่างไว้เป็นค่าว่าง)
หากผู้ใช้ไม่ได้สั่งให้ทำหรือสร้างกระดานงานใดๆ เลย ให้ตั้งอาเรย์ 'tasksToCreate' เป็นอาเรย์ว่าง [] เสมอ

ข้อมูลส่งกลับต้องสอดคล้องกับ JSON schema โดยตรงแบบเป๊ะสุดๆ`;

      const responseObj = await ai.models.generateContent({
        model: "gemini-3.5-flash",
        contents: promptText,
        config: {
          systemInstruction: "You are Misty AI, an on-premise secure corporate assistant that answers general inquiries and schedules/provisions enterprise task boards dynamically.",
          responseMimeType: "application/json",
          responseSchema: {
            type: Type.OBJECT,
            properties: {
              reply: {
                type: Type.STRING,
                description: "ข้อความตอบกลับสนทนากับพนักงานระบุคำแนะนำและคำอธิบายตามหลักเกณฑ์ระเบียบ เป็นภาษาไทย"
              },
              tasksToCreate: {
                type: Type.ARRAY,
                items: {
                  type: Type.OBJECT,
                  properties: {
                    title: { type: Type.STRING, description: "หัวข้อภารกิจหรืองานย่อยที่จะเพิ่มสะสมลงกระดาน" },
                    assignee: { type: Type.STRING, description: "ชื่อหรือฝ่ายรับผิดชอบ เช่น พนักงาน A, พนักงาน B, หรือสุ่มว่างไว้" },
                    description: { type: Type.STRING, description: "รายละเอียดงานเบื้องต้นอ้างอิงและเชื่อมโยงกับความปลอดภัยของระเบียบ" }
                  },
                  required: ["title", "assignee"]
                },
                description: "สำหรับใช้สร้างภารกิจลงบอร์ดงานพร้อมกันหลายงานตามสัญญาทีม"
              }
            },
            required: ["reply", "tasksToCreate"]
          }
        }
      });

      const rawText = responseObj.text || "{}";
      const payload = JSON.parse(rawText.trim());
      let reply = payload.reply || "ยินดีให้บริการข้อคิดเห็นครับ";
      const createdTasks: Task[] = [];

      if (payload.tasksToCreate && Array.isArray(payload.tasksToCreate) && payload.tasksToCreate.length > 0) {
        payload.tasksToCreate.forEach((item: any) => {
          const taskId = "task-" + Math.random().toString(36).substring(2, 11);
          const tTitle = item.title || "งานที่ได้รับมอบหมายด่วน";
          const tAssignee = item.assignee || "พนักงานส่วนกลาง";
          const tDesc = item.description || `งานที่สกัดอัตโนมัติจาก Misty Chat: ${tTitle}`;

          const newTask: Task = {
            id: taskId,
            title: tTitle.trim(),
            description: tDesc.trim(),
            status: "todo",
            startDate: null,
            dueDate: null,
            assignee: tAssignee,
            subtasks: [
              { id: "sub-" + Math.random().toString(36).substring(2, 6), title: "สแกนระเบียบคู่มือและแนวทางดำเนินการร่วมกัน", completed: false },
              { id: "sub-" + Math.random().toString(36).substring(2, 6), title: "ดำเนินการและยื่นใบคำขออนุมัติตามขั้นตอนบริษัท", completed: false }
            ],
            references: matchedDocs.map(d => d.title),
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            companyId: activeCompanyId,
            departmentId: activeDeptId,
            boardId: activeBoardId
          };

          tasksDB.push(newTask);
          createdTasks.push(newTask);
        });

        // Add helpful note to the user in the conversation bubble
        reply = reply + `\n\n📢 **[Misty AI System Notification]**: ระบบได้สร้างและบันทึกงานใหม่สะสมจำนวน **${createdTasks.length} รายการ** ไว้ในกระดานแผงควบคุมบอร์ดงานโครงการนี้ให้เรียบร้อยแล้ว: ${createdTasks.map(t => `\n- **${t.title}** มอบหมายให้: _${t.assignee}_`).join("")}`;
      }

      res.json({
        reply,
        references: matchedDocs.map(d => d.title),
        createdTasksCount: createdTasks.length
      });
    } catch (err) {
      console.error("General chat api error:", err);
      // Fallback response with manual local keyword scanning
      let reply = "สวัสดีครับพนักงาน ผมได้ทำรายการสแกนระเบียบในระบบปิดภายในของคุณเรียบร้อยแล้ว: ";
      let references: string[] = [];
      const { matchedDocs } = executeRAGSearch(message, activeCompanyId, activeDeptId, activeBoardId);
      if (matchedDocs.length > 0) {
        reply += "พบข้อมูลคู่มือสิทธิ์ของคุณที่ใกล้เคียงที่สุดดังนี้ครับ:\n\n" + matchedDocs.map(d => `- **${d.title}**: ${d.content.slice(0, 200)}...`).join("\n\n") + "\n\nกรุณาเข้าศึกษาเพิ่มเติมใน Vault ได้โดยตรงครับ";
        references = matchedDocs.map(d => d.title);
      } else {
        reply += "เนื่องจากสัญญาณเครือข่ายจำลองแบบปิดมีข้อจำกัด และระบบสแกนไม่สามารถหารายการที่ตรงกับความจำเพาะนี้ได้โดยตรง ลองทบทวนคำสำคัญ เช่น OPD, เดินทาง หรือ พักร้อน อีกครั้งครับ";
      }
      res.json({ reply, references, createdTasksCount: 0 });
    }
  });

  // --- Integrate Vite Client Middleware ---

  if (process.env.NODE_ENV !== "production") {
    // Vite Dev Mode configuration
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    // Production Mode serving compiled SPA build
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  // PORT bindings
  app.listen(PORT, "0.0.0.0", () => {
    console.log(`[Enterprise On-Prem Secure Server] running cleanly at http://0.0.0.0:${PORT}`);
  });
}

startServer().catch(err => {
  console.error("Critical server launch failure:", err);
});
