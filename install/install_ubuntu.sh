#!/usr/bin/env bash
# =============================================================================
# VLSI-SoC 2026 "Agentic AI in EDA" tutorial: local install (no Docker)
# Ubuntu 22.04 / 24.04 / 26.04 (x86_64; arm64 best effort)
#
# Installs the same toolchain as the Dockerfile:
#   iverilog, Yosys (from source), OpenROAD (Bazel build), OpenROAD-flow-scripts,
#   KLayout, Ollama (+ llama3.1), Python venv with dspy / pyyaml / ollama
# and writes an environment file (OPENROAD_EXE, YOSYS_EXE, ORFS_DIR, venv, API keys).
#
# Usage (as your normal user, NOT with sudo; the script calls sudo itself):
#   bash install/install_ubuntu.sh [options]
#
# Options:
#   --prefix DIR         Install folder (default: ~/eda)
#   --jobs N             Parallel build jobs (default: nproc). Lower it if you have < 16 GB RAM
#   --openroad-bin PATH  Use an existing openroad binary, do not build OpenROAD
#   --skip-openroad      Do not build OpenROAD (the flows need it for Parts 2-4)
#   --skip-ollama        Do not install Ollama (needed only for the local-model profiles, e.g. 2c)
#   --no-model           Install Ollama but do not pull llama3.1 (~4.7 GB)
#   --no-bashrc          Do not add the environment file to ~/.bashrc
#
# Needs: ~40 GB free disk, 16 GB RAM recommended, 1-2 hours (the OpenROAD build is the long part).
# The script can be re-run: finished steps are skipped.
# =============================================================================
set -euo pipefail

# ---------- options ----------
PREFIX="$HOME/eda"
JOBS="$(nproc)"
OPENROAD_BIN=""
SKIP_OPENROAD=0
SKIP_OLLAMA=0
PULL_MODEL=1
EDIT_BASHRC=1
KLAYOUT_VERSION="0.30.12"

while [ $# -gt 0 ]; do
  case "$1" in
    --prefix)        PREFIX="$2"; shift 2 ;;
    --jobs)          JOBS="$2"; shift 2 ;;
    --openroad-bin)  OPENROAD_BIN="$(readlink -f "$2")"; shift 2 ;;
    --skip-openroad) SKIP_OPENROAD=1; shift ;;
    --skip-ollama)   SKIP_OLLAMA=1; shift ;;
    --no-model)      PULL_MODEL=0; shift ;;
    --no-bashrc)     EDIT_BASHRC=0; shift ;;
    -h|--help)       sed -n '2,25p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1 (see --help)"; exit 1 ;;
  esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFIX="$(mkdir -p "$PREFIX" && cd "$PREFIX" && pwd)"
BIN_DIR="$PREFIX/bin"
VENV="$PREFIX/venv"
ENV_FILE="$PREFIX/vlsi_soc_env.sh"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

step() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m    %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m    WARNING: %s\033[0m\n' "$*"; }

if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi
APT="$SUDO env DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::Retries=3 -y"

# ---------- OS check ----------
. /etc/os-release
UBUNTU_VER="${VERSION_ID:-unknown}"
UBUNTU_MAJOR="${UBUNTU_VER%%.*}"
case "$UBUNTU_VER" in
  22.04|24.04|26.04) ok "Ubuntu $UBUNTU_VER detected" ;;
  *) warn "Tested on Ubuntu 22.04/24.04/26.04, found '${PRETTY_NAME:-unknown}'. Continuing anyway." ;;
esac
case "$(uname -m)" in
  x86_64)  ARCH=amd64 ;;
  aarch64) ARCH=arm64; warn "arm64: KLayout comes from apt; the OpenROAD build is best effort." ;;
  *) echo "Unsupported CPU architecture: $(uname -m)"; exit 1 ;;
esac
echo "    Repository : $REPO_DIR"
echo "    Install to : $PREFIX   (build jobs: $JOBS)"

