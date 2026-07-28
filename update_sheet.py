import re

file_path = "/home/kimbiaw/calenda/calenda_flow/my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart"

with open(file_path, 'r') as f:
    content = f.read()

# Dialog Rename Session
content = content.replace("const Text('เปลี่ยนชื่อเสสชัน', style: TextStyle(color: Colors.white))", "Text('เปลี่ยนชื่อเสสชัน', style: TextStyle(color: GlassColors.onSurface))")
content = content.replace("style: const TextStyle(color: Colors.white),", "style: TextStyle(color: GlassColors.onSurface),")
content = content.replace("hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),", "hintStyle: TextStyle(color: GlassColors.onSurfaceVariant),")
content = content.replace("fillColor: const Color(0x80161926),", "fillColor: GlassColors.surfaceContainer,")
content = content.replace("borderSide: BorderSide.none,", "borderSide: BorderSide(color: GlassColors.outlineVariant),")
content = content.replace("const Text('ยกเลิก', style: TextStyle(color: Colors.white54))", "Text('ยกเลิก', style: TextStyle(color: GlassColors.onSurfaceVariant))")
content = content.replace("const Text('บันทึก', style: TextStyle(color: Colors.white))", "Text('บันทึก', style: TextStyle(color: GlassColors.onSurface))")

# Header section
content = content.replace("Icon(Icons.auto_awesome, color: Colors.white, size: 24)", "Icon(Icons.auto_awesome, color: GlassColors.onSurface, size: 24)")
content = content.replace("color: Colors.white,", "color: GlassColors.onSurface,")
content = content.replace("icon: const Icon(Icons.close, color: Colors.white70),", "icon: Icon(Icons.close, color: GlassColors.onSurfaceVariant),")
content = content.replace("const Divider(color: Colors.white12, height: 1),", "Divider(color: GlassColors.outlineVariant, height: 1),")
content = content.replace("backgroundColor: Colors.white.withOpacity(0.08),", "backgroundColor: GlassColors.surface,")
content = content.replace("side: const BorderSide(color: Colors.white24),", "side: BorderSide(color: GlassColors.outlineVariant),")
content = content.replace("const Text(\n                  '+ เสสชันใหม่',\n                  style: TextStyle(color: Colors.white),\n                )", "Text(\n                  '+ เสสชันใหม่',\n                  style: TextStyle(color: GlassColors.onSurface),\n                )")

# ChoiceChip
content = content.replace("selectedColor: Colors.white,", "selectedColor: GlassColors.primary,")
content = content.replace("color: isActive ? Colors.black : Colors.white,", "color: isActive ? GlassColors.onPrimary : GlassColors.onSurface,")
content = content.replace("const Icon(\n                        Icons.edit_outlined,\n                        size: 16,\n                        color: Colors.black,\n                      )", "Icon(\n                        Icons.edit_outlined,\n                        size: 16,\n                        color: GlassColors.onPrimary,\n                      )")

# CheckboxListTile properties
content = content.replace("activeColor: Colors.white,", "activeColor: GlassColors.primary,")
content = content.replace("checkColor: Colors.black,", "checkColor: GlassColors.onPrimary,")

# TextStyles in ConfigView
content = content.replace("const TextStyle(color: Colors.white)", "TextStyle(color: GlassColors.onSurface)")

# Custom prompt controller
content = content.replace("hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),", "hintStyle: TextStyle(color: GlassColors.onSurfaceVariant),")

# FilledButton icon
content = content.replace("color: Colors.black,", "color: GlassColors.onPrimary,")
content = content.replace("Icon(Icons.auto_awesome, color: Colors.black)", "Icon(Icons.auto_awesome, color: GlassColors.onPrimary)")
content = content.replace("backgroundColor: Colors.white,", "backgroundColor: GlassColors.primary,")
content = content.replace("disabledBackgroundColor: Colors.white.withOpacity(0.5),", "disabledBackgroundColor: GlassColors.primary.withOpacity(0.5),")
content = content.replace("color: Colors.black,\n                  fontWeight: FontWeight.bold,", "color: GlassColors.onPrimary,\n                  fontWeight: FontWeight.bold,")


