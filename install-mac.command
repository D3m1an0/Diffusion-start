#!/bin/bash
# =============================================================
#   Diffusion-Start — Установщик для macOS (Apple Silicon MPS)
# =============================================================

set -e
cd "$(dirname "$0")"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

FORGE_DIR="$HOME/Documents/sd-webui-forge-neo"
COMFY_DIR="$HOME/Documents/ComfyUI"

header() { echo -e "\n${BLUE}${BOLD}══════════════════════════════════════════════${NC}"; echo -e "${BLUE}${BOLD}  $1${NC}"; echo -e "${BLUE}${BOLD}══════════════════════════════════════════════${NC}\n"; }
ok()     { echo -e "  ${GREEN}✓${NC} $1"; }
warn()   { echo -e "  ${YELLOW}⚠${NC}  $1"; }
fail()   { echo -e "  ${RED}✗${NC} $1"; }
info()   { echo -e "  ${CYAN}→${NC} $1"; }

# ── Скачивание с проверкой ──────────────────────────────────
# download <url> <dest> <name> <min_size_bytes>
download() {
    local url="$1" dest="$2" name="$3" min_size="${4:-1000000}"
    local dir; dir="$(dirname "$dest")"
    mkdir -p "$dir"

    # Проверяем существующий файл
    if [ -f "$dest" ]; then
        local size; size=$(stat -f%z "$dest" 2>/dev/null || echo 0)
        if [ "$size" -ge "$min_size" ]; then
            ok "$name уже скачан ($(( size / 1024 / 1024 )) МБ)"
            return 0
        else
            warn "$name — файл повреждён ($size байт), перекачиваю..."
            rm -f "$dest"
        fi
    fi

    info "Скачиваю $name..."
    local http_code
    http_code=$(curl -L --progress-bar -w "%{http_code}" "$url" -o "$dest" 2>&1 | tail -1 || echo "000")

    local size; size=$(stat -f%z "$dest" 2>/dev/null || echo 0)
    if [ "$size" -lt "$min_size" ]; then
        local content; content=$(cat "$dest" 2>/dev/null || echo "")
        fail "$name не скачался (${size} байт). Ответ: ${content:0:120}"
        rm -f "$dest"
        return 1
    fi
    ok "$name скачан ($(( size / 1024 / 1024 )) МБ)"
}

# ── Заголовок ──────────────────────────────────────────────
clear
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║     Diffusion-Start — Установщик для Mac     ║${NC}"
echo -e "${BOLD}║         Forge Neo  +  ComfyUI + Wan 2.1      ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Устанавливается в:"
echo -e "  Forge:   ${CYAN}$FORGE_DIR${NC}"
echo -e "  ComfyUI: ${CYAN}$COMFY_DIR${NC}"
echo ""

# ── Проверка зависимостей ──────────────────────────────────
header "Проверка зависимостей"

if ! command -v git &>/dev/null; then
    fail "git не найден. Установи: brew install git"
    exit 1
fi
ok "git $(git --version | awk '{print $3}')"

# Установка uv если нет
if ! command -v uv &>/dev/null && [ ! -f "$HOME/.local/bin/uv" ]; then
    info "Устанавливаю uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi
export PATH="$HOME/.local/bin:$PATH"
if ! command -v uv &>/dev/null; then
    fail "uv не удалось установить"
    exit 1
fi
ok "uv $(uv --version)"

# ── API ключи ──────────────────────────────────────────────
header "API ключи для скачивания моделей"

echo -e "  ${BOLD}civitai.com${NC} — для JuggernautXL, LoRA и апскейлеров"
echo -e "  Получить: civitai.com → аватарка → Account Settings → API Keys"
echo ""
read -rp "  Введи ключ civitai.com: " CIVITAI_TOKEN

echo ""
echo -e "  ${BOLD}civitai.red${NC} — для Z-Image Turbo, CyberRealistic, Illustrj"
echo -e "  Получить: civitai.red → аватарка → Account Settings → API Keys"
echo ""
read -rp "  Введи ключ civitai.red: " CIVITAI_RED_TOKEN
echo ""

# ══════════════════════════════════════════════
#   FORGE NEO
# ══════════════════════════════════════════════
header "Установка SD WebUI Forge Neo"

# Клонирование
if [ ! -d "$FORGE_DIR/.git" ]; then
    [ -d "$FORGE_DIR" ] && rm -rf "$FORGE_DIR"
    info "Клонирую репозиторий Forge..."
    git clone https://github.com/Haoming02/sd-webui-forge-classic "$FORGE_DIR" --branch neo
    ok "Репозиторий скачан"
else
    info "Обновляю Forge..."
    git -C "$FORGE_DIR" pull --ff-only 2>/dev/null && ok "Forge обновлён" || warn "Не удалось обновить, продолжаю"
fi

# venv
if [ ! -f "$FORGE_DIR/venv/bin/python" ]; then
    info "Создаю Python 3.13 окружение..."
    uv venv "$FORGE_DIR/venv" --python 3.13 --seed
    ok "venv создан"
