#!/bin/bash
#
# checkpoint-manager.sh - Pre-Compaction Checkpointing System
# Inspired by Computer's pattern from Moltbook
#

CHECKPOINT_DIR="${HOME}/clawd/memory/checkpoints"
SESSION_LOG="${HOME}/clawd/memory/session-log.md"
MEMORY_FILE="${HOME}/clawd/MEMORY.md"
CHECKPOINT_THRESHOLD=80  # 80% token usage

# Create checkpoint directory
mkdir -p "$CHECKPOINT_DIR"

# Function to get current token usage (if available from Clawdbot)
get_token_usage() {
    # This would ideally come from Clawdbot's session status
    # For now, we'll check file sizes as a proxy
    if [ -f "${HOME}/.clawdbot/agents/main/sessions/sessions.json" ]; then
        # Check if we can extract token info
        echo "unknown"
    else
        echo "unknown"
    fi
}

# Function to create checkpoint
create_checkpoint() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local checkpoint_file="${CHECKPOINT_DIR}/checkpoint_${timestamp}.md"
    
    echo "📝 Creating checkpoint at ${timestamp}..."
    
    cat > "$checkpoint_file" << EOF
# Checkpoint - $(date '+%Y-%m-%d %H:%M:%S')

## Session Context
- **Trigger:** Token threshold or manual checkpoint
- **Status:** Active session

## Key Decisions Made
<!-- Fill this section during session -->
- 

## Lessons Learned
<!-- Capture insights before they evaporate -->
- 

## Open Questions
<!-- Things to resolve next session -->
- 

## Current Focus
<!-- What was being worked on -->
- 

## Files Modified
\`\`\`bash
$(cd ~/clawd && git status --short 2>/dev/null || ls -lt ~/clawd/memory/*.md 2>/dev/null | head -5)
\`\`\`

## Links & References
<!-- Important URLs, docs, etc -->
- 

---
*Checkpoint created automatically by checkpoint-manager.sh*
EOF

    echo "✅ Checkpoint saved: $checkpoint_file"
    
    # Also update MEMORY.md with a reference
    echo "" >> "$MEMORY_FILE"
    echo "## Checkpoint: $(date '+%Y-%m-%d %H:%M')" >> "$MEMORY_FILE"
    echo "- File: \`checkpoint_${timestamp}.md\`" >> "$MEMORY_FILE"
    echo "- Status: $(cat ~/clawd/memory/heartbeat-state.json 2>/dev/null | grep -o '"lastChecks"' > /dev/null && echo 'HEARTBEAT OK' || echo 'Session active')" >> "$MEMORY_FILE"
}

# Function to read last checkpoint
read_last_checkpoint() {
    local last_checkpoint=$(ls -t "$CHECKPOINT_DIR"/checkpoint_*.md 2>/dev/null | head -1)
    
    if [ -n "$last_checkpoint" ]; then
        echo "📖 Last checkpoint: $last_checkpoint"
        echo ""
        head -50 "$last_checkpoint"
    else
        echo "⚠️ No checkpoints found"
    fi
}

# Function to list all checkpoints
list_checkpoints() {
    echo "📋 Available checkpoints:"
    ls -lt "$CHECKPOINT_DIR"/checkpoint_*.md 2>/dev/null | head -10 | awk '{print $9, $6, $7, $8}'
}

# Main action
case "${1:-create}" in
    create)
        create_checkpoint
        ;;
    read)
        read_last_checkpoint
        ;;
    list)
        list_checkpoints
        ;;
    auto)
        # This would be called by HEARTBEAT when token threshold reached
        usage=$(get_token_usage)
        if [ "$usage" != "unknown" ] && [ "$usage" -ge "$CHECKPOINT_THRESHOLD" ]; then
            echo "⚠️ Token usage at ${usage}%. Creating checkpoint..."
            create_checkpoint
        else
            echo "Token usage: ${usage}%. No checkpoint needed (threshold: ${CHECKPOINT_THRESHOLD}%)"
        fi
        ;;
    *)
        echo "Usage: $0 {create|read|list|auto}"
        echo ""
        echo "Commands:"
        echo "  create  - Create a new checkpoint"
        echo "  read    - Read the most recent checkpoint"
        echo "  list    - List all checkpoints"
        echo "  auto    - Check token usage and create if needed"
        ;;
esac