# SegmentedButton
content = content.replace("backgroundColor: Colors.white.withOpacity(0.05),", "backgroundColor: GlassColors.surface,")
content = content.replace("selectedBackgroundColor: Colors.white.withOpacity(0.15),", "selectedBackgroundColor: GlassColors.surfaceContainer,")
content = content.replace("foregroundColor: Colors.white70,", "foregroundColor: GlassColors.onSurfaceVariant,")
content = content.replace("selectedForegroundColor: Colors.white,", "selectedForegroundColor: GlassColors.onSurface,")
content = content.replace("side: const BorderSide(color: Colors.white12),", "side: BorderSide(color: GlassColors.outlineVariant),")

# MarkdownBlockEditor container
content = content.replace("color: const Color(0x80161926),", "color: GlassColors.surfaceContainer,")
content = content.replace("border: Border.all(color: Colors.white12),", "border: Border.all(color: GlassColors.outlineVariant),")

# Chat bubbles
content = content.replace("GlassColors.primary.withOpacity(0.2)", "GlassColors.primary")
content = content.replace("const Color(0x80161926)", "GlassColors.surfaceContainer")
content = content.replace("GlassColors.primary.withOpacity(0.5)", "GlassColors.primary")
content = content.replace("Colors.white12", "GlassColors.outlineVariant")
content = content.replace("Icon(\n                            isUser ? Icons.person : Icons.auto_awesome,\n                            color: isUser\n                                ? GlassColors.primary\n                                : Colors.white,\n                            size: 16,\n                          )", "Icon(\n                            isUser ? Icons.person : Icons.auto_awesome,\n                            color: isUser\n                                ? GlassColors.onPrimary\n                                : GlassColors.onSurface,\n                            size: 16,\n                          )")
content = content.replace("style: const TextStyle(color: Colors.white),", "style: TextStyle(color: isUser ? GlassColors.onPrimary : GlassColors.onSurface),")
content = content.replace("const LinearProgressIndicator(color: Colors.white)", "LinearProgressIndicator(color: GlassColors.primary)")

# Refinement Chat Bar
content = content.replace("const Color(0x801E2235)", "GlassColors.surfaceContainer")
content = content.replace("BorderSide(color: Colors.white12)", "BorderSide(color: GlassColors.outlineVariant)")
content = content.replace("hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),", "hintStyle: TextStyle(color: GlassColors.onSurfaceVariant),")
content = content.replace("fillColor: Colors.white.withOpacity(0.05),", "fillColor: GlassColors.surface,")
content = content.replace("strokeWidth: 2,\n                          color: Colors.white,", "strokeWidth: 2,\n                          color: GlassColors.onSurface,")
content = content.replace("Icon(\n                        Icons.send_rounded,\n                        color: Colors.white,\n                      )", "Icon(\n                        Icons.send_rounded,\n                        color: GlassColors.onSurface,\n                      )")
content = content.replace("Text(\n                'นำไปใช้',\n                style: GlassText.bodyLG().copyWith(\n                  fontWeight: FontWeight.bold,\n                  color: Colors.white,\n                ),\n              )", "Text(\n                'นำไปใช้',\n                style: GlassText.bodyLG().copyWith(\n                  fontWeight: FontWeight.bold,\n                  color: GlassColors.onPrimary,\n                ),\n              )")

# Also, there's a custom prompt border outline variant:
content = content.replace("hintStyle: TextStyle(color: GlassColors.onSurfaceVariant),\n              filled: true,\n              fillColor: GlassColors.surfaceContainer,\n              border: OutlineInputBorder(\n                borderRadius: BorderRadius.circular(12),\n                borderSide: BorderSide.none,\n              ),", "hintStyle: TextStyle(color: GlassColors.onSurfaceVariant),\n              filled: true,\n              fillColor: GlassColors.surfaceContainer,\n              border: OutlineInputBorder(\n                borderRadius: BorderRadius.circular(12),\n                borderSide: BorderSide(color: GlassColors.outlineVariant),\n              ),")

with open(file_path, 'w') as f:
    f.write(content)
