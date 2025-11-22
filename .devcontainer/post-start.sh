#!/usr/bin/env bash
set -euo pipefail

# This script is run inside the devcontainer after it starts.
# It attempts to start the docker-compose stack and then adds a
# small, idempotent snippet to the interactive shell startup file
# so that the first interactive terminal opened will `docker exec` into
# the `kali-cs` container once.

REPO_PATH="/workspaces/Kali-Codespace"
BASHRC="/home/vscode/.bashrc"
MARKER_START="# >>> kali-codespace auto-enter start >>>"
MARKER_END="# <<< kali-codespace auto-enter end <<<"

echo "[kali-codespace] post-start: checking docker availability..."
if ! command -v docker >/dev/null 2>&1; then
  echo "[kali-codespace] docker not found in container. Skipping auto-start."
  exit 0
fi

if [ ! -f "$REPO_PATH/docker-compose.yml" ]; then
  echo "[kali-codespace] docker-compose.yml not found at $REPO_PATH. Skipping."
  exit 0
fi

echo "[kali-codespace] running: docker compose up -d"
(cd "$REPO_PATH" && docker compose up -d)

echo "[kali-codespace] preparing interactive auto-enter snippet (idempotent)..."

# The snippet will only run for interactive shells and only once per codespace session.
SNIPPET=$(cat <<'SNIP'
%MARKER_START%
# Auto-enter Kali container once per session. Created by .devcontainer/post-start.sh
if [[ $- == *i* ]] && [ -x "$(command -v docker)" ]; then
  # Prevent multiple entries in the same session
  if [ ! -f "/tmp/.kali_auto_entered" ]; then
    # Start services (safe to run again)
    if [ -f "/workspaces/Kali-Codespace/docker-compose.yml" ]; then
      (cd /workspaces/Kali-Codespace && docker compose up -d) >/dev/null 2>&1 || true
    fi
    # If container exists and is running, exec into it and create marker
    if docker ps --filter "name=^kali-cs$" --format '{{.Names}}' | grep -q '^kali-cs$'; then
      touch /tmp/.kali_auto_entered
      # Use exec so that the terminal becomes the container shell
      # Run initial setup commands (idempotent) before handing off an interactive shell
      exec docker exec -it kali-cs bash -lc "sudo su -c 'apt update && apt install -y fastfetch' || true; clear; whoami; fastfetch || true; exec /bin/bash" || true
    fi
    fi
  fi
fi
%MARKER_END%
SNIP
)

SNIPPET=${SNIPPET//%MARKER_START%/$MARKER_START}
SNIPPET=${SNIPPET//%MARKER_END%/$MARKER_END}

# Append the snippet if not already present
if ! grep -Fq "$MARKER_START" "$BASHRC" 2>/dev/null; then
  echo "[kali-codespace] appending auto-enter snippet to $BASHRC"
  # Ensure bashrc exists and is writable
  touch "$BASHRC"
  printf "\n%s\n" "$SNIPPET" >> "$BASHRC"
else
  echo "[kali-codespace] auto-enter snippet already present in $BASHRC"
fi

echo "[kali-codespace] post-start finished. Open a new terminal to auto-enter the kali container (once)."
