#!/usr/bin/env python3
"""
The command to assess for AppMod Kit
"""

import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Any


def generate_summary_content(report_json: Dict[str, Any]) -> str:
    """
    Generate a summary report from the assessment JSON data.
    
    Args:
        report_json: The parsed assessment JSON data
        
    Returns:
        Markdown formatted summary string
    """
    metadata = report_json.get('metadata', {})
    target_display_names = metadata.get('targetDisplayNames', [])
    
    rules = report_json.get('rules', {})
    
    # Build summary markdown
    summary = "# App Modernization Assessment Summary\n\n"
    summary += f"**Target Azure Services**: {', '.join(target_display_names)}\n\n"
    summary += "## Overall Statistics\n\n"
    
    # Group projects by appName
    projects_by_app: Dict[str, List[Any]] = {}
    for project in report_json.get('projects', []):
        app_name = project.get('properties', {}).get('appName', 'Others')
        if app_name not in projects_by_app:
            projects_by_app[app_name] = []
        projects_by_app[app_name].append(project)
    
    summary += f"**Total Applications**: {len(projects_by_app)}\n\n"
    
    # Count severity by app
    for app_name, projects in projects_by_app.items():
        severity_count = {
            'mandatory': 0,
            'potential': 0,
            'optional': 0,
            'information': 0
        }
        
        # Collect all unique rule IDs for this app
        rule_ids = set()
        for project in projects:
            for incident in project.get('incidents', []):
                rule_ids.add(incident.get('ruleId', ''))
        
        # Count by severity
        for rule_id in rule_ids:
            rule = rules.get(rule_id)
            if rule:
                severity = (rule.get('severity') or 'information').lower()
                if severity in severity_count:
                    severity_count[severity] += 1
        
        summary += f"**Name: {app_name}**\n"
        summary += f"- Mandatory: {severity_count['mandatory']} issues\n"
        summary += f"- Potential: {severity_count['potential']} issues\n"
        summary += f"- Optional: {severity_count['optional']} issues\n\n"
    
    # hide information severity in java now, appcat not document information severity
    summary += "> **Severity Levels Explained:**\n"
    summary += "> - **Mandatory**: The issue has to be resolved for the migration to be successful.\n"
    summary += "> - **Potential**: This issue may be blocking in some situations but not in others. These issues should be reviewed to determine whether a change is required or not.\n"
    summary += "> - **Optional**: The issue discovered is real issue fixing which could improve the app after migration, however it is not blocking.\n\n"
    
    # Add Applications Profile section
    summary += "## Applications Profile\n\n"
    
    for app_name, projects in projects_by_app.items():
        first_project = projects[0]
        properties = first_project.get('properties', {})
        
        summary += f"### Name: {app_name}\n"
        summary += f"- **JDK Version**: {properties.get('jdkVersion', 'N/A')}\n"
        summary += f"- **Frameworks**: {', '.join(properties.get('frameworks') or []) or 'N/A'}\n"
        summary += f"- **Languages**: {', '.join(properties.get('languages') or []) or 'N/A'}\n"
        summary += f"- **Build Tools**: {', '.join(properties.get('tools') or []) or 'N/A'}\n\n"
        
        # Collect incidents by rule
        rule_incidents: Dict[str, int] = {}
        for project in projects:
            for incident in project.get('incidents', []):
                # For Java reports, only count incidents with "type=violation" label
                # For .NET reports, labels are empty, so we include all incidents
                incident_labels = incident.get('labels', [])
                
                # Skip filtering if labels are empty (likely a .NET report)
                if incident_labels:
                    has_violation_label = 'type=violation' in incident_labels
                    if not has_violation_label:
                        continue
                
                rule_id = incident.get('ruleId', '')
                rule_incidents[rule_id] = rule_incidents.get(rule_id, 0) + 1
        
        # Group by severity
        issues_by_severity: Dict[str, List[Dict[str, Any]]] = {}
        for rule_id, count in rule_incidents.items():
            rule = rules.get(rule_id)
            if rule:
                severity = rule.get('severity', 'information')
                if severity not in issues_by_severity:
                    issues_by_severity[severity] = []
                issues_by_severity[severity].append({
                    'ruleId': rule_id,
                    'title': rule.get('title', rule_id),
                    'count': count
                })
        
        # Output key findings
        summary += "**Key Findings**:\n"
        for severity in ['mandatory', 'potential', 'optional']:
            issues = issues_by_severity.get(severity, [])
            if issues:
                total_incidents = sum(issue['count'] for issue in issues)
                capitalized_severity = severity.capitalize()
                summary += f"- **{capitalized_severity} Issues ({total_incidents} locations)**:\n"
                for issue in issues:
                    plural = 's' if issue['count'] > 1 else ''
                    summary += f"  - <!--ruleid={issue['ruleId']}-->{issue['title']} ({issue['count']} location{plural} found)\n"
        summary += "\n"
    
    summary += "## Next Steps\n\n"
    summary += "For comprehensive migration guidance and best practices, visit:\n"
    summary += "- [GitHub Copilot App Modernization](https://aka.ms/ghcp-appmod)\n"
    
    return summary


