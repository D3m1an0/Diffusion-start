# =============================================================
#   Diffusion-Start — Установщик для Windows (CUDA)
# =============================================================
#   Запуск: install-windows.bat
# =============================================================

$ErrorActionPreference = "Continue"
$ForgeDir = "$env:USERPROFILE\Documents\sd-webui-forge-neo"
$ComfyDir = "$env:USERPROFILE\Documents\ComfyUI"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── Цвета ────────────────────────────────────────────────────
function Write-Header($text) {
    Write-Host ""
    Write-Host "══════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host "  $text" -ForegroundColor Blue
    Write-Host "══════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""
}
function Write-Ok($text)   { Write-Host "  [OK] $text" -ForegroundColor Green }
function Write-Warn($text) { Write-Host "  [!!] $text" -ForegroundColor Yellow }
function Write-Fail($text) { Write-Host "  [XX] $text" -ForegroundColor Red }
function Write-Info($text) { Write-Host "  --> $text" -ForegroundColor Cyan }

# ── Скачивание с проверкой ───────────────────────────────────
function Download-Model {
    param(
        [string]$Url,
        [string]$Dest,
        [string]$Name,
        [long]$MinSize = 1000000
    )

    $dir = Split-Path -Parent $Dest
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    # Проверяем существующий файл
    if (Test-Path $Dest) {
        $size = (Get-Item $Dest).Length
        if ($size -ge $MinSize) {
            Write-Ok "$Name уже скачан ($([math]::Round($size/1MB)) МБ)"
            return $true
        } else {
            Write-Warn "$Name — файл повреждён ($size байт), перекачиваю..."
            Remove-Item $Dest -Force
        }
    }

    Write-Info "Скачиваю $Name..."
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")

        # Прогресс-бар
        $global:dlName = $Name
        Register-ObjectEvent $wc DownloadProgressChanged -Action {
            $pct = $Event.SourceEventArgs.ProgressPercentage
            $dl  = [math]::Round($Event.SourceEventArgs.BytesReceived / 1MB)
            $tot = [math]::Round($Event.SourceEventArgs.TotalBytesToReceive / 1MB)
            Write-Progress -Activity "Скачиваю $global:dlName" `
                -Status "$dl МБ / $tot МБ" -PercentComplete $pct
        } | Out-Null

        $task = $wc.DownloadFileTaskAsync($Url, $Dest)
        while (!$task.IsCompleted) { Start-Sleep -Milliseconds 500 }
        Write-Progress -Activity "Скачиваю $Name" -Completed

        if ($task.IsFaulted) { throw $task.Exception }
    } catch {
        Write-Fail "Ошибка скачивания $Name`: $_"
        if (Test-Path $Dest) { Remove-Item $Dest -Force }
        return $false
    }

    if (Test-Path $Dest) {
        $size = (Get-Item $Dest).Length
        if ($size -ge $MinSize) {
            Write-Ok "$Name скачан ($([math]::Round($size/1MB)) МБ)"
            return $true
        }
    }
    Write-Fail "$Name — файл слишком маленький после скачивания"
    if (Test-Path $Dest) { Remove-Item $Dest -Force }
    return $false
}

# ── Заголовок ─────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Diffusion-Start — Установщик для Windows   ║" -ForegroundColor Cyan
Write-Host "║        Forge Neo  +  ComfyUI + Wan 2.1       ║" -ForegroundColor Cyan
Write-Host "║              CUDA (NVIDIA GPU)               ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Требуется: NVIDIA GPU + драйвер 572+ (CUDA 13.0)" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Forge:   $ForgeDir" -ForegroundColor Cyan
Write-Host "  ComfyUI: $ComfyDir" -ForegroundColor Cyan
Write-Host ""

# ── Зависимости ────────────────────────────────────────────────
Write-Header "Проверка зависимостей"

# Git
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Fail "git не найден. Скачай: https://git-scm.com/download/win"
    Pause; exit 1
}
Write-Ok "git $(git --version)"

