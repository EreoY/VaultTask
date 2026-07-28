# Requirements Document

## Introduction

ระบบ Calenda Flow ปัจจุบันรองรับการดึงข้อความ (text extraction) จากไฟล์แนบเฉพาะ PDF และ DOCX เท่านั้น ฟีเจอร์นี้ขยายความสามารถให้ระบบสามารถดึงข้อความจากไฟล์รูปภาพ (PNG, JPEG) ผ่าน Vision AI ได้ด้วย โดยใช้ในทั้งหน้า Meetings (การประชุม) และหน้า Docs (เอกสาร) — ทุกจุดที่มีการแนบไฟล์

ระบบจะใช้ Gemini multimodal API ผ่าน OpenRouter proxy (เส้นทางเดียวกับ `extractPdfText`) เพื่อวิเคราะห์ภาพและดึงข้อความออกมาเป็น plain text ให้ AI summarizer สามารถอ่านเนื้อหาจากภาพได้เช่นเดียวกับเอกสาร

## Glossary

- **Extraction_Service**: ระบบย่อยใน `ApiCloudflare` ที่รับผิดชอบการดึงข้อความจากไฟล์แนบทุกประเภท (PDF, DOCX, PNG, JPEG)
- **Vision_AI**: Gemini multimodal model ที่รับภาพเป็น input และตอบเป็นข้อความ ทำงานผ่าน `/api/ai/chat` endpoint บน Cloudflare Worker
- **Extractable_File**: ไฟล์แนบที่ระบบสามารถดึงข้อความออกมาได้ ประกอบด้วย PDF, DOCX, PNG, JPEG
- **Meetings_Sheet**: หน้าจอรายละเอียดการประชุม (`meetings_board_sheet.dart`) ที่มีระบบแนบไฟล์และสรุปด้วย AI
- **Docs_Sheet**: หน้าจอเอกสาร (`docs_board_sheet.dart`) ที่มีระบบแนบไฟล์และสรุปด้วย AI
- **Extracted_Text**: ข้อความที่ดึงได้จากไฟล์แนบ ถูกเก็บในฟิลด์ `extractedText` ของ attachment map
- **AI_Chat_Proxy**: Worker route `/api/ai/chat` ที่ส่งต่อ request ไปยัง OpenRouter/Gemini API

## Requirements

### Requirement 1: รองรับไฟล์รูปภาพเป็น Extractable File

**User Story:** As a user, I want the system to recognize PNG and JPEG files as extractable, so that I can extract text content from image attachments just like PDF/DOCX files.

#### Acceptance Criteria

1. WHEN a PNG file is attached, THE Extraction_Service SHALL identify the file as an Extractable_File
2. WHEN a JPEG file is attached, THE Extraction_Service SHALL identify the file as an Extractable_File
3. THE Extraction_Service SHALL detect PNG files by file extension (`.png`) or MIME type (`image/png`)
4. THE Extraction_Service SHALL detect JPEG files by file extension (`.jpg`, `.jpeg`) or MIME type (`image/jpeg`)
5. WHILE the system evaluates extractability, THE Extraction_Service SHALL check file extension, URL path, and MIME type fields (consistent with existing PDF/DOCX detection logic)

### Requirement 2: ดึงข้อความจากรูปภาพผ่าน Vision AI

**User Story:** As a user, I want to extract text and content from attached images, so that AI summarization can include information from whiteboard photos, screenshots, and scanned documents.

#### Acceptance Criteria

1. WHEN a PNG or JPEG file is submitted for extraction, THE Extraction_Service SHALL download the image bytes from R2 storage
2. WHEN image bytes are retrieved successfully, THE Extraction_Service SHALL encode the image as base64 and send a multimodal request to the AI_Chat_Proxy with a text extraction prompt
3. THE Extraction_Service SHALL use the `image_url` content type with `data:{mime};base64,{data}` format (consistent with existing `generateAiDescription` and `extractPdfText` patterns)
4. THE Extraction_Service SHALL instruct the Vision_AI to extract all visible text content from the image as plain text, preserving structure (headings, lists, tables) where possible
5. WHEN the Vision_AI returns extracted text successfully, THE Extraction_Service SHALL store the result in the `extractedText` field of the attachment (truncated to 12000 characters maximum)
6. IF the image download fails, THEN THE Extraction_Service SHALL return an empty string and log the error
7. IF the Vision_AI request fails, THEN THE Extraction_Service SHALL return an empty string and log the error
8. THE Extraction_Service SHALL use the `google/gemini-3.1-flash-lite` model for image text extraction (consistent with PDF extraction)

