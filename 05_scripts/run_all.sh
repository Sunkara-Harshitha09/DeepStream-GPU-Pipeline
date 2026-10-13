
#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

OUTPUT="$PROJECT_ROOT/06_outputs"
SUMMARY_DIR="$OUTPUT/summary"
LOG_DIR="$OUTPUT/logs"

mkdir -p "$SUMMARY_DIR" "$LOG_DIR"

RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
MASTER_LOG="$LOG_DIR/run_all_${RUN_ID}.log"
SUMMARY_FILE="$SUMMARY_DIR/execution_report_${RUN_ID}.txt"

exec > >(tee -a "$MASTER_LOG") 2>&1

START_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
START_EPOCH="$(date +%s)"

echo "=========================================="
echo " DeepStream GPU Pipeline - Run All Tasks"
echo "=========================================="
echo "Project: $PROJECT_ROOT"
echo "Run ID:  $RUN_ID"
echo "Start:   $START_UTC"
echo "Log:     $MASTER_LOG"
echo

write_summary_header() {
    {
        echo "DeepStream GPU Pipeline Execution Report"
        echo "Run ID: $RUN_ID"
        echo "Start UTC: $START_UTC"
        echo "Project: $PROJECT_ROOT"
        echo
    } > "$SUMMARY_FILE"
}

finish_report() {
    local status="$1"
    local end_utc
    local end_epoch
    local elapsed

    end_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    end_epoch="$(date +%s)"
    elapsed=$((end_epoch - START_EPOCH))

    {
        echo
        echo "End UTC: $end_utc"
        echo "Elapsed wall time (seconds): $elapsed"
        echo "Final status: $status"
        echo "Master log: $MASTER_LOG"
    } >> "$SUMMARY_FILE"

    echo
    echo "=========================================="
    echo "Final status: $status"
    echo "Summary: $SUMMARY_FILE"
    echo "Master log: $MASTER_LOG"
    echo "=========================================="
}

write_summary_header

if [[ ! -f "$PROJECT_ROOT/01_input/PNNL_Parking_LOT(1).avi" ]]; then
    echo "ERROR: Input video missing."
    echo "FAILED: Preflight - input video missing" >> "$SUMMARY_FILE"
    finish_report "FAILED"
    exit 1
fi

if [[ ! -f "$PROJECT_ROOT/02_models/yolo11m.onnx" ]]; then
    echo "ERROR: ONNX model missing."
    echo "FAILED: Preflight - ONNX model missing" >> "$SUMMARY_FILE"
    finish_report "FAILED"
    exit 1
fi

if [[ ! -f "$PROJECT_ROOT/02_models/labels.txt" ]]; then
    echo "ERROR: labels.txt missing."
    echo "FAILED: Preflight - labels missing" >> "$SUMMARY_FILE"
    finish_report "FAILED"
    exit 1
fi

if [[ ! -f "$PROJECT_ROOT/02_models/nvdsinfer_custom_impl_Yolo/libnvdsinfer_custom_impl_Yolo.so" ]]; then
    echo "ERROR: YOLO parser library missing."
    echo "Build it using 05_scripts/build_parser.sh inside the compatible"
    echo "DeepStream development container first."
    echo "FAILED: Preflight - parser library missing" >> "$SUMMARY_FILE"
    finish_report "FAILED"
    exit 1
fi

if ! command -v deepstream-app >/dev/null 2>&1; then
    echo "ERROR: deepstream-app is not available in this environment."
    echo "Run this orchestrator inside the compatible DeepStream container."
    echo "FAILED: Preflight - deepstream-app unavailable" >> "$SUMMARY_FILE"
    finish_report "FAILED"
    exit 1
fi

cd "$PROJECT_ROOT"

run_task() {
    local task_name="$1"
    local task_script="$2"

    echo
    echo "------------------------------------------"
    echo "Starting: $task_name"
    echo "------------------------------------------"

    if [[ ! -f "$task_script" ]]; then
        echo "ERROR: Task script missing: $task_script"
        echo "FAILED: $task_name - script missing" >> "$SUMMARY_FILE"
        finish_report "FAILED"
        exit 1
    fi

    if bash "$task_script"; then
        echo "COMPLETED: $task_name"
        echo "COMPLETED: $task_name" >> "$SUMMARY_FILE"
    else
        local task_status=$?
        echo "FAILED: $task_name (exit code $task_status)"
        echo "FAILED: $task_name (exit code $task_status)" >> "$SUMMARY_FILE"
        echo "Stopping execution. Inspect task logs."
        finish_report "FAILED"
        exit "$task_status"
    fi
}

run_task "Task A - Object Detection" \
    "$PROJECT_ROOT/04_tasks/task_a_detection.sh"

run_task "Task B - Object Tracking" \
    "$PROJECT_ROOT/04_tasks/task_b_tracking.sh"

run_task "Task C - Performance Benchmark" \
    "$PROJECT_ROOT/04_tasks/task_c_performance.sh"

finish_report "SUCCESS"