def get_report_content(report_json: Dict[str, Any]) -> str:
    """
    Parse the assessment JSON and generate a markdown table report for Azure Migrate.
    
    Args:
        report_json: The parsed assessment JSON data
        
    Returns:
        Markdown formatted report string
    """
    # Get metadata and target IDs
    metadata = report_json.get('metadata', {})
    target_ids = metadata.get('targetIds', [])
    
    azure_targets = ["azure-appservice", "azure-aks", "azure-container-apps", "AppService.Windows", "AppService.Linux",
      "AKS.Linux", "AKS.Windows", "ACA", "AppServiceContainer.Linux", "AppServiceContainer.Windows", "AppServiceManagedInstance.Windows"]
    filtered_targets = [t for t in target_ids if t in azure_targets]
    
    if not filtered_targets:
        raise ValueError(
            "No target Azure services specified in the assessment report. "
        )
    
    issues = []
    
    # Get projects and rules
    projects = report_json.get('projects', [])
    rules = report_json.get('rules', {})
    
    # Process all projects
    for project in projects:
        if not project:
            continue
        
        properties = project.get('properties', {})
        app_name = properties.get('appName', '')
        
        # Skip projects without appName
        if not app_name:
            continue
        
        # Process incidents for this project
        incidents = project.get('incidents', [])
        
        # Group incidents by ruleId to get incident count per rule and collect target information
        rule_incidents: Dict[str, Dict[str, Any]] = {}
        
        for incident in incidents:
            rule_id = incident.get('ruleId', '')
            if not rule_id:
                continue
            
            # For Java reports, only count incidents with "type=violation" label
            # For .NET reports, labels are empty, so we include all incidents
            incident_labels = incident.get('labels', [])
            
            # Skip filtering if labels are empty (likely a .NET report)
            if incident_labels:
                has_violation_label = 'type=violation' in incident_labels
                if not has_violation_label:
                    continue
            
            if rule_id not in rule_incidents:
                rule_incidents[rule_id] = {
                    'count': 0,
                    'targets': incident.get('targets', {})
                }
            rule_incidents[rule_id]['count'] += 1
        
        # Create issues from rules that have incidents
        for rule_id, incident_data in rule_incidents.items():
            rule_data = rules.get(rule_id)
            
            if not rule_data:
                continue
            
            incident_count = incident_data['count']
            incident_targets = incident_data['targets']
            
            # Format links
            links_data = rule_data.get('links', [])
            links_str = ''
            if links_data:
                link_texts = []
                for link in links_data:
                    if link:
                        title = link.get('title', '')
                        url = link.get('url', '')
                        if title and url:
                            link_texts.append(f"[{title}]({url})")
                        elif url:
                            link_texts.append(f"[Link]({url})")
                links_str = ','.join(link_texts)
            
            target_groups: Dict[str, List[str]] = {}
            
            if incident_targets:
                for target_id, target_info in incident_targets.items():
                    # Only process targets that are in our Azure targets list
                    if target_id in filtered_targets:
                        severity = target_info.get('severity') or rule_data.get('severity', '')
                        effort = target_info.get('effort') or rule_data.get('effort', 0)
                        
                        group_key = f"{severity}-{effort}"
                        
                        if group_key not in target_groups:
                            target_groups[group_key] = []
                        
                        target_groups[group_key].append(target_id)
            
            # Only create issues if we found relevant targets
            if target_groups:
                for group_key, target_display_names in target_groups.items():
                    parts = group_key.split('-', 1)
                    severity = parts[0]
                    effort_str = parts[1] if len(parts) > 1 else '0'
                    target_services = ','.join(target_display_names)
                    
                    rule_title = rule_data.get('title', '')
                    effort_int = int(effort_str) if effort_str else 0
                    
                    issue = {
                        'ruleId': rule_id,
                        'title': rule_title,
                        'criticality': severity,
                        'effort': effort_int,
                        'links': links_str,
                        'incidentNumber': incident_count,
                        'appName': app_name,
                        'targetServices': target_services
                    }
                    issues.append(issue)
    
    # Generate markdown table
    if not issues:
        return ''
    
    comment_body = "# Assessment Report - Issues Summary\n\n"
    comment_body += "| # | Web-app name | Target Ids | Issue Id | Issue Title | Criticality | Effort | Links | Incident Number |\n"
    comment_body += "|-|-|-|-|-|-|-|-|-|\n"
    
    for idx, issue in enumerate(issues, start=1):
        comment_body += (
            f"| {idx} | {issue['appName']} | {issue['targetServices']} | "
            f"{issue['ruleId']} | {issue['title']} | {issue['criticality']} | "
            f"{issue['effort']} | {issue['links']} | {issue['incidentNumber']} |\n"
        )
    
    return comment_body


