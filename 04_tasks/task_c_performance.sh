
#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

INPUT="$PROJECT_ROOT/01_input/PNNL_Parking_LOT(1).avi"
CONFIG="$PROJECT_ROOT/03_pipeline/deepstream_benchmark_config.txt"

OUT="$PROJECT_ROOT/06_outputs/task_c_benchmark"
CSV_DIR="$OUT/csv"
REPORT_DIR="$OUT/reports"
LOG_DIR="$OUT/logs"

mkdir -p "$CSV_DIR" "$OUT/charts" "$REPORT_DIR" "$LOG_DIR"

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
START_EPOCH="$(date +%s)"
START_NS="$(date +%s%N)"

LOG="$LOG_DIR/benchmark_${START_EPOCH}.log"
CSV="$CSV_DIR/benchmark_results.csv"
REPORT="$REPORT_DIR/benchmark_${START_EPOCH}.txt"

echo "=========================================="
echo " Task C - Performance Benchmark"
echo "=========================================="

if [[ ! -f "$INPUT" ]]; then
    echo "ERROR: Input video not found: $INPUT"
    exit 1
fi

if [[ ! -f "$CONFIG" ]]; then
    echo "ERROR: Detection config not found: $CONFIG"
    exit 1
fi

if ! command -v deepstream-app >/dev/null 2>&1; then
    echo "ERROR: deepstream-app not found."
    exit 1
fi

GPU_NAME="unknown"
if command -v nvidia-smi >/dev/null 2>&1; then
    GPU_NAME="$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -n 1 || true)"
    [[ -n "$GPU_NAME" ]] || GPU_NAME="unknown"
fi

echo "Timestamp UTC: $TIMESTAMP"
echo "GPU: $GPU_NAME"
echo "Input: $INPUT"
echo "Config: $CONFIG"
echo

set +e
deepstream-app -c "$CONFIG" 2>&1 | tee "$LOG"
PIPE_STATUS=("${PIPESTATUS[@]}")
set -e

APP_STATUS="${PIPE_STATUS[0]}"
END_NS="$(date +%s%N)"
END_EPOCH="$(date +%s)"

ELAPSED_SECONDS="$(awk -v start="$START_NS" -v end="$END_NS" 'BEGIN {printf "%.6f", (end-start)/1000000000}')"

if [[ "$APP_STATUS" -ne 0 ]]; then
    STATUS="FAILED"
else
    STATUS="COMPLETED"
fi

if [[ ! -f "$CSV" ]]; then
    echo "timestamp_utc,gpu_name,elapsed_seconds,status,log_file" > "$CSV"
fi

printf '"%s","%s",%s,"%s","%s"\n' \
    "$TIMESTAMP" "$GPU_NAME" "$ELAPSED_SECONDS" "$STATUS" "$LOG" >> "$CSV"

{
    echo "DeepStream GPU Benchmark Report"
    echo "==============================="
    echo "Timestamp UTC: $TIMESTAMP"
    echo "GPU: $GPU_NAME"
    echo "Input: $INPUT"
    echo "Config: $CONFIG"
    echo "Start epoch: $START_EPOCH"
    echo "End epoch: $END_EPOCH"
    echo "Elapsed seconds: $ELAPSED_SECONDS"
    echo "Status: $STATUS"
    echo "Execution log: $LOG"
    echo
    echo "Note: elapsed wall time is not inference FPS."
    echo "Use DeepStream performance logs for measured FPS."
} > "$REPORT"

echo
echo "Elapsed seconds: $ELAPSED_SECONDS"
echo "Status: $STATUS"
echo "CSV: $CSV"
echo "Report: $REPORT"

if [[ "$APP_STATUS" -ne 0 ]]; then
    exit "$APP_STATUS"
fi
