#!/usr/bin/env bash

set -euo pipefail

TODO_DIR="${TODO_DIR:-$HOME/DB}"
TODO_FILE="${TODO_FILE:-$TODO_DIR/todo.txt}"
DONE_FILE="${DONE_FILE:-$TODO_DIR/done.txt}"

ensure_files() {
  mkdir -p "$TODO_DIR"
  touch "$TODO_FILE" "$DONE_FILE"
}

usage() {
  cat <<'EOF'
todo.sh - tiny todo.txt-style task manager

Usage:
  todo.sh                 List open tasks
  todo.sh list            List open tasks
  todo.sh add <text...>   Add a new task
  todo.sh done <id>       Complete task by list number
  todo.sh pri <A-Z> <id>  Set priority on task by list number
EOF
}

list_tasks() {
  ensure_files
  if [[ ! -s "$TODO_FILE" ]]; then
    echo "No open tasks."
    return 0
  fi

  awk '{ printf "%3d %s\n", NR, $0 }' "$TODO_FILE"
}

add_task() {
  ensure_files
  if [[ $# -eq 0 ]]; then
    echo "error: missing task text"
    usage
    exit 1
  fi

  local text
  text="$*"
  printf "%s %s\n" "$(date +%F)" "$text" >> "$TODO_FILE"
  echo "Added: $text"
}

done_task() {
  ensure_files
  local id
  id="${1:-}"

  if [[ -z "$id" || ! "$id" =~ ^[0-9]+$ ]]; then
    echo "error: done requires a numeric task id"
    usage
    exit 1
  fi

  local line
  line="$(sed -n "${id}p" "$TODO_FILE")"
  if [[ -z "$line" ]]; then
    echo "error: task id $id not found"
    exit 1
  fi

  sed -i.bak "${id}d" "$TODO_FILE"
  rm -f "$TODO_FILE.bak"
  printf "x %s %s\n" "$(date +%F)" "$line" >> "$DONE_FILE"
  echo "Done: $line"
}

set_priority() {
  ensure_files
  local priority id
  priority="${1:-}"
  id="${2:-}"

  if [[ ! "$priority" =~ ^[A-Z]$ ]]; then
    echo "error: priority must be A-Z"
    usage
    exit 1
  fi

  if [[ -z "$id" || ! "$id" =~ ^[0-9]+$ ]]; then
    echo "error: pri requires a numeric task id"
    usage
    exit 1
  fi

  local line cleaned
  line="$(sed -n "${id}p" "$TODO_FILE")"
  if [[ -z "$line" ]]; then
    echo "error: task id $id not found"
    exit 1
  fi

  cleaned="$line"
  if [[ "$cleaned" =~ ^\([A-Z]\)[[:space:]]+ ]]; then
    cleaned="${cleaned#???}"
  fi

  sed -i.bak "${id}s|.*|(${priority}) ${cleaned}|" "$TODO_FILE"
  rm -f "$TODO_FILE.bak"
  echo "Priority set: ($priority) $cleaned"
}

cmd="${1:-list}"
case "$cmd" in
  list|ls)
    list_tasks
    ;;
  add)
    shift
    add_task "$@"
    ;;
  done)
    shift
    done_task "${1:-}"
    ;;
  pri)
    shift
    set_priority "${1:-}" "${2:-}"
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "error: unknown command '$cmd'"
    usage
    exit 1
    ;;
esac
