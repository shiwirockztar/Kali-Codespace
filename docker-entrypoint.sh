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
