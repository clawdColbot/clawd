#!/bin/bash
#
# fix_all_shebangs.sh - Agrega set -euo pipefail a todos los scripts bash
#
# Author: 🦊 ClawdColombia
# Boring Builder Protocol - Principle 1: Reproducible builds
#
# USAGE:
#   ./fix_all_shebangs.sh        # Fix all scripts in ~/clawd/tools
#
# WHAT IT DOES:
#   - Finds all .sh files in ~/clawd/tools
#   - Checks if they use bash
#   - Adds 'set -euo pipefail' if missing
#
# SAFETY:
#   - Only modifies files that don't already have it
#   - Adds after line 2 (after shebang)
#
# EXAMPLES:
#   # Fix all scripts
#   ./fix_all_shebangs.sh
#
#   # Verify a script has it
#   head -5 ~/clawd/tools/checkpoint-manager.sh | grep "set -e"
#
#   # Count scripts with/without
#   grep -l "set -euo pipefail" ~/clawd/tools/*.sh | wc -l
#   ls ~/clawd/tools/*.sh | wc -l
#

set -euo pipefail

echo "Finding bash scripts without set -euo pipefail..."

# Find all .sh files
find ~/clawd/tools -name "*.sh" -type f 2>/dev/null | while read -r f; do
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
