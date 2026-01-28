#!/usr/bin/env python3
"""
Configuration validator for Claude Dev Skills.

Usage:
    python validate-config.py [config_file]

If no config file is specified, validates .claude/config.json
"""

import json
import sys
from pathlib import Path
from typing import Dict, List, Tuple


def load_schema(schema_path: Path) -> Dict:
    """Load JSON schema."""
    with open(schema_path, 'r') as f:
        return json.load(f)


def load_config(config_path: Path) -> Dict:
    """Load configuration file."""
    with open(config_path, 'r') as f:
        return json.load(f)


def validate_required_fields(config: Dict) -> List[str]:
    """Validate required fields."""
    errors = []

    if 'claude-dev-skills' not in config:
        errors.append("Missing required field: 'claude-dev-skills' (namespaced config)")
        return errors

    skill_config = config['claude-dev-skills']

    if 'version' not in skill_config:
        errors.append("Missing required field: 'claude-dev-skills.version'")
    elif not isinstance(skill_config['version'], str):
        errors.append("'claude-dev-skills.version' must be a string")

    return errors


def validate_jira_config(config: Dict) -> List[str]:
    """Validate Jira configuration."""
    errors = []

    if 'claude-dev-skills' not in config:
        return errors

    skill_config = config['claude-dev-skills']

    if 'jira' not in skill_config:
        return errors

    jira = skill_config['jira']

    # Validate customFields
    if 'customFields' in jira:
        custom_fields = jira['customFields']
        if 'storyPoints' in custom_fields:
            sp = custom_fields['storyPoints']
            if not isinstance(sp, str):
                errors.append("jira.customFields.storyPoints must be a string")
            elif not sp.startswith('customfield_'):
                errors.append("jira.customFields.storyPoints must start with 'customfield_'")

    # Validate defaultProjectKey
    if 'defaultProjectKey' in jira:
        key = jira['defaultProjectKey']
        if not isinstance(key, str):
            errors.append("jira.defaultProjectKey must be a string")
        elif not key.isupper():
            errors.append("jira.defaultProjectKey must be uppercase")
        elif len(key) < 2 or len(key) > 10:
            errors.append("jira.defaultProjectKey must be 2-10 characters")

    return errors


def validate_confluence_config(config: Dict) -> List[str]:
    """Validate Confluence configuration."""
    errors = []

    if 'claude-dev-skills' not in config:
        return errors

    skill_config = config['claude-dev-skills']

    if 'confluence' not in skill_config:
        return errors

    confluence = skill_config['confluence']

    if 'spaces' in confluence:
        spaces = confluence['spaces']
        if not isinstance(spaces, list):
            errors.append("confluence.spaces must be an array")
        elif len(spaces) == 0:
            errors.append("confluence.spaces must have at least one space")
        elif not all(isinstance(s, str) for s in spaces):
            errors.append("confluence.spaces must contain only strings")

    return errors


def validate_commit_config(config: Dict) -> List[str]:
    """Validate commit configuration."""
    errors = []

    if 'claude-dev-skills' not in config:
        return errors

    skill_config = config['claude-dev-skills']

    if 'commit' not in skill_config:
        return errors

    commit = skill_config['commit']

    # Validate scopes
    if 'scopes' in commit:
        scopes = commit['scopes']
        if not isinstance(scopes, list):
            errors.append("commit.scopes must be an array")
        elif len(scopes) == 0:
            errors.append("commit.scopes must have at least one scope")
        elif not all(isinstance(s, str) for s in scopes):
            errors.append("commit.scopes must contain only strings")

    # Validate types
    if 'types' in commit:
        types = commit['types']
        valid_types = ['feat', 'fix', 'docs', 'style', 'refactor', 'perf',
                       'test', 'build', 'ci', 'chore', 'revert']
        if not isinstance(types, list):
            errors.append("commit.types must be an array")
        elif len(types) == 0:
            errors.append("commit.types must have at least one type")
        else:
            for t in types:
                if not isinstance(t, str):
                    errors.append("commit.types must contain only strings")
                elif t not in valid_types:
                    errors.append(f"Invalid commit type: '{t}'. Valid types: {', '.join(valid_types)}")

    # Validate titleMaxLength
    if 'titleMaxLength' in commit:
        max_len = commit['titleMaxLength']
        if not isinstance(max_len, (int, float)):
            errors.append("commit.titleMaxLength must be a number")
        elif max_len < 20 or max_len > 100:
            errors.append("commit.titleMaxLength must be between 20 and 100")

    # Validate bodyMaxLength
    if 'bodyMaxLength' in commit:
        max_len = commit['bodyMaxLength']
        if not isinstance(max_len, (int, float)):
            errors.append("commit.bodyMaxLength must be a number")
        elif max_len < 50 or max_len > 120:
            errors.append("commit.bodyMaxLength must be between 50 and 120")

    return errors