# ---------- 1. system packages ----------
step "1/8 System packages (apt)"
$APT update
$APT install wget curl ca-certificates build-essential gcc g++ gawk git make lld bison clang flex \
     libffi-dev libfl-dev libreadline-dev pkg-config tcl-dev zlib1g-dev graphviz xdot \
     python3 python3-dev python3-venv python3-pip time unzip zstd pciutils lshw iverilog
ok "iverilog $(iverilog -V 2>/dev/null | head -1 | awk '{print $4}')"

# ---------- 2. Python venv ----------
# A venv avoids the "externally-managed-environment" error of pip on Ubuntu 24.04+.
step "2/8 Python virtual environment ($VENV)"
[ -x "$VENV/bin/python" ] || python3 -m venv "$VENV"
"$VENV/bin/pip" install --upgrade pip
"$VENV/bin/pip" install dspy pyyaml ollama cmake
ok "$("$VENV/bin/python" -c 'import dspy, yaml; print("dspy", dspy.__version__)')"

# ---------- 3. Yosys ----------
step "3/8 Yosys (from source)"
YOSYS_EXE="$PREFIX/yosys-install/bin/yosys"
if [ -x "$YOSYS_EXE" ]; then
  ok "already installed: $("$YOSYS_EXE" -V)"
else
  [ -d "$PREFIX/yosys" ] || git clone https://github.com/YosysHQ/yosys.git "$PREFIX/yosys"
  cd "$PREFIX/yosys"
  git submodule update --init --recursive
  if [ -f CMakeLists.txt ]; then
    "$VENV/bin/cmake" -B build . -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX/yosys-install"
    "$VENV/bin/cmake" --build build --config Release --parallel "$JOBS"
    "$VENV/bin/cmake" --install build --strip
  else
    make -j"$JOBS" PREFIX="$PREFIX/yosys-install"
    make install PREFIX="$PREFIX/yosys-install"
  fi
  ok "$("$YOSYS_EXE" -V)"
fi

# ---------- 4. OpenROAD ----------
step "4/8 OpenROAD"
if [ -n "$OPENROAD_BIN" ]; then
  OPENROAD_EXE="$OPENROAD_BIN"
  ok "using existing binary $OPENROAD_EXE"
elif [ "$SKIP_OPENROAD" -eq 1 ]; then
  OPENROAD_EXE="$PREFIX/OpenROAD/bazel-bin/openroad"
  warn "skipped (--skip-openroad). Parts 2-4 need it: re-run without the flag later."
else
  OPENROAD_EXE="$PREFIX/OpenROAD/bazel-bin/openroad"
  if [ -x "$OPENROAD_EXE" ]; then
    ok "already built"
  else
    if ! command -v bazel >/dev/null; then
      wget -q -O "$BIN_DIR/bazel" "https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-$ARCH"
      chmod +x "$BIN_DIR/bazel"
    fi
    bazel --version
    [ -d "$PREFIX/OpenROAD" ] || git clone --recursive https://github.com/The-OpenROAD-Project/OpenROAD.git "$PREFIX/OpenROAD"
    cd "$PREFIX/OpenROAD"
    echo "    Building OpenROAD with Bazel (this takes a long time)..."
    bazel build --jobs="$JOBS" //:openroad
  fi
fi
# 'openroad' command in PATH (same wrapper as in the Docker image)
printf '#!/bin/sh\nexec "%s" "$@"\n' "$OPENROAD_EXE" > "$BIN_DIR/openroad"
chmod +x "$BIN_DIR/openroad"
[ -x "$OPENROAD_EXE" ] && ok "openroad $("$OPENROAD_EXE" -version 2>/dev/null | head -1)"

# ---------- 5. KLayout ----------
step "5/8 KLayout"
if command -v klayout >/dev/null; then
  ok "already installed: $(klayout -v 2>/dev/null)"
else
  KL_OK=0
  if [ "$ARCH" = amd64 ]; then
    TMP_DEB="$(mktemp -d)"
    # Try the .deb for this Ubuntu version, then the newest older one
    for v in "$UBUNTU_MAJOR" 24 22; do
      URL="https://www.klayout.org/downloads/Ubuntu-$v/klayout_${KLAYOUT_VERSION}-1_amd64.deb"
      if wget -q -O "$TMP_DEB/klayout.deb" "$URL" && $APT install "$TMP_DEB/klayout.deb"; then
        KL_OK=1; ok "installed from $URL"; break
      fi
    done
    rm -rf "$TMP_DEB"
  fi
  if [ "$KL_OK" -eq 0 ]; then
    warn "no matching KLayout .deb, using the Ubuntu package"
    $APT install klayout
  fi
