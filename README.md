# Diffusion-Start

Automated installer for **SD WebUI Forge Neo** + **ComfyUI** with all models needed for realistic character and video generation.

## What gets installed

### SD WebUI Forge Neo
Image generation interface

**Models:**
- JuggernautXL v9 — realistic characters
- Z-Image Turbo — fast generation
- CyberRealistic — photorealism
- Illustrj — illustrations
- SDXL VAE + AE VAE
- Qwen3 Text Encoder
- LoRA: DetailTweaker XL, Add Detail, Film Velvia
- Upscaler: 4x-UltraSharp
- Embedding: NegativeXL
- CLIP Vision G (for IP-Adapter)
- antelopev2 (for InstantID/FaceID)
- ControlNet: 21 models (IP-Adapter, InstantID, pose, depth, etc.)

### ComfyUI + Wan 2.1
Node-graph interface for **video** generation

**Models:**
- Wan 2.1 14B — 720p video generation
- Clip Vision H, UMT5 XXL, Wan VAE
- Wan LoRA
- Custom nodes: GGUF, KJ Nodes, Manager, VideoHelper, rgthree

Forge models are automatically symlinked into ComfyUI — no duplicate downloads.

---

## Installation

### Requirements

**macOS (Apple Silicon M1/M2/M3/M4):**
- macOS 12+
- git (`brew install git`)
- ~80 GB free disk space

**Windows (NVIDIA GPU):**
- Windows 10/11 x64
- NVIDIA GPU + driver 572+ (CUDA 13.0)
- git: https://git-scm.com/download/win
- Python 3.13: https://python.org/downloads
- ~80 GB free disk space

### Before you start: get API keys

**civitai.com** — for JuggernautXL, LoRAs, upscalers:
1. Sign up at civitai.com
2. Avatar → Account Settings → API Keys → Add API key

**civitai.red** — for Z-Image Turbo, CyberRealistic, Illustrj:
1. Sign up at civitai.red
2. Avatar → Account Settings → API Keys

The installer will prompt for these keys during the download step — paste them when asked.

---

### macOS

```bash
git clone https://github.com/D3m1an0/Diffusion-start
cd Diffusion-start
```

Double-click **`install-mac.command`** in Finder.

Or via terminal:
```bash
chmod +x install-mac.command
./install-mac.command
```

### Windows

```bat
git clone https://github.com/D3m1an0/Diffusion-start
cd Diffusion-start
```

Double-click **`install-windows.bat`** (runs as administrator).

---

## Is anything left to configure after install?

No — the installer is fully automatic. It clones both repos, creates the Python virtual environments, installs all dependencies, copies the custom nodes, downloads and verifies every model (re-downloading anything corrupted or incomplete), and links shared models between Forge and ComfyUI. The only manual input required is pasting your civitai.com / civitai.red API keys when prompted.

After installation finishes, just launch the apps — no extra setup needed.

---

## After installation

**macOS:**
- Forge: `~/Documents/sd-webui-forge-neo/run.command`
- ComfyUI: `~/Documents/ComfyUI/run.command`

**Windows:**
- Forge: `%USERPROFILE%\Documents\sd-webui-forge-neo\run.bat`
- ComfyUI: `%USERPROFILE%\Documents\ComfyUI\run.bat`

Forge opens at http://127.0.0.1:7860
ComfyUI opens at http://127.0.0.1:8188

---

## Re-running the installer

The script is **idempotent** — safe to run again:
- Already-downloaded models of the correct size are skipped
- Corrupted files are deleted and re-downloaded
- Repositories are updated via `git pull`
- Any missing components are installed

---

## Structure

```
Diffusion-start/
├── install-mac.command     # macOS installer
├── install-windows.bat     # Windows installer (launches PS1)
├── install-windows.ps1     # PowerShell install script
├── custom_nodes/           # ComfyUI custom nodes (bundled)
│   ├── ComfyUI-GGUF
│   ├── comfyui-kjnodes
│   ├── comfyui-manager
│   ├── comfyui-videohelpersuite
│   └── rgthree-comfy
├── README.md
└── LICENSE
```

---

## License

MIT — see [LICENSE](LICENSE).
