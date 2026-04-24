# AgentForce Report Builder

Reusable Agentforce invocable actions that let AI agents create native Salesforce reports via the Analytics REST API. Give your agent the ability to build tabular, summary, and matrix reports from natural language — no clicks required.

<a href="https://githubsfdeploy.herokuapp.com/app/githubdeploy/jcd386/AgentForce-Report-Builder?ref=main">
  <img alt="Deploy to Salesforce" src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

## What's Included

### Apex Invocable Actions

| Action | Description |
|--------|-------------|
| **AgentReportCreate** | Creates a native Salesforce report via the Analytics REST API. Supports TABULAR, SUMMARY, and MATRIX formats with column selection, row/column groupings, filters (JSON array), standard date filters, and folder targeting. |
| **AgentListReportTypes** | Queries the Analytics API for available report types. Returns a JSON array of `apiName`, `label`, and `description` for each type. Supports keyword filtering and result limits. |
| **AgentGetReportTypeColumns** | Discovers valid column API names for any report type by creating a temporary probe report, reading back its default columns, then deleting it. Returns a JSON array of `apiName` and `label` per column. |

### Autolaunched Flows (ALFs)

Flow wrappers for each Apex action — ready to add as Agentforce topic actions:

| Flow | Wraps |
|------|-------|
| **Agent - ALF - Create Report** | `AgentReportCreate` |
| **Agent - ALF - List Report Types** | `AgentListReportTypes` |
| **Agent - ALF - Get Report Type Columns** | `AgentGetReportTypeColumns` |

### Supporting Components

| Component | Purpose |
|-----------|---------|
| **SessionId** (VF Page) | Returns the current session ID as plain text. Used by the Apex actions to authenticate Analytics API callouts in agent contexts where `UserInfo.getSessionId()` returns null. |

## How It Works

The typical agent workflow:

1. **Discover** — Agent calls `List Report Types` to find the right report type (e.g., `OpportunityList`, `CaseList`)
2. **Inspect** — Agent calls `Get Report Type Columns` to discover valid field API names for that type
3. **Create** — Agent calls `Create Report` with the report name, type, columns, groupings, and filters
4. **Deliver** — Agent returns the report URL to the user, who clicks it to see the report in Lightning

## Setup

1. Click the **Deploy to Salesforce** button above
2. Grant the agent user access to the **Reports** and **Analytics** APIs
3. In Agent Builder, create a topic and add the three ALF flows as actions
4. Paste the topic configuration below into your topic settings

### Required Permissions

The agent user (or running user) needs:
- **Create and Customize Reports** permission
- **Run Reports** permission
- Access to the Analytics API (enabled by default in most orgs)

## Agent Configuration

Create a topic in Agent Builder with the following settings. You can use one combined topic or split into two (discovery + creation) depending on your agent's complexity.

### Recommended: Single Topic

**Topic Label:** `Report Builder`

**Classification Description:**
> This topic applies when users want to create, build, or generate Salesforce reports, or when they need help finding report types or available fields.

**Scope:**
> Your job is to help users create native Salesforce reports. You do this by discovering the right report type, inspecting available columns, and then creating the report with the user's desired configuration. Always follow the discover → inspect → create workflow.

**Instructions** (add each as a separate instruction in Agent Builder):

