public with sharing class AgentReportCreate {

    private static final String API_VERSION = 'v65.0';

    public class Input {
        @InvocableVariable(
            required=true
            label='Report Name'
            description='Human-readable name for the report. Example: "Open Opportunities by Stage". Must be unique within the folder.'
        )
        public String reportName;

        @InvocableVariable(
            required=true
            label='Report Type'
            description='The API name of the report type. Common values: AccountList, OpportunityList, ContactList, CaseList, LeadList. Use the "List Report Types" action to discover available types.'
        )
        public String reportType;

        @InvocableVariable(
            required=true
            label='Detail Columns'
            description='Comma-separated list of field API names to include as columns. Use the report-type column format (e.g., ACCOUNT.NAME, OPPORTUNITY.AMOUNT, CONTACT.EMAIL). Use the "Describe Object Schema" action to find valid field API names.'
        )
        public String detailColumns;

        @InvocableVariable(
            label='Report Format'
            description='TABULAR (flat list, default), SUMMARY (grouped with subtotals), or MATRIX (row and column groupings).'
        )
        public String reportFormat;

        @InvocableVariable(
            label='Groupings Down'
            description='Comma-separated field API names for row groupings. Required when reportFormat is SUMMARY or MATRIX. Maximum 3 groupings.'
        )
        public String groupingsDown;

        @InvocableVariable(
            label='Groupings Across'
            description='Comma-separated field API names for column groupings. Only used when reportFormat is MATRIX. Maximum 3 groupings.'
        )
        public String groupingsAcross;

        @InvocableVariable(
            label='Filters JSON'
            description='JSON array of filter objects. Each has: column (field API name), operator (equals, notEqual, greaterThan, lessThan, contains, startsWith), value. Example: [{"column":"OPPORTUNITY.STAGE_NAME","operator":"equals","value":"Closed Won"}]'
        )
        public String filtersJson;

        @InvocableVariable(
            label='Date Filter'
            description='Standard date filter. Format: "FIELD:RANGE" where RANGE is THIS_FISCAL_QUARTER, LAST_FISCAL_QUARTER, THIS_FISCAL_YEAR, LAST_FISCAL_YEAR, THIS_MONTH, LAST_MONTH, LAST_30_DAYS, LAST_90_DAYS, CUSTOM. Example: "CLOSE_DATE:THIS_FISCAL_YEAR"'
        )
        public String dateFilter;

        @InvocableVariable(
            label='Folder Name'
            description='Name of the report folder to save the report in. Leave blank for the user\'s private reports folder.'
        )
        public String folderName;
    }

    public class Output {
        @InvocableVariable(label='Report ID' description='Salesforce ID of the created report.')
        public String reportId;

        @InvocableVariable(label='Report URL' description='Lightning URL to view the report in Salesforce.')
        public String reportUrl;

        @InvocableVariable(label='Success' description='True if the report was created successfully, false otherwise.')
        public Boolean success;

        @InvocableVariable(label='Error Message' description='Error details when success is false. Empty when success is true.')
        public String errorMessage;
    }

    @InvocableMethod(
        label='Create Report'
        description='Creates a native Salesforce report using the Analytics API. Provide a report name, report type, and column list at minimum. Use "List Report Types" first to find the correct report type. Use "Describe Object Schema" to find valid field API names for columns and filters.'
        category='Agent Reporting'
        callout=true
    )
    public static List<Output> createReport(List<Input> inputs) {
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
            // Validate required fields
            if (String.isBlank(input.reportName)) {
                output.success = false;
                output.errorMessage = 'reportName is required';
                return output;
            }
            if (String.isBlank(input.reportType)) {
                output.success = false;
                output.errorMessage = 'reportType is required';
                return output;
            }
            if (String.isBlank(input.detailColumns)) {
                output.success = false;
                output.errorMessage = 'detailColumns is required';
                return output;
            }

            // Default and validate reportFormat
            String fmt = String.isBlank(input.reportFormat) ? 'TABULAR' : input.reportFormat.toUpperCase().trim();
            if (fmt != 'TABULAR' && fmt != 'SUMMARY' && fmt != 'MATRIX') {
                output.success = false;
                output.errorMessage = 'reportFormat must be TABULAR, SUMMARY, or MATRIX. Received: ' + input.reportFormat;
                return output;
            }

            // Validate grouping requirements
            if ((fmt == 'SUMMARY' || fmt == 'MATRIX') && String.isBlank(input.groupingsDown)) {
                output.success = false;
                output.errorMessage = 'groupingsDown is required when reportFormat is ' + fmt;
                return output;
            }

            // Resolve folder ID
            String folderId = null;
            if (!String.isBlank(input.folderName)) {
                folderId = resolveFolderId(input.folderName);
            }

            // Build metadata JSON and POST
            String body = buildReportMetadata(input, fmt, folderId);
            HttpResponse res = doCallout('POST', '/analytics/reports', body);

            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> meta = (Map<String, Object>) root.get('reportMetadata');
                String rId = (String) meta.get('id');
                String baseUrl = URL.getOrgDomainUrl().toExternalForm();
                output.reportId = rId;
                output.reportUrl = baseUrl + '/lightning/r/Report/' + rId + '/view';
                output.success = true;
            } else {
                output.success = false;
                output.errorMessage = 'Analytics API error ' + res.getStatusCode() + ': ' + res.getBody();
            }
        } catch (Exception e) {
            output.success = false;
            output.errorMessage = 'Unexpected error: ' + e.getMessage();
        }
        return output;
    }

    @TestVisible
    private static String buildReportMetadata(Input input, String fmt, String folderId) {
        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartObject();
            gen.writeFieldName('reportMetadata');
            gen.writeStartObject();
                gen.writeStringField('name', input.reportName);
                gen.writeStringField('developerName', sanitizeDeveloperName(input.reportName));
                gen.writeStringField('reportFormat', fmt);

                // reportType object
                gen.writeFieldName('reportType');
                gen.writeStartObject();
                    gen.writeStringField('type', input.reportType);
                gen.writeEndObject();

                // detailColumns array
                List<String> cols = splitTrimmed(input.detailColumns);
                gen.writeFieldName('detailColumns');
                gen.writeStartArray();
                for (String col : cols) {
                    gen.writeString(col);
                }
                gen.writeEndArray();

                // groupingsDown
                if (!String.isBlank(input.groupingsDown)) {
                    List<String> groupsDown = splitTrimmed(input.groupingsDown);
                    gen.writeFieldName('groupingsDown');
                    gen.writeStartArray();
                    for (String g : groupsDown) {
                        gen.writeStartObject();
                            gen.writeStringField('name', g);
                            gen.writeStringField('sortOrder', 'Asc');
                            gen.writeStringField('dateGranularity', 'None');
                        gen.writeEndObject();
                    }
                    gen.writeEndArray();
                }

                // groupingsAcross
                if (!String.isBlank(input.groupingsAcross)) {
                    List<String> groupsAcross = splitTrimmed(input.groupingsAcross);
                    gen.writeFieldName('groupingsAcross');
                    gen.writeStartArray();
                    for (String g : groupsAcross) {
                        gen.writeStartObject();
                            gen.writeStringField('name', g);
                            gen.writeStringField('sortOrder', 'Asc');
                            gen.writeStringField('dateGranularity', 'None');
                        gen.writeEndObject();
                    }
                    gen.writeEndArray();
                }

                // reportFilters
                if (!String.isBlank(input.filtersJson)) {
                    List<Object> rawFilters = (List<Object>) JSON.deserializeUntyped(input.filtersJson);
                    gen.writeFieldName('reportFilters');
                    gen.writeStartArray();
                    for (Object rawFilter : rawFilters) {
                        Map<String, Object> f = (Map<String, Object>) rawFilter;
                        gen.writeStartObject();
                            gen.writeStringField('column', (String) f.get('column'));
                            gen.writeStringField('operator', (String) f.get('operator'));
                            gen.writeStringField('value', (String) f.get('value'));
                        gen.writeEndObject();
                    }
                    gen.writeEndArray();
                }

                // standardDateFilter — expects "FIELD:RANGE"
                if (!String.isBlank(input.dateFilter) && input.dateFilter.contains(':')) {
                    List<String> parts = input.dateFilter.split(':', 2);
                    gen.writeFieldName('standardDateFilter');
                    gen.writeStartObject();
                        gen.writeStringField('column', parts[0].trim());
                        gen.writeStringField('durationValue', parts[1].trim());
                        gen.writeNullField('startDate');
                        gen.writeNullField('endDate');
                    gen.writeEndObject();
                }

                // folderId
                if (!String.isBlank(folderId)) {
                    gen.writeStringField('folderId', folderId);
                }

            gen.writeEndObject(); // reportMetadata
        gen.writeEndObject(); // root

        return gen.getAsString();
    }

    @TestVisible
    private static String resolveFolderId(String folderName) {
        List<Folder> folders = [
            SELECT Id
            FROM Folder
            WHERE Name = :folderName
              AND Type = 'Report'
            LIMIT 1
        ];
        return folders.isEmpty() ? null : folders[0].Id;
    }

    @TestVisible
    private static HttpResponse doCallout(String method, String path, String body) {
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl + '/services/data/' + API_VERSION + path);
        req.setMethod(method);
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(30000);
        if (body != null) {
            req.setBody(body);
        }
        return new Http().send(req);
    }

    @TestVisible
    private static String sanitizeDeveloperName(String name) {
        if (String.isBlank(name)) {
            return 'Report_' + String.valueOf(System.currentTimeMillis()).right(8);
        }
        // Replace non-alphanumeric characters with underscores
        String sanitized = name.replaceAll('[^a-zA-Z0-9]', '_');
        // Collapse consecutive underscores
        sanitized = sanitized.replaceAll('_{2,}', '_');
        // Remove leading/trailing underscores
        sanitized = sanitized.replaceAll('^_+|_+$', '');
        // Guard against fully-stripped empty string
        if (String.isBlank(sanitized)) {
            return 'Report_' + String.valueOf(System.currentTimeMillis()).right(8);
        }
        // Ensure it starts with a letter
        if (!sanitized.substring(0, 1).isAlpha()) {
            sanitized = 'R_' + sanitized;
        }
        // Trim to 80 characters
        if (sanitized.length() > 80) {
            sanitized = sanitized.substring(0, 80);
        }
        return sanitized;
    }

    @TestVisible
    private static List<String> splitTrimmed(String csv) {
        List<String> result = new List<String>();
        if (String.isBlank(csv)) {
            return result;
        }
        for (String s : csv.split(',')) {
            String trimmed = s.trim();
            if (!String.isBlank(trimmed)) {
                result.add(trimmed);
            }
        }
        return result;
    }
}