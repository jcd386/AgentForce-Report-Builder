# AgentForce Report Builder

Reusable Agentforce invocable actions that let AI agents create and edit native Salesforce reports via the Analytics REST API. Give your agent the ability to build tabular, summary, and matrix reports — and modify existing ones — from natural language, no clicks required.

<a href="https://githubsfdeploy.herokuapp.com/app/githubdeploy/jcd386/AgentForce-Report-Builder?ref=main">
  <img alt="Deploy to Salesforce" src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

The package ships as deployable metadata — the Agentforce topic, its actions, and their instructions are all included. There's no manual "paste this into Agent Builder" step; you deploy, assign a permission set, and attach the pre-built topic to your agent.

## What's Included

### Apex Invocable Actions

| Action | Description |
|--------|-------------|
| **AgentCreateReport** | Creates a native Salesforce report via the Analytics REST API. Supports TABULAR, SUMMARY, and MATRIX formats with column selection, filters (single, multi, or boolean logic), groupings, date granularity, cross-filters, bucket fields, and custom formulas. |
| **AgentEditReport** | Edits an existing report in place. Reads the report's current metadata, applies only the fields you supply, and writes it back — everything you don't mention is left untouched. Identify the report by ID or by its exact current name. |
| **AgentDeleteReport** | Deletes a report by ID. Internal utility (not exposed as an agent action — no Flow/GenAiFunction wrapper) used for cleanup during development and testing. |
| **AgentListReportTypes** | Queries the Analytics API for available report types. Returns a JSON array of `apiName`, `label`, and `description` for each type. Supports keyword filtering and result limits. |
| **AgentGetReportTypeColumns** | Discovers valid column API names for any report type via the report type describe endpoint (merges `reportExtendedMetadata` and `reportTypeMetadata` so both standard and custom report types return their full column set). Returns a JSON array of `apiName` and `label` per column, plus the type's default column set. |

### Autolaunched Flows (ALFs)

Thin flow wrappers around the Apex actions — these are what the agent actually invokes as topic actions:

| Flow | Wraps |
|------|-------|
| **WSM - ALF - Agent: Create Report** | `AgentCreateReport` |
| **WSM - ALF - Agent: Edit Report** | `AgentEditReport` |
| **WSM - ALF - Agent: List Report Types** | `AgentListReportTypes` |
| **WSM - ALF - Agent: Get Report Type Columns** | `AgentGetReportTypeColumns` |

`AgentDeleteReport` has no flow wrapper and is not agent-invocable — it's called directly from Apex (dev/test cleanup only).

### Agentforce Metadata (GenAiFunction / GenAiPlugin)