# Python
if (!(Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Fail "Python не найден. Скачай Python 3.13: https://python.org/downloads"
    Pause; exit 1
}
$pyver = python --version 2>&1
Write-Ok "Python: $pyver"

# uv
if (!(Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Info "Устанавливаю uv..."
    Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
    $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
}
if (Get-Command uv -ErrorAction SilentlyContinue) {
    Write-Ok "uv $(uv --version)"
} else {
    Write-Warn "uv не найден, буду использовать pip"
}

# ── API ключи ──────────────────────────────────────────────────
Write-Header "API ключи для скачивания моделей"

Write-Host "  civitai.com — JuggernautXL, LoRA, апскейлеры" -ForegroundColor White
Write-Host "  Получить: civitai.com -> аватарка -> Account Settings -> API Keys" -ForegroundColor Gray
Write-Host ""
$CivitaiToken = Read-Host "  Введи ключ civitai.com"

Write-Host ""
Write-Host "  civitai.red — Z-Image Turbo, CyberRealistic, Illustrj" -ForegroundColor White
Write-Host "  Получить: civitai.red -> аватарка -> Account Settings -> API Keys" -ForegroundColor Gray
Write-Host ""
$CivitaiRedToken = Read-Host "  Введи ключ civitai.red"
Write-Host ""

# ══════════════════════════════════════════════
#   FORGE NEO
# ══════════════════════════════════════════════
Write-Header "Установка SD WebUI Forge Neo"

# Клонирование
if (!(Test-Path "$ForgeDir\.git")) {
    if (Test-Path $ForgeDir) { Remove-Item $ForgeDir -Recurse -Force }
    Write-Info "Клонирую репозиторий Forge..."
    git clone https://github.com/Haoming02/sd-webui-forge-classic $ForgeDir --branch neo
    Write-Ok "Репозиторий скачан"
} else {
    Write-Info "Обновляю Forge..."
    git -C $ForgeDir pull --ff-only 2>$null
    Write-Ok "Forge обновлён"
}

# venv
if (!(Test-Path "$ForgeDir\venv\Scripts\python.exe")) {
    Write-Info "Создаю Python 3.13 окружение..."
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        uv venv "$ForgeDir\venv" --python 3.13 --seed
    } else {
        python -m venv "$ForgeDir\venv"
    }
    Write-Ok "venv создан"
} else {
    Write-Ok "venv уже есть"
}

# webui-user.bat для Windows (CUDA 13.0)
@"
@echo off
set TORCH_COMMAND=pip install torch==2.11.0+cu130 torchvision==0.26.0+cu130 --extra-index-url https://download.pytorch.org/whl/cu130
set COMMANDLINE_ARGS=--uv
call webui.bat
"@ | Set-Content "$ForgeDir\webui-user.bat" -Encoding UTF8

# Устанавливаем torch с CUDA
Write-Info "Устанавливаю PyTorch с CUDA 13.0..."
& "$ForgeDir\venv\Scripts\pip.exe" install `
    "torch==2.11.0+cu130" "torchvision==0.26.0+cu130" `
    --extra-index-url https://download.pytorch.org/whl/cu130 -q
Write-Ok "PyTorch CUDA установлен"

# run.bat
@"
@echo off
cd /d "%~dp0"
set COMMANDLINE_ARGS=--uv --skip-install
call webui.bat
"@ | Set-Content "$ForgeDir\run.bat" -Encoding UTF8

# ── Модели Forge ────────────────────────────────────────────
Write-Header "Скачивание моделей для Forge"

$sd = "$ForgeDir\models\Stable-diffusion"
Download-Model "https://civitai.com/api/download/models/456194?token=$CivitaiToken" "$sd\juggernautXL_v9.safetensors"  "JuggernautXL v9"    5000000000
Download-Model "https://civitai.red/api/download/models/2442439?token=$CivitaiRedToken" "$sd\z-image-turbo.safetensors" "Z-Image Turbo" 5000000000
Download-Model "https://civitai.red/api/download/models/2334591?token=$CivitaiRedToken" "$sd\CyberRealistic.safetensors" "CyberRealistic" 5000000000
Download-Model "https://civitai.red/api/download/models/2728617?token=$CivitaiRedToken" "$sd\Illustrj.safetensors"       "Illustrj"       5000000000

$vae = "$ForgeDir\models\VAE"
Download-Model "https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors" "$vae\sdxl_vae.safetensors" "SDXL VAE" 300000000
Download-Model "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors" "$vae\ae.safetensors" "AE VAE" 300000000

Download-Model "https://huggingface.co/unsloth/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q5_K_M.gguf" "$ForgeDir\models\text_encoder\Qwen3-4B-Q5_K_M.gguf" "Qwen3 Text Encoder" 2000000000

$lora = "$ForgeDir\models\Lora"
Download-Model "https://civitai.com/api/download/models/135867?token=$CivitaiToken" "$lora\DetailTweakerXL.safetensors" "DetailTweaker XL" 100000000
Download-Model "https://civitai.com/api/download/models/62833?token=$CivitaiToken"  "$lora\add_detail.safetensors"      "Add Detail"       10000000
Download-Model "https://civitai.com/api/download/models/90072?token=$CivitaiToken"  "$lora\FilmVelvia.safetensors"      "Film Velvia"      100000000

Download-Model "https://civitai.com/api/download/models/125843?token=$CivitaiToken" "$ForgeDir\models\ESRGAN\4x-UltraSharp.pth" "4x-UltraSharp" 50000000
Download-Model "https://civitai.com/api/download/models/134583?token=$CivitaiToken" "$ForgeDir\models\embeddings\negativeXL_D.safetensors" "NegativeXL" 50000

New-Item -ItemType Directory "$ForgeDir\models\clip_vision" -Force | Out-Null
Download-Model "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/image_encoder/model.safetensors" "$ForgeDir\models\clip_vision\clip_vision_g.safetensors" "CLIP Vision G" 500000000

# antelopev2
$antelopeDir = "$ForgeDir\models\insightface\models\antelopev2"
$antelopeOk = $true
foreach ($f in @("1k3d68.onnx","2d106det.onnx","genderage.onnx","glintr100.onnx","scrfd_10g_bnkps.onnx")) {
    $fp = "$antelopeDir\$f"
    if (!(Test-Path $fp) -or (Get-Item $fp).Length -lt 1000) { $antelopeOk = $false; break }
}
if (!$antelopeOk) {
    Write-Info "Скачиваю antelopev2..."
    if (Test-Path $antelopeDir) { Remove-Item $antelopeDir -Recurse -Force }
    New-Item -ItemType Directory $antelopeDir -Force | Out-Null
    $tmp = "$env:TEMP\antelopev2.zip"
    (New-Object System.Net.WebClient).DownloadFile("https://github.com/deepinsight/insightface/releases/download/v0.7/antelopev2.zip", $tmp)
    Expand-Archive $tmp -DestinationPath "$ForgeDir\models\insightface\models\" -Force
    Remove-Item $tmp
    Write-Ok "antelopev2 скачан"
} else {
    Write-Ok "antelopev2 уже есть"
}

# ══════════════════════════════════════════════
#   COMFYUI
# ══════════════════════════════════════════════
Write-Header "Установка ComfyUI"

if (!(Test-Path "$ComfyDir\.git")) {
    if (Test-Path $ComfyDir) { Remove-Item $ComfyDir -Recurse -Force }
    Write-Info "Клонирую ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI $ComfyDir
    Write-Ok "ComfyUI скачан"
} else {
    Write-Info "Обновляю ComfyUI..."
    git -C $ComfyDir pull --ff-only 2>$null
    Write-Ok "ComfyUI обновлён"
}

if (!(Test-Path "$ComfyDir\venv\Scripts\python.exe")) {
    Write-Info "Создаю Python 3.13 окружение для ComfyUI..."
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        uv venv "$ComfyDir\venv" --python 3.13 --seed
    } else {
        python -m venv "$ComfyDir\venv"
    }
    Write-Ok "venv создан"
} else {
    Write-Ok "venv уже есть"
}

