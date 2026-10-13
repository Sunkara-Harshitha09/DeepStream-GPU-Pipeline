
#!/usr/bin/env bash
set -u

PASS=0
WARN=0
FAIL=0

pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
warn() { echo "[WARN] $1"; WARN=$((WARN + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "=========================================="
echo " DeepStream GPU Pipeline - Target Check"
echo "=========================================="
echo

echo "[1] Operating system"
if [ -r /etc/os-release ]; then
    . /etc/os-release
    echo "OS: ${PRETTY_NAME:-Unknown}"
    echo "Architecture: $(uname -m)"
    pass "Linux OS information available"
else
    warn "Cannot read /etc/os-release"
fi

echo
echo "[2] NVIDIA GPU and driver"
if command -v nvidia-smi >/dev/null 2>&1; then
    if nvidia-smi; then
        pass "Host NVIDIA GPU/driver query succeeded"
    else
        fail "nvidia-smi exists but failed"
    fi
else
    fail "nvidia-smi not found; verify NVIDIA driver and GPU access"
fi

echo
echo "[3] Docker CLI and daemon"
if ! command -v docker >/dev/null 2>&1; then
    fail "Docker CLI not installed"
elif docker info >/dev/null 2>&1; then
    pass "Docker daemon is running"
    docker version --format 'Docker server: {{.Server.Version}}' 2>/dev/null || true
else
    fail "Docker daemon unavailable or permission denied"
fi

echo
echo "[4] Docker GPU passthrough"
if command -v docker >/dev/null 2>&1 &&
   docker info >/dev/null 2>&1 &&
   command -v nvidia-smi >/dev/null 2>&1; then

    echo "Testing NVIDIA GPU access inside a CUDA container."
    echo "The first run may download the test image."

    if docker run --rm --gpus all \
        nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi; then
        pass "Docker container can access an NVIDIA GPU"
    else
        fail "Docker GPU test failed; inspect NVIDIA Container Toolkit, driver compatibility, and runtime configuration"
    fi
else
    warn "Skipped: host GPU or Docker prerequisite is missing"
fi

echo
echo "[5] DeepStream installation"
if command -v deepstream-app >/dev/null 2>&1; then
    deepstream-app --version-all 2>&1 || true
    pass "deepstream-app command found"
else
    warn "DeepStream is not installed on the host PATH; it may be provided by a compatible container"
fi

echo
echo "=========================================="
echo " RESULTS"
echo "=========================================="
echo "PASS: $PASS"
echo "WARN: $WARN"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -gt 0 ]; then
    echo "STATUS: NOT READY - resolve failed checks first."
    exit 1
elif [ "$WARN" -gt 0 ]; then
    echo "STATUS: PARTIAL - review warnings before choosing the DeepStream runtime."
    exit 2
else
    echo "STATUS: BASIC CHECKS PASSED."
    echo "DeepStream model/parser compatibility still needs validation."
fi
