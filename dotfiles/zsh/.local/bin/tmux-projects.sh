#!/usr/bin/env bash

set -euo pipefail

projects_dir="${PROJECTS_DIR:-$HOME/code}"

if [[ ! -d "$projects_dir" ]]; then
  tmux display-message "Projects directory not found: $projects_dir"
  exit 1
fi

selected_project="$((find "$projects_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true) | sort | fzf --prompt="Project > " --height=100% --reverse)"

if [[ -z "${selected_project:-}" ]]; then
  exit 0
fi

session_name="$(basename "$selected_project" | tr ' .:' '---' | tr -cd '[:alnum:]_-')"
if [[ -z "$session_name" ]]; then
  session_name="project"
fi

if ! tmux has-session -t "$session_name" 2>/dev/null; then
  tmux new-session -d -s "$session_name" -c "$selected_project"
fi

if [[ -n "${TMUX:-}" ]]; then
  tmux switch-client -t "$session_name"
else
  tmux attach-session -t "$session_name"
fi
