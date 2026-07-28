import re

file_path = "/home/kimbiaw/calenda/calenda_flow/my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart"

with open(file_path, 'r') as f:
    content = f.read()

# Replace all remaining Colors.white with GlassColors.onSurface except in explicit places we missed
content = content.replace("style: TextStyle(color: Colors.white)", "style: TextStyle(color: GlassColors.onSurface)")

with open(file_path, 'w') as f:
    f.write(content)
