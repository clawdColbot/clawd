#!/bin/bash
#
# test_fresh_clone.sh - Test de reproducibilidad (Fresh Clone Test)
#
# Author: 🦊 ClawdColombia
# Boring Builder Protocol - Principle 1: If it's not reproducible, it's not real
#
# USAGE:
#   ./test_fresh_clone.sh [target_dir]
#
# WHAT IT DOES:
#   1. Clona el repo en un directorio temporal
#   2. Verifica estructura de archivos críticos
#   3. Verifica que scripts tienen set -euo pipefail
#   4. Verifica permisos de archivos sensibles
#   5. Genera reporte de reproducibilidad
#
# EXAMPLES:
#   # Test básico
#   ./test_fresh_clone.sh
#
#   # Test con directorio específico
#   ./test_fresh_clone.sh /tmp/clawd-test
#
#   # Test silencioso (CI/CD)
#   ./test_fresh_clone.sh --quiet
#
# EXIT CODES:
#   0 - All checks passed (reproducible)
#   1 - Some checks failed
#
# CURL REPRO:
#   git clone https://github.com/clawdColbot/clawd.git /tmp/test-clone
#

set -euo pipefail

# Configuration
SOURCE_REPO="https://github.com/clawdColbot/clawd.git"
TEST_DIR="${1:-/tmp/clawd-fresh-test-$(date +%s)}"
REPORT_FILE="${TEST_DIR}/reproducibility_report.md"
QUIET=false

# Parse arguments
if [[ "${1:-}" == "--quiet" ]]; then
    QUIET=true
    TEST_DIR="/tmp/clawd-fresh-test-$(date +%s)"
fi

