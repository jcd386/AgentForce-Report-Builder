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
    }

    public class Output {
        @InvocableVariable(
            label='Columns JSON'
            description='JSON array of available columns for the report type. Each element has "apiName" (use in Create Report columns input) and "label" (human-readable name). Select only the apiName values relevant to what the user asked for — do not pass all columns.'
        )
        public String columnsJson;

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

            // Step 1: Create a temporary report with empty detailColumns.
            // Salesforce auto-populates detailColumns with all valid defaults for the type.
            Map<String, Object> requestBody = new Map<String, Object>{
                'reportMetadata' => new Map<String, Object>{
                    'name'          => 'TEMP_PROBE_' + reportType + '_' + System.now().getTime(),
                    'reportType'    => new Map<String, Object>{ 'type' => reportType },
                    'reportFormat'  => 'TABULAR',
                    'detailColumns' => new List<String>()
                }
            };

            HttpRequest createReq = new HttpRequest();
            createReq.setEndpoint(baseUrl + '/services/data/' + API_VERSION + '/analytics/reports');
            createReq.setMethod('POST');
            createReq.setHeader('Authorization', 'Bearer ' + sessionId);
            createReq.setHeader('Content-Type', 'application/json');
            createReq.setBody(JSON.serialize(requestBody));

            HttpResponse createRes = new Http().send(createReq);

            if (createRes.getStatusCode() != 200 && createRes.getStatusCode() != 201) {
                output.success = false;
                output.errorMessage = 'Could not probe report type ' + reportType
                    + ' (HTTP ' + createRes.getStatusCode() + '): '
                    + createRes.getBody().abbreviate(200);
                output.columnCount = 0;
                output.columnsJson = '[]';
                return output;
            }

            Map<String, Object> createBody = (Map<String, Object>) JSON.deserializeUntyped(createRes.getBody());
            Map<String, Object> attrs = (Map<String, Object>) createBody.get('attributes');
            String reportId = attrs != null ? String.valueOf(attrs.get('reportId')) : null;

            // Step 2: Read back the detailColumns Salesforce assigned.
            Map<String, Object> meta = (Map<String, Object>) createBody.get('reportMetadata');
            List<String> detailCols = new List<String>();
            if (meta != null && meta.containsKey('detailColumns')) {
                for (Object col : (List<Object>) meta.get('detailColumns')) {
                    detailCols.add(String.valueOf(col));
                }
            }

            // Step 3: Delete the temp report (best-effort, don't fail if delete fails).
            if (String.isNotBlank(reportId)) {
                HttpRequest delReq = new HttpRequest();
                delReq.setEndpoint(baseUrl + '/services/data/' + API_VERSION + '/analytics/reports/' + reportId);
                delReq.setMethod('DELETE');
                delReq.setHeader('Authorization', 'Bearer ' + sessionId);
                new Http().send(delReq);
            }

            // Step 4: Build output — each column gets an apiName entry.
            // Labels are the same as apiName since the describe endpoint doesn't return labels
            // for standard types; the LLM can match apiName to user intent directly.
            List<Map<String, String>> columns = new List<Map<String, String>>();
            for (String col : detailCols) {
                columns.add(new Map<String, String>{ 'apiName' => col, 'label' => col });
            }

            output.columnsJson = JSON.serialize(columns);
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
    private static String getSessionId() {
        String sessionId = UserInfo.getSessionId();
        if (String.isBlank(sessionId)) {
            sessionId = Test.isRunningTest() ? 'TEST_SESSION_ID' : Page.SessionId.getContent().toString().trim();
        }
        return sessionId;
    }
}
