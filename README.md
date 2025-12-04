![Kali-Codespace](https://g.top4top.io/p_3536nulms0.png)

# Tutorial

Este tutorial muestra cómo configurar un contenedor de Kali Linux en GitHub Codespaces para pentesting usando herramientas de terminal y basadas en web.

## Notas

- Los contenedores en Codespaces se detienen tras un periodo de inactividad.
- Guarda archivos importantes en el volumen (`kali-data`) o en el repositorio.
- Usuario predeterminado: `rosemary`, contraseña root: `kali`.


Advertencia sobre Codespaces:

- En entornos de GitHub Codespaces es posible que no tengas acceso al daemon de Docker. Si `docker` falla, ejecuta estos pasos en una máquina con Docker instalado o usa un devcontainer/VM en lugar de Docker-in-Docker.


## Instrucciones para este entorno

En este entorno, las siguientes instrucciones debes ejecutarlas manualmente porque el script no las ejecuta automáticamente al iniciar Codespace:

```bash
whoami
sudo su -c 'apt update && apt install -y fastfetch'
fastfetch
```

Ejecuta las tres líneas en este orden dentro de la sesión donde estés trabajando en el Codespace o dentro del contenedor si has entrado en él. Esto actualizará paquetes (para instalar `fastfetch`) y luego mostrará la información del sistema.


## Referencias

- [Imágenes Docker de Kali Linux](https://hub.docker.com/r/kalilinux/kali-rolling)
- [Documentación de GitHub Codespaces](https://docs.github.com/en/codespaces)
