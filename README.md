![Kali-Codespace](https://g.top4top.io/p_3536nulms0.png)

# Tutorial

Este tutorial muestra cómo configurar un contenedor de Kali Linux en GitHub Codespaces para pentesting usando herramientas de terminal y basadas en web.

---

## 1. Actualizar y mejorar el sistema

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 2. Crear directorio del proyecto (opcional)

```bash
mkdir -p ~/kali-codespace
cd ~/kali-codespace
```

---

## 3. Crear Dockerfile

```bash
echo 'FROM kalilinux/kali-rolling

RUN apt update && apt install -y \
    git curl wget python3 python3-pip \
    ca-certificates build-essential sudo \
    && apt clean

RUN useradd -ms /bin/bash rosemary && echo "rosemary:kali" | chpasswd && adduser rosemary sudo
RUN echo "rosemary ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER rosemary
WORKDIR /home/rosemary

CMD ["/bin/bash"]' > Dockerfile
```

Notas: la contraseña root para `rosemary` es `kali`.

---

## 4. Crear `docker-compose.yml`

```bash
echo 'version: "3.8"

services:
  kali:
    build: .
    container_name: kali-cs
    tty: true
    stdin_open: true
    volumes:
      - kali-data:/home/

volumes:
  kali-data:' > docker-compose.yml
```

Notas: el volumen `kali-data` almacena datos persistentes.

---

## 5. Construir el contenedor

```bash
docker compose build
```

---

## 6. Ejecutar el contenedor

```bash
docker compose up -d
```

---

## 7. Acceder al contenedor Kali

```bash
docker exec -it kali-cs /bin/bash
```

---

## Notas

- Los contenedores en Codespaces se detienen tras un periodo de inactividad.
- Guarda archivos importantes en el volumen (`kali-data`) o en el repositorio.
- Usuario predeterminado: `rosemary`, contraseña root: `kali`.

---

## Ejecutar el script de configuración

Sigue estos pasos para ejecutar el script `setup_kali_codespace.sh` que automatiza los pasos del tutorial.

1. Asegúrate de estar en la carpeta del proyecto:

```bash
cd /workspaces/Kali-Codespace
```

2. Comprueba que Docker esté disponible (si trabajas en Codespaces puede no estarlo):

```bash
docker --version
docker info
```

3. Haz el script ejecutable (si aún no lo es) y ejecútalo:

```bash
chmod +x setup_kali_codespace.sh
./setup_kali_codespace.sh
```

Alternativa (no requiere cambiar permisos):

```bash
bash setup_kali_codespace.sh
```

Nota sobre la interacción final:

- El script contiene al final `docker exec -it kali-cs /bin/bash`, lo que abrirá una shell interactiva dentro del contenedor y dejará tu terminal dentro de ese contenedor hasta que salgas (`exit` o Ctrl+D).
- Si prefieres que el script no abra esa shell, ejecuta una versión temporal sin la línea final:

```bash
sed '/docker exec -it kali-cs \\\/bin\\\/bash/d' setup_kali_codespace.sh > /tmp/setup_noshell.sh && bash /tmp/setup_noshell.sh
```

Advertencia sobre Codespaces:

- En entornos de GitHub Codespaces es posible que no tengas acceso al daemon de Docker. Si `docker` falla, ejecuta estos pasos en una máquina con Docker instalado o usa un devcontainer/VM en lugar de Docker-in-Docker.


## Referencias

- [Imágenes Docker de Kali Linux](https://hub.docker.com/r/kalilinux/kali-rolling)
- [Documentación de GitHub Codespaces](https://docs.github.com/en/codespaces)
