
#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

INPUT="$PROJECT_ROOT/01_input/PNNL_Parking_LOT(1).avi"
MODEL="$PROJECT_ROOT/02_models/yolo11m.onnx"
LABELS="$PROJECT_ROOT/02_models/labels.txt"
PARSER="$PROJECT_ROOT/02_models/nvdsinfer_custom_impl_Yolo/libnvdsinfer_custom_impl_Yolo.so"
CONFIG="$PROJECT_ROOT/03_pipeline/deepstream_app_config.txt"

OUT="$PROJECT_ROOT/06_outputs/task_b_tracking"
LOG_DIR="$OUT/logs"
VIDEO_DIR="$OUT/videos"
LOG="$LOG_DIR/tracking.log"

mkdir -p "$LOG_DIR" "$VIDEO_DIR" "$OUT/tracks" "$OUT/reports"

echo "=========================================="
echo " Task B - Object Tracking"
echo "=========================================="

for file in "$INPUT" "$MODEL" "$LABELS" "$PARSER" "$CONFIG"; do
    if [[ ! -f "$file" ]]; then
        echo "ERROR: Required file missing: $file"
        exit 1
    fi
done

if ! command -v deepstream-app >/dev/null 2>&1; then
    echo "ERROR: deepstream-app not found."
    echo "Run this script inside the compatible DeepStream container."
    exit 1
fi

cd "$PROJECT_ROOT"

echo "Input:  $INPUT"
echo "Config: $CONFIG"
echo "Log:    $LOG"
echo

set +e
deepstream-app -c "$CONFIG" 2>&1 | tee "$LOG"
PIPE_STATUS=("${PIPESTATUS[@]}")
set -e

APP_STATUS="${PIPE_STATUS[0]}"

if [[ "$APP_STATUS" -ne 0 ]]; then
    echo "ERROR: Tracking failed. Review $LOG"
    exit "$APP_STATUS"
fi

echo
echo "Tracking command completed."
echo "Expected video: $VIDEO_DIR/tracked_output.mp4"
echo "Review the log to confirm tracker initialization and execution."