fi

# ---------- 6. OpenROAD-flow-scripts ----------
step "6/8 OpenROAD-flow-scripts"
ORFS_DIR="$PREFIX/OpenROAD-flow-scripts"
[ -d "$ORFS_DIR/flow" ] || git clone https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git "$ORFS_DIR"
ok "$ORFS_DIR"

# ---------- 7. Ollama ----------
step "7/8 Ollama"
if [ "$SKIP_OLLAMA" -eq 1 ]; then
  warn "skipped (--skip-ollama)"
else
  command -v ollama >/dev/null || curl -fsSL https://ollama.com/install.sh | sh
  # The installer starts a systemd service. Without systemd (e.g. WSL), start the server by hand.
  if ! curl -s http://127.0.0.1:11434 >/dev/null; then
    (nohup ollama serve >/dev/null 2>&1 &) ; sleep 3
  fi
  if [ "$PULL_MODEL" -eq 1 ]; then ollama pull llama3.1 || warn "could not pull llama3.1, run: ollama pull llama3.1"; fi
  ok "$(ollama --version 2>/dev/null | tail -1)"
fi

# ---------- 8. environment file ----------
step "8/8 Environment file ($ENV_FILE)"
cat > "$ENV_FILE" <<ENVEOF
# VLSI-SoC tutorial environment (generated by install/install_ubuntu.sh)
export VLSI_SOC_REPO="$REPO_DIR"
export PATH="$BIN_DIR:$PREFIX/yosys-install/bin:\$PATH"
export OPENROAD_EXE="$OPENROAD_EXE"
export YOSYS_EXE="$YOSYS_EXE"
export ORFS_DIR="$ORFS_DIR"          # overrides design.orfs_dir of the run configs
[ -f "$VENV/bin/activate" ] && . "$VENV/bin/activate"
# API keys (scripts/api_keys.sh is git-ignored; copy it from api_keys.example.sh)
if [ -f "$REPO_DIR/scripts/api_keys.sh" ]; then eval "\$(tr -d '\r' < "$REPO_DIR/scripts/api_keys.sh")"; fi
# Start the Ollama server if it is installed and not running
if command -v ollama >/dev/null && ! curl -s http://127.0.0.1:11434 >/dev/null 2>&1; then
  (nohup ollama serve >/dev/null 2>&1 &)
fi
ENVEOF
if [ "$EDIT_BASHRC" -eq 1 ] && ! grep -qF "$ENV_FILE" "$HOME/.bashrc" 2>/dev/null; then
  printf '\n# VLSI-SoC tutorial\n[ -f "%s" ] && . "%s"\n' "$ENV_FILE" "$ENV_FILE" >> "$HOME/.bashrc"
  ok "added to ~/.bashrc"
fi
if [ ! -f "$REPO_DIR/scripts/api_keys.sh" ] && [ -f "$REPO_DIR/scripts/api_keys.example.sh" ]; then
  cp "$REPO_DIR/scripts/api_keys.example.sh" "$REPO_DIR/scripts/api_keys.sh"
  warn "created scripts/api_keys.sh from the example: put your API keys in it"
fi

# ---------- summary ----------
step "Check"
set +e
. "$ENV_FILE" >/dev/null
for t in iverilog vvp yosys openroad klayout make python3 ollama; do
  if command -v "$t" >/dev/null; then printf '    %-9s %s\n' "$t" "$(command -v "$t")"; else printf '    %-9s \033[1;31mMISSING\033[0m\n' "$t"; fi
done
cat <<DONE

Done. Open a new terminal (or run:  source $ENV_FILE), then for example:
  cd $REPO_DIR/scripts/part2/solution
  python3 asic_autonomous_flow.py --config run_configs/2a_single_agent.yaml
DONE
