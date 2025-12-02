#!/usr/bin/env python3
"""
The command to create-plan for AppMod Kit
"""

import json
import os
import re
import subprocess
from pathlib import Path
from typing import Optional

def create_plan_command(
    short_name: str = None,
    github_issue_uri: Optional[str] = None,
    json_output: bool = False
):
    """
    Create a new modernization plan.
    
    This command will:
    1. Find the next available plan number
    2. Create a new git branch with the format: <number>-<short-name>
    3. Create a directory structure under .github/modernization/
    4. Set environment variables for the current session
    """
    
    if not short_name or short_name.strip() == "":
        print("Error: ShortName is required.")
        print("A concise short name (5-10 words) that describes the modernization intent, e.g., 'modernize-complete-application'")
        exit(1)

    # Find the github issue if any
    github_issue_to_use = github_issue_uri or os.getenv("GITHUB_ISSUE_URI")

    # Get repository root
    repo_root = Path.cwd()

    # Create the modernization directory path
    modernization_dir = repo_root / ".github" / "modernization"
    modernization_dir.mkdir(parents=True, exist_ok=True)

    # Find the next available number by examining existing folders
    existing_folders = [
        d for d in modernization_dir.iterdir() 
        if d.is_dir() and re.match(r'^\d{3}-', d.name)
    ]
    
    next_number = 1
    if existing_folders:
        existing_numbers = []
        for folder in existing_folders:
            match = re.match(r'^(\d{3})-', folder.name)
            if match:
                existing_numbers.append(int(match.group(1)))
        
        if existing_numbers:
            existing_numbers.sort()
            next_number = max(existing_numbers) + 1

    # Format the number with leading zeros (3 digits)
    feature_num = f"{next_number:03d}"

    # Create the branch name with feature number prefix
    # Convert to lowercase and replace non-alphanumeric with hyphens
    branch_suffix = re.sub(r'[^a-z0-9]', '-', short_name.lower())
    # Remove multiple consecutive hyphens
    branch_suffix = re.sub(r'-{2,}', '-', branch_suffix)
    # Remove leading/trailing hyphens
    branch_suffix = branch_suffix.strip('-')
    branch_name = f"{feature_num}-{branch_suffix}"

    # GitHub enforces a 244-byte limit on branch names
    max_branch_length = 244
    if len(branch_name) > max_branch_length:
        # Calculate how much we need to trim from suffix
        # Account for: feature number (3) + hyphen (1) = 4 chars
        max_suffix_length = max_branch_length - 4
        
        # Truncate suffix
        truncated_suffix = branch_suffix[:max_suffix_length].rstrip('-')
        
        original_branch_name = branch_name
        branch_name = f"{feature_num}-{truncated_suffix}"
        
        print("Warning: Branch name exceeded GitHub's 244-byte limit")
        print(f"Original: {original_branch_name} ({len(original_branch_name)} bytes)")
        print(f"Truncated to: {branch_name} ({len(branch_name)} bytes)")

    # Create the branch
    # If it fails, just warn and continue
    try:
        subprocess.run(
            ["git", "checkout", "-b", branch_name],
            capture_output=True,
            check=True
        )
    except subprocess.CalledProcessError:
        print(f"[yellow]Warning:[/yellow] Failed to create git branch: {branch_name}")

    # Create the folder for plan specs in .github/modernization/<branch-name>
    plan_dir = modernization_dir / branch_name
    plan_dir.mkdir(exist_ok=True)
    
    # Set the environment variable for the current session
    os.environ["APPMODKIT_FEATURE_BRANCH"] = branch_name

    # Output results
    if json_output:
        output = {
            "BranchName": branch_name,
            "PlanFolderName": f".github/modernization/{branch_name}"
        }
        if github_issue_to_use:
            output["GitHubIssueURI"] = github_issue_to_use
        print(json.dumps(output, separators=(',', ':')))
    else:
        if github_issue_to_use:
            print(f"GITHUB_ISSUE_URI: {github_issue_to_use}")
        print(f"BRANCH_NAME: {branch_name}")
        print(f"PLAN_FOLDER_NAME: .github/modernization/{branch_name}")


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Create a new modernization plan")
    parser.add_argument(
        "--short-name", "-s",
        required=True,
        help="A concise short name (5-10 words) that describes the modernization intent"
    )
    parser.add_argument(
        "--github-issue-uri", "-g",
        help="GitHub issue URI for this modernization plan"
    )
    parser.add_argument(
        "--json", "-j",
        action="store_true",
        help="Output results in JSON format"
    )
    
    args = parser.parse_args()
    
    try:
        create_plan_command(
            short_name=args.short_name,
            github_issue_uri=args.github_issue_uri,
            json_output=args.json
        )
    except SystemExit:
        pass