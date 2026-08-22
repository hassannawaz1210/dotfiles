#!/bin/sh

# A touchpad can expose several XInput nodes under the same device name. Enable
# tapping only on nodes that actually provide libinput's tapping property.
xinput list --id-only 2>/dev/null | while IFS= read -r id; do
    if xinput list-props "$id" 2>/dev/null | grep -q 'libinput Tapping Enabled ('; then
        xinput set-prop "$id" 'libinput Tapping Enabled' 1
    fi
done
