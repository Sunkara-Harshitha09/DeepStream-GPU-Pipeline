
#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

if [[ -z "${DEEPSTREAM_IMAGE:-}" ]]; then
    echo "ERROR: DEEPSTREAM_IMAGE is not set."
    echo "Set it to a compatible NVIDIA DeepStream development image."
    echo 'Example: DEEPSTREAM_IMAGE="your-image" bash 05_scripts/start_deepstream_container.sh'
    exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker CLI is not installed or unavailable."
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker daemon is unavailable."
    exit 1
fi

if [[ ! -f "$PROJECT_ROOT/01_input/PNNL_Parking_LOT(1).avi" ]]; then
    echo "ERROR: Input video is missing."
    exit 1
fi

if [[ ! -f "$PROJECT_ROOT/02_models/yolo11m.onnx" ]]; then
    echo "ERROR: YOLO11 ONNX model is missing."
    exit 1
fi

echo "=========================================="
echo " DeepStream GPU Container Launcher"
echo "=========================================="
echo "Project: $PROJECT_ROOT"
echo "Image:   $DEEPSTREAM_IMAGE"
echo
echo "The project will be mounted at /workspace."
echo "GPU access requires a compatible NVIDIA driver and Docker setup."
echo

docker run --rm -it \
    --gpus all \
    --ipc=host \
    --mount "type=bind,source=$PROJECT_ROOT,target=/workspace" \
    --workdir /workspace \
    "$DEEPSTREAM_IMAGE" \
    bash
