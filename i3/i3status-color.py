#!/usr/bin/env python3
import sys
import json
import subprocess

# Colors matched by block name field
COLORS = {
    "volume":    "#50fa7b",  # green
    "battery":   "#ffb86c",  # orange
    "disk_info": "#ff79c6",  # pink
    "memory":    "#8be9fd",  # cyan
    "load":      "#bd93f9",  # purple
    "brightness":"#f8f8f2",  # white
    "tztime":    "#f1fa8c",  # yellow
}

def get_brightness():
    try:
        result = subprocess.run(
            ["brightnessctl", "info", "-m"],
            capture_output=True, text=True, timeout=2
        )
        # Output format: device,class,cur,max,percentage
        pct = result.stdout.strip().split(",")[3]
        return f"☀ {pct}"
    except Exception:
        return None

def process(line):
    line = line.strip()
    if not line or line == "[":
        print(line, flush=True)
        return
    prefix = ""
    if line.startswith(","):
        prefix = ","
        line = line[1:]
    try:
        blocks = json.loads(line)
        # Inject brightness block after volume (at position 1)
        brightness = get_brightness()
        if brightness:
            bright_block = {
                "name": "brightness",
                "full_text": brightness,
            }
            # Insert after volume (index 1) or at the start
            blocks.insert(1, bright_block)
        for block in blocks:
            name = block.get("name", "")
            if name in COLORS and "color" not in block:
                block["color"] = COLORS[name]
        print(prefix + json.dumps(blocks), flush=True)
    except json.JSONDecodeError:
        print(prefix + line, flush=True)

# Pass through header
print(sys.stdin.readline().strip(), flush=True)  # {"version":1}
print(sys.stdin.readline().strip(), flush=True)  # [

for line in sys.stdin:
    process(line)
