#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="setup_kali_codespace.sh"
WORKDIR_DEFAULT="/workspaces/Kali-Codespace"

usage() {
  cat <<EOF
Usage: $0 [--dir DIR] [--no-shell] [--force]

Options:
  --dir DIR     Directory to run in (default: ${WORKDIR_DEFAULT})
  --no-shell    Do not open an interactive shell inside the container at the end
  --force       Overwrite existing Dockerfile/docker-compose.yml without asking
  -h, --help    Show this help
EOF
}

DIR="${WORKDIR_DEFAULT}"
NO_SHELL=0
FORCE=0

while [[ ${#} -gt 0 ]]; do
  case "$1" in
    --dir) DIR="$2"; shift 2;;
    --no-shell) NO_SHELL=1; shift;;
    --force) FORCE=1; shift;;
    -h|--help) usage; exit 0;;
    --) shift; break;;
    -*) echo "Unknown option: $1" >&2; usage; exit 2;;
    *) break;;
  esac
done

echo "Working directory: $DIR"
if [[ ! -d "$DIR" ]]; then
  echo "Directory does not exist: $DIR" >&2
  exit 1
fi

cd "$DIR"

confirm_overwrite() {
  local file="$1"
  if [[ -e "$file" && $FORCE -ne 1 ]]; then
    read -r -p "$file already exists. Overwrite? [y/N]: " resp
    case "${resp,,}" in
      y|yes) return 0;;
      *) echo "Skipping overwrite of $file"; return 1;;
    esac
  fi
  return 0
}

write_dockerfile() {
  local f="Dockerfile"
  if ! confirm_overwrite "$f"; then return 0; fi
  cat > "$f" <<'DOCKER'
FROM kalilinux/kali-rolling
# Instala dependencias básicas en la imagen. Las herramientas que el usuario
# solicitó instalar al iniciar (`fastfetch` y `nmap`) se instalarán en tiempo
# de ejecución desde el entrypoint, como pidió.
RUN apt update && apt install -y \
    git curl wget python3 python3-pip \
    ca-certificates build-essential sudo \
    && apt clean

# Copiamos el entrypoint que se encargará de instalar `fastfetch` y `nmap`
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

RUN useradd -ms /bin/bash rosemary && echo "rosemary:kali" | chpasswd && adduser rosemary sudo
RUN echo "rosemary ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER rosemary
WORKDIR /home/rosemary

# El entrypoint se ejecuta (como usuario rosemary con sudo sin password)
# y luego delega al comando por defecto (bash)
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
DOCKER
  echo "Wrote $f"
}

write_entrypoint() {
  local f="docker-entrypoint.sh"
  if ! confirm_overwrite "$f"; then return 0; fi
  cat > "$f" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

echo "Running initial apt update and installing fastfetch and nmap (non-fatal)..."
# Intentamos actualizar e instalar. No queremos que el contenedor muera por
# un fallo de red puntual, así que las operaciones son tolerantes.
sudo apt update -y || true
sudo apt install -y fastfetch nmap || true

# Ejecuta fastfetch si está disponible, pero no fallar si no lo está
fastfetch || true

# Ejecuta el comando por defecto (normalmente /bin/bash)
exec "$@"
SH
  chmod +x "$f"
  echo "Wrote $f"
}

write_compose() {
  local f="docker-compose.yml"
  if ! confirm_overwrite "$f"; then return 0; fi
  cat > "$f" <<'YAML'
version: "3.8"

services:
  kali:
    build: .
    container_name: kali-cs
    tty: true
    stdin_open: true
    volumes:
      - kali-data:/home/

volumes:
  kali-data:
YAML
  echo "Wrote $f"
}

check_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Command not found: $1" >&2
    return 1
  fi
  return 0
}

echo "Checking required commands..."
if ! check_cmd docker; then
  echo "Please install or enable Docker and ensure the 'docker' command is available." >&2
  exit 1
fi

# Prefer 'docker compose' (v2) but fall back to 'docker-compose' if necessary
DOCKER_COMPOSE_CMD=""
if docker compose version >/dev/null 2>&1; then
  DOCKER_COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  DOCKER_COMPOSE_CMD="docker-compose"
else
  echo "Neither 'docker compose' nor 'docker-compose' is available." >&2
  exit 1
fi

printf "Using compose command: %s\n" "$DOCKER_COMPOSE_CMD"

write_dockerfile
write_compose

echo "Building Docker image (this may take a while)..."
set -x
$DOCKER_COMPOSE_CMD build --pull
set +x

echo "Starting container..."
set -x
$DOCKER_COMPOSE_CMD up -d
set +x

echo "Waiting for container 'kali-cs' to appear..."
for i in {1..10}; do
  if docker ps --filter "name=kali-cs" --format '{{.Names}}' | grep -q '^kali-cs$'; then
    echo "Container kali-cs is running."
    break
  fi
  echo "Waiting... ($i)"
  sleep 1
done

if [[ $NO_SHELL -eq 1 ]]; then
  echo "Setup finished. Not opening a shell due to --no-shell."
  exit 0
fi

set -x
echo "Opening interactive shell inside 'kali-cs' (user: rosemary, password: kali). Running initial commands and leaving you in an interactive shell."
# fastfetch ya se instala durante la construcción de la imagen; ejecutamos y no fallamos si no está disponible
docker exec -it kali-cs bash -lc "clear; whoami; fastfetch || true; exec /bin/bash"
set +x

echo "Exited container shell."
