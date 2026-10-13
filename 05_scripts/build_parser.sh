
#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PARSER_DIR="$PROJECT_ROOT/02_models/nvdsinfer_custom_impl_Yolo"
OUTPUT_LIB="$PARSER_DIR/libnvdsinfer_custom_impl_Yolo.so"
DEEPSTREAM_INCLUDE="/opt/nvidia/deepstream/deepstream/sources/includes"

echo "=========================================="
echo " DeepStream YOLOv11 Parser Build"
echo "=========================================="
echo "Project: $PROJECT_ROOT"
echo "Parser:  $PARSER_DIR"
echo

if [[ ! -f "$PARSER_DIR/Makefile" ]]; then
    echo "ERROR: Parser Makefile not found."
    exit 1
fi

if [[ ! -f "$PARSER_DIR/nvdsparsebbox_Yolo.cpp" ]]; then
    echo "ERROR: Parser C++ source file not found."
    exit 1
fi

if [[ ! -f "$PARSER_DIR/nvdsparsebbox_Yolo_cuda.cu" ]]; then
    echo "ERROR: Parser CUDA source file not found."
    exit 1
fi

for cmd in make g++ nvcc nm; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: Required build command not found: $cmd"
        exit 1
    fi
done

if [[ ! -d "$DEEPSTREAM_INCLUDE" ]]; then
    echo "ERROR: DeepStream development headers not found:"
    echo "       $DEEPSTREAM_INCLUDE"
    echo "Use a compatible NVIDIA DeepStream development container."
    exit 1
fi

echo "CUDA compiler:"
nvcc --version | tail -n 4
echo

echo "Cleaning previous build..."
make -C "$PARSER_DIR" clean

echo
echo "Building custom parser..."
make -C "$PARSER_DIR" -j"$(nproc)"

if [[ ! -f "$OUTPUT_LIB" ]]; then
    echo "ERROR: Expected shared library was not created:"
    echo "       $OUTPUT_LIB"
    exit 1
fi

echo
echo "Checking exported YOLOv11 parser symbol..."

if ! nm -D --defined-only "$OUTPUT_LIB" \
    | c++filt \
    | grep -q 'NvDsInferParseYoloV11'; then
    echo "ERROR: NvDsInferParseYoloV11 was not found in exported symbols."
    echo "Inspect the source, Makefile and build output."
    exit 1
fi

echo "[PASS] YOLOv11 parser symbol found."

echo
echo "Checking shared library details..."
file "$OUTPUT_LIB" || true
ls -lh "$OUTPUT_LIB"

echo
echo "SUCCESS: Parser library built and symbol check passed."
echo "NOTE: This does not yet prove compatibility with the target"
echo "DeepStream version or successful inference."
