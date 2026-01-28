#!/usr/bin/env bash
#
# Claude Dev Skills Bootstrap Script
#
# Installs claude-dev-skills to ~/.claude/skills/
# Usage: ./bootstrap.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation directories
CLAUDE_DIR="$HOME/.claude"
SKILLS_BASE_DIR="$CLAUDE_DIR/skills"
COMMON_DIR="$SKILLS_BASE_DIR/claude-dev-skills-common"
CONFIG_FILE="$CLAUDE_DIR/config.json"

# Script directory (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Helper functions
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_warning "$1 is not installed"
        return 1
    fi
}

# Start bootstrap
clear
print_header "Claude Dev Skills Bootstrap"

echo -e "Installing to: ${BLUE}$SKILLS_BASE_DIR${NC}"
echo -e "Config file: ${BLUE}$CONFIG_FILE${NC}"
echo ""

# Step 1: Check prerequisites
print_header "Step 1: Checking Prerequisites"

ALL_REQUIRED_INSTALLED=true

# Required
if ! check_command "claude"; then
    print_error "Claude Code CLI is required"
    echo "  Install: https://claude.com/claude-code"
    ALL_REQUIRED_INSTALLED=false
fi

if ! check_command "git"; then
    print_error "Git is required"
    echo "  Install: https://git-scm.com/"
    ALL_REQUIRED_INSTALLED=false
fi

# Check Claude Code version (requires 2.1.17+ for task lists)
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")
    if [[ "$CLAUDE_VERSION" != "unknown" ]]; then
        REQUIRED_VERSION="2.1.17"
        if printf '%s\n%s\n' "$REQUIRED_VERSION" "$CLAUDE_VERSION" | sort -V -C; then
            print_success "Claude Code version $CLAUDE_VERSION meets minimum requirement ($REQUIRED_VERSION)"
        else
            print_warning "Claude Code version $CLAUDE_VERSION is below recommended minimum ($REQUIRED_VERSION)"
            echo "  Some features may not work. Consider updating."
        fi
    fi
fi

# Optional
echo -e "\n${BLUE}Optional dependencies:${NC}"
check_command "python3" || print_info "Python 3 is needed for tdd-to-jira-tickets skill"
check_command "gh" || print_info "GitHub CLI is needed for create-pr skill"

# Check for Superpowers
if [[ -d "$HOME/.claude/plugins/marketplaces/superpowers-marketplace" ]]; then
    print_success "Superpowers skills are installed"
else
    print_warning "Superpowers skills not found"
    echo "  These skills require Superpowers for code review functionality"
    echo "  Install from Claude Code marketplace or:"
    echo "  git clone https://github.com/obra/superpowers.git ~/.claude/skills/superpowers"
fi

if [[ "$ALL_REQUIRED_INSTALLED" == "false" ]]; then
    echo ""
    print_error "Missing required dependencies. Please install them and try again."
    exit 1
fi

# Step 2: Install skills
print_header "Step 2: Installing Skills"

# Create base directories
mkdir -p "$SKILLS_BASE_DIR"
mkdir -p "$COMMON_DIR"

# List of skills to install
SKILLS=("bugfix-v2" "implement-v2" "create-pr" "tdd-to-jira-tickets")

# Install each skill
for SKILL in "${SKILLS[@]}"; do
    SKILL_SRC="$SCRIPT_DIR/skills/$SKILL"
    SKILL_DEST="$SKILLS_BASE_DIR/$SKILL"

    if [[ ! -d "$SKILL_SRC" ]]; then
        print_error "Skill source not found: $SKILL_SRC"
        continue
    fi

    if [[ -d "$SKILL_DEST" ]]; then
        print_warning "Skill already installed: $SKILL"
        read -p "  Overwrite? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$SKILL_DEST"
            cp -r "$SKILL_SRC" "$SKILL_DEST"
            print_success "Updated: $SKILL"
        else
            print_info "Skipped: $SKILL"
        fi
    else
        cp -r "$SKILL_SRC" "$SKILL_DEST"
        print_success "Installed: $SKILL"
    fi
done

# Install common files
print_info "Installing common files..."
COMMON_SRC="$SCRIPT_DIR/skills/claude-dev-skills-common"

if [[ ! -d "$COMMON_SRC" ]]; then
    print_error "Common files source not found: $COMMON_SRC"
    exit 1
fi

if [[ -d "$COMMON_DIR" ]] && [[ "$(ls -A $COMMON_DIR 2>/dev/null)" ]]; then
    print_warning "Common files already installed"
    read -p "  Overwrite? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$COMMON_DIR"
        cp -r "$COMMON_SRC" "$COMMON_DIR"
        print_success "Updated: claude-dev-skills-common"
    else
        print_info "Skipped: claude-dev-skills-common"
    fi
else
    cp -r "$COMMON_SRC" "$COMMON_DIR"
    print_success "Installed: claude-dev-skills-common"
fi

# Step 3: Configuration
print_header "Step 3: Configuration Setup"

# Try installed location first, fall back to source
if [[ -f "$COMMON_DIR/config.example.json" ]]; then
    EXAMPLE_CONFIG="$COMMON_DIR/config.example.json"
elif [[ -f "$COMMON_SRC/config.example.json" ]]; then
    EXAMPLE_CONFIG="$COMMON_SRC/config.example.json"
else
    print_error "Example config not found in $COMMON_DIR or $COMMON_SRC"
    exit 1
