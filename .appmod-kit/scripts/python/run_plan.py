#!/usr/bin/env python3
"""
The command to run-plan for AppMod Kit
"""

import json
import os
import re
from pathlib import Path
from typing import Optional

def find_plan_location() -> Optional[str]:
    """
    Find the latest plan.md location in .github/modernization folders.
    Returns the latest plan based on folder prefix (highest number).
    """    
    repo_root = Path.cwd()
    modernization_dir = repo_root / ".github" / "modernization"
    if not modernization_dir.exists():
        return None
    
    # Check if .gitignore exists in modernization folder and add patterns
    gitignore_path = modernization_dir / ".gitignore"
    patterns_to_add = ["**/*progress.md", ".gitignore"]
    
    if gitignore_path.exists():
        gitignore_content = gitignore_path.read_text(encoding="utf-8")
        patterns_to_write = [p for p in patterns_to_add if p not in gitignore_content]
        if patterns_to_write:
            with gitignore_path.open("a", encoding="utf-8") as f:
                if not gitignore_content.endswith("\n"):
                    f.write("\n")
                for pattern in patterns_to_write:
                    f.write(f"{pattern}\n")
    else:
        gitignore_path.write_text("\n".join(patterns_to_add) + "\n", encoding="utf-8")

    # Find all plan folders (format: ###-branch-name)
    plan_folders = [
        d for d in modernization_dir.iterdir() 
        if d.is_dir() and re.match(r'^\d{3}-', d.name)
    ]
    
    if not plan_folders:
        return None
    
    # Return the latest plan based on folder prefix (highest number)
    plan_folders.sort(key=lambda x: int(re.match(r'^(\d{3})-', x.name).group(1)), reverse=True)
    for folder in plan_folders:
        plan_file = folder / "plan.md"
        if plan_file.exists():
            return str(plan_file.relative_to(repo_root))
    
    return None

def run_plan_command(
    github_issue_uri: Optional[str] = None,
    json_output: bool = False
):
    """
    Run a modernization plan.
    
    This command will:
    1. Find the right github URI and return it
    2. Find the latest plan.md location in .github/modernization folders
    """
    
    # Find the github issue if any
    github_issue_to_use = github_issue_uri or os.getenv("GITHUB_ISSUE_URI")
    
    # Find the plan location
    plan_location = find_plan_location()

    # Output results
    if json_output:
        output = {}
        if github_issue_to_use:
            output["GitHubIssueURI"] = github_issue_to_use
        if plan_location:
            output["PlanLocation"] = plan_location
        print(json.dumps(output, separators=(',', ':')))
    else:
        if github_issue_to_use:
            print(f"GITHUB_ISSUE_URI: {github_issue_to_use}")
        if plan_location:
            print(f"PLAN_LOCATION: {plan_location}")

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Run a modernization plan")
    parser.add_argument(
        "--github-issue", "-g",
        help="GitHub issue URI for this modernization plan"
    )
    parser.add_argument(
        "--json", "-j",
        action="store_true",
        help="Output results in JSON format"
    )
    
    args = parser.parse_args()
    
    try:
        run_plan_command(
            github_issue_uri=args.github_issue,
            json_output=args.json
        )
    except SystemExit:
        pass