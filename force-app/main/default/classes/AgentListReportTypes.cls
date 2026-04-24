public with sharing class AgentListReportTypes {

    private static final String API_VERSION = 'v65.0';
    private static final Integer DEFAULT_MAX_RESULTS = 50;
    private static final Integer HARD_MAX_RESULTS = 200;

    public class Input {
        @InvocableVariable(
            label='Filter Keyword'
            description='Optional keyword to filter report types by label or API name. Case-insensitive. For example, "Opportunity" returns only report types whose label or API name contains "Opportunity". Leave blank to return all available report types.'
        )
        public String filterKeyword;

        @InvocableVariable(
            label='Max Results'
            description='Maximum number of report types to return. Defaults to 50 if not provided. Maximum allowed value is 200. Use lower values when you only need to browse a few types to reduce token usage.'
        )
        public Integer maxResults;
    }

    public class Output {
        @InvocableVariable(
            label='Report Types JSON'
            description='JSON array of available report type objects. Each element contains "apiName" (the value to use when creating a report), "label" (the human-readable display name), and "description" (what kind of data the report type covers). Use "apiName" as the reportType value when calling the Create Report action.'
        )
        public String reportTypesJson;

        @InvocableVariable(
            label='Type Count'
            description='Number of report types returned in reportTypesJson. Use this to confirm results were found before passing apiName values downstream.'
        )
        public Integer typeCount;

        @InvocableVariable(
            label='Success'
            description='True if the report types were retrieved successfully, false if an error occurred. Always check this before using reportTypesJson.'
        )
        public Boolean success;

        @InvocableVariable(
            label='Error Message'
            description='Description of the error if success is false. Empty when success is true. Common causes: session timeout, insufficient permissions, or the Analytics API being unavailable.'
        )
        public String errorMessage;
    }

    @InvocableMethod(
        label='List Report Types'
        description='Lists available Salesforce report types by querying the Analytics REST API. Use this before creating a report to discover valid reportType values. Optionally filter by a keyword to narrow results. Returns a JSON array with apiName, label, and description for each type.'
        category='Agent Reporting'
        callout=true
    )
    public static List<Output> listReportTypes(List<Input> inputs) {
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
            Integer maxResults = (input == null || input.maxResults == null)
                ? DEFAULT_MAX_RESULTS
                : input.maxResults;
            maxResults = Math.max(1, Math.min(maxResults, HARD_MAX_RESULTS));

            String filterKeyword = (input == null) ? null : input.filterKeyword;

            HttpResponse res = doCallout('/analytics/reportTypes');

            if (res.getStatusCode() != 200) {
                output.success = false;
                output.errorMessage = 'Analytics API returned HTTP ' + res.getStatusCode()
                    + ': ' + res.getBody();
                output.typeCount = 0;
                output.reportTypesJson = '[]';
                return output;
            }

            List<Map<String, String>> reportTypes = parseReportTypes(res.getBody());

            if (String.isNotBlank(filterKeyword)) {
                reportTypes = filterByKeyword(reportTypes, filterKeyword.trim());
            }

            while (reportTypes.size() > maxResults) {
                reportTypes.remove(reportTypes.size() - 1);
            }

            output.reportTypesJson = JSON.serialize(reportTypes);
            output.typeCount = reportTypes.size();
            output.success = true;

        } catch (Exception e) {
            output.success = false;
            output.errorMessage = 'Error listing report types: ' + e.getMessage();
            output.typeCount = 0;
            output.reportTypesJson = '[]';
        }
        return output;
    }

    @TestVisible
    private static HttpResponse doCallout(String path) {
        String sessionId = UserInfo.getSessionId();
        if (String.isBlank(sessionId)) {
            sessionId = Test.isRunningTest() ? 'TEST_SESSION_ID' : Page.SessionId.getContent().toString().trim();
        }
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(baseUrl + '/services/data/' + API_VERSION + path);
        req.setHeader('Authorization', 'Bearer ' + sessionId);
        req.setHeader('Content-Type', 'application/json');
        return new Http().send(req);
    }

    @TestVisible
    private static List<Map<String, String>> parseReportTypes(String responseBody) {
        List<Map<String, String>> result = new List<Map<String, String>>();
        if (String.isBlank(responseBody)) {
            return result;
        }

        List<Object> rawList = (List<Object>) JSON.deserializeUntyped(responseBody);
        for (Object item : rawList) {
            Map<String, Object> rawMap = (Map<String, Object>) item;
            // The Analytics API returns a grouped structure:
            // [{label: "Group Name", reportTypes: [{type, label, description}, ...]}, ...]
            // Handle both grouped (has reportTypes key) and flat (has type key) formats.
            if (rawMap.containsKey('reportTypes')) {
                List<Object> types = (List<Object>) rawMap.get('reportTypes');
                if (types != null) {
                    for (Object typeItem : types) {
                        Map<String, Object> t = (Map<String, Object>) typeItem;
                        Map<String, String> entry = new Map<String, String>();
                        entry.put('apiName', t.containsKey('type') ? String.valueOf(t.get('type')) : '');
                        entry.put('label', t.containsKey('label') ? String.valueOf(t.get('label')) : '');
                        Object descVal = t.get('description');
                        entry.put('description', descVal != null ? String.valueOf(descVal) : '');
                        result.add(entry);
                    }
                }
            } else {
                // Flat format fallback
                Map<String, String> entry = new Map<String, String>();
                entry.put('apiName', rawMap.containsKey('type') ? String.valueOf(rawMap.get('type')) : '');
                entry.put('label', rawMap.containsKey('label') ? String.valueOf(rawMap.get('label')) : '');
                Object descVal = rawMap.get('description');
                entry.put('description', descVal != null ? String.valueOf(descVal) : '');
                result.add(entry);
            }
        }
        return result;
    }

    @TestVisible
    private static List<Map<String, String>> filterByKeyword(
        List<Map<String, String>> reportTypes,
        String keyword
    ) {
        String lower = keyword.toLowerCase();
        List<Map<String, String>> filtered = new List<Map<String, String>>();
        for (Map<String, String> entry : reportTypes) {
            String label = entry.get('label') != null ? entry.get('label').toLowerCase() : '';
            String apiName = entry.get('apiName') != null ? entry.get('apiName').toLowerCase() : '';
            if (label.contains(lower) || apiName.contains(lower)) {
                filtered.add(entry);
            }
        }
        return filtered;
    }
}