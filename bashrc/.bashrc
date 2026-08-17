# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias cd=z
alias sus='sudo systemctl suspend'

eval "$(zoxide init bash)"
export PATH="$HOME/.local/bin:$PATH:/opt/nvim-linux-x86_64/bin"

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
. "$HOME/.cargo/env"

# Go
export PATH=$PATH:/usr/local/go/bin

# Truncate all call-related tables (analytics + primary) AND the Redis KPI /
# concurrency counters so the /calls page + dashboard total reset to zero.
clearcalls() {
  (\
    docker compose exec -T timescaledb psql -U ringba -d ringba_ts -c "TRUNCATE calls, call_events, target_dial_attempts, rtt_pings, call_pixel_fires, call_recordings, call_tags CASCADE;" && \
    docker compose exec -T postgres psql -U ringba -d ringba -c "TRUNCATE conversion_receipts, conversion_attempts CASCADE;" && \
    docker compose exec -T redis sh -c 'for p in "daily_total:*" "daily_answered:*" "daily_cost_cents:*" "cap:concurrent:*" "calls:count:*" "calls:livecount:*"; do redis-cli --scan --pattern "$p" | xargs -r redis-cli del >/dev/null; done; echo "redis counters cleared"')
}

# masscall [rate] [max] [did] — fire loopback test calls into FreeSWITCH.
# Defaults: 10 calls/sec, 300 total, tracking number 18005550300.
#   masscall            # 10cps, 300 calls
#   masscall 20 500     # 20cps, 500 calls
masscall() {
  local rate="${1:-10}" max="${2:-300}" did="${3:-18005550300}" dur=2000 fired=0 s now
  while [ "$fired" -lt "$max" ]; do
    s=$(date +%s)
    for _ in $(seq 1 "$rate"); do
      [ "$fired" -ge "$max" ] && break
      fs_cli -x "bgapi originate {origination_caller_id_number=1555${RANDOM:0:3}${fired},ignore_early_media=true}loopback/${did}/default &sleep(${dur})" >/dev/null 2>&1 || true
      fired=$((fired + 1))
    done
    now=$(date +%s); [ "$now" -le "$s" ] && sleep 1
  done
  echo "masscall: fired $fired calls (${rate}cps -> ${did})"
}

# masscallsip [rate] [max] [did] [concurrent] — REALISTIC mass call via SIPp:
# real SIP INVITEs with two-way RTP into FreeSWITCH's trunk profile. One channel
# per call (one uuid → list count == DB total), real media (calls hold), clean
# BYE (no zombies). Prefer this over `masscall` (loopback) for accurate tests.
# Defaults: 10 cps, 300 total, 18005550300, 50 concurrent.
#   masscallsip            # 10cps, 300 calls
#   masscallsip 20 500     # 20cps, 500 calls
masscallsip() {
  RATE="${1:-10}" MAX="${2:-300}" DID="${3:-18005550100}" CONCURRENT="${4:-50}" \
    bash /home/hassan/ringba/ringba-backend/tests/sipp/masscall_sip.sh
}
eval "$(/home/hassan/.local/bin/mise activate bash)"
export EDITOR=nvim
alias ringba-ip='/home/hassan/ringba/ringba-ip.sh'

# internet speed test via Cloudflare (parallel streams)
speedtest() {
  local n=6 mb=20 start end bytes
  start=$(date +%s.%N)
  for i in $(seq $n); do curl -s -o /dev/null "https://speed.cloudflare.com/__down?bytes=$((mb*1000000))" & done
  wait
  end=$(date +%s.%N)
  bytes=$((n*mb*1000000))
  echo "scale=1; $bytes*8/($end-$start)/1000000" | bc -l | sed 's/$/ Mbps/'
}
