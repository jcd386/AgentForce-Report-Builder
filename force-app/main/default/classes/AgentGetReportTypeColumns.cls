/**
 * AgentGetReportTypeColumns
 * Invocable action that discovers valid column API names for any Salesforce report type.
 *
 * Strategy: the GET /analytics/reportTypes/{type} endpoint returns empty column data
 * for standard types. Instead, we create a temporary report with empty detailColumns,
 * read back the default columns Salesforce assigns, then immediately delete the temp report.
 * This reliably returns the full list of available columns for any report type.
 */
public with sharing class AgentGetReportTypeColumns {

    private static final String API_VERSION = 'v65.0';

    public class Input {
        @InvocableVariable(
            required=true
            label='Report Type API Name'
            description='The report type API name to inspect. Example: CampaignList, ProductList, ContractList. Obtain this from List Report Types.'
        )
        public String reportType;

        @InvocableVariable(
            required=false
            label='Filter Keyword'
            description='Optional keyword to filter columns by label or API name. Case-insensitive. Example: "Amount" returns only columns containing "Amount". Leave blank to return all columns.'
        )
        public String filterKeyword;

        @InvocableVariable(
            required=false
            label='Max Results'
            description='Maximum number of columns to return. Defaults to all columns if not provided. Use lower values to reduce response size when browsing.'
        )
        public Integer maxResults;
    }

    public class Output {
        @InvocableVariable(
            label='Columns JSON'
            description='JSON array of available columns for the report type. Each element has "apiName" (use in Create Report columns input) and "label" (human-readable name). Select only the apiName values relevant to what the user asked for — do not pass all columns.'
        )
        public String columnsJson;

        @InvocableVariable(
            label='Default Columns JSON'
            description='JSON array of column API names that are in the default column set for this report type. These are the columns Salesforce uses by default when creating a report of this type.'
        )
        public String defaultColumnsJson;

        @InvocableVariable(
            label='Column Count'
            description='Number of columns returned. Use to confirm results before building the report.'
        )
        public Integer columnCount;

        @InvocableVariable(
            label='Success'
            description='True if columns were retrieved successfully, false if an error occurred.'
        )
        public Boolean success;

        @InvocableVariable(
            label='Error Message'
            description='Error details when success is false. Common causes: invalid report type name, session timeout, or insufficient permissions.'
        )
        public String errorMessage;
    }

    @InvocableMethod(
        label='Get Report Type Columns'
        description='Returns valid column API names for any Salesforce report type by creating a temporary probe report and reading back the default columns. Call this after List Report Types to discover which columns are available. Then pass only the relevant apiName values (comma-separated) to Create Report — not all of them.'
        category='Agent Reporting'
        callout=true
    )
    public static List<Output> getColumns(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        for (Input input : inputs) {
            outputs.add(processInput(input));
        }
        return outputs;
    }

    @TestVisible
    private static Output processInput(Input input) {
        Output output = new Output();
        try {
            if (input == null || String.isBlank(input.reportType)) {
                output.success = false;
                output.errorMessage = 'reportType is required.';
                output.columnCount = 0;
                output.columnsJson = '[]';
                return output;
            }

            String reportType = input.reportType.trim();
            String sessionId = getSessionId();
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();

            // Use the GET /analytics/reportTypes/{type} endpoint to discover columns.
            // This avoids the probe-create-read-delete approach which fails on:
            //   - Heavily customized report types (>100 default columns exceeds the report column limit)
            //   - Long report type API names (probe report name exceeds 40 char limit)
            //   - Report types that require folder permissions to probe
            HttpRequest describeReq = new HttpRequest();
            describeReq.setEndpoint(baseUrl + '/services/data/' + API_VERSION + '/analytics/reportTypes/' + reportType);
            describeReq.setMethod('GET');
            describeReq.setHeader('Authorization', 'Bearer ' + sessionId);
            describeReq.setTimeout(30000);

            HttpResponse describeRes = new Http().send(describeReq);

            if (describeRes.getStatusCode() != 200) {
                output.success = false;
                output.errorMessage = 'Could not describe report type ' + reportType
                    + ' (HTTP ' + describeRes.getStatusCode() + '): '
                    + describeRes.getBody().abbreviate(200);
                output.columnCount = 0;
                output.columnsJson = '[]';
                return output;
            }

            Map<String, Object> describeBody = (Map<String, Object>) JSON.deserializeUntyped(describeRes.getBody());

            // Extract available columns. Standard report types put them in reportExtendedMetadata.detailColumnInfo;
            // custom report types only put DEFAULT columns there (often just 1) and put the FULL available set in
            // reportTypeMetadata.categories[*].columns. We read both and merge so the agent sees every valid column.
            List<Map<String, String>> columns = new List<Map<String, String>>();
            Set<String> seen = new Set<String>();
            if (describeBody.containsKey('reportExtendedMetadata')) {
                Map<String, Object> extMeta = (Map<String, Object>) describeBody.get('reportExtendedMetadata');
                Map<String, Object> detailColInfo = (Map<String, Object>) extMeta.get('detailColumnInfo');
                if (detailColInfo != null) {
                    for (String apiName : detailColInfo.keySet()) {
                        Map<String, Object> colMeta = (Map<String, Object>) detailColInfo.get(apiName);
                        String label = colMeta != null && colMeta.get('label') != null
                            ? String.valueOf(colMeta.get('label'))
                            : apiName;
                        columns.add(new Map<String, String>{ 'apiName' => apiName, 'label' => label });
                        seen.add(apiName);
                    }
                }
            }
            if (describeBody.containsKey('reportTypeMetadata')) {
                Map<String, Object> rtMeta = (Map<String, Object>) describeBody.get('reportTypeMetadata');
                Object catsRaw = rtMeta.get('categories');
                if (catsRaw instanceof List<Object>) {
                    for (Object catObj : (List<Object>) catsRaw) {
                        Map<String, Object> cat = (Map<String, Object>) catObj;
                        Map<String, Object> catCols = (Map<String, Object>) cat.get('columns');
                        if (catCols == null) continue;
                        for (String apiName : catCols.keySet()) {
                            if (seen.contains(apiName)) continue;
                            Map<String, Object> colMeta = (Map<String, Object>) catCols.get(apiName);
                            String label = colMeta != null && colMeta.get('label') != null
                                ? String.valueOf(colMeta.get('label'))
                                : apiName;
                            columns.add(new Map<String, String>{ 'apiName' => apiName, 'label' => label });
                            seen.add(apiName);
                        }
                    }
                }
            }

            // Extract the default column set from reportMetadata.detailColumns
            List<String> defaultCols = new List<String>();
            if (describeBody.containsKey('reportMetadata')) {
                Map<String, Object> reportMeta = (Map<String, Object>) describeBody.get('reportMetadata');
                if (reportMeta.containsKey('detailColumns') && reportMeta.get('detailColumns') != null) {
                    for (Object col : (List<Object>) reportMeta.get('detailColumns')) {
                        defaultCols.add(String.valueOf(col));
                    }
                }
            }

            if (input.filterKeyword != null && String.isNotBlank(input.filterKeyword)) {
                columns = filterByKeyword(columns, input.filterKeyword.trim());
            }
            if (input.maxResults != null && input.maxResults > 0 && columns.size() > input.maxResults) {
                while (columns.size() > input.maxResults) {
                    columns.remove(columns.size() - 1);
                }
            }

            output.columnsJson = JSON.serialize(columns);
            output.defaultColumnsJson = JSON.serialize(defaultCols);
            output.columnCount = columns.size();
            output.success = true;


        } catch (Exception e) {
            output.success = false;
            output.errorMessage = 'Error getting report type columns: ' + e.getMessage();
            output.columnCount = 0;
            output.columnsJson = '[]';
        }
        return output;
    }

    @TestVisible
    private static List<Map<String, String>> filterByKeyword(
        List<Map<String, String>> columns, String keyword
    ) {
        String lower = keyword.toLowerCase();
        List<Map<String, String>> filtered = new List<Map<String, String>>();
        for (Map<String, String> col : columns) {
            String label = col.get('label') != null ? col.get('label').toLowerCase() : '';
            String apiName = col.get('apiName') != null ? col.get('apiName').toLowerCase() : '';
            if (label.contains(lower) || apiName.contains(lower)) {
                filtered.add(col);
            }
        }
        return filtered;
    }

    @TestVisible
    private static String getSessionId() {
        String sessionId = UserInfo.getSessionId();
        if (String.isBlank(sessionId)) {
            sessionId = Test.isRunningTest() ? 'TEST_SESSION_ID' : Page.SessionId.getContent().toString().trim();
        }
        return sessionId;
    }
}