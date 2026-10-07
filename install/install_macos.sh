#!/usr/bin/env bash
# =============================================================================
# VLSI-SoC 2026 "Agentic AI in EDA" tutorial: local install on macOS (best effort)
# macOS 14+ (Apple Silicon or Intel), with Homebrew (https://brew.sh)
#
# Installs with Homebrew: icarus-verilog, yosys, klayout, ollama, GNU make/time/sed/coreutils
# (OpenROAD-flow-scripts needs the GNU versions), python; then a Python venv with dspy,
# OpenROAD-flow-scripts, and tries to build OpenROAD with Bazel.
#
# OpenROAD has no official macOS support. If its build fails, everything else still works:
#   - Part 1 and the testbench / RTL / synthesis steps run natively,
#   - for the OpenROAD steps (Parts 2-4 end to end) use the Docker image or a Linux machine.
#
# Usage:  bash install/install_macos.sh [--prefix DIR] [--jobs N] [--skip-openroad]
#                                       [--openroad-bin PATH] [--no-model] [--no-zshrc]
# =============================================================================
set -euo pipefail

PREFIX="$HOME/eda"
JOBS="$(sysctl -n hw.ncpu)"
OPENROAD_BIN=""
SKIP_OPENROAD=0
PULL_MODEL=1
EDIT_RC=1
while [ $# -gt 0 ]; do
  case "$1" in
    --prefix)        PREFIX="$2"; shift 2 ;;
    --jobs)          JOBS="$2"; shift 2 ;;
    --openroad-bin)  OPENROAD_BIN="$2"; shift 2 ;;
    --skip-openroad) SKIP_OPENROAD=1; shift ;;
    --no-model)      PULL_MODEL=0; shift ;;
    --no-zshrc)      EDIT_RC=0; shift ;;
    -h|--help)       sed -n '2,17p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1 (see --help)"; exit 1 ;;
  esac
done

step() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m    %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m    WARNING: %s\033[0m\n' "$*"; }

[ "$(uname)" = Darwin ] || { echo "This script is for macOS. On Ubuntu use install/install_ubuntu.sh"; exit 1; }
command -v brew >/dev/null || { echo "Homebrew is required: https://brew.sh"; exit 1; }
xcode-select -p >/dev/null 2>&1 || { echo "Install the Xcode command line tools first: xcode-select --install"; exit 1; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$PREFIX/bin"; PREFIX="$(cd "$PREFIX" && pwd)"
BIN_DIR="$PREFIX/bin"; VENV="$PREFIX/venv"; ENV_FILE="$PREFIX/vlsi_soc_env.sh"
BREW="$(brew --prefix)"
export PATH="$BIN_DIR:$PATH"
echo "    Repository : $REPO_DIR"
echo "    Install to : $PREFIX"

# ---------- 1. Homebrew packages ----------
step "1/6 Homebrew packages"
brew install python@3.12 icarus-verilog yosys bazelisk make gnu-time gnu-sed coreutils gawk git wget ollama
brew install --cask klayout || warn "KLayout cask failed (only needed for the final GDS merge)"
GNU_PATH="$BREW/opt/make/libexec/gnubin:$BREW/opt/gnu-time/libexec/gnubin:$BREW/opt/gnu-sed/libexec/gnubin:$BREW/opt/coreutils/libexec/gnubin"
KLAYOUT_APP_BIN="/Applications/klayout.app/Contents/MacOS"
# 'klayout' command in PATH
[ -x "$KLAYOUT_APP_BIN/klayout" ] && ln -sf "$KLAYOUT_APP_BIN/klayout" "$BIN_DIR/klayout"
ok "iverilog, yosys $(yosys -V | awk '{print $2}'), GNU make $("$BREW/opt/make/libexec/gnubin/make" --version | head -1 | awk '{print $3}')"

# ---------- 2. Python venv ----------
step "2/6 Python virtual environment ($VENV)"
[ -x "$VENV/bin/python" ] || "$BREW/bin/python3.12" -m venv "$VENV"
"$VENV/bin/pip" install --upgrade pip
"$VENV/bin/pip" install dspy pyyaml ollama
ok "$("$VENV/bin/python" -c 'import dspy; print("dspy", dspy.__version__)')"

# ---------- 3. OpenROAD-flow-scripts ----------
step "3/6 OpenROAD-flow-scripts"
ORFS_DIR="$PREFIX/OpenROAD-flow-scripts"
[ -d "$ORFS_DIR/flow" ] || git clone https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git "$ORFS_DIR"
ok "$ORFS_DIR"

# ---------- 4. OpenROAD (best effort) ----------
step "4/6 OpenROAD"
OPENROAD_EXE="$PREFIX/OpenROAD/bazel-bin/openroad"
if [ -n "$OPENROAD_BIN" ]; then
  OPENROAD_EXE="$OPENROAD_BIN"; ok "using existing binary $OPENROAD_EXE"
elif [ "$SKIP_OPENROAD" -eq 1 ]; then
  warn "skipped (--skip-openroad)"
elif [ -x "$OPENROAD_EXE" ]; then
  ok "already built"
else
  [ -d "$PREFIX/OpenROAD" ] || git clone --recursive https://github.com/The-OpenROAD-Project/OpenROAD.git "$PREFIX/OpenROAD"
  echo "    Building OpenROAD with Bazel (long; not officially supported on macOS)..."
  if (cd "$PREFIX/OpenROAD" && bazel build --jobs="$JOBS" //:openroad); then
    ok "built"
  else
    warn "the OpenROAD build failed. Use Docker for the OpenROAD steps (see the main README)."
  fi
fi
if [ -x "$OPENROAD_EXE" ]; then
  printf '#!/bin/sh\nexec "%s" "$@"\n' "$OPENROAD_EXE" > "$BIN_DIR/openroad"; chmod +x "$BIN_DIR/openroad"
fi

# ---------- 5. Ollama ----------
step "5/6 Ollama"
brew services start ollama >/dev/null 2>&1 || (nohup ollama serve >/dev/null 2>&1 &)
sleep 3
if [ "$PULL_MODEL" -eq 1 ]; then ollama pull llama3.1 || warn "could not pull llama3.1, run: ollama pull llama3.1"; fi

# ---------- 6. environment file ----------
step "6/6 Environment file ($ENV_FILE)"
cat > "$ENV_FILE" <<ENVEOF
# VLSI-SoC tutorial environment (generated by install/install_macos.sh)
export VLSI_SOC_REPO="$REPO_DIR"
# GNU make/time/sed/coreutils first: OpenROAD-flow-scripts needs them
export PATH="$BIN_DIR:$GNU_PATH:\$PATH"
export OPENROAD_EXE="$OPENROAD_EXE"
export YOSYS_EXE="$BREW/bin/yosys"
export ORFS_DIR="$ORFS_DIR"          # overrides design.orfs_dir of the run configs
[ -f "$VENV/bin/activate" ] && . "$VENV/bin/activate"
if [ -f "$REPO_DIR/scripts/api_keys.sh" ]; then eval "\$(tr -d '\r' < "$REPO_DIR/scripts/api_keys.sh")"; fi
ENVEOF
if [ "$EDIT_RC" -eq 1 ]; then
  for rc in "$HOME/.zshrc" "$HOME/.bash_profile"; do
    grep -qF "$ENV_FILE" "$rc" 2>/dev/null || printf '\n# VLSI-SoC tutorial\n[ -f "%s" ] && . "%s"\n' "$ENV_FILE" "$ENV_FILE" >> "$rc"
  done
  ok "added to ~/.zshrc and ~/.bash_profile"
fi
if [ ! -f "$REPO_DIR/scripts/api_keys.sh" ] && [ -f "$REPO_DIR/scripts/api_keys.example.sh" ]; then
  cp "$REPO_DIR/scripts/api_keys.example.sh" "$REPO_DIR/scripts/api_keys.sh"
  warn "created scripts/api_keys.sh from the example: put your API keys in it"
fi

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
