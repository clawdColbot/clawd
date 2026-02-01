#!/bin/bash
# fix_all_shebangs.sh - Simple version

echo "Finding bash scripts without set -euo pipefail..."

cd ~/clawd

# Find all .sh files
find tools -name "*.sh" -type f 2>/dev/null | while read -r f; do
    # Check if it's a bash script
    if head -1 "$f" 2>/dev/null | grep -q "bash"; then
        # Check if it already has set -euo pipefail
        if ! grep -q "set -euo pipefail" "$f" 2>/dev/null; then
            echo "Fixing: $f"
            # Add after line 2 (after shebang)
            sed -i '2a set -euo pipefail' "$f"
        fi
    fi
done

echo "Done!"