else
    ok "venv уже есть"
fi

# webui-user.sh для Mac (MPS, без CUDA)
cat > "$FORGE_DIR/webui-user.sh" << 'WEBUIEOF'
#!/bin/bash
export TORCH_COMMAND="pip install torch==2.12.0 torchvision==0.27.0"
export COMMANDLINE_ARGS="--uv"
WEBUIEOF
chmod +x "$FORGE_DIR/webui-user.sh" "$FORGE_DIR/webui.sh" 2>/dev/null

# Устанавливаем torch вручную (чтобы не ждать при первом запуске)
info "Устанавливаю PyTorch (MPS)..."
"$FORGE_DIR/venv/bin/pip" install torch==2.12.0 torchvision==0.27.0 -q
ok "PyTorch установлен"

# run.command
cat > "$FORGE_DIR/run.command" << 'RUNEOF'
#!/bin/bash
cd "$(dirname "$0")"
COMMANDLINE_ARGS="--uv --skip-install" ./webui.sh
RUNEOF
chmod +x "$FORGE_DIR/run.command"

# ── Модели Forge ───────────────────────────────────────────
header "Скачивание моделей для Forge"

# Чекпоинты
download "https://civitai.com/api/download/models/456194?token=$CIVITAI_TOKEN" \
    "$FORGE_DIR/models/Stable-diffusion/juggernautXL_v9.safetensors" "JuggernautXL v9" 5000000000

download "https://civitai.red/api/download/models/2442439?token=$CIVITAI_RED_TOKEN" \
    "$FORGE_DIR/models/Stable-diffusion/z-image-turbo.safetensors" "Z-Image Turbo" 5000000000

download "https://civitai.red/api/download/models/2334591?token=$CIVITAI_RED_TOKEN" \
    "$FORGE_DIR/models/Stable-diffusion/CyberRealistic.safetensors" "CyberRealistic" 5000000000

download "https://civitai.red/api/download/models/2728617?token=$CIVITAI_RED_TOKEN" \
    "$FORGE_DIR/models/Stable-diffusion/Illustrj.safetensors" "Illustrj" 5000000000

# VAE
download "https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors" \
    "$FORGE_DIR/models/VAE/sdxl_vae.safetensors" "SDXL VAE" 300000000

download "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors" \
    "$FORGE_DIR/models/VAE/ae.safetensors" "AE VAE" 300000000

# Text encoder
download "https://huggingface.co/unsloth/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q5_K_M.gguf" \
    "$FORGE_DIR/models/text_encoder/Qwen3-4B-Q5_K_M.gguf" "Qwen3 Text Encoder" 2000000000

# LoRA
download "https://civitai.com/api/download/models/135867?token=$CIVITAI_TOKEN" \
    "$FORGE_DIR/models/Lora/DetailTweakerXL.safetensors" "DetailTweaker XL" 100000000

download "https://civitai.com/api/download/models/62833?token=$CIVITAI_TOKEN" \
    "$FORGE_DIR/models/Lora/add_detail.safetensors" "Add Detail" 10000000

download "https://civitai.com/api/download/models/90072?token=$CIVITAI_TOKEN" \
    "$FORGE_DIR/models/Lora/FilmVelvia.safetensors" "Film Velvia" 100000000

# Апскейлер
download "https://civitai.com/api/download/models/125843?token=$CIVITAI_TOKEN" \
    "$FORGE_DIR/models/ESRGAN/4x-UltraSharp.pth" "4x-UltraSharp" 50000000

# Embeddings
download "https://civitai.com/api/download/models/134583?token=$CIVITAI_TOKEN" \
    "$FORGE_DIR/models/embeddings/negativeXL_D.safetensors" "NegativeXL" 50000

# CLIP Vision
mkdir -p "$FORGE_DIR/models/clip_vision"
download "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/image_encoder/model.safetensors" \
    "$FORGE_DIR/models/clip_vision/clip_vision_g.safetensors" "CLIP Vision G" 500000000

# antelopev2
ANTELOPE_DIR="$FORGE_DIR/models/insightface/models/antelopev2"
ANTELOPE_OK=true
for f in 1k3d68.onnx 2d106det.onnx genderage.onnx glintr100.onnx scrfd_10g_bnkps.onnx; do
    fpath="$ANTELOPE_DIR/$f"
    [ -f "$fpath" ] && sz=$(stat -f%z "$fpath") || sz=0
    [ "$sz" -lt 1000 ] && { ANTELOPE_OK=false; break; }
done

if [ "$ANTELOPE_OK" = false ]; then
    info "Скачиваю antelopev2..."
    rm -rf "$ANTELOPE_DIR"
    mkdir -p "$ANTELOPE_DIR"
    curl -L --progress-bar \
        "https://github.com/deepinsight/insightface/releases/download/v0.7/antelopev2.zip" \
        -o /tmp/antelopev2.zip
    unzip -o /tmp/antelopev2.zip -d "$FORGE_DIR/models/insightface/models/"
    rm -f /tmp/antelopev2.zip
    ok "antelopev2 скачан"
