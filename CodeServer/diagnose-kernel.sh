#!/bin/bash
# Run this inside the code-server container (Terminal in code-server, or docker exec).
# Diagnoses why "Select Kernel" prompts to install Python + Jupyter.

echo "=== 1. HOME and extension paths ==="
echo "HOME=$HOME"
echo "XDG_DATA_HOME=${XDG_DATA_HOME:-<not set>}"
EXT_DIR="${HOME}/.local/share/code-server/extensions"
ALT_EXT_DIR="${HOME}/.vscode-server/extensions"
echo "Checking: $EXT_DIR"
ls -la "$EXT_DIR" 2>/dev/null || echo "  (not found or not readable)"
echo "Checking: $ALT_EXT_DIR"
ls -la "$ALT_EXT_DIR" 2>/dev/null || echo "  (not found or not readable)"

echo ""
echo "=== 2. Installed extensions (by folder name) ==="
for d in "$EXT_DIR" "$ALT_EXT_DIR"; do
  [ -d "$d" ] && ls -1 "$d" 2>/dev/null | head -30
done

echo ""
echo "=== 3. Python and Jupyter ==="
echo -n "python3: "; which python3 2>/dev/null || echo "not found"
echo -n "python3 version: "; python3 --version 2>/dev/null || echo "failed"
echo -n "jupyter: "; which jupyter 2>/dev/null || echo "not in PATH"
echo -n "jupyter (via python3 -m): "; python3 -m jupyter --version 2>/dev/null || echo "failed"
echo "Jupyter kernels:"
python3 -m jupyter kernelspec list 2>/dev/null || echo "  (jupyter kernelspec list failed)"

echo ""
echo "=== 4. code-server binary and version ==="
which code-server 2>/dev/null || true
[ -x /app/code-server/bin/code-server ] && /app/code-server/bin/code-server --version 2>/dev/null || true