Write-Info "Устанавливаю зависимости ComfyUI (CUDA)..."
& "$ComfyDir\venv\Scripts\pip.exe" install `
    "torch==2.11.0+cu130" "torchvision==0.26.0+cu130" `
    --extra-index-url https://download.pytorch.org/whl/cu130 -q
& "$ComfyDir\venv\Scripts\pip.exe" install -r "$ComfyDir\requirements.txt" -q
Write-Ok "Зависимости установлены"

# custom_nodes
foreach ($node in @("ComfyUI-GGUF","comfyui-kjnodes","comfyui-manager","comfyui-videohelpersuite","rgthree-comfy")) {
    $src = "$ScriptDir\custom_nodes\$node"
    $dst = "$ComfyDir\custom_nodes\$node"
    if ((Test-Path $src) -and !(Test-Path $dst)) {
        Copy-Item $src $dst -Recurse
        Write-Ok "custom_node: $node"
    } elseif (Test-Path $dst) {
        Write-Ok "custom_node уже есть: $node"
    }
}

# run.bat
@"
@echo off
cd /d "%~dp0"
call venv\Scripts\activate.bat
python main.py
"@ | Set-Content "$ComfyDir\run.bat" -Encoding UTF8

# ── Модели ComfyUI ───────────────────────────────────────────
Write-Header "Скачивание моделей для ComfyUI"

