#!/bin/bash
# Setup script for tdd-to-jira-tickets skill
# Usage: ./setup.sh

set -e  # Exit on error

echo "=========================================="
echo "TDD to Jira Tickets - Setup Script"
echo "=========================================="
echo ""

# Check Python version
echo "Checking Python version..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed"
    echo "Please install Python 3.8 or higher"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo "✓ Found Python $PYTHON_VERSION"
echo ""

# Check pip
echo "Checking pip..."
if ! command -v pip3 &> /dev/null; then
    echo "❌ Error: pip3 is not installed"
    echo "Please install pip3"
    exit 1
fi
echo "✓ Found pip3"
echo ""

# Install dependencies
echo "Installing Python dependencies..."
pip3 install -r requirements.txt
echo "✓ Dependencies installed"
echo ""

# Check for environment variables
echo "Checking Jira credentials..."
if [ -z "$JIRA_EMAIL" ]; then
    echo "⚠️  JIRA_EMAIL environment variable is not set"
    echo ""
    read -p "Enter your Jira email: " email
    export JIRA_EMAIL="$email"
    echo "export JIRA_EMAIL=\"$email\"" >> ~/.bash_profile
    echo "✓ JIRA_EMAIL set and added to ~/.bash_profile"
else
    echo "✓ JIRA_EMAIL is set: $JIRA_EMAIL"
fi
echo ""

if [ -z "$JIRA_TOKEN" ]; then
    echo "⚠️  JIRA_TOKEN environment variable is not set"
    echo ""
    echo "To get a Jira API token:"
    echo "1. Go to https://id.atlassian.com/manage-profile/security/api-tokens"
    echo "2. Click 'Create API token'"
    echo "3. Copy the token"
    echo ""
    read -sp "Enter your Jira API token: " token
    echo ""
    export JIRA_TOKEN="$token"
    echo "export JIRA_TOKEN=\"$token\"" >> ~/.bash_profile
    echo "✓ JIRA_TOKEN set and added to ~/.bash_profile"
else
    echo "✓ JIRA_TOKEN is set"
fi
echo ""

# Make script executable
chmod +x create_jira_tickets_and_links.py

echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "You can now use the skill:"
echo "  python3 create_jira_tickets_and_links.py <csv_file>"
echo ""
echo "Or through Claude Code:"
echo "  /tdd-to-jira-tickets <csv_file>"
echo ""
echo "Note: You may need to restart your terminal or run:"
echo "  source ~/.bash_profile"
echo "for the environment variables to take effect."
