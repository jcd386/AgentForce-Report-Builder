public with sharing class AgentCreateReport {

    private static final String API_VERSION = 'v65.0';

    public class Input {
        @InvocableVariable(
            required=true
            label='Report Name'
            description='Display name for the new report. Truncated to 40 characters if longer.'
        )
        public String reportName;

        @InvocableVariable(
            required=true
            label='Report Type'
            description='Report type API name from "List Report Types". Examples: CaseList, AccountList, Opportunity, ContactList, LeadList, OpportunityProduct.'
        )
        public String reportType;

        @InvocableVariable(
            required=true
            label='Columns'
            description='Comma-separated column API names from "Get Report Type Columns". Examples: CASE_NUMBER,SUBJECT,STATUS or ACCOUNT.NAME,AMOUNT,STAGE_NAME. Do not include group-by columns here — they are added automatically.'
        )
        public String columns;

        @InvocableVariable(
            required=false
            label='Report Format'
            description='TABULAR (flat list, default), SUMMARY (grouped with subtotals), or MATRIX (row and column groupings). Defaults to TABULAR if omitted.'
        )
        public String reportFormat;

        @InvocableVariable(
            required=false
            label='Groupings Down'
            description='Comma-separated column API names for row groupings. Required when format is SUMMARY or MATRIX. Maximum 3. Example: STAGE_NAME,OWNER_NAME'
        )
        public String groupingsDown;

        @InvocableVariable(
            required=false
            label='Groupings Across'
            description='Comma-separated column API names for column groupings. Only used when format is MATRIX. Maximum 3.'
        )
        public String groupingsAcross;

        @InvocableVariable(
            required=false
            label='Filter Column'
            description='Column API name to filter on for a single filter. Example: STATUS or CLOSED. Use Filters JSON instead when multiple filters are needed.'
        )
        public String filterColumn;

        @InvocableVariable(
            required=false
            label='Filter Operator'
            description='Filter operator. Values: equals, notEqual, lessThan, greaterThan, lessOrEqual, greaterOrEqual, contains, notContain, startsWith, includes, excludes.'
        )
        public String filterOperator;

        @InvocableVariable(
            required=false
            label='Filter Value'
            description='Value to filter by. Use YYYY-MM-DD for dates, true/false for booleans, numbers without currency symbols.'
        )
        public String filterValue;

        @InvocableVariable(
            required=false
            label='Filters JSON'
            description='JSON array of filter objects for multi-filter reports. Each object: {"column":"FIELD","operator":"equals","value":"X"}. Example: [{"column":"STAGE_NAME","operator":"equals","value":"Closed Won"},{"column":"CLOSE_DATE","operator":"greaterThan","value":"2026-01-01"}]. Takes precedence over the single filter fields if both are provided.'
        )
        public String filtersJson;

        @InvocableVariable(
            required=false
            label='Date Filter'
            description='Standard date filter. Format: "FIELD:RANGE" where RANGE is THIS_FISCAL_QUARTER, LAST_FISCAL_QUARTER, THIS_FISCAL_YEAR, LAST_FISCAL_YEAR, THIS_MONTH, LAST_MONTH, LAST_30_DAYS, LAST_90_DAYS, or CUSTOM. Example: "CLOSE_DATE:THIS_FISCAL_YEAR"'
        )
        public String dateFilter;

        @InvocableVariable(
            required=false
            label='Scope'
            description='Whose records to include. Use "user" for "my" records, "team" for "my team", or "organization" for all records org-wide. Defaults to "organization".'
        )
        public String scope;

        @InvocableVariable(
            required=false
            label='Folder Name'
            description='Name of the report folder to save the report in. Leave blank for the user\'s private reports folder.'
        )
        public String folderName;

        @InvocableVariable(
            required=false
            label='Date Granularity'
            description='Granularity for date groupings. Values: Day, Month, Quarter, Year, FiscalQuarter, FiscalYear, None (default). Applied to all date-type groupings in groupingsDown and groupingsAcross.'
        )
        public String dateGranularity;

        @InvocableVariable(
            required=false
            label='Sort Order'
            description='Sort direction for groupings. Values: Asc (default) or Desc. Applied to all groupings in groupingsDown and groupingsAcross.'
        )
        public String sortOrder;

        @InvocableVariable(
            required=false
            label='Filter Logic'
            description='Boolean logic for combining multiple filters. Uses 1-based indices matching filter order. Example: "(1 OR 2) AND 3". Without this, all filters are combined with AND.'
        )
        public String reportBooleanFilter;

        @InvocableVariable(
            required=false
            label='Cross-Filters JSON'
            description='JSON array of cross-filter objects for related-record filtering. Each: {"primaryEntityField":"ACCOUNT_ID","relatedEntity":"Opportunity","relatedEntityJoinField":"AccountId","includesObject":true}. includesObject=true means WITH, false means WITHOUT. Optional "criteria" array for sub-filters.'
        )
        public String crossFiltersJson;

        @InvocableVariable(
            required=false
            label='Buckets JSON'
            description='JSON array of bucket field definitions. Each: {"bucketType":"picklist","developerName":"BucketField_1","label":"Region","sourceColumnName":"BILLING_STATE","otherBucketLabel":"Other","values":[{"label":"West","sourceDimensionValues":["CA","OR","WA"]}]}. Reference in columns/groupings by developerName.'
        )
        public String bucketsJson;

        @InvocableVariable(
            required=false
            label='Custom Detail Formulas JSON'
            description='JSON array of row-level formula definitions. Each: {"label":"Days Open","formula":"TODAY() - CREATED_DATE","formulaType":"number","decimalPlaces":0}. Referenced in columns as CDF1, CDF2, etc.'
        )
        public String customDetailFormulasJson;

        @InvocableVariable(
            required=false
            label='Custom Summary Formula JSON'
            description='JSON object for a custom summary formula. Example: {"label":"Win Rate","formula":"CLOSED_WON:SUM / RowCount:SUM * 100","formulaType":"percent","decimalPlaces":1,"downGroupType":"all","acrossGroupType":"grand_total"}. Only for SUMMARY/MATRIX reports.'
        )
        public String customSummaryFormulaJson;
    }

    public class Output {
        @InvocableVariable(label='Success' description='True if the report was created successfully.')
        public Boolean success;

        @InvocableVariable(label='Report ID' description='Salesforce ID of the created report. Only populated on success.')
        public String reportId;

        @InvocableVariable(label='Report URL' description='Full Lightning URL to view the report in a browser.')
        public String reportUrl;

        @InvocableVariable(label='Report Path' description='Relative path to the report. Fallback when the full URL is unavailable.')
        public String reportPath;

        @InvocableVariable(label='Report Name' description='Display name of the created report.')
        public String reportName;

        @InvocableVariable(label='Error Message' description='Error details when success is false. Empty on success.')
        public String errorMessage;
    }

    @InvocableMethod(
        label='Create Salesforce Report'
        description='Creates a native Salesforce report using the Analytics REST API. Supports tabular, summary, and matrix formats with filters, groupings, date filters, scope control, and folder placement. Use "List Report Types" and "Get Report Type Columns" first to discover valid inputs.'
        category='Agent Reporting'
        callout=true
    )
    public static List<Output> createReport(List<Input> inputs) {
        List<Output> results = new List<Output>();
        for (Input inp : inputs) {
            results.add(execute(inp));
        }
        return results;
    }

    @TestVisible
    private static Output execute(Input inp) {
        Output out = new Output();
        try {
            if (String.isBlank(inp.reportName)) {
                out.success = false;
                out.errorMessage = 'reportName is required';
                return out;
            }
            if (String.isBlank(inp.reportType)) {
                out.success = false;
                out.errorMessage = 'reportType is required';
                return out;
            }
            if (String.isBlank(inp.columns)) {
                out.success = false;
                out.errorMessage = 'columns is required';
                return out;
            }

            String fmt = String.isBlank(inp.reportFormat) ? 'TABULAR' : inp.reportFormat.toUpperCase().trim();
            if (fmt != 'TABULAR' && fmt != 'SUMMARY' && fmt != 'MATRIX') {
                out.success = false;
                out.errorMessage = 'reportFormat must be TABULAR, SUMMARY, or MATRIX. Received: ' + inp.reportFormat;
                return out;
            }
            if ((fmt == 'SUMMARY' || fmt == 'MATRIX') && String.isBlank(inp.groupingsDown)) {
                out.success = false;
                out.errorMessage = 'groupingsDown is required when reportFormat is ' + fmt;
                return out;
            }

            List<Object> reportFilters = buildFilters(inp, out);
            if (out.errorMessage != null) return out;

            String folderId = null;
            if (String.isNotBlank(inp.folderName)) {
                folderId = resolveFolderId(inp.folderName);
            }

            String body = buildReportBody(inp, fmt, reportFilters, folderId);
            String sessionId = getSessionId();
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();

            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/services/data/' + API_VERSION + '/analytics/reports');
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + sessionId);
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(30000);
            req.setBody(body);

            HttpResponse res = new Http().send(req);

            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> attrs = (Map<String, Object>) result.get('attributes');
                String reportId = (String) attrs.get('reportId');
                String reportEndpoint = baseUrl + '/services/data/' + API_VERSION + '/analytics/reports/' + reportId;

                patchDateFilter(result, reportEndpoint, sessionId, inp);
                patchScope(reportEndpoint, sessionId, inp);

                out.success = true;
                out.reportId = reportId;
                out.reportUrl = baseUrl + '/lightning/r/Report/' + reportId + '/view?queryScope=userFolders';
                out.reportPath = '/lightning/r/Report/' + reportId + '/view?queryScope=userFolders';
                out.reportName = (String) attrs.get('reportName');
                if (inp.reportName != null && inp.reportName.length() > 40) {
                    out.reportName = out.reportName + ' (note: name was truncated from "' + inp.reportName + '")';
                }
            } else {
                out.success = false;
                out.errorMessage = 'Analytics API error ' + res.getStatusCode() + ': ' + res.getBody().abbreviate(300);
            }
        } catch (Exception e) {
            out.success = false;
            out.errorMessage = e.getMessage();
        }
        return out;
    }

    @TestVisible
    private static String buildReportBody(Input inp, String fmt, List<Object> reportFilters, String folderId) {
        Set<String> groupBySet = new Set<String>();
        List<String> groupsDown = splitTrimmed(inp.groupingsDown);
        groupBySet.addAll(groupsDown);
        if (String.isNotBlank(inp.groupingsAcross)) {
            groupBySet.addAll(splitTrimmed(inp.groupingsAcross));
        }

        List<String> detailCols = new List<String>();
        for (String col : splitTrimmed(inp.columns)) {
            if (!groupBySet.contains(col)) {
                detailCols.add(col);
            }
        }

        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartObject();
        gen.writeFieldName('reportMetadata');
        gen.writeStartObject();

        gen.writeStringField('name', inp.reportName.left(40));
        gen.writeStringField('developerName', sanitizeDeveloperName(inp.reportName));
        gen.writeStringField('reportFormat', fmt);

        gen.writeFieldName('reportType');
        gen.writeStartObject();
        gen.writeStringField('type', inp.reportType);
        gen.writeEndObject();

        gen.writeFieldName('detailColumns');
        gen.writeStartArray();
        for (String col : detailCols) {
            gen.writeString(col);
        }
        gen.writeEndArray();

        String grpSortOrder = String.isBlank(inp.sortOrder) ? 'Asc' : inp.sortOrder.trim();
        String grpDateGran = String.isBlank(inp.dateGranularity) ? 'None' : inp.dateGranularity.trim();

        if (!groupsDown.isEmpty()) {
            gen.writeFieldName('groupingsDown');
            gen.writeStartArray();
            for (String g : groupsDown) {
                gen.writeStartObject();
                gen.writeStringField('name', g);
                gen.writeStringField('sortOrder', grpSortOrder);
                gen.writeStringField('dateGranularity', grpDateGran);
                gen.writeEndObject();
            }
            gen.writeEndArray();
        }

        if (String.isNotBlank(inp.groupingsAcross)) {
            List<String> groupsAcross = splitTrimmed(inp.groupingsAcross);
            gen.writeFieldName('groupingsAcross');
            gen.writeStartArray();
            for (String g : groupsAcross) {
                gen.writeStartObject();
                gen.writeStringField('name', g);
                gen.writeStringField('sortOrder', grpSortOrder);
                gen.writeStringField('dateGranularity', grpDateGran);
                gen.writeEndObject();
            }
            gen.writeEndArray();
        }

        if (!reportFilters.isEmpty()) {
            gen.writeFieldName('reportFilters');
            gen.writeStartArray();
            for (Object filterObj : reportFilters) {
                Map<String, Object> f = (Map<String, Object>) filterObj;
                gen.writeStartObject();
                gen.writeStringField('column', (String) f.get('column'));
                gen.writeStringField('operator', (String) f.get('operator'));
                gen.writeStringField('value', (String) f.get('value'));
                gen.writeEndObject();
            }
            gen.writeEndArray();
        }

        if (String.isNotBlank(inp.reportBooleanFilter)) {
            gen.writeStringField('reportBooleanFilter', inp.reportBooleanFilter);
        }

        if (String.isNotBlank(inp.dateFilter) && inp.dateFilter.contains(':')) {
            List<String> parts = inp.dateFilter.split(':', 2);
            gen.writeFieldName('standardDateFilter');
            gen.writeStartObject();
            gen.writeStringField('column', parts[0].trim());
            gen.writeStringField('durationValue', parts[1].trim());
            gen.writeNullField('startDate');
            gen.writeNullField('endDate');
            gen.writeEndObject();
        }

        if (String.isNotBlank(inp.crossFiltersJson)) {
            List<Object> crossFilters = (List<Object>) JSON.deserializeUntyped(inp.crossFiltersJson);
            gen.writeFieldName('crossFilters');
            gen.writeStartArray();
            for (Object cfObj : crossFilters) {
                Map<String, Object> cf = (Map<String, Object>) cfObj;
                gen.writeStartObject();
                gen.writeStringField('primaryEntityField', (String) cf.get('primaryEntityField'));
                gen.writeBooleanField('includesObject', cf.get('includesObject') == true);
                gen.writeStringField('relatedEntity', (String) cf.get('relatedEntity'));
                gen.writeStringField('relatedEntityJoinField', (String) cf.get('relatedEntityJoinField'));
                if (cf.containsKey('criteria')) {
                    List<Object> criteria = (List<Object>) cf.get('criteria');
                    gen.writeFieldName('criteria');
                    gen.writeStartArray();
                    for (Object crit : criteria) {
                        Map<String, Object> c = (Map<String, Object>) crit;
                        gen.writeStartObject();
                        gen.writeStringField('column', (String) c.get('column'));
                        gen.writeStringField('operator', (String) c.get('operator'));
                        gen.writeStringField('value', String.valueOf(c.get('value')));
                        gen.writeEndObject();
                    }
                    gen.writeEndArray();
                }
                gen.writeEndObject();
            }
            gen.writeEndArray();
        }

        if (String.isNotBlank(inp.bucketsJson)) {
            List<Object> buckets = (List<Object>) JSON.deserializeUntyped(inp.bucketsJson);
            gen.writeFieldName('buckets');
            gen.writeStartArray();
            for (Object bkt : buckets) {
                gen.writeObject(bkt);
            }
            gen.writeEndArray();
        }

        if (String.isNotBlank(inp.customDetailFormulasJson)) {
            List<Object> cdfs = (List<Object>) JSON.deserializeUntyped(inp.customDetailFormulasJson);
            gen.writeFieldName('customDetailFormula');
            gen.writeStartArray();
            for (Object cdf : cdfs) {
                gen.writeObject(cdf);
            }
            gen.writeEndArray();
        }

        if (String.isNotBlank(inp.customSummaryFormulaJson)) {
            Object csf = JSON.deserializeUntyped(inp.customSummaryFormulaJson);
            gen.writeFieldName('customSummaryFormula');
            gen.writeObject(csf);
        }

        if (String.isNotBlank(folderId)) {
            gen.writeStringField('folderId', folderId);
        }

        gen.writeEndObject();
        gen.writeEndObject();

        return gen.getAsString();
    }

    @TestVisible
    private static List<Object> buildFilters(Input inp, Output out) {
        List<Object> filters = new List<Object>();
        if (String.isNotBlank(inp.filtersJson)) {
            try {
                List<Object> rawFilters = (List<Object>) JSON.deserializeUntyped(inp.filtersJson);
                for (Object rawFilter : rawFilters) {
                    Map<String, Object> f = (Map<String, Object>) rawFilter;
                    filters.add(new Map<String, Object>{
                        'column'   => String.valueOf(f.get('column')),
                        'operator' => String.valueOf(f.get('operator')),
                        'value'    => f.get('value') != null ? String.valueOf(f.get('value')) : ''
                    });
                }
            } catch (Exception e) {
                out.success = false;
                out.errorMessage = 'Invalid filtersJson format: ' + e.getMessage();
            }
        } else if (String.isNotBlank(inp.filterColumn) && String.isNotBlank(inp.filterOperator)) {
            filters.add(new Map<String, Object>{
                'column'   => inp.filterColumn,
                'operator' => inp.filterOperator,
                'value'    => inp.filterValue != null ? inp.filterValue : ''
            });
        }
        return filters;
    }

    private static void patchDateFilter(Map<String, Object> result, String reportEndpoint, String sessionId, Input inp) {
        if (String.isNotBlank(inp.dateFilter)) return;
        Map<String, Object> createdMeta = (Map<String, Object>) result.get('reportMetadata');
        if (createdMeta == null) return;
        Map<String, Object> sdf = (Map<String, Object>) createdMeta.get('standardDateFilter');
        if (sdf == null) return;
        sdf.put('durationValue', 'CUSTOM');
        sdf.put('startDate', null);
        sdf.put('endDate', null);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(reportEndpoint);
        req.setMethod('PATCH');
        req.setHeader('Authorization', 'Bearer ' + sessionId);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, Object>{
            'reportMetadata' => new Map<String, Object>{ 'standardDateFilter' => sdf }
        }));
        new Http().send(req);
    }

    private static void patchScope(String reportEndpoint, String sessionId, Input inp) {
        String requestedScope = String.isBlank(inp.scope) ? 'organization' : inp.scope.toLowerCase().trim();
        if (requestedScope == 'mine' || requestedScope == 'me' || requestedScope == 'my') {
            requestedScope = 'user';
        } else if (requestedScope == 'all' || requestedScope == 'org') {
            requestedScope = 'organization';
        }
        List<String> scopesToTry = new List<String>{ requestedScope };
        if (requestedScope == 'organization') scopesToTry.add('org');
        for (String scopeVal : scopesToTry) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(reportEndpoint);
            req.setMethod('PATCH');
            req.setHeader('Authorization', 'Bearer ' + sessionId);
            req.setHeader('Content-Type', 'application/json');
            req.setBody('{"reportMetadata":{"scope":"' + scopeVal + '"}}');
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() == 200) break;
        }
    }

    @TestVisible
    private static String resolveFolderId(String folderName) {
        List<Folder> folders = [
            SELECT Id FROM Folder
            WHERE Name = :folderName AND Type = 'Report'
            LIMIT 1
        ];
        return folders.isEmpty() ? null : folders[0].Id;
    }

    @TestVisible
    private static String getSessionId() {
        String sessionId = UserInfo.getSessionId();
        if (String.isBlank(sessionId)) {
            sessionId = Test.isRunningTest() ? 'TEST_SESSION_ID' : Page.SessionId.getContent().toString().trim();
        }
        return sessionId;
    }

    @TestVisible
    private static String sanitizeDeveloperName(String name) {
        if (String.isBlank(name)) {
            return 'Report_' + String.valueOf(System.currentTimeMillis()).right(8);
        }
        String sanitized = name.replaceAll('[^a-zA-Z0-9]', '_');
        sanitized = sanitized.replaceAll('_{2,}', '_');
        sanitized = sanitized.replaceAll('^_+|_+$', '');
        if (String.isBlank(sanitized)) {
            return 'Report_' + String.valueOf(System.currentTimeMillis()).right(8);
        }
        if (!sanitized.substring(0, 1).isAlpha()) {
            sanitized = 'R_' + sanitized;
        }
        if (sanitized.length() > 80) {
            sanitized = sanitized.substring(0, 80);
        }
        return sanitized;
    }

    @TestVisible
    private static List<String> splitTrimmed(String csv) {
        List<String> result = new List<String>();
        if (String.isBlank(csv)) return result;
        for (String s : csv.split(',')) {
            String trimmed = s.trim();
            if (String.isNotBlank(trimmed)) result.add(trimmed);
        }
        return result;
    }
}