Download-Model "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" "$ComfyDir\models\clip_vision\clip_vision_h.safetensors" "Clip Vision H" 500000000
Download-Model "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors" "$ComfyDir\models\diffusion_models\wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors" "Wan 2.1 14B (видео)" 10000000000
Download-Model "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "$ComfyDir\models\text_encoders\umt5_xxl_fp8_e4m3fn_scaled.safetensors" "UMT5 XXL" 5000000000
Download-Model "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" "$ComfyDir\models\vae\wan_2.1_vae.safetensors" "Wan 2.1 VAE" 100000000
Download-Model "https://civitai.com/api/download/models/1900322?token=$CivitaiToken" "$ComfyDir\models\loras\wan_lora.safetensors" "Wan LoRA" 50000000

# ── Симлинки: Forge → ComfyUI ───────────────────────────────
Write-Header "Линковка общих моделей"
Write-Info "Создаю символические ссылки (без дублирования файлов)..."

function Link-Files($SrcDir, $DstDir, $Pattern) {
    if (!(Test-Path $DstDir)) { New-Item -ItemType Directory $DstDir -Force | Out-Null }
    Get-ChildItem "$SrcDir\$Pattern" -ErrorAction SilentlyContinue | ForEach-Object {
        $dst = "$DstDir\$($_.Name)"
        if (!(Test-Path $dst)) {
            New-Item -ItemType SymbolicLink -Path $dst -Target $_.FullName -Force | Out-Null
        }
    }
}

Link-Files "$ForgeDir\models\Stable-diffusion" "$ComfyDir\models\checkpoints"    "*.safetensors"
Link-Files "$ForgeDir\models\VAE"               "$ComfyDir\models\vae"            "*.safetensors"
Link-Files "$ForgeDir\models\Lora"              "$ComfyDir\models\loras"          "*.safetensors"
Link-Files "$ForgeDir\models\ESRGAN"            "$ComfyDir\models\upscale_models" "*.pth"
Link-Files "$ForgeDir\models\ControlNet"        "$ComfyDir\models\controlnet"     "*.safetensors"
Link-Files "$ForgeDir\models\clip_vision"       "$ComfyUI\models\clip_vision"     "*.safetensors"
Link-Files "$ForgeDir\models\text_encoder"      "$ComfyDir\models\text_encoders"  "*.gguf"
Write-Ok "Симлинки созданы"

# ── Финал ────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║       Установка завершена успешно!           ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Запуск Forge:   $ForgeDir\run.bat" -ForegroundColor Cyan
Write-Host "  Запуск ComfyUI: $ComfyDir\run.bat" -ForegroundColor Cyan
Write-Host ""
Pause
