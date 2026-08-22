#!/usr/bin/env python3
import os
import sys
import glob
import json
import signal
import shutil
import threading
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
    "vpn":       "#50fa7b",  # green when up (set inline below)
}

def _is_vpn_iface(path):
    # TUN device (OpenVPN, WireGuard-userspace, Cloudflare WARP, ...): has
    # tun_flags with the IFF_TUN bit (0x1) set. We require TUN, not TAP (0x2),
    # so libvirt/qemu VM tap interfaces don't count as a VPN.
    try:
        with open(os.path.join(path, "tun_flags")) as f:
            if int(f.read().strip(), 16) & 0x1:
                return True
    except OSError:
        pass
    # Kernel WireGuard device: uevent reports DEVTYPE=wireguard (no tun_flags).
    try:
        with open(os.path.join(path, "uevent")) as f:
            return "DEVTYPE=wireguard" in f.read()
    except OSError:
        return False


def vpn_block():
    # ponytail: read /sys files, no subprocess. Covers tun-based VPNs + kernel
    # WireGuard. Add an nmcli check only if you adopt a VPN that routes over a
    # plain device with no tun/wg interface.
    up = any(_is_vpn_iface(p) for p in glob.glob("/sys/class/net/*"))
    return {
        "name": "vpn",
        "full_text": "🔒 VPN" if up else "🔓 no VPN",
        "color": "#50fa7b" if up else "#6272a4",
    }

# Scroll step (percent) for the wheel
VOLUME_STEP = 5
BRIGHTNESS_STEP = 5

# i3status subprocess — we spawn it ourselves so this script owns stdin and can
# receive i3bar click/scroll events (a shell pipe would route stdin to i3status).
i3status = subprocess.Popen(
    ["i3status"], stdout=subprocess.PIPE, text=True
)


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


def refresh():
    # Force i3status to emit a new line immediately so the bar reflects the change.
    try:
        i3status.send_signal(signal.SIGUSR1)
    except Exception:
        pass


def run(cmd):
    # Redirect output to DEVNULL: anything a command prints to stdout would
    # otherwise corrupt the i3bar JSON protocol stream (our stdout) and crash
    # the bar — brightnessctl prints by default.
    return subprocess.run(
        cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    ).returncode == 0


def change_volume(amount):
    """Adjust the default sink with the audio tool available on this system."""
    if shutil.which("wpctl"):
        return run(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", amount])
    if shutil.which("pactl"):
        return run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", amount])
    return False


def toggle_mute():
    if shutil.which("wpctl"):
        return run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
    if shutil.which("pactl"):
        return run(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"])
    return False


def handle_click(event):
    name = event.get("name", "")
    button = event.get("button", 0)
    if name == "volume":
        if button == 4:    # wheel up
            change_volume(f"{VOLUME_STEP}%+")
        elif button == 5:  # wheel down
            change_volume(f"{VOLUME_STEP}%-")
        elif button == 1:  # left click toggles mute
            toggle_mute()
        else:
            return
        refresh()
    elif name == "brightness":
        if button == 4:    # wheel up
            run(["brightnessctl", "set", f"+{BRIGHTNESS_STEP}%"])
        elif button == 5:  # wheel down
            run(["brightnessctl", "set", f"{BRIGHTNESS_STEP}%-"])
        else:
            return
        refresh()


def click_event_loop():
    # i3bar sends click events as a JSON array stream on our stdin:
    # first line "[", then "{...}" / ",{...}" per event.
    for line in sys.stdin:
        line = line.strip()
        if not line or line == "[":
            continue
        if line.startswith(","):
            line = line[1:]
        try:
            handle_click(json.loads(line))
        except Exception:
            continue


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
        # VPN indicator at the far left of the bar.
        blocks.insert(0, vpn_block())
        for block in blocks:
            name = block.get("name", "")
            if name in COLORS and "color" not in block:
                block["color"] = COLORS[name]
        print(prefix + json.dumps(blocks), flush=True)
    except json.JSONDecodeError:
        print(prefix + line, flush=True)


# Header from i3status: {"version":1}. Re-emit it with click events enabled so
# i3bar forwards scroll/click events on our blocks (and skips its own
# workspace-switch fallback for those blocks).
header_line = i3status.stdout.readline().strip()
try:
    header = json.loads(header_line)
except json.JSONDecodeError:
    header = {"version": 1}
header["click_events"] = True
print(json.dumps(header), flush=True)

# Start the click-event reader once we've declared click_events support.
threading.Thread(target=click_event_loop, daemon=True).start()

print(i3status.stdout.readline().strip(), flush=True)  # opening "["

for line in i3status.stdout:
    process(line)
