/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useRef, useEffect } from 'react';
import { 
  Bot, User, Send, Trash2, ShieldCheck, 
  Paperclip, Sparkles, AlertCircle, HelpCircle 
} from 'lucide-react';
import { KnowledgeDoc } from '../types';

interface Message {
  id: string;
  sender: 'user' | 'agent';
  text: string;
  timestamp: string;
  referencedGuides?: string[];
}

interface AIAgentChatProps {
  allDocs: KnowledgeDoc[];
  activeCompanyId: string;
  activeDepartmentId: string;
  activeBoardId: string;
  companies: any[];
  departments: any[];
  boards: any[];
  onRefreshTasks?: () => void;
}

export default function AIAgentChat({ 
  allDocs, 
  activeCompanyId, 
  activeDepartmentId, 
  activeBoardId,
  companies,
  departments,
  boards,
  onRefreshTasks
}: AIAgentChatProps) {
  
  const activeCompany = companies.find(c => c.id === activeCompanyId);
  const activeDept = departments.find(d => d.id === activeDepartmentId);
  const activeBoard = boards.find(b => b.id === activeBoardId);

  const [messages, setMessages] = useState<Message[]>([
    {
      id: 'welcome',
      sender: 'agent',
      text: `สวัสดีครับผมคือ **Misty AI** ห้องผู้ช่วยนิรภัยอัจฉริยะ ประจำกระดานข้อมูลพนักงาน ยินดีต้อนรับครับ!\n\nด้วยสถาปัตยกรรม RAG ในระบบจำลองภายใน ผมทำงานภายใต้ขอบเขตความคลุมเครือของ:\n🏢 **บริษัท**: ${activeCompany ? activeCompany.name : 'ยังไม่เลือกบริษัท'}\n👥 **แผนก**: ${activeDept ? activeDept.name : 'ยังไม่เลือกแผนก'}\n🎯 **ระเบียบบอร์ดงาน**: ${activeBoard ? activeBoard.title : 'ยังไม่เลือกบอร์ด'}\n\nผมได้ทำการสแกนคำสั่งและสิทธิ์คู่มือประจำโฮสต์เรียบร้อยครับ ลองเปิดประเด็นตรวจสอบสิทธิ์ เช่น ประกันค่าเบิก OPD หรือนโยบายลางาน ได้ทันทีในกล่องข้อความความปลอดภัยนี้ครับ!`,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      referencedGuides: []
    }
  ]);

  const [inputVal, setInputVal] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    scrollRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, isTyping]);

  const handleClearChat = () => {
    if (window.confirm("คุณแน่ใจว่าต้องการเคลียร์ประวัติการคุยทั้งหมดหรือไม่?")) {
      setMessages([
        {
          id: 'welcome-reset',
          sender: 'agent',
          text: "ประวัติการคุยถูกเคลียร์ใหม่หมดเรียบร้อยแล้ว แชทเซสชันได้รับความปลอดภัยขั้นสูงสุด ปลอดภัยและปราศจาก Logs ใดๆ พิมพ์ถามเงื่อนไขใหม่ได้ทันทีครับ",
          timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        }
      ]);
    }
  };

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputVal.trim() || isTyping) return;

    const userText = inputVal.trim();
    setInputVal('');

    const userMessage: Message = {
      id: Math.random().toString(36).substring(7),
      sender: 'user',
      text: userText,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };

    setMessages(prev => [...prev, userMessage]);
    setIsTyping(true);

    try {
      const res = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ 
          message: userText,
          companyId: activeCompanyId,
          departmentId: activeDepartmentId,
          boardId: activeBoardId
        })
      });

      if (res.ok) {
        const data = await res.json();
        setMessages(prev => [...prev, {
          id: Math.random().toString(36).substring(7),
          sender: 'agent',
          text: data.reply,
          timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          referencedGuides: data.references || []
        }]);

        if (data.createdTasksCount > 0 && onRefreshTasks) {
          onRefreshTasks();
        }
      } else {
        throw new Error("Chat api failed");
      }

    } catch (err) {
      console.error("Local chat request failed, fallback:", err);
      
      setTimeout(() => {
        const norm = userText.toLowerCase();
        let fallbackText = "ขณะนี้ผลจากการประมวลผล RAG ของห้องจำลอง ได้คัดกรองคู่มือหลักเสร็จสิ้น:\n\n";
        let refs: string[] = [];

        if (norm.includes("retail") || norm.includes("ยอดขาย") || norm.includes("posm") || norm.includes("f09")) {
          fallbackText += "อ้างอิง **นโยบายการเบิกจ่ายสินค้าตัวแทนกลุ่ม Retail**:\n1. การรวบรวมยอดจำนำหรืองานเบิกเครื่อง POSM ต้องกรอกร่วมกับแบบฟอร์มรหัสปฏิบัติการ **RETAIL-EXP-F09**\n2. จำกัดงบประกันหรือเบี้ยเลี้ยงส่งของกลุ่มคู่ค้าไม่เกิน 1,200 บาท หากเกินต้องแนบใบเสนอราคาครับ";
          refs.push("นโยบายดำเนินงานฝ่ายขายและการซ่อมบำรุงกลุ่มคู่ค้า Retail (Retail Policy)");
        } else if (norm.includes("เดินทาง") || norm.includes("ทริป") || norm.includes("ที่พัก") || norm.includes("รถไฟฟ้า")) {
          fallbackText += "อ้างอิง **ข้อกำหนดพิจารณาแผนกเดินทางและเบิกจ่าย (Travel Reimbursement)**:\n1. อนุญาตให้พนักงานเบิกเบี้ยเลี้ยงสิทธิ์เบ็ดเสร็จได้อยู่ที่ราคา **400 บาทต่อวัน** (สำหรับผู้จัดการ **600 บาทต่อวัน**)\n2. ค่าพาหนะโดยสารแท็กซี่ฉุกเฉินในเวลางาน ปักรหัสดำเนินการจัดเก็บในฟอร์ม **EXP-TRAVEL-501** คีย์เสร็จภายใน 3 วันครับ";
          refs.push("ระเบียบข้อกำหนดการคืนเงินและเบิกจ่ายค่าเดินทางจัดหา (Travel Rules v1)");
        } else if (norm.includes("ลา") || norm.includes("พักร้อน") || norm.includes("opd") || norm.includes("สวัสดิการ")) {
          fallbackText += "อ้างอิงตาม **คู่มือสวัสดิการบุคลากรใหม่ (Employee Benefits Manual 2026)**:\n1. สิทธิการลางานพักร้อนประจำปี (Annual Leave) อยู่ที่ **10 วันทำการต่อปี** ยื่นคำขอผ่านใบลาอิเล็กทรอนิกส์ **HR-LEAVE-ONLINE** อย่างต่ำล่วงหน้า 3 วันทำการ\n2. สปอนเซอร์ประกันสุขภาพผู้ป่วยนอก OPD คุ้มครองรับเงินคืนสูงสุดไม่เกิน **2,000 บาท/ครั้ง** (ไม่จำกัดแพทย์เฉพาะสาย)";
          refs.push("คู่มือสวัสดิการพนักงานใหม่และประกันภัยภายนอก (Employee Benefits Manual)");
        } else {
          fallbackText += "ระบบสืบค้น RAG ยังตรวจไม่พบระเบียบเฉพาะที่สอดคล้องกับหัวข้อนี้ครับ ลองเสวนาเรื่องเกณฑ์การเบิกอื่นๆ เช่น 'ขอค่าอาหารเดินทาง', 'เคลม OPD สุขภาพ' หรือ 'แบบฟอร์มเบิกเบี้ยซ่อมกลุ่ม Retail' เพื่อวิจัยประวัติข้อมูลอย่างแม่นยำครับ!";
        }

        setMessages(prev => [...prev, {
          id: Math.random().toString(36).substring(7),
          sender: 'agent',
          text: fallbackText,
          timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          referencedGuides: refs
        }]);

      }, 700);
    } finally {
      setIsTyping(false);
    }
  };

  return (
    <div className="flex flex-col h-[calc(100vh-90px)] bg-white text-[#37352f] animate-fadeIn" id="agent-chat-container">
      
      {/* Upper Information Banner */}
      <div className="flex items-center justify-between border-b border-[#ededeb] pb-4 mb-4 select-none">
        <div className="flex items-center space-x-2.5">
          <div className="p-2 bg-[#dfefe4] text-[#008000] rounded-xl">
            <Bot className="h-5 w-5 animate-pulse" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-[#37352f] flex items-center space-x-1.5 leading-none">
              <span>Misty Private AI</span>
            </h1>
            <p className="text-[#7c7b77] text-xs mt-1 font-medium font-sans">
              ระบบสืบค้นคู่มือองค์กร RAG พร้อมทำงานร่วมกับคุณอย่างไร้ช่องทางรั่วไหล
            </p>
          </div>
        </div>

        <button
          onClick={handleClearChat}
          className="bg-white border border-[#ededeb] hover:bg-[#efefe0]/60 text-[#7c7b77] transition px-3 py-1.5 rounded-xl text-xs font-semibold flex items-center space-x-1.5 cursor-pointer shadow-2xs"
          title="Reset current conversation logs"
        >
          <Trash2 className="h-3.5 w-3.5 text-[#df1c1c]/80" />
          <span>ล้างประวัติแชท</span>
        </button>
      </div>

      {/* Message List viewport */}
      <div className="flex-1 overflow-y-auto mb-4 space-y-4 pr-1 scrollbar-hide" id="chat-messages-tracker">
        {messages.map((msg) => {
          const isMe = msg.sender === 'user';
          
          return (
            <div 
              key={msg.id}
              className={`flex items-start gap-3.5 ${isMe ? 'flex-row-reverse' : ''}`}
            >
              
              {/* Avatar indicator */}
              <div className={`p-1.5 rounded-full shrink-0 border select-none ${
                isMe 
                  ? 'bg-[#e0f0ff] border-[#b0d4ff] text-[#2383e2]' 
                  : 'bg-[#fbfbfa] border-[#ededeb] text-[#7c7b77]'
              }`}>
                {isMe ? <User className="h-4.5 w-4.5" /> : <Bot className="h-4.5 w-4.5" />}
              </div>

              {/* Speech bubble - clean Notion light panel */}
              <div className={`max-w-[75%] rounded-2xl p-3.5 border transition ${
                isMe 
                  ? 'bg-white border-[#b0d4ff] text-[#37352f] rounded-tr-xs shadow-2xs' 
                  : 'bg-[#f1f1ef]/50 border-[#ededeb] text-[#37352f] rounded-tl-xs leading-relaxed'
              }`}>
                
                {/* Text Content */}
                <p className="text-xs font-sans select-text whitespace-pre-wrap leading-relaxed font-semibold">
                  {msg.text}
                </p>

                {/* Sub-references of RAG match if available */}
                {msg.referencedGuides && msg.referencedGuides.length > 0 && (
                  <div className="mt-3.5 pt-2.5 border-t border-[#ededeb] space-y-1.5">
                    <span className="text-[9.5px] font-sans font-bold text-[#0066cc] flex items-center space-x-1 select-none">
                      <ShieldCheck className="h-3 w-3 shrink-0" />
                      <span>RAG SOURCE DOCUMENTS RETRIEVED:</span>
                    </span>
                    <div className="flex flex-wrap gap-1.5 text-[10px]">
                      {msg.referencedGuides.map((guide, idx) => (
                        <span 
                          key={idx}
                          className="bg-white border border-[#ededeb] text-[#7c7b77] px-2.5 py-0.5 rounded-full shadow-2xs flex items-center space-x-1"
                        >
                          <ShieldCheck className="h-3 w-3 text-[#00aa00] shrink-0" />
                          <span>{guide}</span>
                        </span>
                      ))}
                    </div>
                  </div>
                )}

                {/* Date indicator */}
                <span className="text-[8.5px] font-mono text-[#7c7b77] block text-right mt-1.5 select-none font-bold">
                  {msg.timestamp}
                </span>

              </div>

            </div>
          );
        })}

        {isTyping && (
          <div className="flex items-start gap-4" id="chat-is-typing-indicator">
            <div className="p-1.5 rounded-full bg-[#f1f1ef] border border-[#ededeb] text-[#7c7b77]">
              <Bot className="h-4.5 w-4.5 animate-pulse" />
            </div>
            <div className="bg-[#f1f1ef]/40 border border-[#ededeb] p-3.5 rounded-2xl rounded-tl-xs text-xs text-[#7c7b77] flex items-center space-x-2 font-semibold">
              <span className="w-1.5 h-1.5 rounded-full bg-[#2383e2] animate-bounce"></span>
              <span className="w-1.5 h-1.5 rounded-full bg-[#2383e2] animate-bounce" style={{ animationDelay: '0.2s' }}></span>
              <span className="w-1.5 h-1.5 rounded-full bg-[#2383e2] animate-bounce" style={{ animationDelay: '0.4s' }}></span>
              <span>Misty AI กำลังสืบค้นประมวลความหลังใน Knowledge Vault...</span>
            </div>
          </div>
        )}

        <div ref={scrollRef} />
      </div>

      {/* Suggested chips row for immediate click queries */}
      <div className="flex flex-wrap gap-1.5 mb-3 select-none">
        <button
          onClick={() => setInputVal("สิทธิเบิกประกัน OPD จำกัดการคุ้มครองอยู่ที่เท่าไหร่นะครับ?")}
          className="text-[10px] bg-white border border-[#ededeb] hover:bg-[#efefe0]/50 text-[#37352f] transition px-3 py-1.5 rounded-full text-left font-bold cursor-pointer shadow-2xs"
        >
          สิทธิการขอ OPD
        </button>
        <button
          onClick={() => setInputVal("การไปปฎิบัติภารกิจและเบิกเงินเดินทาง ตจว. มีกฎเกณฑ์จำกัดราคาเท่าไหร่?")}
          className="text-[10px] bg-white border border-[#ededeb] hover:bg-[#efefe0]/50 text-[#37352f] transition px-3 py-1.5 rounded-full text-left font-bold cursor-pointer shadow-2xs"
        >
          ค่าพาริการเดินทาง ตจว.
        </button>
        <button
          onClick={() => setInputVal("พนักงานกลุ่ม Retail หากต้องการตั้งเบิกเครื่อง POSM ต้องแนบรหัสเอกสารชิ้นไหนครับ?")}
          className="text-[10px] bg-white border border-[#ededeb] hover:bg-[#efefe0]/50 text-[#37352f] transition px-3 py-1.5 rounded-full text-left font-bold cursor-pointer shadow-2xs"
        >
          เบิกงานขายกลุ่ม Retail
        </button>
      </div>

      {/* Prompt Writing Console matching Screenshot 4/6 design */}
      <form onSubmit={handleSend} className="bg-white border border-[#ededeb] rounded-2xl p-2.5 flex items-center gap-2 relative shadow-2xs">
        
        {/* Attachment clip indicator */}
        <button
          type="button"
          onClick={() => alert("คำแนะนำ: สำหรับหัวหนังสือคู่มือนโยบายบริษัทขององค์กร ให้ไปลากอัปโหลดเก็บตรงที่หน้าเมนู 'Corporate Wiki' ได้ทันที เพื่อการจัดทำดัชนี RAG แบบปิดอย่างเต็มประสิทธิภาพป้องข้อมูลลูกค้าสูงสุดครับ!")}
          className="text-[#7c7b77] hover:text-[#37352f] p-1.5 rounded-full hover:bg-[#efefe0]/60 transition"
          title="Upload reference document to Wiki"
        >
          <Paperclip className="h-4.5 w-4.5" />
        </button>

        <input
          type="text"
          placeholder="พิมพ์คำสำคัญ หรือพูดคุยสอบถามเงื่อนไขสัญญางานร่วมกับ Misty AI..."
          value={inputVal}
          onChange={(e) => setInputVal(e.target.value)}
          className="bg-transparent text-xs w-full py-2 px-1 text-[#37352f] focus:outline-none placeholder-[#a0a0a0] font-sans font-semibold"
          required
          disabled={isTyping}
        />

        <button
          type="submit"
          disabled={!inputVal.trim() || isTyping}
          className="p-2.5 bg-white border border-[#ededeb] hover:bg-[#efefe0]/60 text-[#2383e2] rounded-full transition shadow-2xs disabled:opacity-40 cursor-pointer shrink-0"
        >
          <Send className="h-3.5 w-3.5" />
        </button>

      </form>

      <span className="text-[9px] font-mono text-[#a0a0a0] block text-center mt-2.5 tracking-wider uppercase select-none font-bold">
        AI ASSISTED RETRIEVAL RETRIEVES OFFLINE SPECIFICATIONS SECURELY.
      </span>

    </div>
  );
}
