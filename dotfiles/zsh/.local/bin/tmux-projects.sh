#!/bin/bash

projects_dir="${PROJECTS_DIR:-$HOME/code}"

if [[ ! -d "$projects_dir" ]]; then
  tmux display-message "Projects directory not found: $projects_dir"
  exit 1
fi

cd "$projects_dir"

projects=($(find . -mindepth 1 -maxdepth 1 -type d -not -name '.*' 2>/dev/null | sed 's|^\./||' | sort))

if [[ ${#projects[@]} -eq 0 ]]; then
  tmux display-message "No projects found in $projects_dir"
  exit 0
fi

selected_project="$(printf '%s\n' "${projects[@]}" | /opt/homebrew/bin/fzf --prompt="Project > ")" || exit 0

if [[ -z "${selected_project:-}" ]]; then
  exit 0
fi

session_name="$(basename "$selected_project" | tr ' .:' '---' | tr -cd '[:alnum:]_-')"
if [[ -z "$session_name" ]]; then
  session_name="project"
fi

if ! tmux has-session -t "$session_name" 2>/dev/null; then
  tmux new-session -d -s "$session_name" -c "$projects_dir/$selected_project"
fi

if [[ -n "${TMUX:-}" ]]; then
  tmux switch-client -t "$session_name"
else
  tmux attach-session -t "$session_name"
fi
