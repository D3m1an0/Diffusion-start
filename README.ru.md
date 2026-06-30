# Diffusion-Start

[English version](README.md)

Автоматический установщик **SD WebUI Forge Neo** + **ComfyUI** со всеми моделями, необходимыми для генерации реалистичных персонажей и видео.

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
- ControlNet: 21 моделей (IP-Adapter, InstantID, поза, глубина и др.)

### ComfyUI + Wan 2.1
Нодовый интерфейс для генерации **видео**

**Модели:**
- Wan 2.1 14B — генерация видео 720p
- Clip Vision H, UMT5 XXL, Wan VAE
- Wan LoRA
- Кастомные ноды: GGUF, KJ Nodes, Manager, VideoHelper, rgthree

Модели Forge автоматически симлинкаются в ComfyUI — без дублирования загрузок.

---

## Установка

### Требования

**macOS (Apple Silicon M1/M2/M3/M4):**
- macOS 12+
- git (`brew install git`)
- ~80 ГБ свободного места на диске

**Windows (NVIDIA GPU):**
- Windows 10/11 x64
- NVIDIA GPU + драйвер 572+ (CUDA 13.0)
- git: https://git-scm.com/download/win
- Python 3.13: https://python.org/downloads
- ~80 ГБ свободного места на диске

### Перед началом: получите API-ключи

**civitai.com** — для JuggernautXL, LoRA, апскейлеров:
1. Зарегистрируйтесь на civitai.com
2. Аватар → Account Settings → API Keys → Add API key

**civitai.red** — для Z-Image Turbo, CyberRealistic, Illustrj:
1. Зарегистрируйтесь на civitai.red
2. Аватар → Account Settings → API Keys

Установщик запросит эти ключи на этапе загрузки моделей — просто вставьте их, когда будет предложено.

---

### macOS

```bash
git clone https://github.com/D3m1an0/Diffusion-start
cd Diffusion-start
```

Дважды кликните **`install-mac.command`** в Finder.

Или через терминал:
```bash
chmod +x install-mac.command
./install-mac.command
```

### Windows

```bat
git clone https://github.com/D3m1an0/Diffusion-start
cd Diffusion-start
```

Дважды кликните **`install-windows.bat`** (запустится от имени администратора).

---

## Нужно ли что-то донастраивать после установки?

Нет — установщик полностью автоматический. Он клонирует оба репозитория, создаёт виртуальные окружения Python, устанавливает все зависимости, копирует кастомные ноды, скачивает и проверяет каждую модель (перекачивая повреждённые или неполные файлы), а также связывает общие модели между Forge и ComfyUI симлинками. Единственный ручной шаг — вставить свои API-ключи civitai.com / civitai.red, когда установщик их запросит.

После завершения установки достаточно просто запустить приложения — дополнительная настройка не требуется.

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

Скрипт **идемпотентен** — его безопасно запускать повторно:
- Уже скачанные модели правильного размера пропускаются
- Повреждённые файлы удаляются и перекачиваются заново
- Репозитории обновляются через `git pull`
- Любые отсутствующие компоненты доустанавливаются

---

## Структура

```
Diffusion-start/
├── install-mac.command     # установщик для macOS
├── install-windows.bat     # установщик для Windows (запускает PS1)
├── install-windows.ps1     # PowerShell-скрипт установки
├── custom_nodes/           # кастомные ноды ComfyUI (входят в комплект)
│   ├── ComfyUI-GGUF
│   ├── comfyui-kjnodes
│   ├── comfyui-manager
│   ├── comfyui-videohelpersuite
│   └── rgthree-comfy
├── README.md
├── README.ru.md
└── LICENSE
```

---

## Лицензия

MIT — см. [LICENSE](LICENSE).
