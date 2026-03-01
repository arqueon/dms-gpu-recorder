# Dank Material Shell: GPU Screen Recorder Plugin

Este es un plugin nativo (en Quickshell / QML) para **Dank Material Shell**, que te permite iniciar, pausar y detener grabaciones de pantalla de manera sencilla utilizando `gpu-screen-recorder`.

## Características
- **Alternar Grabación:** Inicia un proceso detached para grabar video con alta calidad (`h264`, `opus`, `very_high`). 
- **Pausa del Proceso:** Al hacer Click Derecho sobre la cámara, puedes pausar (usando la señal UNIX `SIGSTOP`) la grabación en progreso. Un segundo Click Derecho reanudará la captura (`SIGCONT`).
- **Manejo Seguro de Archivos:** A la hora de detener la grabación, el plugin envía graciosamente la señal `SIGINT`, permitiendo al codificador de `gpu-screen-recorder` cerrar correctamente el archivo MP4 resultante (sin corrupción).
- **Interfaz Integrada:** Posee un Control Center sub-panel para editar rápidamente los FPS, calidad, y forzar o esconder el puntero del ratón en tu grabación.

## Requisitos Previos
- **Dank Material Shell** instalado y funcional.
- Paquete `gpu-screen-recorder` instalado a nivel de sistema.

## Instalación

### Método Manual (Git)
Clona este repositorio directamente en tu carpeta de plugins de Dank Material Shell:

```sh
cd ~/.config/DankMaterialShell/plugins/
git clone https://github.com/TUREPOSITORIO/dankGpuRecorder.git
```

Luego, es imperativo habilitarlo en el archivo global `~/.config/DankMaterialShell/plugin_settings.json`:
```json
  "dankGpuRecorder": {
    "enabled": true
  }
```

Finalmente, relanza Dank Material Shell (con tu atajo nativo, ej. `Mod+Shift+B` o reiniciando la sesión de Wayland).

## Uso
Una vez instalado, aparecerá el ícono de una videocámara en tu *Dankbar*:

- **Click Izquierdo**: Inicia la grabación interactiva (capturando ventana/portal). Notificarás el temporizador en marcha en rojo en el panel.
- **Click Derecho o Central (En curso)**: Pausa o Reanuda el metraje.
- **Click Izquierdo (En curso)**: Detiene por completo la grabación. Tu clip se autoguardará por defecto en `~/Videos/Screencasting/`.

## Ajustes Relevantes (Control Center)
Haciendo uso del "Control Center" dentro de Dank Material Shell o presionando sobre los detalles del plugin, podrás configurar:
- **Tasa de Refresco:** 30 FPS ó 60 FPS.
- **Calidad de Salida:** Medium, High o Very High.
- **Cursor:** Desactivarlo si quieres grabar secuencias "limpias" sin ratón.

---
**Nota Técnica**: El plugin no utiliza `kill -9` (SIGKILL). Preservamos la integridad de los contenedores `.mp4` controlando el demonio vía procesos de shell POSIX estándar (`execDetached`).