### Requirement 3: การดึงข้อความจากรูปภาพในหน้า Meetings

**User Story:** As a meeting participant, I want text extracted from image attachments in meetings, so that whiteboard photos and agenda screenshots can be included in AI meeting summaries.

#### Acceptance Criteria

1. WHEN a PNG or JPEG file is attached in the Meetings_Sheet, THE Meetings_Sheet SHALL trigger background text extraction automatically (fire-and-forget pattern, consistent with existing PDF/DOCX behavior)
2. WHILE extraction is in progress for an image attachment, THE Meetings_Sheet SHALL display an inline loading indicator for that specific attachment
3. WHEN extraction completes for an image, THE Meetings_Sheet SHALL store the extracted text in the attachment's `extractedText` field and trigger auto-save
4. THE Meetings_Sheet SHALL display a "view extracted text" button for image attachments (consistent with existing PDF/DOCX UI pattern)
5. WHEN a meeting with existing image attachments is loaded, THE Meetings_Sheet SHALL lazily extract text from images that have no cached `extractedText` (legacy extraction behavior)

### Requirement 4: การดึงข้อความจากรูปภาพในหน้า Docs

**User Story:** As a document author, I want text extracted from image attachments in docs, so that screenshots and scanned pages can contribute to AI document summaries.

#### Acceptance Criteria

1. WHEN a PNG or JPEG file is attached in the Docs_Sheet, THE Docs_Sheet SHALL trigger background text extraction automatically (fire-and-forget pattern, consistent with existing PDF/DOCX behavior)
2. WHILE extraction is in progress for an image attachment, THE Docs_Sheet SHALL display an inline loading indicator for that specific attachment
3. WHEN extraction completes for an image, THE Docs_Sheet SHALL store the extracted text in the attachment's `extractedText` field and trigger auto-save
4. THE Docs_Sheet SHALL display a "view extracted text" button for image attachments (consistent with existing PDF/DOCX UI pattern)
5. WHEN a document with existing image attachments is loaded, THE Docs_Sheet SHALL lazily extract text from images that have no cached `extractedText` (legacy extraction behavior)

### Requirement 5: AI Summarizer ใช้ข้อความจากรูปภาพได้

**User Story:** As a user, I want the AI summarizer to include extracted text from images when generating summaries, so that information in attached images is not lost during summarization.

#### Acceptance Criteria

1. WHEN the AI summarizer collects attachment texts for summarization, THE Extraction_Service SHALL include `extractedText` from image attachments alongside PDF/DOCX extracted texts
2. THE Extraction_Service SHALL present image-extracted text to the summarizer in the same format as document-extracted text (plain text string)
3. WHILE the summarizer prepares context, THE Extraction_Service SHALL wait for in-progress image extractions to complete before proceeding (or use cached results if available)

### Requirement 6: ขนาดไฟล์รูปภาพและการจำกัดทรัพยากร

**User Story:** As a system administrator, I want image extraction to respect resource limits, so that very large images do not cause timeouts or excessive API costs.

#### Acceptance Criteria

1. THE Extraction_Service SHALL limit image payload to 10 MB before sending to the Vision_AI (reject larger images with an empty result and debug log)
2. THE Extraction_Service SHALL set a request timeout of 30 seconds for the Vision_AI image extraction call
3. IF the image exceeds the size limit, THEN THE Extraction_Service SHALL return an empty string and log a warning message indicating the file is too large
4. THE Extraction_Service SHALL truncate extracted text output to 12000 characters maximum (consistent with existing PDF extraction behavior)
