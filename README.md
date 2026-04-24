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
3. In Agent Builder, add the three ALF flows as actions to your report-building topic
4. Write topic instructions that guide the agent through the discover → inspect → create workflow

### Required Permissions

The agent user (or running user) needs:
- **Create and Customize Reports** permission
- **Run Reports** permission
- Access to the Analytics API (enabled by default in most orgs)

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
