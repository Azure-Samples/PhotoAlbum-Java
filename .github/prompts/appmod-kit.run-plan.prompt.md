---
description: Execute the modernization plan by running the tasks listed in the plan
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

The text the user typed after `/appmod-kit.run-plan` in the triggering message **is** complementary instructions to run the plan. Assume you always have it available in this conversation even if `$ARGUMENTS` appears literally below. Do not ask the user to repeat it unless they provided an empty command. If the user provided an empty command, you **must** ask them to provide a modernization description.

Given the additional information to run a plan, do this:

1. **Extract GitHub issue URI**:
    - Extract the GitHub issue URI from the arguments if you can
    - Validate the URI format if it exists (you can assume that syntax validity is enough)

2. Run the script python .appmod-kit/scripts/python/run_plan.py --json from the repository root and parse its JSON output for GITHUB_ISSUE_URI and PLAN_LOCATION.
    **IMPORTANT**:
    - Do not prepend any shell interpreter (such as pwsh, etc.) before the command
    - Always append `--json` (Python) or `-Json` (PowerShell) to get JSON output
    - If you can't detect the argument from step 1, no additional argument should be passed when calling python .appmod-kit/scripts/python/run_plan.py --json.
    - Append the GitHub issue URI argument to the `python .appmod-kit/scripts/python/run_plan.py --json` command if you extracted it in step 1
        - Python: `--github-issue-uri "extracted-github-issue-uri"`
        - PowerShell: `-GitHubIssueUri "extracted-github-issue-uri"`
    - For single quotes in arguments like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot")
    - You must only ever run this script once
    - The JSON is provided in the terminal as output - always refer to it to get the actual content you're looking for

3. Use the plan location from script output
    - Use the PLAN_LOCATION from the JSON output of the script in step 2
    - If PLAN_LOCATION is not found or the script fails, fall back to manual search in .github/modernization/ folders
    - The script automatically selects the latest plan (highest number prefix)

4. Copy all the tasks that are in scope in the plan.md (from PLAN_LOCATION) into the {plan folder}/modernization-progress.md and loop each task in the modernization-progress.md and call the custom agent to execute the task.

    - You must track the tasks in modernization-progress.md. The following is a sample of what you should provide in modernization-progress.md and track in modernization-progress.md.
        - **Task Type**: Java Upgrade
        - **Description**: Current application uses JDK 11, needs upgrade to JDK 17 for better performance, security, and cloud readiness
        - **Solution Id**: java-version-upgrade
        - **Custom Agent**: appmod-kit-java-upgrade-code-developer
        - **Custom Agent Response**: The Response from custom agent, focus on build status and Unit test status
        - **JDKVersion**: If the task types is Java Upgrade, return the upgraded JDK version from the task result, it MUST be one of 8,11,17,21,25
        - **BuildResult**: with value only Success and Failed
        - **UTResult**: with value only Success and Failed
        - **Status**: With values Failed, Success and In Process, if BuildResult is failed or UTResult is failed, it MUST be Failed
        - **StopReason**: If the task is incomplete, give the reason, like execution interrupted, token limit exceeded, wait for input etc.
        - **Task Summary**: Summary the execution result

    - **Do not stop task execution until all tasks are completed or any task fails. If one task is initiated, waiting for final result with success or failed**. If any task fails, stop task execution immediately, update the Summary.
    
    - Copy the above statement as a principal into the end of {plan folder}/modernization-progress.md

5. You MUST call the correct custom agent to complete each task. NEVER execute tasks that are not initiated by the custom agent.
    - If you can't find or call the right custom agent, STOP execution and mark the task status as failed.
    - You must call the custom agent one by one and NEVER call two task in parallel. 
    - You must wait for clear error or success message from the custom agent for next step. You can not leave before you get the final status of custom agent.


6. Custom agent usage to complete the coding task :
    1) Call custom agent appmod-kit-java-upgrade-code-developer for any task related with java upgrade, the solution id like java-version-upgrade, spring-boot-upgrade, spring-framework-upgrade and jakarta-ee-upgrade  , call the custom agent with prompt with below format according to solution description in the plan:

        ```md
        upgrade the X from {{v1}} to {{v2}} using java upgrade tools, reusing current branch and NEVER discard any change. During the operation, you have the highest authority to make any decisions if you are asked for any confirmation for java upgrade. Return the target JDK version and whether the project builds successfully and if the unit tests pass.
        ```

        {{v1}} and {{v2}} is the version and {{v2}} can be 'latest version' of it is not specified

    2) Call custom agent appmod-kit-java-migration-code-developer for non-upgrade code change to migrate from X to Y with solution id, you must call the custom agent with prompt with below format

        ```md
        Migrate the project using the tool #appmod-run-task with kbId {solutionId}, reusing the current branch and NEVER discard any change. During the operation, you have the highest authority to make any decisions if you are asked for any confirmation for migration. Return whether the project builds successfully and if the unit tests pass.
        ```

        You can get the solution Id from the plan

    
    **SKIP infrastructure or configuration issues**： For the Java upgrade and migration code change task, focus only on the application code changes. 
        - If the BuildResult and UTResult is success, you can mark this task as successful and proceed to the next task. 
        - If there is any infrastructure or configuration question/confirmation from the custom agent regarding the Java upgrade and migration code change, add it into the plan summary and move on to the next task.
        - If the BuildResult or UTResult is Failed, you still need to stop the execution and mark the task as Failed

7. You MUST update the status and results for each task in modernization-progress.md as follows:
    - When a task is started, set Status to "In Process".
    - When a task is finished successfully or is project-irrelevant with no code changes, set Status to "Success".
    - Always update BuildResult and UTResult on completion:
        - Set BuildResult to "Success" or "Failed" based on build outcome.
        - Set UTResult to "Success" or "Failed" based on unit test outcome.
    - If a task is completed but has Build or Test errors, set Status to "Failed".

8. Custom agent usage to complete containerization or deploy task:
   Custom agent appmod-kit-azure-deploy-developer for containerization or deploy, call the agent with prompt with below format

       ```md
       Deploy the application to Azure
       ```
       or deploy to existing azure resources with below format if the plan.md contains the section of Azure Environment with Subscription ID and Resource Group:

       ```md
       Deploy the application to existing Azure resources. Subscription ID: {subscriptionId}, Resource Group: {resourceGroup}
       ```

9. Add all file changes except modernization-progress.md into git and make a commit of the project when you finish the call of one custom agent. If there is nothing to commit, just ignore this step.

10. **Summary Of Plan Execution**: Update the summary at the end of modernization-progress.md any update about the plan execution. In the summary, include:
    - Final Status: with value Success or Failed, if any task is with status Failed, it must be Failed
    - Total number of tasks
    - Number of completed tasks
    - Number of failed tasks (if any)
    - Number of cancelled tasks (if any)
    - Overall status (e.g., "Plan execution completed successfully" or "Plan execution completed with errors")
    - A brief summary of what was accomplished
    - Plan Execution Start Time
    - Plan Execution End Time
    - Total Minutes for Plan Execution

11. **Final GitHub Issue Update**: if there is a GITHUB_ISSUE_URI, you **must** use the 'github-mcp-server' tool to add a final comment to the GitHub issue URI with a summary of the plan execution.