def validate_quality_config(config: Dict) -> List[str]:
    """Validate quality configuration."""
    errors = []

    if 'claude-dev-skills' not in config:
        return errors

    skill_config = config['claude-dev-skills']

    if 'quality' not in skill_config:
        return errors

    quality = skill_config['quality']

    if 'testCoverage' in quality:
        coverage = quality['testCoverage']

        if 'minimum' in coverage:
            minimum = coverage['minimum']
            if not isinstance(minimum, (int, float)):
                errors.append("quality.testCoverage.minimum must be a number")
            elif minimum < 0 or minimum > 100:
                errors.append("quality.testCoverage.minimum must be between 0 and 100")

        if 'unit' in coverage:
            unit = coverage['unit']
            if unit != 'percent':
                errors.append("quality.testCoverage.unit must be 'percent'")

    return errors


def validate_config(config: Dict) -> Tuple[List[str], List[str]]:
    """
    Validate configuration.

    Returns:
        Tuple of (errors, warnings)
    """
    errors = []
    warnings = []

    # Required fields
    errors.extend(validate_required_fields(config))

    # Jira configuration
    errors.extend(validate_jira_config(config))

    # Confluence configuration
    errors.extend(validate_confluence_config(config))

    # Commit configuration
    errors.extend(validate_commit_config(config))

    # Quality configuration
    errors.extend(validate_quality_config(config))

    # Warnings for missing optional sections
    if 'claude-dev-skills' in config:
        skill_config = config['claude-dev-skills']
        if 'jira' not in skill_config:
            warnings.append("No Jira configuration found (required for tdd-to-jira-tickets skill)")

        if 'confluence' not in skill_config:
            warnings.append("No Confluence configuration found (used in discovery phases)")

        if 'commit' not in skill_config:
            warnings.append("No commit configuration found (scopes will not be validated)")

        if 'quality' not in skill_config:
            warnings.append("No quality configuration found (test coverage thresholds not set)")

    return errors, warnings


def main():
    """Main validation function."""
    # Determine config file path
    if len(sys.argv) > 1:
        config_path = Path(sys.argv[1])
    else:
        config_path = Path('.claude/config.json')

    print(f"Validating configuration: {config_path}")
    print("=" * 60)

    # Check file exists
    if not config_path.exists():
        print(f"❌ Error: Configuration file not found: {config_path}")
        print("\nTip: Copy .claude/config.example.json to create a new config file")
        sys.exit(1)

    # Load configuration
    try:
        config = load_config(config_path)
    except json.JSONDecodeError as e:
        print(f"❌ Error: Invalid JSON syntax")
        print(f"   {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: Could not read configuration file")
        print(f"   {e}")
        sys.exit(1)

    # Validate configuration
    errors, warnings = validate_config(config)

    # Report results
    if errors:
        print("\n❌ VALIDATION FAILED\n")
        print("Errors:")
        for error in errors:
            print(f"  • {error}")
    else:
        print("\n✅ VALIDATION PASSED\n")

    if warnings:
        print("\nWarnings:")
        for warning in warnings:
            print(f"  ⚠ {warning}")

    print("\n" + "=" * 60)

    # Exit with appropriate code
    if errors:
        sys.exit(1)
    else:
        print("Configuration is valid!")
        sys.exit(0)


if __name__ == "__main__":
    main()
