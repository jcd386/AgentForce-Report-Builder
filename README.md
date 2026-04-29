# AgentForce Report Builder

Reusable Agentforce invocable actions that let AI agents create native Salesforce reports via the Analytics REST API. Give your agent the ability to build tabular and summary reports from natural language — no clicks required.

<a href="https://githubsfdeploy.herokuapp.com/app/githubdeploy/jcd386/AgentForce-Report-Builder?ref=main">
  <img alt="Deploy to Salesforce" src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

## What's Included

### Apex Invocable Actions

| Action | Description |
|--------|-------------|
| **AgentCreateReport** | Creates a native Salesforce report via the Analytics REST API. Supports TABULAR and SUMMARY formats with column selection, a single filter, and group-by field. Automatically clears the default date filter and sets scope to organization. |
| **AgentListReportTypes** | Queries the Analytics API for available report types. Returns a JSON array of `apiName`, `label`, and `description` for each type. Supports keyword filtering and result limits. |
| **AgentGetReportTypeColumns** | Discovers valid column API names for any report type by creating a temporary probe report, reading back its default columns, then deleting it. Returns a JSON array of `apiName` and `label` per column. |

### Autolaunched Flows (ALFs)

Flow wrappers for each Apex action — ready to add as Agentforce topic actions:

| Flow | Wraps |
|------|-------|
| **Agent - ALF - Create Report** | `AgentCreateReport` |
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

Create a single topic in Agent Builder with the following settings.

**Topic Label:** `Report Building`

**Classification Description:**
> Create Salesforce reports on any object by calling the Create Report action directly. Handles report type selection, column discovery via Get Report Type Columns, filters, groupings, and all report configuration through the Analytics REST API.

**Scope:**
> Create Salesforce reports and assist reps with reporting needs. Maps user requests to report types, columns, filters, and groupings, then creates reports directly via the Analytics REST API. Always follows the 4-step workflow: (1) identify report type, (2) discover columns via Get Report Type Columns for non-standard objects, (3) call Create Report, (4) return the report URL.

**Instructions** (add each as a separate instruction in Agent Builder):

| # | Instruction |
|---|-------------|
| 1 | You help users create Salesforce reports on any object they ask about — cases, accounts, opportunities, contacts, orders, leads, products, assets, campaigns, contracts, activities, custom objects. Always call "Create Report" directly. If the user's request is ambiguous (e.g., "customers" could mean accounts or contacts), state your interpretation before proceeding — e.g., "I'll create this as an Accounts report — let me know if you meant something else." |
| 2 | **How to Build Any Report (4-step workflow):** Step 1 — Determine the report type: If the object is one of the known types listed in instruction 3, use it directly (no lookup needed). Otherwise, call "List Report Types" with filterKeyword = the object name and pick the best-matching apiName. Step 2 — Determine the columns: If the type is one of the 6 core types (CaseList/AccountList/Opportunity/ContactList/LeadList/OrderList), use the hardcoded column list in instruction 4 (no lookup needed). For ANY other type, you MUST call "Get Report Type Columns" first and use ONLY apiName values from the response. Step 3 — Call "Create Report" with: reportName, reportType, columns (comma-separated, NOT including groupByColumn), optional filterColumn + filterOperator + filterValue, optional groupByColumn. Step 4 — Respond with the report name and a clickable link using reportUrl. Say: "Your report '{reportName}' is ready! [Open Report]({reportUrl})". If success=false, share the errorMessage and tell the user to create it manually. |
| 3 | **Report Type Selection — Known types (use directly, no lookup needed):** Cases → `CaseList`, Accounts → `AccountList`, Opportunities → `Opportunity`, Contacts → `ContactList`, Leads → `LeadList`, Orders → `OrderList`, Campaigns → `CampaignList`, Contracts → `ContractList`, Assets → `AssetWithProduct`, Products → `ProductList`, Price Books → `PricebookProduct`. For anything NOT in this list (Activities, custom objects like Invoice\_\_c, etc.), call "List Report Types" with filterKeyword = the object name the user mentioned. Use the apiName field from the results, NOT the label. CRITICAL: Report type API names are NOT the same as Salesforce object names. Never guess them. |
| 4 | **Column API Names — Known types (use directly, no lookup needed):** `CaseList`: CASE_NUMBER, SUBJECT, STATUS, PRIORITY, ORIGIN, ACCOUNT.NAME, AGE. `AccountList`: ACCOUNT.NAME, TYPE, RATING, USERS.NAME (note: very few columns available). `Opportunity`: OPPORTUNITY_NAME, AMOUNT, STAGE_NAME, CLOSE_DATE, ACCOUNT_NAME, FULL_NAME, TYPE, PROBABILITY, LEAD_SOURCE. `ContactList`: FIRST_NAME, LAST_NAME, ACCOUNT.NAME, TITLE, EMAIL, OWNER_FULL_NAME (use FIRST_NAME + LAST_NAME separately, NOT FULL_NAME). `LeadList`: FIRST_NAME, LAST_NAME, COMPANY, EMAIL, LEAD_SOURCE, RATING. `OrderList`: ORDER_NUMBER, ORDER_STATUS, ORDER_TOTAL_AMOUNT, ACCOUNT_NAME, ORDER_EFFECTIVE_DATE (NOT STATUS, TOTAL_AMOUNT, or EFFECTIVE_DATE). For CampaignList, ContractList, AssetWithProduct, ProductList, PricebookProduct, and all other types — you MUST call "Get Report Type Columns" to discover column names. Do NOT guess. |
| 5 | **Grouping and Filter Reference.** Grouping examples (groupByColumn accepts comma-separated values): CaseList by status → STATUS; by origin → ORIGIN. AccountList by type → TYPE; by rating → RATING. Opportunity by stage → STAGE_NAME; by stage and owner → STAGE_NAME,FULL_NAME. ContactList by account → ACCOUNT.NAME. LeadList by source → LEAD_SOURCE. Filter shorthand: "open cases" → filterColumn=CLOSED, filterOperator=equals, filterValue=0. "open opportunities" → filterColumn=STAGE_NAME, filterOperator=notEqual, filterValue=Closed Won. "closed won" → filterColumn=STAGE_NAME, filterOperator=equals, filterValue=Closed Won. Date ranges use filterOperator=equals with: THIS_MONTH, THIS_YEAR, LAST_MONTH, LAST_N_DAYS:90, TODAY, LAST_YEAR. IMPORTANT: Never put the groupByColumn value in the columns list — it causes an API error. For Opportunity reports, filter on STAGE_NAME, not IsClosed. |