| Component | Purpose |
|-----------|---------|
| **WSM_Agent_Create_Report** / **WSM_Agent_Edit_Report** / **WSM_Agent_List_Report_Types** / **WSM_Agent_Get_Report_Type_Columns** (`GenAiFunction`) | Registers each ALF as an Agentforce-invocable function. |
| **WSM_Report_Builder** (`GenAiPlugin`, `pluginType=Topic`) | The "Report Builder" topic. Bundles all four functions with a full instruction set covering the create workflow (discover type → discover columns → create), the edit workflow (identify → change only what's asked → confirm), report formats, filter logic, cross-filters, buckets, and custom formulas. |

### Supporting Components

| Component | Purpose |
|-----------|---------|
| **WSM_Report_Builder_Agent** (`PermissionSet`) | Grants class access to all four agent-facing Apex actions plus the `CreateCustomizeReports` and `RunReports` user permissions needed to call the Analytics API. Assign to the agent's running user. |
| **SessionId** (VF Page) | Returns the current session ID as plain text. Used by the Apex actions to authenticate Analytics API callouts in agent contexts where `UserInfo.getSessionId()` returns null. |

## How It Works

**Creating a report:**

1. **Discover** — Agent calls `List Report Types` to find the right report type (e.g., `OpportunityList`, `CaseList`)
2. **Inspect** — Agent calls `Get Report Type Columns` to discover valid column API names for that type
3. **Create** — Agent calls `Create Report` with the report name, type, columns, groupings, and filters
4. **Deliver** — Agent returns the report URL to the user

**Editing a report:**

1. **Identify** — Agent uses the report's ID (if already known from this conversation) or its exact current name
2. **Change only what's asked** — Agent calls `Edit Report` passing only the fields that are actually changing; everything else on the report is preserved as-is
3. **Confirm** — Agent tells the user which fields changed (`fieldsUpdated`) and shares the report URL

## Setup

1. Click the **Deploy to Salesforce** button above
2. Assign the **WSM Report Builder Agent** permission set to your agent's running user
3. In Agent Builder, add the existing **Report Builder** topic to your agent — it's pre-configured with all four actions and their instructions, no manual setup needed
4. Activate the agent
5. Add your org's own domains to **Trusted URLs** (Setup → Security → Trusted URLs) so the agent can return report links. Agentforce redacts any URL in an agent response whose domain isn't on the trusted list (shown as `URL_Redacted`), and the report URL these actions emit uses the `URL.getOrgDomainUrl()` form. Add both, Context **All**:
   - `https://<mydomain>.my.salesforce.com` — the domain in the emitted report URL (**required**)
   - `https://<mydomain>.lightning.force.com` — the domain Lightning redirects to when the link is opened

### Required Permissions

The permission set grants these automatically. If assigning access manually instead, the running user needs:
- **Create and Customize Reports** (`CreateCustomizeReports`)
- **Run Reports** (`RunReports`)
- Access to the Analytics API (enabled by default in most orgs)

## Action Field Reference

### Create Salesforce Report (`AgentCreateReport`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `reportName` | String | **Yes** | Display name for the new report. Truncated to 40 characters if longer. |
| `reportType` | String | **Yes** | Report type API name from List Report Types (e.g., `CaseList`, `AccountList`, `Opportunity`). |
| `columns` | String | **Yes** | Comma-separated column API names from Get Report Type Columns. Do not include group-by columns — excluded automatically. |
| `reportFormat` | String | No | `TABULAR` (default), `SUMMARY`, or `MATRIX`. |
| `groupingsDown` | String | No | Comma-separated columns for row grouping. Required when format is `SUMMARY`/`MATRIX`. Max 3. |
| `groupingsAcross` | String | No | Comma-separated columns for column grouping (`MATRIX` only). Max 3. |
| `filterColumn` / `filterOperator` / `filterValue` | String | No | Single filter. Use `filtersJson` instead for multiple filters. |
| `filtersJson` | String | No | JSON array of filter objects, e.g. `[{"column":"STAGE_NAME","operator":"equals","value":"Closed Won"}]`. Takes precedence over the single filter fields. |
| `reportBooleanFilter` | String | No | Filter logic using 1-based indices, e.g. `"(1 OR 2) AND 3"`. Default is AND across all filters. |
| `dateFilter` | String | No | Standard date range, format `"FIELD:RANGE"` (e.g., `"CLOSE_DATE:THIS_FISCAL_YEAR"`). |
| `scope` | String | No | `"user"` (my records), `"team"`, or `"organization"` (default). |
| `folderName` | String | No | Report folder to save into. Defaults to the user's private folder; unknown folder names are silently ignored (report still saves to the default location). |
| `dateGranularity` | String | No | `Day`, `Month`, `Quarter`, `Year`, `FiscalQuarter`, `FiscalYear`, `None` (default). Applies to all date-type groupings. |
| `sortOrder` | String | No | `Asc` (default) or `Desc`. Applies to all groupings. |
| `crossFiltersJson` | String | No | JSON array of cross-filter objects for WITH/WITHOUT related-record filtering. |
| `bucketsJson` | String | No | JSON array of bucket field definitions. |
| `customDetailFormulasJson` | String | No | JSON array of row-level formula definitions, referenced in columns as `CDF1`, `CDF2`, etc. |
| `customSummaryFormulaJson` | String | No | JSON object for a single aggregate formula. `SUMMARY`/`MATRIX` only. |

**Outputs:** `success`, `reportId`, `reportUrl` (Lightning URL), `reportPath`, `reportName`, `errorMessage`

### Edit Salesforce Report (`AgentEditReport`)

Identify the report with **one of** `reportId` (preferred) or `reportName` (errors if zero or multiple reports share that name). Every other field is optional — only supplied fields are changed; anything you leave blank is preserved from the existing report.

| Field | Type | Notes |
|-------|------|-------|
| `reportId` | String | Preferred identifier — skips the name lookup. |
| `reportName` | String | Exact current name, used only to look up the report when `reportId` is omitted. |
| `newReportName` | String | Renames the report. Truncated to 40 characters. |
| `columns` | String | **Replaces** all detail columns. |
| `reportFormat` | String | `TABULAR`, `SUMMARY`, or `MATRIX`. If switching to (or already) `SUMMARY`/`MATRIX`, `groupingsDown` must exist — either newly supplied or already set on the report. |
| `groupingsDown` / `groupingsAcross` | String | **Replaces** existing groupings entirely. Max 3 each. |
| `dateGranularity` / `sortOrder` | String | Only applied to groupings set in the *same* call — no-op if groupings aren't also being changed. |
| `filterColumn` / `filterOperator` / `filterValue` | String | **Replaces** all existing filters with a single filter. |
| `filtersJson` | String | **Replaces** all existing filters. Takes precedence over the single filter fields. |
| `reportBooleanFilter` | String | Only applied when filters are also being replaced in the same call. |
| `dateFilter` | String | `"FIELD:RANGE"` to set, or the literal `"NONE"` to clear an existing date filter. |
| `scope` | String | `"user"`, `"team"`, or `"organization"`. |
| `folderName` | String | Moves the report to this folder — **errors** if the folder isn't found (unlike Create, which ignores unknown folders). |
| `crossFiltersJson` / `bucketsJson` / `customDetailFormulasJson` / `customSummaryFormulaJson` | String | Each **replaces** the existing value if provided. |

**Outputs:** `success`, `reportId`, `reportUrl`, `reportName` (current name), `fieldsUpdated` (comma-separated list of what changed), `errorMessage`

If no fields beyond the identifier are supplied, the action errors with `"No fields were provided to update"` and makes no changes.

### List Report Types (`AgentListReportTypes`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `filterKeyword` | String | No | Case-insensitive keyword filter. Leave blank to return all types. |
| `maxResults` | Number | No | Defaults to 50, max 200. |

**Outputs:** `reportTypesJson` (JSON array of `apiName`, `label`, `description`), `typeCount`, `success`, `errorMessage`

### Get Report Type Columns (`AgentGetReportTypeColumns`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `reportType` | String | **Yes** | Report type API name to inspect, from List Report Types. |
| `filterKeyword` | String | No | Case-insensitive filter on label or API name. Leave blank on the first call to see the full list. |
| `maxResults` | Number | No | Defaults to all columns. |

**Outputs:** `columnsJson` (JSON array of `apiName`, `label`), `defaultColumnsJson` (JSON array of the type's default column API names), `columnCount`, `success`, `errorMessage`

### Delete Report (`AgentDeleteReport`, internal only)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `reportId` | String | **Yes** | Salesforce ID of the report to delete. |

**Outputs:** `success`, `errorMessage`

## Example Prompts

Once wired to an Agentforce topic, users can say things like:

- *"Create a report showing open opportunities grouped by stage"*
- *"Build a cases report grouped by category"*
- *"Show me all accounts grouped by type"*
- *"Create a contacts report for accounts in the technology industry"*
- *"Add a priority column to the report you just made"*
- *"Change that to group by owner instead"*
- *"Rename my 'Open Cases' report to 'Open Cases - This Quarter' and filter it to this month"*
- *"Move the Q1 Pipeline report to the Sales Leadership folder"*

## File Inventory

```
force-app/main/default/
├── classes/
│   ├── AgentCreateReport.cls                  # Create action
│   ├── AgentCreateReport.cls-meta.xml
│   ├── AgentCreateReportTest.cls
│   ├── AgentCreateReportTest.cls-meta.xml
│   ├── AgentEditReport.cls                    # Edit action
│   ├── AgentEditReport.cls-meta.xml
│   ├── AgentEditReportTest.cls
│   ├── AgentEditReportTest.cls-meta.xml
│   ├── AgentDeleteReport.cls                  # Delete action (internal only)
│   ├── AgentDeleteReport.cls-meta.xml
│   ├── AgentDeleteReportTest.cls
│   ├── AgentDeleteReportTest.cls-meta.xml
│   ├── AgentListReportTypes.cls               # Report type discovery
│   ├── AgentListReportTypes.cls-meta.xml
│   ├── AgentListReportTypesTest.cls
│   ├── AgentListReportTypesTest.cls-meta.xml
│   ├── AgentGetReportTypeColumns.cls          # Column discovery
│   ├── AgentGetReportTypeColumns.cls-meta.xml
│   ├── AgentGetReportTypeColumnsTest.cls
│   └── AgentGetReportTypeColumnsTest.cls-meta.xml
├── flows/
│   ├── WSM_ALF_Agent_Create_Report.flow-meta.xml
│   ├── WSM_ALF_Agent_Edit_Report.flow-meta.xml
│   ├── WSM_ALF_Agent_List_Report_Types.flow-meta.xml
│   └── WSM_ALF_Agent_Get_Report_Type_Columns.flow-meta.xml
├── genAiFunctions/
│   ├── WSM_Agent_Create_Report/WSM_Agent_Create_Report.genAiFunction-meta.xml
│   ├── WSM_Agent_Edit_Report/WSM_Agent_Edit_Report.genAiFunction-meta.xml
│   ├── WSM_Agent_List_Report_Types/WSM_Agent_List_Report_Types.genAiFunction-meta.xml
│   └── WSM_Agent_Get_Report_Type_Columns/WSM_Agent_Get_Report_Type_Columns.genAiFunction-meta.xml
├── genAiPlugins/
│   └── WSM_Report_Builder.genAiPlugin-meta.xml  # "Report Builder" topic
├── permissionsets/
│   └── WSM_Report_Builder_Agent.permissionset-meta.xml
└── pages/
    ├── SessionId.page
    └── SessionId.page-meta.xml
```

## Author

Built by [We Summit Mountains](https://wesummitmountains.com) — a Salesforce consulting firm in Dallas, TX.
