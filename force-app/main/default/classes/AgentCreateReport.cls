/**
 * AgentCreateReport
 * Invocable action that creates a Salesforce report via the Analytics REST API.
 * Used by the Report Builder Agentforce agent.
 */
public with sharing class AgentCreateReport {

    @InvocableMethod(
        label='Create Salesforce Report'
        description='Creates a new Salesforce report using the Analytics REST API. Pass the report name, type, columns, optional filter, and optional group-by field.'
    )
    public static List<Output> createReport(List<Input> inputs) {
        List<Output> results = new List<Output>();
        for (Input inp : inputs) {
            results.add(execute(inp));
        }
        return results;
    }

    private static Output execute(Input inp) {
        Output out = new Output();
        try {
            // Parse group-by columns (comma-separated, e.g. "STAGE_NAME,OWNER_NAME")
            List<String> groupByCols = new List<String>();
            if (String.isNotBlank(inp.groupByColumn)) {
                for (String g : inp.groupByColumn.split(',')) {
                    String gt = g.trim();
                    if (String.isNotBlank(gt)) groupByCols.add(gt);
                }
            }
            Set<String> groupBySet = new Set<String>(groupByCols);

            // Build detail columns list (exclude all group-by columns to avoid API error)
            List<String> detailCols = new List<String>();
            if (String.isNotBlank(inp.columns)) {
                for (String col : inp.columns.split(',')) {
                    String trimmed = col.trim();
                    if (String.isNotBlank(trimmed) && !groupBySet.contains(trimmed)) {
                        detailCols.add(trimmed);
                    }
                }
            }

            // Build report metadata map
            Map<String, Object> reportType = new Map<String, Object>{ 'type' => inp.reportType };
            Map<String, Object> metadata = new Map<String, Object>{
                'name'          => inp.reportName,
                'reportType'    => reportType,
                'reportFormat'  => String.isNotBlank(inp.groupByColumn) ? 'SUMMARY' : 'TABULAR',
                'detailColumns' => detailCols
            };

            // Add filter if provided
            if (String.isNotBlank(inp.filterColumn) && String.isNotBlank(inp.filterOperator)) {
                Map<String, Object> filter = new Map<String, Object>{
                    'column'   => inp.filterColumn,
                    'operator' => inp.filterOperator,
                    'value'    => inp.filterValue != null ? inp.filterValue : ''
                };
                metadata.put('reportFilters', new List<Object>{ filter });
            }

            // Add groupings if provided (supports comma-separated multi-grouping)
            if (!groupByCols.isEmpty()) {
                List<Object> groupings = new List<Object>();
                for (String gc : groupByCols) {
                    groupings.add(new Map<String, Object>{
                        'name'          => gc,
                        'sortAggregate' => null,
                        'sortOrder'     => 'Asc'
                    });
                }
                metadata.put('groupingsDown', groupings);
            }

            Map<String, Object> requestBody = new Map<String, Object>{
                'reportMetadata' => metadata
            };

            // Call Analytics REST API
            // UserInfo.getSessionId() returns null in async/agent contexts. Fall back to VF page trick.
            String sessionId = UserInfo.getSessionId();
            if (String.isBlank(sessionId)) {
                sessionId = Test.isRunningTest() ? 'TEST_SESSION_ID' : Page.SessionId.getContent().toString().trim();
            }
            HttpRequest req = new HttpRequest();
            String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
            req.setEndpoint(baseUrl + '/services/data/v65.0/analytics/reports');
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + sessionId);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(requestBody));

            HttpResponse res = new Http().send(req);

            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> attrs = (Map<String, Object>) result.get('attributes');
                String reportId = (String) attrs.get('reportId');

                String reportEndpoint = baseUrl + '/services/data/v65.0/analytics/reports/' + reportId;
                Map<String, Object> createdMeta = (Map<String, Object>) result.get('reportMetadata');
                if (createdMeta != null) {
                    // PATCH 1: date filter — always works across all report types
                    Map<String, Object> sdf = (Map<String, Object>) createdMeta.get('standardDateFilter');
                    if (sdf != null) {
                        sdf.put('durationValue', 'CUSTOM');
                        sdf.put('startDate', null);
                        sdf.put('endDate', null);
                        HttpRequest dateReq = new HttpRequest();
                        dateReq.setEndpoint(reportEndpoint);
                        dateReq.setMethod('PATCH');
                        dateReq.setHeader('Authorization', 'Bearer ' + sessionId);
                        dateReq.setHeader('Content-Type', 'application/json');
                        dateReq.setBody(JSON.serialize(new Map<String, Object>{
                            'reportMetadata' => new Map<String, Object>{ 'standardDateFilter' => sdf }
                        }));
                        new Http().send(dateReq); // best-effort
                    }
                    // PATCH 2: scope — try 'organization' first (most types), fall back to 'org' (LeadList)
                    for (String scopeVal : new List<String>{'organization', 'org'}) {
                        HttpRequest scopeReq = new HttpRequest();
                        scopeReq.setEndpoint(reportEndpoint);
                        scopeReq.setMethod('PATCH');
                        scopeReq.setHeader('Authorization', 'Bearer ' + sessionId);
                        scopeReq.setHeader('Content-Type', 'application/json');
                        scopeReq.setBody('{"reportMetadata":{"scope":"' + scopeVal + '"}}');
                        HttpResponse scopeRes = new Http().send(scopeReq);
                        if (scopeRes.getStatusCode() == 200) break;
                    }
                }

                out.success = true;
                out.reportId = reportId;
                // Use lightning.force.com domain for browser-accessible URLs.
                // getOrgDomainUrl() returns the API my-domain (*.my.salesforce.com);
                // replace with lightning.force.com so the link works in the browser.
                String lightningBase = baseUrl.replace('.my.salesforce.com', '.lightning.force.com');
                out.reportUrl = lightningBase + '/lightning/r/Report/' + reportId + '/view?queryScope=userFolders';
                out.reportPath = '/lightning/r/Report/' + reportId + '/view?queryScope=userFolders';
                out.reportName = (String) attrs.get('reportName');
            } else {
                String errBody = res.getBody();
                out.success = false;
                out.errorMessage = 'API error ' + res.getStatusCode() + ': ' + errBody.abbreviate(300);
            }
        } catch (Exception e) {
            out.success = false;
            out.errorMessage = e.getMessage();
        }
        return out;
    }

    public class Input {
        @InvocableVariable(required=true label='Report Name' description='Display name for the new report')
        public String reportName;

        @InvocableVariable(required=true label='Report Type' description='Salesforce report type API name. Examples: CaseList, AccountList, Opportunity, ContactList, OrderList, OpportunityProduct, LeadList, AccountContact')
        public String reportType;

        @InvocableVariable(required=false label='Columns (comma-separated)' description='Column API names to include. Examples: CASE_NUMBER,SUBJECT,STATUS,PRIORITY or ACCOUNT.NAME,AMOUNT,STAGE_NAME')
        public String columns;

        @InvocableVariable(required=false label='Filter Column' description='Column API name to filter on. Example: STATUS or CLOSED')
        public String filterColumn;

        @InvocableVariable(required=false label='Filter Operator' description='Filter operator. Values: equals, notEqual, lessThan, greaterThan, lessOrEqual, greaterOrEqual, contains, notContain, startsWith, includes, excludes')
        public String filterOperator;

        @InvocableVariable(required=false label='Filter Value' description='Value to filter by. Example: Closed or 0')
        public String filterValue;

        @InvocableVariable(required=false label='Group By Column' description='Column API name to group rows by in a Summary report. Example: Case.Case_Category__c or STAGE_NAME')
        public String groupByColumn;
    }

    public class Output {
        @InvocableVariable
        public Boolean success;

        @InvocableVariable
        public String reportId;

        @InvocableVariable
        public String reportUrl;

        @InvocableVariable(label='Report Path' description='Relative path to the report, e.g. /lightning/r/Report/00O.../view. Use this as a fallback when the full URL is unavailable.')
        public String reportPath;

        @InvocableVariable
        public String reportName;

        @InvocableVariable
        public String errorMessage;
    }
}