**Actions** (add all three):
- `Agent - ALF - Create Report`
- `Agent - ALF - List Report Types`
- `Agent - ALF - Get Report Type Columns`

### Action Field Reference

#### Agent - ALF - Create Report

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `reportName` | String | **Yes** | Display name for the new report |
| `reportType` | String | **Yes** | Salesforce report type API name (e.g., `CaseList`, `AccountList`, `Opportunity`) |
| `columns` | String | No | Comma-separated column API names (e.g., `CASE_NUMBER,SUBJECT,STATUS,PRIORITY`). Do NOT include the groupByColumn here. |
| `filterColumn` | String | No | Column API name to filter on (e.g., `STATUS`, `CLOSED`) |
| `filterOperator` | String | No | Filter operator: `equals`, `notEqual`, `lessThan`, `greaterThan`, `contains`, `notContain`, `startsWith` |
| `filterValue` | String | No | Value to filter by (e.g., `Closed`, `0`) |
| `groupByColumn` | String | No | Column API name to group rows by. Supports comma-separated values for multi-level grouping (e.g., `STAGE_NAME,FULL_NAME`). Automatically switches format to SUMMARY. |

**Outputs:** `reportId`, `reportUrl` (Lightning URL), `createdReportName`, `success`, `errorMessage`

#### Agent - ALF - List Report Types

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `filterKeyword` | String | **Yes** | Keyword to filter report types. Case-insensitive. Example: "Opportunity" returns OpportunityList, OpportunityWithContact, etc. |
| `maxResults` | Number | No | Maximum number of report types to return. Defaults to 50. Max 200. |

**Outputs:** `reportTypesJson` (JSON array of `apiName`, `label`, `description`), `typeCount`, `success`, `errorMessage`

#### Agent - ALF - Get Report Type Columns

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `reportType` | String | **Yes** | The report type API name to inspect (e.g., `CaseList`, `OpportunityList`). Get this from the List Report Types action. |

**Outputs:** `columnsJson` (JSON array of `apiName`, `label`), `defaultColumnsJson` (JSON array of default column API names), `columnCount`, `success`, `errorMessage`

## Example Prompts

Once wired to an Agentforce topic, users can say things like:

- *"Create a report showing open opportunities grouped by stage"*
- *"Build a cases report grouped by category"*
- *"Show me all accounts grouped by type"*
- *"Create a contacts report for accounts in the technology industry"*

## File Inventory

```
force-app/main/default/
├── classes/
│   ├── AgentCreateReport.cls              # Core report creation action
│   ├── AgentCreateReport.cls-meta.xml
│   ├── AgentCreateReportTest.cls          # Test class
│   ├── AgentCreateReportTest.cls-meta.xml
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