| # | Instruction |
|---|-------------|
| 1 | When the user asks for a report, first determine what object or data they want to report on. Use the "List Report Types" action to search for matching report types. If the user says "opportunities", search for "opportunity". If they say "cases", search for "case". Present the matching report types and confirm which one to use. |
| 2 | After confirming the report type, use the "Get Report Type Columns" action to discover all available fields for that report type. Use these results to select the most relevant columns for the user's request. Do not guess column API names — only use values returned by this action. |
| 3 | When creating the report, choose the appropriate format: use TABULAR for simple lists with no grouping, SUMMARY when the user wants grouping or subtotals (requires groupingsDown), and MATRIX when the user wants both row and column groupings (requires groupingsDown and groupingsAcross). Default to TABULAR if the user doesn't specify. |
| 4 | For filters, construct a JSON array of filter objects. Each object needs: column (the field API name from the column discovery step), operator (equals, notEqual, greaterThan, lessThan, contains, startsWith), and value. Example: [{"column":"STAGE_NAME","operator":"equals","value":"Closed Won"}]. Only apply filters the user explicitly requests. |
| 5 | For date filters, use the FIELD:RANGE format. Common ranges: THIS_FISCAL_QUARTER, LAST_FISCAL_QUARTER, THIS_FISCAL_YEAR, LAST_FISCAL_YEAR, THIS_MONTH, LAST_MONTH, LAST_30_DAYS, LAST_90_DAYS. Example: "CLOSE_DATE:THIS_FISCAL_YEAR". Only apply a date filter if the user mentions a time period. |
| 6 | After the report is created successfully, share the report URL with the user so they can view it immediately. If the creation fails, read the error message and explain what went wrong in plain language. Common issues: invalid field names (re-run column discovery), invalid report type (re-run type listing), or missing permissions. |
| 7 | If the user asks you to group the report by a field, switch the format to SUMMARY and add that field to groupingsDown. If they want a cross-tab or pivot-style layout, use MATRIX and put row groupings in groupingsDown and column groupings in groupingsAcross. Maximum 3 grouping fields in each direction. |

**Actions** (add all three):
- `Agent - ALF - List Report Types`
- `Agent - ALF - Get Report Type Columns`
- `Agent - ALF - Create Report`

### Alternative: Two-Topic Split

For agents with many topics, splitting reduces classification ambiguity:

**Topic 1 — Report Type Discovery**
- **Scope:** Assist users in identifying the most suitable Salesforce report type based on their data requirements. You cannot create reports under this topic.
- **Actions:** `Agent - ALF - List Report Types`, `Agent - ALF - Get Report Type Columns`
- **Instructions:** Instructions 1 and 2 from above.

**Topic 2 — Report Creation**
- **Scope:** Assist users in building reports by configuring columns, filters, groupings, date ranges, and format. Assume the report type and columns have already been identified.
- **Actions:** `Agent - ALF - Create Report`
- **Instructions:** Instructions 3 through 7 from above.

## Supported Report Formats

| Format | Description | Requires |
|--------|-------------|----------|
| TABULAR | Flat list of records | Nothing extra |
| SUMMARY | Grouped rows with subtotals | `groupingsDown` (1-3 fields) |
| MATRIX | Cross-tab with row and column groupings | `groupingsDown` + `groupingsAcross` |

## Example Prompts

Once wired to an Agentforce topic, users can say things like:

- *"Create a report showing open opportunities grouped by stage"*
- *"Build a cases report grouped by category"*
- *"Create an activities report showing tasks for this month"*
- *"Show me contacts at accounts in the technology industry"*

## File Inventory

```
force-app/main/default/
├── classes/
│   ├── AgentReportCreate.cls              # Core report creation action
│   ├── AgentReportCreate.cls-meta.xml
│   ├── AgentReportCreateTest.cls          # Test class (100% coverage)
│   ├── AgentReportCreateTest.cls-meta.xml
│   ├── AgentListReportTypes.cls           # Report type discovery action
│   ├── AgentListReportTypes.cls-meta.xml
│   ├── AgentListReportTypesTest.cls
│   ├── AgentListReportTypesTest.cls-meta.xml
│   ├── AgentGetReportTypeColumns.cls      # Column discovery action
│   ├── AgentGetReportTypeColumns.cls-meta.xml
│   ├── AgentGetReportTypeColumnsTest.cls
│   └── AgentGetReportTypeColumnsTest.cls-meta.xml
├── flows/
│   ├── Agent_ALF_Create_Report.flow-meta.xml
│   ├── Agent_ALF_List_Report_Types.flow-meta.xml
│   └── Agent_ALF_Get_Report_Type_Columns.flow-meta.xml
└── pages/
    ├── SessionId.page
    └── SessionId.page-meta.xml
```

## Author

Built by [We Summit Mountains](https://wesummitmountains.com) — a Salesforce consulting firm in Dallas, TX.
