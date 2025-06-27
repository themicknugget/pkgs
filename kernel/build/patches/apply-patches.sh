#!/usr/bin/env bash
# Apply regenerated patches to kernel source

set -euo pipefail

# Get the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <kernel-source-dir>"
    exit 1
fi

KERNEL_DIR="$1"
echo "Applying patches to $KERNEL_DIR..."

# Check metadata to see what version these patches are for
if [ -f "$SCRIPT_DIR/metadata.json" ]; then
    echo "Reading patch metadata..."
    python3 -c "
import json
with open('$SCRIPT_DIR/metadata.json') as f:
    meta = json.load(f)
print(f\"Patches are for: {meta['patches_against']}\")
print(f\"Generated: {meta['generation_date']}\")
print(f\"Total patches: {meta['total_patches']}\")
"
fi

# Apply patches in order
for category in 01-core-boot-soc 02-peripherals 03-graphics-display 99-uncategorized; do
    if [ -d "$SCRIPT_DIR/$category" ]; then
        patch_count=$(find "$SCRIPT_DIR/$category" -name "*.patch" | wc -l)
        if [ "$patch_count" -gt 0 ]; then
            echo "Applying $category patches ($patch_count patches)..."
            for patch in "$SCRIPT_DIR/$category"/*.patch; do
                if [ -f "$patch" ]; then
                    echo "  Applying: $(basename "$patch")"
                    patch -p1 -d "$KERNEL_DIR" < "$patch"
                fi
            done
        fi
    fi
done

echo "All patches applied successfully!"
