public with sharing class AgentEditReport {

    private static final String API_VERSION = 'v65.0';

    public class Input {
        @InvocableVariable(
            required=false
            label='Report ID'
            description='Salesforce ID of the report to edit. Preferred over Report Name when known — skips the name lookup.'
        )
        public String reportId;

        @InvocableVariable(
            required=false
            label='Report Name'
            description='Exact current name of the report to edit. Used to look up the report when Report ID is not provided. Errors if zero or multiple reports share this name.'
        )
        public String reportName;

        @InvocableVariable(
            required=false
            label='New Report Name'
            description='Renames the report to this value. Truncated to 40 characters if longer. Leave blank to keep the current name.'
        )
        public String newReportName;

        @InvocableVariable(
            required=false
            label='Columns'
            description='Comma-separated column API names to replace the report\'s detail columns. Leave blank to keep existing columns. Do not include group-by columns — they are excluded automatically.'
        )
        public String columns;

        @InvocableVariable(
            required=false
            label='Report Format'
            description='TABULAR, SUMMARY, or MATRIX. Leave blank to keep the current format. Switching to SUMMARY/MATRIX requires groupingsDown (new or already set on the report).'
        )
        public String reportFormat;

        @InvocableVariable(
            required=false
            label='Groupings Down'
            description='Comma-separated column API names for row groupings. Replaces existing row groupings entirely. Maximum 3.'
        )
        public String groupingsDown;

        @InvocableVariable(
            required=false
            label='Groupings Across'
            description='Comma-separated column API names for column groupings (MATRIX only). Replaces existing column groupings entirely. Maximum 3.'
        )
        public String groupingsAcross;

        @InvocableVariable(
            required=false
            label='Filter Column'
            description='Column API name for a single replacement filter. Use Filters JSON instead for multiple filters. Replaces ALL existing filters.'
        )
        public String filterColumn;

        @InvocableVariable(
            required=false
            label='Filter Operator'
            description='Filter operator: equals, notEqual, lessThan, greaterThan, lessOrEqual, greaterOrEqual, contains, notContain, startsWith, includes, excludes.'
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
            description='JSON array of filter objects to replace ALL existing filters. Each object: {"column":"FIELD","operator":"equals","value":"X"}. Takes precedence over the single filter fields if both are provided.'
        )
        public String filtersJson;

        @InvocableVariable(
            required=false
            label='Date Filter'
            description='Standard date filter, format "FIELD:RANGE" (e.g., "CLOSE_DATE:THIS_FISCAL_YEAR"). Pass the literal value "NONE" to clear an existing date filter. Leave blank to keep the current date filter unchanged.'
        )
        public String dateFilter;

        @InvocableVariable(
            required=false
            label='Scope'
            description='Whose records to include: "user" (my records), "team", or "organization" (all records). Leave blank to keep the current scope.'
        )
        public String scope;

        @InvocableVariable(
            required=false
            label='Folder Name'
            description='Moves the report to this folder. Leave blank to keep the report in its current folder. Errors if the folder is not found.'
        )
        public String folderName;

        @InvocableVariable(
            required=false
            label='Date Granularity'
            description='Granularity applied to new groupings set in this call: Day, Month, Quarter, Year, FiscalQuarter, FiscalYear, None (default). Only applies when groupingsDown or groupingsAcross is also provided.'
        )
        public String dateGranularity;

        @InvocableVariable(
            required=false
            label='Sort Order'
            description='Sort direction applied to new groupings set in this call: Asc (default) or Desc. Only applies when groupingsDown or groupingsAcross is also provided.'
        )
        public String sortOrder;

        @InvocableVariable(
            required=false
            label='Filter Logic'
            description='Boolean logic for combining filters set in this call. Uses 1-based indices, e.g. "(1 OR 2) AND 3". Only applies when filters are also being replaced this call.'
        )
        public String reportBooleanFilter;

        @InvocableVariable(
            required=false
            label='Cross-Filters JSON'
            description='JSON array of cross-filter objects to replace existing cross-filters. Each: {"primaryEntityField":"ACCOUNT_ID","relatedEntity":"Opportunity","relatedEntityJoinField":"AccountId","includesObject":true}.'
        )
        public String crossFiltersJson;

        @InvocableVariable(
            required=false
            label='Buckets JSON'
            description='JSON array of bucket field definitions to replace existing buckets.'
        )
        public String bucketsJson;

        @InvocableVariable(
            required=false
            label='Custom Detail Formulas JSON'
            description='JSON array of row-level formula definitions to replace existing ones. Referenced in columns as CDF1, CDF2, etc.'
        )
        public String customDetailFormulasJson;

        @InvocableVariable(
            required=false
            label='Custom Summary Formula JSON'
            description='JSON object for a custom summary formula, replacing the existing one. Only for SUMMARY/MATRIX reports.'
        )
        public String customSummaryFormulaJson;
    }

    public class Output {
        @InvocableVariable(label='Success' description='True if the report was updated successfully.')
        public Boolean success;

        @InvocableVariable(label='Report ID' description='Salesforce ID of the edited report.')
        public String reportId;

        @InvocableVariable(label='Report URL' description='Full Lightning URL to view the updated report.')
        public String reportUrl;

        @InvocableVariable(label='Report Name' description='Current display name of the report.')
        public String reportName;

        @InvocableVariable(label='Fields Updated' description='Comma-separated list of fields that were changed. Empty on failure.')
        public String fieldsUpdated;

        @InvocableVariable(label='Error Message' description='Error details when success is false. Empty on success.')
        public String errorMessage;
    }

    @InvocableMethod(
        label='Edit Salesforce Report'
        description='Edits an existing native Salesforce report via the Analytics REST API. Only the fields you supply are changed — everything else on the report is left as-is. Identify the report with reportId (preferred) or reportName. Use "Get Report Type Columns" first if changing columns/groupings on a report type you have not inspected yet.'
        category='Agent Reporting'
        callout=true
    )
    public static List<Output> editReport(List<Input> inputs) {
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
            String reportId = String.isNotBlank(inp.reportId) ? inp.reportId : resolveReportId(inp.reportName, out);
            if (out.errorMessage != null) return out;
            if (String.isBlank(reportId)) {
                out.success = false;
                out.errorMessage = 'Either reportId or reportName is required';
                return out;
            }
            if (!hasAnyChangeField(inp)) {
                out.success = false;
                out.errorMessage = 'No fields were provided to update';
                return out;
            }

            String sessionId = getSessionId();
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            String reportEndpoint = baseUrl + '/services/data/' + API_VERSION + '/analytics/reports/' + reportId;

            Map<String, Object> describeResult = describeReport(reportEndpoint, sessionId, out);
            if (out.errorMessage != null) return out;

            Map<String, Object> metadata = (Map<String, Object>) describeResult.get('reportMetadata');
            if (metadata == null) {
                out.success = false;
                out.errorMessage = 'Could not read existing report metadata';
                return out;
            }

            List<String> fieldsUpdated = new List<String>();
            applyChanges(inp, metadata, fieldsUpdated, out);
            if (out.errorMessage != null) return out;

            if (fieldsUpdated.isEmpty()) {
                out.success = false;
                out.errorMessage = 'No fields were provided to update';
                return out;
            }

            HttpRequest req = new HttpRequest();
            req.setEndpoint(reportEndpoint);
            req.setMethod('PATCH');
            req.setHeader('Authorization', 'Bearer ' + sessionId);
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(30000);
            req.setBody(JSON.serialize(new Map<String, Object>{ 'reportMetadata' => metadata }));

            HttpResponse res = new Http().send(req);

            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> resultMeta = (Map<String, Object>) result.get('reportMetadata');
                String uiBaseUrl = baseUrl.replace('.my.salesforce.com', '.lightning.force.com');
                out.success = true;
                out.reportId = reportId;
                out.reportUrl = uiBaseUrl + '/lightning/r/Report/' + reportId + '/view?queryScope=userFolders';
                out.reportName = resultMeta != null && resultMeta.get('name') != null
                    ? (String) resultMeta.get('name')
                    : (String) metadata.get('name');
                out.fieldsUpdated = String.join(fieldsUpdated, ', ');
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
    private static Boolean hasAnyChangeField(Input inp) {
        return String.isNotBlank(inp.newReportName)
            || String.isNotBlank(inp.columns)
            || String.isNotBlank(inp.reportFormat)
            || String.isNotBlank(inp.groupingsDown)
            || String.isNotBlank(inp.groupingsAcross)
            || (String.isNotBlank(inp.filterColumn) && String.isNotBlank(inp.filterOperator))
            || String.isNotBlank(inp.filtersJson)
            || String.isNotBlank(inp.dateFilter)
            || String.isNotBlank(inp.scope)
            || String.isNotBlank(inp.folderName)
            || String.isNotBlank(inp.crossFiltersJson)
            || String.isNotBlank(inp.bucketsJson)
            || String.isNotBlank(inp.customDetailFormulasJson)
            || String.isNotBlank(inp.customSummaryFormulaJson);
    }

    @TestVisible
    private static Map<String, Object> describeReport(String reportEndpoint, String sessionId, Output out) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(reportEndpoint + '/describe');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + sessionId);
        req.setTimeout(30000);
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            out.success = false;
            out.errorMessage = 'Could not load existing report (HTTP ' + res.getStatusCode() + '): ' + res.getBody().abbreviate(300);
            return new Map<String, Object>();
        }
        return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    }

    @TestVisible
    private static void applyChanges(Input inp, Map<String, Object> metadata, List<String> fieldsUpdated, Output out) {
        if (String.isNotBlank(inp.newReportName)) {
            metadata.put('name', inp.newReportName.left(40));
            fieldsUpdated.add('name');
        }

        String fmt;
        if (String.isNotBlank(inp.reportFormat)) {
            fmt = inp.reportFormat.toUpperCase().trim();
            if (fmt != 'TABULAR' && fmt != 'SUMMARY' && fmt != 'MATRIX') {
                out.success = false;
                out.errorMessage = 'reportFormat must be TABULAR, SUMMARY, or MATRIX. Received: ' + inp.reportFormat;
                return;
            }
            metadata.put('reportFormat', fmt);
            fieldsUpdated.add('reportFormat');
        } else {
            fmt = (String) metadata.get('reportFormat');
        }

        String grpSortOrder = String.isBlank(inp.sortOrder) ? 'Asc' : inp.sortOrder.trim();
        String grpDateGran = String.isBlank(inp.dateGranularity) ? 'None' : inp.dateGranularity.trim();

        List<String> effectiveGroupsDown;
        if (String.isNotBlank(inp.groupingsDown)) {
            effectiveGroupsDown = splitTrimmed(inp.groupingsDown);
            metadata.put('groupingsDown', buildGroupings(effectiveGroupsDown, grpSortOrder, grpDateGran));
            fieldsUpdated.add('groupingsDown');
        } else {
            effectiveGroupsDown = extractGroupingNames(metadata.get('groupingsDown'));
        }

        List<String> effectiveGroupsAcross;
        if (String.isNotBlank(inp.groupingsAcross)) {
            effectiveGroupsAcross = splitTrimmed(inp.groupingsAcross);
            metadata.put('groupingsAcross', buildGroupings(effectiveGroupsAcross, grpSortOrder, grpDateGran));
            fieldsUpdated.add('groupingsAcross');
        } else {
            effectiveGroupsAcross = extractGroupingNames(metadata.get('groupingsAcross'));
        }

        if ((fmt == 'SUMMARY' || fmt == 'MATRIX') && effectiveGroupsDown.isEmpty()) {
            out.success = false;
            out.errorMessage = 'groupingsDown is required (new or existing) when reportFormat is ' + fmt;
            return;
        }

        if (String.isNotBlank(inp.columns)) {
            Set<String> groupBySet = new Set<String>();
            groupBySet.addAll(effectiveGroupsDown);
            groupBySet.addAll(effectiveGroupsAcross);
            List<String> detailCols = new List<String>();
            for (String col : splitTrimmed(inp.columns)) {
                if (!groupBySet.contains(col)) detailCols.add(col);
            }
            metadata.put('detailColumns', detailCols);
            fieldsUpdated.add('columns');
        }

        List<Object> reportFilters = buildFilters(inp, out);
        if (out.errorMessage != null) return;
        if (reportFilters != null) {
            metadata.put('reportFilters', reportFilters);
            fieldsUpdated.add('filters');
            if (String.isNotBlank(inp.reportBooleanFilter)) {
                metadata.put('reportBooleanFilter', inp.reportBooleanFilter);
                fieldsUpdated.add('reportBooleanFilter');
            }
        }

        if (String.isNotBlank(inp.dateFilter)) {
            if (inp.dateFilter.trim().equalsIgnoreCase('NONE')) {
                Map<String, Object> sdf = (Map<String, Object>) metadata.get('standardDateFilter');
                if (sdf != null) {
                    sdf.put('durationValue', 'CUSTOM');
                    sdf.put('startDate', null);
                    sdf.put('endDate', null);
                }
                fieldsUpdated.add('dateFilter (cleared)');
            } else if (inp.dateFilter.contains(':')) {
                List<String> parts = inp.dateFilter.split(':', 2);
                metadata.put('standardDateFilter', new Map<String, Object>{
                    'column' => parts[0].trim(),
                    'durationValue' => parts[1].trim(),
                    'startDate' => null,
                    'endDate' => null
                });
                fieldsUpdated.add('dateFilter');
            } else {
                out.success = false;
                out.errorMessage = 'dateFilter must be in "FIELD:RANGE" format or "NONE". Received: ' + inp.dateFilter;
                return;
            }
        }

        if (String.isNotBlank(inp.scope)) {
            String normalizedScope = inp.scope.toLowerCase().trim();
            if (normalizedScope == 'mine' || normalizedScope == 'me' || normalizedScope == 'my') {
                normalizedScope = 'user';
            } else if (normalizedScope == 'all' || normalizedScope == 'org') {
                normalizedScope = 'organization';
            }
            metadata.put('scope', normalizedScope);
            fieldsUpdated.add('scope');
        }

        if (String.isNotBlank(inp.folderName)) {
            String folderId = resolveFolderId(inp.folderName);
            if (folderId == null) {
                out.success = false;
                out.errorMessage = 'No report folder found named "' + inp.folderName + '"';
                return;
            }
            metadata.put('folderId', folderId);
            fieldsUpdated.add('folderName');
        }

        if (String.isNotBlank(inp.crossFiltersJson)) {
            metadata.put('crossFilters', JSON.deserializeUntyped(inp.crossFiltersJson));
            fieldsUpdated.add('crossFilters');
        }

        if (String.isNotBlank(inp.bucketsJson)) {
            metadata.put('buckets', JSON.deserializeUntyped(inp.bucketsJson));
            fieldsUpdated.add('buckets');
        }

        if (String.isNotBlank(inp.customDetailFormulasJson)) {
            metadata.put('customDetailFormula', JSON.deserializeUntyped(inp.customDetailFormulasJson));
            fieldsUpdated.add('customDetailFormulas');
        }

        if (String.isNotBlank(inp.customSummaryFormulaJson)) {
            metadata.put('customSummaryFormula', JSON.deserializeUntyped(inp.customSummaryFormulaJson));
            fieldsUpdated.add('customSummaryFormula');
        }
    }

    @TestVisible
    private static List<Object> buildGroupings(List<String> names, String sortOrder, String dateGranularity) {
        List<Object> groupings = new List<Object>();
        for (String name : names) {
            groupings.add(new Map<String, Object>{
                'name' => name,
                'sortOrder' => sortOrder,
                'dateGranularity' => dateGranularity
            });
        }
        return groupings;
    }

    @TestVisible
    private static List<String> extractGroupingNames(Object groupingsRaw) {
        List<String> names = new List<String>();
        if (groupingsRaw == null) return names;
        for (Object g : (List<Object>) groupingsRaw) {
            Map<String, Object> gm = (Map<String, Object>) g;
            if (gm.get('name') != null) names.add((String) gm.get('name'));
        }
        return names;
    }

    @TestVisible
    private static List<Object> buildFilters(Input inp, Output out) {
        if (String.isNotBlank(inp.filtersJson)) {
            try {
                List<Object> rawFilters = (List<Object>) JSON.deserializeUntyped(inp.filtersJson);
                List<Object> filters = new List<Object>();
                for (Object rawFilter : rawFilters) {
                    Map<String, Object> f = (Map<String, Object>) rawFilter;
                    filters.add(new Map<String, Object>{
                        'column'   => String.valueOf(f.get('column')),
                        'operator' => String.valueOf(f.get('operator')),
                        'value'    => f.get('value') != null ? String.valueOf(f.get('value')) : ''
                    });
                }
                return filters;
            } catch (Exception e) {
                out.success = false;
                out.errorMessage = 'Invalid filtersJson format: ' + e.getMessage();
                return null;
            }
        } else if (String.isNotBlank(inp.filterColumn) && String.isNotBlank(inp.filterOperator)) {
            return new List<Object>{
                new Map<String, Object>{
                    'column'   => inp.filterColumn,
                    'operator' => inp.filterOperator,
                    'value'    => inp.filterValue != null ? inp.filterValue : ''
                }
            };
        }
        return null;
    }

    @TestVisible
    private static String resolveReportId(String reportName, Output out) {
        if (String.isBlank(reportName)) return null;
        List<Report> matches = [
            SELECT Id FROM Report WHERE Name = :reportName LIMIT 2
        ];
        if (matches.isEmpty()) {
            out.success = false;
            out.errorMessage = 'No report found named "' + reportName + '"';
            return null;
        }
        if (matches.size() > 1) {
            out.success = false;
            out.errorMessage = 'Multiple reports named "' + reportName + '" found — use reportId instead';
            return null;
        }
        return matches[0].Id;
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
    private static List<String> splitTrimmed(String csv) {
        List<String> result = new List<String>();
        if (String.isBlank(csv)) return result;
        for (String s : csv.split(',')) {
            String trimmed = s.trim();
            if (String.isNotBlank(trimmed)) result.add(trimmed);
        }
        return result;
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