def assess_command(
    output_path: str,
    issue_source: str = "other",
    json_output: bool = False,
):
    """
    Process AppCat assessment report and generate summary.

    Args:
        output_path: Path to the folder containing report.json (required)
        issue_source: Source of the issue report - 'azuremigrate' or 'other' (default: 'other')
        json_output: Output results in JSON format (default: False)

    This command will:
    1. Read the AppCat report.json file from the output folder
    2. Generate a summary based on issue_source:
       - 'azuremigrate': Generate table format for Azure Migrate
       - 'other': Generate comprehensive summary with statistics (default)
    3. Save the summary to summary.md in the same folder
    4. Output the assessment result status

    Examples:
        assess.py --output-path /path/to/output
        assess.py --output-path /path/to/output --issue-source azuremigrate
        assess.py --output-path /path/to/output --json
    """

    # Convert to Path object and construct report.json path
    output_path = Path(output_path)
    report_json_path = output_path / "report.json"

    # Check if report.json exists
    if report_json_path.exists():
        appcat_result = "success"
        summary_md_path = output_path / "summary.md"
        
        try:
            # Read and parse the JSON file
            with open(report_json_path, 'r', encoding='utf-8') as f:
                report_json = json.load(f)
            
            if not report_json:
                raise ValueError("No assessment data found. Please assess your application first.")
            
            # Generate summary based on issue_source
            if issue_source.lower() == "azuremigrate":
                summary_content = get_report_content(report_json)
            else:
                summary_content = generate_summary_content(report_json)
            
            if summary_content:
                # Write summary to summary.md
                with open(summary_md_path, "w", encoding="utf-8") as f:
                    f.write(summary_content)
            else:
                print("Warning: No issues found in the assessment report.")
                
        except Exception as e:
            print(f"Warning: Failed to generate assessment summary: {e}", file=sys.stderr)
            appcat_result = "failure"
    else:
        appcat_result = "failure"

    # Output results
    if json_output:
        output = {
            "AppCatResult": appcat_result,
        }
        print(json.dumps(output, separators=(",", ":")))
    else:
        print(f"APPCAT_RESULT: {appcat_result}")


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Process AppCat assessment report and generate summary")
    parser.add_argument("--output-path", "-o", required=True,
                       help="Path to the folder containing report.json")
    parser.add_argument("--issue-source", "-s", default="other",
                       choices=["azuremigrate", "other"],
                       help="Source of the issue report (default: other)")
    parser.add_argument("--json", "-j", action="store_true", 
                       help="Output results in JSON format")
    args = parser.parse_args()
    
    try:
        assess_command(
            output_path=args.output_path,
            issue_source=args.issue_source,
            json_output=args.json
        )
    except SystemExit:
        pass
