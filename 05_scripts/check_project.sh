
#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
WARN=0

check_file() {
    local description="$1"
    local path="$2"

    if [[ -f "$path" ]]; then
        printf '[PASS] %s\n' "$description"
        PASS=$((PASS + 1))
    else
        printf '[FAIL] %s\n       Missing: %s\n' "$description" "$path"
        FAIL=$((FAIL + 1))
    fi
}

check_dir() {
    local description="$1"
    local path="$2"

    if [[ -d "$path" ]]; then
        printf '[PASS] %s\n' "$description"
        PASS=$((PASS + 1))
    else
        printf '[FAIL] %s\n       Missing: %s\n' "$description" "$path"
        FAIL=$((FAIL + 1))
    fi
}

echo "=========================================="
echo " DeepStream Project Completeness Check"
echo "=========================================="
echo "Project root: $PROJECT_ROOT"
echo

check_file "Input video" \
    "$PROJECT_ROOT/01_input/PNNL_Parking_LOT(1).avi"

check_file "YOLO11 ONNX model" \
    "$PROJECT_ROOT/02_models/yolo11m.onnx"

check_file "COCO labels" \
    "$PROJECT_ROOT/02_models/labels.txt"

check_file "YOLO parser C++ source" \
    "$PROJECT_ROOT/02_models/nvdsinfer_custom_impl_Yolo/nvdsparsebbox_Yolo.cpp"

check_file "YOLO parser CUDA source" \
    "$PROJECT_ROOT/02_models/nvdsinfer_custom_impl_Yolo/nvdsparsebbox_Yolo_cuda.cu"

check_file "Parser Makefile" \
    "$PROJECT_ROOT/02_models/nvdsinfer_custom_impl_Yolo/Makefile"

check_file "Parser build script" \
    "$PROJECT_ROOT/05_scripts/build_parser.sh"

check_file "Task A script" \
    "$PROJECT_ROOT/04_tasks/task_a_detection.sh"

check_file "Task B script" \
    "$PROJECT_ROOT/04_tasks/task_b_tracking.sh"

check_file "Task C script" \
    "$PROJECT_ROOT/04_tasks/task_c_performance.sh"

check_file "Run-all script" \
    "$PROJECT_ROOT/05_scripts/run_all.sh"

check_file "Inference config" \
    "$PROJECT_ROOT/03_pipeline/config_infer_primary.txt"

check_file "Detection app config" \
    "$PROJECT_ROOT/03_pipeline/deepstream_detection_config.txt"

check_file "Tracking app config" \
    "$PROJECT_ROOT/03_pipeline/deepstream_app_config.txt"

check_dir "Task A output directory" \
    "$PROJECT_ROOT/06_outputs/task_a_detection"

check_dir "Task B output directory" \
    "$PROJECT_ROOT/06_outputs/task_b_tracking"

check_dir "Task C output directory" \
    "$PROJECT_ROOT/06_outputs/task_c_benchmark"

echo
echo "Checking label count..."

LABEL_FILE="$PROJECT_ROOT/02_models/labels.txt"

if [[ -f "$LABEL_FILE" ]]; then
    LABEL_COUNT="$(grep -cve '^[[:space:]]*$' "$LABEL_FILE" || true)"

    if [[ "$LABEL_COUNT" -eq 80 ]]; then
        echo "[PASS] Found 80 non-empty COCO labels."
        PASS=$((PASS + 1))
    else
        echo "[FAIL] Expected 80 labels; found $LABEL_COUNT."
        FAIL=$((FAIL + 1))
    fi
fi

echo
echo "Checking required commands in this environment..."

for cmd in bash make g++ nvcc deepstream-app; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "[PASS] Command available: $cmd"
        PASS=$((PASS + 1))
    else
        echo "[WARN] Command unavailable: $cmd"
        WARN=$((WARN + 1))
    fi
done

echo
echo "=========================================="
echo " PASS: $PASS"
echo " FAIL: $FAIL"
echo " WARN: $WARN"
echo "=========================================="

if [[ "$FAIL" -gt 0 ]]; then
    echo "RESULT: INCOMPLETE - fix missing files before execution."
    exit 1
fi

echo "RESULT: File checks passed."
echo "Note: This does not prove GPU access or DeepStream compatibility."
echo "Run the GPU and configuration checks inside the target container."