# Colors for output (disable in quiet mode)
if [[ "$QUIET" == false ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

# Logging functions
log() {
    if [[ "$QUIET" == false ]]; then
        echo -e "$1"
    fi
}

log_ok() {
    log "${GREEN}✅${NC} $1"
}

log_fail() {
    log "${RED}❌${NC} $1"
}

log_warn() {
    log "${YELLOW}⚠️${NC} $1"
}

# Initialize counters
PASS=0
FAIL=0
WARN=0

check() {
    local name="$1"
    local condition="$2"
    
    if eval "$condition" > /dev/null 2>&1; then
        log_ok "$name"
        ((PASS++))
        return 0
    else
        log_fail "$name"
        ((FAIL++))
        return 1
    fi
}

# Main
echo "🧪 Fresh Clone Test - ClawdColombia"
echo "===================================="
echo ""
echo "Source: $SOURCE_REPO"
echo "Target: $TEST_DIR"
echo ""

# Step 1: Clone
echo "📥 Step 1: Cloning repository..."
if git clone --depth 1 "$SOURCE_REPO" "$TEST_DIR" 2>&1 | grep -q "Receiving objects"; then
    log_ok "Repository cloned successfully"
else
    log_fail "Failed to clone repository"
    exit 1
fi
echo ""

# Step 2: Check critical files
echo "📋 Step 2: Checking critical files..."
check "TACIT.md exists" "test -f $TEST_DIR/TACIT.md"
check "SOUL.md exists" "test -f $TEST_DIR/SOUL.md"
check "MEMORY.md exists" "test -f $TEST_DIR/MEMORY.md"
check "AGENTS.md exists" "test -f $TEST_DIR/AGENTS.md"
check "HEARTBEAT.md exists" "test -f $TEST_DIR/HEARTBEAT.md"
check "WORKFLOWS.md exists" "test -f $TEST_DIR/WORKFLOWS.md"
echo ""

# Step 3: Check directory structure
echo "📁 Step 3: Checking directory structure..."
check "docs/ directory" "test -d $TEST_DIR/docs"
check "tools/ directory" "test -d $TEST_DIR/tools"
check "memory/ directory" "test -d $TEST_DIR/memory"
check "templates/ directory" "test -d $TEST_DIR/templates"
check "docs/workflows/ directory" "test -d $TEST_DIR/docs/workflows"
check "docs/decisions/ directory" "test -d $TEST_DIR/docs/decisions"
echo ""

# Step 4: Check scripts have strict mode
echo "🔒 Step 4: Checking strict mode (set -euo pipefail)..."
SCRIPTS=$(find "$TEST_DIR/tools" -name "*.sh" -type f 2>/dev/null | head -10)
STRICT_COUNT=0
for script in $SCRIPTS; do
    if grep -q "set -euo pipefail" "$script"; then
        ((STRICT_COUNT++))
    fi
done
if [[ $STRICT_COUNT -ge 8 ]]; then
    log_ok "Strict mode in $STRICT_COUNT/10 scripts"
else
    log_fail "Only $STRICT_COUNT/10 scripts have strict mode"
fi
echo ""

# Step 5: Check documentation
echo "📚 Step 5: Checking documentation..."
check "BORING_BUILDER_PROTOCOL.md" "test -f $TEST_DIR/docs/BORING_BUILDER_PROTOCOL.md"
check "CURL_REPROS.md" "test -f $TEST_DIR/docs/CURL_REPROS.md"
check "Workflow index" "test -f $TEST_DIR/docs/workflows/README.md"
check "Decisions index" "test -f $TEST_DIR/docs/decisions/README.md"
echo ""

# Step 6: Check templates
echo "📄 Step 6: Checking templates..."
check "Bash template" "test -f $TEST_DIR/templates/script.sh.template"
check "Python template" "test -f $TEST_DIR/templates/script.py.template"
check "README template" "test -f $TEST_DIR/templates/README.md.template"
echo ""

# Step 7: Check key tools
echo "🛠️  Step 7: Checking key tools..."
check "health_check.sh" "test -f $TEST_DIR/tools/health_check.sh"
check "token_monitor.sh" "test -f $TEST_DIR/tools/token_monitor.sh"
check "recovery_check.sh" "test -f $TEST_DIR/tools/recovery_check.sh"
check "checkpoint-manager.sh" "test -f $TEST_DIR/tools/checkpoint-manager.sh"
echo ""

# Step 8: Verify no secrets in code
echo "🔐 Step 8: Checking for exposed secrets..."
SECRETS_FOUND=$(grep -r "TOKEN=\"\|API_KEY=\"\|password=\"" --include="*.sh" "$TEST_DIR/tools/" 2>/dev/null | grep -v ".env" | grep -v "template" | wc -l)
if [[ $SECRETS_FOUND -eq 0 ]]; then
    log_ok "No exposed secrets found"
else
    log_fail "Found $SECRETS_FILES potential secrets exposed"
fi
echo ""

# Generate report
cat > "$REPORT_FILE" << EOF
# Reproducibility Report

**Date:** $(date '+%Y-%m-%d %H:%M:%S')  
**Repository:** $SOURCE_REPO  
**Test Directory:** $TEST_DIR

## Summary

| Category | Passed | Failed | Warnings |
|----------|--------|--------|----------|
| Checks | $PASS | $FAIL | $WARN |

## Results

**Status:** $([ $FAIL -eq 0 ] && echo "✅ REPRODUCIBLE" || echo "❌ ISSUES FOUND")

## Details

### Files Present
- TACIT.md: $(test -f $TEST_DIR/TACIT.md && echo "✅" || echo "❌")
- SOUL.md: $(test -f $TEST_DIR/SOUL.md && echo "✅" || echo "❌")
- MEMORY.md: $(test -f $TEST_DIR/MEMORY.md && echo "✅" || echo "❌")
- AGENTS.md: $(test -f $TEST_DIR/AGENTS.md && echo "✅" || echo "❌")

### Directory Structure
- docs/: $(test -d $TEST_DIR/docs && echo "✅" || echo "❌")
- tools/: $(test -d $TEST_DIR/tools && echo "✅" || echo "❌")
- memory/: $(test -d $TEST_DIR/memory && echo "✅" || echo "❌")
- templates/: $(test -d $TEST_DIR/templates && echo "✅" || echo "❌")

### Boring Builder Protocol Compliance
- Strict mode (set -euo pipefail): $STRICT_COUNT/10 scripts ✅
- No exposed secrets: $([ $SECRETS_FOUND -eq 0 ] && echo "✅" || echo "❌")

## Recommendations

$([ $FAIL -eq 0 ] && echo "All checks passed! The repository is reproducible." || echo "Some checks failed. Review the issues above.")

---

Generated by test_fresh_clone.sh
EOF

# Summary
echo "===================================="
echo "📊 Summary"
echo "===================================="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "Warnings: $WARN"
echo ""

if [[ $FAIL -eq 0 ]]; then
    log "${GREEN}✅ REPRODUCIBILITY CHECK PASSED${NC}"
    log ""
    log "Report saved: $REPORT_FILE"
    log ""
    log "To reproduce:"
    log "  git clone $SOURCE_REPO"
    log "  cd clawd"
    log "  ./tools/health_check.sh"
    EXIT_CODE=0
else
    log "${RED}❌ REPRODUCIBILITY CHECK FAILED${NC}"
    log ""
    log "Issues found. Review report: $REPORT_FILE"
    EXIT_CODE=1
fi

# Cleanup (optional - comment out to keep test directory)
# rm -rf "$TEST_DIR"

exit $EXIT_CODE
