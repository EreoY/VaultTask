#!/usr/bin/env python3
import re
import os

BASE = "/run/media/kimbiaw/pro/calenda_project/my_ai_assistant/lib/ui/screens"
WIDGETS = "/run/media/kimbiaw/pro/calenda_project/my_ai_assistant/lib/ui/widgets"

IMPORTS = """import '../theme/glass_theme.dart';
import '../widgets/glass_widgets.dart';"""

def add_imports(content):
    # Find last import line and add after it
    lines = content.split('\n')
    last_import_idx = -1
    for i, line in enumerate(lines):
        if line.startswith('import '):
            last_import_idx = i
    if last_import_idx >= 0 and 'glass_theme.dart' not in content:
        lines.insert(last_import_idx + 1, IMPORTS)
    return '\n'.join(lines)

def add_gradient_bg(content):
    # Pattern: return Scaffold(\n      backgroundColor: isDark ? const Color(...) : const Color(...),
    # Replace with transparent + gradient container wrapping the body
    # This is tricky because each file has different body structure
    # We'll do a simple replacement for the backgroundColor line
    content = re.sub(
        r'return Scaffold\(\n\s+backgroundColor: isDark \? const Color\(0x[0-9a-fA-F]+\) : const Color\(0x[0-9a-fA-F]+\),',
        'return Scaffold(\n      backgroundColor: Colors.transparent,',
        content
    )
    # Also handle shorter hex format
    content = re.sub(
        r'return Scaffold\(\n\s+backgroundColor: isDark \? const Color\(0xff[0-9a-fA-F]+\) : const Color\(0xff[0-9a-fA-F]+\),',
        'return Scaffold(\n      backgroundColor: Colors.transparent,',
        content
    )
    return content

def add_glass_to_cards(content):
    # Replace common card decoration patterns with GlassDecorations.surface
    # Only replace the decoration: BoxDecoration inside Container that looks like a card
    # This is a simplified approach
    content = re.sub(
        r'decoration: BoxDecoration\(\n\s+color: isDark \? const Color\(0xff1e293b\) : Colors\.white,',
        'decoration: GlassDecorations.surface(isDark),',
        content
    )
    content = re.sub(
        r'decoration: BoxDecoration\(\n\s+color: Colors\.white,',
        'decoration: GlassDecorations.surface(isDark),',
        content
    )
    return content

files = [
    os.path.join(BASE, "screen_boards.dart"),
    os.path.join(BASE, "screen_calendar.dart"),
    os.path.join(BASE, "screen_chat.dart"),
    os.path.join(BASE, "screen_profile.dart"),
    os.path.join(BASE, "screen_kanban.dart"),
    os.path.join(WIDGETS, "dialog_task_detail.dart"),
]

for f in files:
    with open(f, 'r') as file:
        content = file.read()
    
    content = add_imports(content)
    content = add_gradient_bg(content)
    content = add_glass_to_cards(content)
    
    with open(f, 'w') as file:
        file.write(content)
    print(f"Updated {f}")