else
    ok "antelopev2 уже есть"
fi

ok "Все модели Forge готовы"

# ══════════════════════════════════════════════
#   COMFYUI
# ══════════════════════════════════════════════
header "Установка ComfyUI"

# Клонирование
if [ ! -d "$COMFY_DIR/.git" ]; then
    [ -d "$COMFY_DIR" ] && rm -rf "$COMFY_DIR"
    info "Клонирую ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI "$COMFY_DIR"
    ok "ComfyUI скачан"
else
    info "Обновляю ComfyUI..."
    git -C "$COMFY_DIR" pull --ff-only 2>/dev/null && ok "ComfyUI обновлён" || warn "Не удалось обновить"
fi

# venv
if [ ! -f "$COMFY_DIR/venv/bin/python" ]; then
    info "Создаю Python 3.13 окружение для ComfyUI..."
    uv venv "$COMFY_DIR/venv" --python 3.13 --seed
    ok "venv создан"
else
    ok "venv уже есть"
fi

info "Устанавливаю зависимости ComfyUI..."
"$COMFY_DIR/venv/bin/pip" install torch==2.12.0 torchvision==0.27.0 -q
"$COMFY_DIR/venv/bin/pip" install -r "$COMFY_DIR/requirements.txt" -q
ok "Зависимости установлены"

# custom_nodes
CUSTOM_NODES=("ComfyUI-GGUF" "comfyui-kjnodes" "comfyui-manager" "comfyui-videohelpersuite" "rgthree-comfy")
for node in "${CUSTOM_NODES[@]}"; do
    src="$(dirname "$0")/custom_nodes/$node"
    dst="$COMFY_DIR/custom_nodes/$node"
    if [ -d "$src" ] && [ ! -d "$dst" ]; then
        cp -r "$src" "$dst"
        ok "custom_node: $node"
    elif [ -d "$dst" ]; then
        ok "custom_node уже есть: $node"
    fi
done

# run.command
cat > "$COMFY_DIR/run.command" << 'RUNEOF'
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
python main.py
RUNEOF
chmod +x "$COMFY_DIR/run.command"

# ── Модели ComfyUI ─────────────────────────────────────────
header "Скачивание моделей для ComfyUI"

download "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" \
    "$COMFY_DIR/models/clip_vision/clip_vision_h.safetensors" "Clip Vision H" 500000000

download "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors" \
    "$COMFY_DIR/models/diffusion_models/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors" "Wan 2.1 14B (видео)" 10000000000

download "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
    "$COMFY_DIR/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "UMT5 XXL" 5000000000

download "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" \
    "$COMFY_DIR/models/vae/wan_2.1_vae.safetensors" "Wan 2.1 VAE" 100000000

download "https://civitai.com/api/download/models/1900322?token=$CIVITAI_TOKEN" \
    "$COMFY_DIR/models/loras/wan_lora.safetensors" "Wan LoRA" 50000000

# ── Симлинки: Forge модели → ComfyUI ──────────────────────
header "Линковка общих моделей"
info "Создаю символические ссылки (без дублирования файлов)..."

link_files() {
    local src_dir="$1" dst_dir="$2" pattern="$3"
    mkdir -p "$dst_dir"
    for f in "$src_dir"/$pattern; do
        [ -f "$f" ] || continue
        fname="$(basename "$f")"
        [ -e "$dst_dir/$fname" ] || ln -sf "$f" "$dst_dir/$fname"
    done
}

link_files "$FORGE_DIR/models/Stable-diffusion" "$COMFY_DIR/models/checkpoints" "*.safetensors"
link_files "$FORGE_DIR/models/VAE"               "$COMFY_DIR/models/vae"         "*.safetensors"
link_files "$FORGE_DIR/models/Lora"              "$COMFY_DIR/models/loras"       "*.safetensors"
link_files "$FORGE_DIR/models/ESRGAN"            "$COMFY_DIR/models/upscale_models" "*.pth"
link_files "$FORGE_DIR/models/ControlNet"        "$COMFY_DIR/models/controlnet"  "*.safetensors"
link_files "$FORGE_DIR/models/clip_vision"       "$COMFY_DIR/models/clip_vision" "*.safetensors"
link_files "$FORGE_DIR/models/text_encoder"      "$COMFY_DIR/models/text_encoders" "*.gguf"

ok "Симлинки созданы"

# ══════════════════════════════════════════════
#   ФИНАЛ
# ══════════════════════════════════════════════
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║         Установка завершена успешно!         ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Запуск Forge:   ${CYAN}$FORGE_DIR/run.command${NC}"
echo -e "  Запуск ComfyUI: ${CYAN}$COMFY_DIR/run.command${NC}"
echo ""
echo -e "  Или двойной клик на ${BOLD}run.command${NC} в Finder"
echo ""
read -rp "  Нажми Enter для выхода..."
