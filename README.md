# Diffusion-Start

Автоматический установщик **SD WebUI Forge Neo** + **ComfyUI** со всеми моделями для генерации реалистичных персонажей и видео.

## Что устанавливается

### SD WebUI Forge Neo
Интерфейс для генерации изображений

**Модели:**
- JuggernautXL v9 — реалистичные персонажи
- Z-Image Turbo — быстрая генерация
- CyberRealistic — фотореализм
- Illustrj — иллюстрации
- SDXL VAE + AE VAE
- Qwen3 Text Encoder
- LoRA: DetailTweaker XL, Add Detail, Film Velvia
- Апскейлер: 4x-UltraSharp
- Embedding: NegativeXL
- CLIP Vision G (для IP-Adapter)
- antelopev2 (для InstantID/FaceID)
- ControlNet: 21 модель (IP-Adapter, InstantID, позы, глубина и др.)

### ComfyUI + Wan 2.1
Интерфейс для генерации **видео** (нод-граф)

**Модели:**
- Wan 2.1 14B — генерация видео 720p
- Clip Vision H, UMT5 XXL, Wan VAE
- Wan LoRA
- Custom nodes: GGUF, KJ Nodes, Manager, VideoHelper, rgthree

Модели Forge автоматически линкуются в ComfyUI без дублирования.

---

## Установка

### Требования

**macOS (Apple Silicon M1/M2/M3/M4):**
- macOS 12+
- git (`brew install git`)
- ~80 ГБ свободного места

**Windows (NVIDIA GPU):**
- Windows 10/11 x64
- NVIDIA GPU + драйвер 572+ (CUDA 13.0)
- git: https://git-scm.com/download/win
- Python 3.13: https://python.org/downloads
- ~80 ГБ свободного места

### Перед установкой получи API ключи

**civitai.com** — для JuggernautXL, LoRA, апскейлеров:
1. Зарегистрируйся на civitai.com
2. Аватарка → Account Settings → API Keys → Add API key

**civitai.red** — для Z-Image Turbo, CyberRealistic, Illustrj:
1. Зарегистрируйся на civitai.red
2. Аватарка → Account Settings → API Keys

---

### macOS

```bash
# Скачай репозиторий
git clone https://github.com/ВАШ_АККАУНТ/Diffusion-start
```

Затем двойной клик на **`install-mac.command`** в Finder.

Или через терминал:
```bash
chmod +x install-mac.command
./install-mac.command
```

### Windows

```bat
git clone https://github.com/ВАШ_АККАУНТ/Diffusion-start
```

Двойной клик на **`install-windows.bat`** (запустится от имени администратора).

---

## После установки

**macOS:**
- Forge: `~/Documents/sd-webui-forge-neo/run.command`
- ComfyUI: `~/Documents/ComfyUI/run.command`

**Windows:**
- Forge: `%USERPROFILE%\Documents\sd-webui-forge-neo\run.bat`
- ComfyUI: `%USERPROFILE%\Documents\ComfyUI\run.bat`

Forge открывается на http://127.0.0.1:7860  
ComfyUI открывается на http://127.0.0.1:8188

---

## Повторный запуск установщика

Скрипт **идемпотентен** — можно запускать повторно:
- Уже скачанные модели правильного размера пропускаются
- Повреждённые файлы удаляются и перекачиваются
- Репозитории обновляются через `git pull`
- Установка недостающих компонентов продолжается

---

## Структура

```
Diffusion-start/
├── install-mac.command     # Установщик macOS
├── install-windows.bat     # Установщик Windows (запускает PS1)
├── install-windows.ps1     # PowerShell скрипт установки
├── custom_nodes/           # Ноды для ComfyUI (из комплекта)
│   ├── ComfyUI-GGUF
│   ├── comfyui-kjnodes
│   ├── comfyui-manager
│   ├── comfyui-videohelpersuite
│   └── rgthree-comfy
└── README.md
```
