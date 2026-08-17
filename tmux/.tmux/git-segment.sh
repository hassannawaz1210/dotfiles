#!/bin/sh
# Renders the " repo:branch*" segment for tmux pane-border-format.
# Emits tmux #[...] style codes directly (no escaping needed in a real file).
# Usage: git-segment.sh <pane_current_path> <pane_active: 1|0>

path=$1
active=$2

cd "$path" 2>/dev/null || exit 0

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
[ -n "$branch" ] || exit 0

# Use --git-common-dir (not --show-toplevel) so worktrees report the real
# repo name instead of the worktree's own directory name.
repo=$(basename "$(dirname "$(cd "$(git rev-parse --git-common-dir 2>/dev/null)" 2>/dev/null && pwd)")")

# "*" if the working tree has uncommitted changes (staged or unstaged)
dirty=
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    dirty="*"
fi

# Linked worktree: --git-dir lives under .git/worktrees/, so it differs from
# the shared --git-common-dir. Mark it with a tree glyph.
wt=
if [ "$(git rev-parse --git-dir 2>/dev/null)" != "$(git rev-parse --git-common-dir 2>/dev/null)" ]; then
    wt=" ⑂"
fi

if [ "$active" = "1" ]; then
    repo_bg=colour18    # repo name on its own dark blue background (distinct from title purple)
    branch_bg=colour22  # branch on the green segment background
    branch_fg=colour231 # bright white
else
    repo_bg=colour240   # dim grey background (a touch lighter than the segment)
    branch_bg=colour237 # dim segment background
    branch_fg=colour244 # dim grey
fi

# repo: white text on its own background; branch: keeps the segment background
printf ' #[fg=colour231,bg=%s] %s #[fg=%s,bg=%s] :%s%s%s #[default]' \
    "$repo_bg" "$repo" "$branch_fg" "$branch_bg" "$branch" "$dirty" "$wt"