fi

if [[ -f "$CONFIG_FILE" ]]; then
    print_warning "Config file already exists: $CONFIG_FILE"
    read -p "  Overwrite with example config? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp "$EXAMPLE_CONFIG" "$CONFIG_FILE"
        print_success "Config file replaced"
    else
        print_info "Keeping existing config"
    fi
else
    cp "$EXAMPLE_CONFIG" "$CONFIG_FILE"
    print_success "Config file created: $CONFIG_FILE"
fi


# Step 4: Environment setup
print_header "Step 4: Environment Setup"

# Check if CLAUDE_CODE_ENABLE_TASKS is set
if grep -q "CLAUDE_CODE_ENABLE_TASKS=true" "$HOME/.bashrc" 2>/dev/null || \
   grep -q "CLAUDE_CODE_ENABLE_TASKS=true" "$HOME/.zshrc" 2>/dev/null || \
   [[ "${CLAUDE_CODE_ENABLE_TASKS:-}" == "true" ]]; then
    print_success "Task list support is enabled"
else
    print_warning "Task list support is not enabled"
    echo ""
    echo "To enable task lists (required for multi-phase workflows), add to your shell profile:"
    echo ""
    echo -e "  ${BLUE}export CLAUDE_CODE_ENABLE_TASKS=true${NC}"
    echo ""
    read -p "Add to your shell profile now? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Detect shell
        if [[ -n "${BASH_VERSION:-}" ]]; then
            SHELL_RC="$HOME/.bashrc"
        elif [[ -n "${ZSH_VERSION:-}" ]]; then
            SHELL_RC="$HOME/.zshrc"
        else
            SHELL_RC="$HOME/.profile"
        fi

        echo "" >> "$SHELL_RC"
        echo "# Claude Code task list support" >> "$SHELL_RC"
        echo "export CLAUDE_CODE_ENABLE_TASKS=true" >> "$SHELL_RC"
        print_success "Added to $SHELL_RC"
        print_info "Run: source $SHELL_RC"
    fi
fi

# Step 5: Python dependencies (optional)
print_header "Step 5: Python Dependencies (Optional)"

if command -v python3 &> /dev/null; then
    REQUIREMENTS_FILE="$SKILLS_BASE_DIR/tdd-to-jira-tickets/requirements.txt"

    if [[ -f "$REQUIREMENTS_FILE" ]]; then
        print_info "Python dependencies are needed for tdd-to-jira-tickets skill"
        read -p "Install Python dependencies now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            pip3 install -r "$REQUIREMENTS_FILE"
            print_success "Python dependencies installed"
        else
            print_info "Skipped. Install later with: pip3 install -r $REQUIREMENTS_FILE"
        fi
    fi
else
    print_info "Python 3 not found - skipping Python dependency installation"
fi

# Step 6: Validation
print_header "Step 6: Validation"

# Check if validation script exists
VALIDATE_SCRIPT="$COMMON_DIR/validate-config.py"
if [[ -f "$VALIDATE_SCRIPT" ]] && command -v python3 &> /dev/null; then
    print_info "Validating configuration..."
    if python3 "$VALIDATE_SCRIPT" "$CONFIG_FILE"; then
        print_success "Configuration is valid"
    else
        print_warning "Configuration validation failed"
        echo "  Edit $CONFIG_FILE and fix the errors"
    fi
else
    print_info "Validation script not found or Python not available"
fi

# Step 7: Summary
print_header "Installation Complete!"

echo -e "${GREEN}✓${NC} Claude Dev Skills are ready to use\n"

echo -e "${BLUE}Installed Skills:${NC}"
echo "  • /implement-v2        → $SKILLS_BASE_DIR/implement-v2"
echo "  • /bugfix-v2           → $SKILLS_BASE_DIR/bugfix-v2"
echo "  • /create-pr           → $SKILLS_BASE_DIR/create-pr"
echo "  • /tdd-to-jira-tickets → $SKILLS_BASE_DIR/tdd-to-jira-tickets"
echo ""
echo -e "${BLUE}Common Files:${NC}"
echo "  • Configuration        → $CONFIG_FILE"
echo "  • Workflow definitions → $COMMON_DIR/workflow-definitions"
echo "  • Validation script    → $COMMON_DIR/validate-config.py"
echo ""

echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Edit configuration: $CONFIG_FILE"
echo "     - Set your project-specific commit scopes"
echo "     - Configure Jira custom field IDs (if using Jira integration)"
echo "     - Update Confluence spaces (if using Confluence)"
echo ""
echo "  2. Set up environment variables (if using tdd-to-jira-tickets):"
echo "     - Add to ~/.bashrc or ~/.zshrc:"
echo "       export JIRA_BASE_URL=https://yourcompany.atlassian.net"
echo "       export JIRA_EMAIL=your.email@company.com"
echo "       export JIRA_TOKEN=your_api_token"
echo ""
echo "  3. Validate configuration:"
echo "     python3 $VALIDATE_SCRIPT $CONFIG_FILE"
echo ""
echo "  4. Try it out:"
echo "     claude"
echo "     > /implement-v2 TICKET-123"
echo ""

if [[ -n "${SHELL_RC:-}" ]] && [[ "${REPLY:-}" =~ ^[Yy]$ ]]; then
    print_warning "Don't forget to reload your shell:"
    echo "  source $SHELL_RC"
fi

echo ""
print_success "Happy coding! 🚀"
