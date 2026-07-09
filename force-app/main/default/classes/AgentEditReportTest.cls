@IsTest
public class AgentEditReportTest {

    private static final String REPORT_ID = '00Og5000003TESTEA0';

    @IsTest
    static void testEditColumnsSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockDescribeAndPatch(baseMetadata()));

        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;
        inp.columns = 'CASE_NUMBER,SUBJECT,PRIORITY';

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
        System.assertEquals(REPORT_ID, results[0].reportId);
        System.assert(results[0].reportUrl.contains('/lightning/r/Report/'));
        System.assert(results[0].fieldsUpdated.contains('columns'));
    }

    @IsTest
    static void testEditRenameSuccess() {
        Map<String, Object> meta = baseMetadata();
        Test.setMock(HttpCalloutMock.class, new MockDescribeAndPatch(meta));

        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;
        inp.newReportName = 'Renamed Report';

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
        System.assertEquals('Renamed Report', results[0].reportName);
        System.assert(results[0].fieldsUpdated.contains('name'));
    }

    @IsTest
    static void testEditFormatToSummaryWithNewGroupings() {
        Test.setMock(HttpCalloutMock.class, new MockDescribeAndPatch(baseMetadata()));

        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;
        inp.reportFormat = 'SUMMARY';
        inp.groupingsDown = 'STATUS';

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
        System.assert(results[0].fieldsUpdated.contains('groupingsDown'));
    }

    @IsTest
    static void testEditFormatToSummaryUsesExistingGroupings() {
        Map<String, Object> meta = baseMetadata();
        meta.put('groupingsDown', new List<Object>{
            new Map<String, Object>{ 'name' => 'STATUS', 'sortOrder' => 'Asc', 'dateGranularity' => 'None' }
        });
        Test.setMock(HttpCalloutMock.class, new MockDescribeAndPatch(meta));

        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;
        inp.reportFormat = 'SUMMARY';

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
    }

    @IsTest
    static void testEditSummaryWithoutGroupingsFails() {
        Test.setMock(HttpCalloutMock.class, new MockDescribeAndPatch(baseMetadata()));

        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;
        inp.reportFormat = 'SUMMARY';

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].success);
        System.assert(results[0].errorMessage.contains('groupingsDown'));
    }

    @IsTest
    static void testEditInvalidFormat() {
        Test.setMock(HttpCalloutMock.class, new MockDescribeAndPatch(baseMetadata()));

        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;
        inp.reportFormat = 'PIVOT';

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].success);
    }

    @IsTest
    static void testEditSingleFilterReplace() {
        Test.setMock(HttpCalloutMock.class, new MockDescribeAndPatch(baseMetadata()));

        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;
        inp.filterColumn = 'STATUS';
        inp.filterOperator = 'notEqual';
        inp.filterValue = 'Closed';

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
        System.assert(results[0].fieldsUpdated.contains('filters'));
    }

    @IsTest
    static void testEditFiltersJsonWithBooleanLogic() {
        Test.setMock(HttpCalloutMock.class, new MockDescribeAndPatch(baseMetadata()));

        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;
        inp.filtersJson = '[{"column":"STAGE_NAME","operator":"equals","value":"Closed Won"},{"column":"CLOSE_DATE","operator":"greaterThan","value":"2026-01-01"}]';
        inp.reportBooleanFilter = '1 OR 2';

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
        System.assert(results[0].fieldsUpdated.contains('reportBooleanFilter'));
    }

    @IsTest
    static void testEditInvalidFiltersJson() {
        Test.setMock(HttpCalloutMock.class, new MockDescribeAndPatch(baseMetadata()));

        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;
        inp.filtersJson = 'not-valid-json';

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].success);
        System.assert(results[0].errorMessage.contains('filtersJson'));
    }

    @IsTest
    static void testEditDateFilterSet() {
        Test.setMock(HttpCalloutMock.class, new MockDescribeAndPatch(baseMetadata()));

        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;
        inp.dateFilter = 'CLOSE_DATE:THIS_MONTH';

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
        System.assert(results[0].fieldsUpdated.contains('dateFilter'));
    }

    @IsTest
    static void testEditDateFilterClear() {
        Map<String, Object> meta = baseMetadata();
        meta.put('standardDateFilter', new Map<String, Object>{
            'column' => 'CREATED_DATE',
            'durationValue' => 'THIS_FISCAL_QUARTER',
            'startDate' => '2026-04-01',
            'endDate' => '2026-06-30'
        });
        Test.setMock(HttpCalloutMock.class, new MockDescribeAndPatch(meta));

        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;
        inp.dateFilter = 'NONE';

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
        System.assert(results[0].fieldsUpdated.contains('cleared'));
    }

    @IsTest
    static void testEditDateFilterInvalidFormat() {
        Test.setMock(HttpCalloutMock.class, new MockDescribeAndPatch(baseMetadata()));

        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;
        inp.dateFilter = 'BADFORMAT';

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].success);
    }

    @IsTest
    static void testEditScopeNormalization() {
        AgentEditReport.Output out = new AgentEditReport.Output();
        List<String> fieldsUpdated = new List<String>();

        Map<String, Object> meta1 = baseMetadata();
        AgentEditReport.Input inp1 = new AgentEditReport.Input();
        inp1.scope = 'mine';
        AgentEditReport.applyChanges(inp1, meta1, fieldsUpdated, out);
        System.assertEquals('user', meta1.get('scope'));

        Map<String, Object> meta2 = baseMetadata();
        List<String> fieldsUpdated2 = new List<String>();
        AgentEditReport.Input inp2 = new AgentEditReport.Input();
        inp2.scope = 'all';
        AgentEditReport.applyChanges(inp2, meta2, fieldsUpdated2, out);
        System.assertEquals('organization', meta2.get('scope'));
    }

    @IsTest
    static void testEditFolderNotFound() {
        Test.setMock(HttpCalloutMock.class, new MockDescribeAndPatch(baseMetadata()));

        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;
        inp.folderName = 'NonExistentFolderXYZ';

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].success);
        System.assert(results[0].errorMessage.contains('folder'));
    }

    @IsTest
    static void testEditAdvancedJsonFields() {
        Test.setMock(HttpCalloutMock.class, new MockDescribeAndPatch(baseMetadata()));

        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;
        inp.crossFiltersJson = '[{"primaryEntityField":"ACCOUNT_ID","relatedEntity":"Opportunity","relatedEntityJoinField":"AccountId","includesObject":true}]';
        inp.bucketsJson = '[{"bucketType":"picklist","developerName":"BucketField_1","label":"Region","sourceColumnName":"BILLING_STATE","otherBucketLabel":"Other","values":[]}]';
        inp.customDetailFormulasJson = '[{"label":"Days Open","formula":"TODAY() - CREATED_DATE","formulaType":"number","decimalPlaces":0}]';
        inp.customSummaryFormulaJson = '{"label":"Win Rate","formula":"CLOSED_WON:SUM / RowCount:SUM * 100","formulaType":"percent","decimalPlaces":1,"downGroupType":"all","acrossGroupType":"grand_total"}';

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
        System.assert(results[0].fieldsUpdated.contains('crossFilters'));
        System.assert(results[0].fieldsUpdated.contains('buckets'));
        System.assert(results[0].fieldsUpdated.contains('customDetailFormulas'));
        System.assert(results[0].fieldsUpdated.contains('customSummaryFormula'));
    }

    @IsTest
    static void testEditGroupingsAcrossWithGranularityAndSort() {
        Test.setMock(HttpCalloutMock.class, new MockDescribeAndPatch(baseMetadata()));

        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;
        inp.reportFormat = 'MATRIX';
        inp.groupingsDown = 'STAGE_NAME';
        inp.groupingsAcross = 'CLOSE_DATE';
        inp.dateGranularity = 'Month';
        inp.sortOrder = 'Desc';

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
        System.assert(results[0].fieldsUpdated.contains('groupingsAcross'));
    }

    @IsTest
    static void testEditNoFieldsProvided() {
        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].success);
        System.assert(results[0].errorMessage.contains('No fields'));
    }

    @IsTest
    static void testEditMissingIdentifier() {
        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.columns = 'CASE_NUMBER';

        AgentEditReport.Output output = AgentEditReport.execute(inp);
        System.assertEquals(false, output.success);
        System.assert(output.errorMessage.contains('reportId or reportName'));
    }

    @IsTest
    static void testEditByReportNameNotFound() {
        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportName = 'NoSuchReportXYZ123DoesNotExist';
        inp.columns = 'CASE_NUMBER';

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].success);
        System.assert(results[0].errorMessage.contains('No report found'));
    }

    @IsTest
    static void testDescribeGetFails() {
        Test.setMock(HttpCalloutMock.class, new MockDescribeError());

        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;
        inp.columns = 'CASE_NUMBER';

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].success);
        System.assert(results[0].errorMessage.contains('Could not load'));
    }

    @IsTest
    static void testPatchApiError() {
        Test.setMock(HttpCalloutMock.class, new MockDescribeSuccessPatchError());

        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;
        inp.columns = 'CASE_NUMBER';

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].success);
        System.assertNotEquals(null, results[0].errorMessage);
    }

    @IsTest
    static void testCalloutException() {
        Test.setMock(HttpCalloutMock.class, new MockCalloutError());

        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;
        inp.columns = 'CASE_NUMBER';

        Test.startTest();
        List<AgentEditReport.Output> results = AgentEditReport.editReport(
            new List<AgentEditReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].success);
    }

    @IsTest
    static void testInnerClassProperties() {
        AgentEditReport.Input inp = new AgentEditReport.Input();
        inp.reportId = REPORT_ID;
        inp.reportName = 'Existing Report';
        inp.newReportName = 'New Name';
        inp.columns = 'CASE_NUMBER';
        inp.reportFormat = 'MATRIX';
        inp.groupingsDown = 'STATUS';
        inp.groupingsAcross = 'ORIGIN';
        inp.filterColumn = 'STATUS';
        inp.filterOperator = 'equals';
        inp.filterValue = 'Open';
        inp.filtersJson = '[]';
        inp.dateFilter = 'CREATED_DATE:LAST_30_DAYS';
        inp.scope = 'organization';
        inp.folderName = 'My Reports';
        inp.dateGranularity = 'Month';
        inp.sortOrder = 'Desc';
        inp.reportBooleanFilter = '1 AND 2';
        inp.crossFiltersJson = '[]';
        inp.bucketsJson = '[]';
        inp.customDetailFormulasJson = '[]';
        inp.customSummaryFormulaJson = '{}';

        AgentEditReport.Output out = new AgentEditReport.Output();
        out.success = true;
        out.reportId = REPORT_ID;
        out.reportUrl = 'https://example.lightning.force.com/lightning/r/Report/' + REPORT_ID + '/view';
        out.reportName = 'New Name';
        out.fieldsUpdated = 'name, columns';
        out.errorMessage = null;
    }

    // ---- Helpers ----

    private static Map<String, Object> baseMetadata() {
        return new Map<String, Object>{
            'id' => REPORT_ID,
            'name' => 'Existing Report',
            'developerName' => 'Existing_Report',
            'reportFormat' => 'TABULAR',
            'reportType' => new Map<String, Object>{ 'type' => 'CaseList' },
            'detailColumns' => new List<Object>{ 'CASE_NUMBER', 'SUBJECT' },
            'reportFilters' => new List<Object>(),
            'scope' => 'organization'
        };
    }

    // ---- Mocks ----

    private class MockDescribeAndPatch implements HttpCalloutMock {
        private Map<String, Object> describeMetadata;

        MockDescribeAndPatch(Map<String, Object> describeMetadata) {
            this.describeMetadata = describeMetadata;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            if (req.getMethod() == 'GET') {
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'reportMetadata' => describeMetadata,
                    'reportTypeMetadata' => new Map<String, Object>()
                }));
            } else {
                Map<String, Object> patched = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());
                res.setBody(JSON.serialize(patched));
            }
            return res;
        }
    }

    private class MockDescribeError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(404);
            res.setBody('[{"errorCode":"NOT_FOUND","message":"Report not found"}]');
            return res;
        }
    }

    private class MockDescribeSuccessPatchError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getMethod() == 'GET') {
                res.setStatusCode(200);
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'reportMetadata' => baseMetadata()
                }));
            } else {
                res.setStatusCode(400);
                res.setBody('[{"errorCode":"BAD_REQUEST","message":"Invalid column name"}]');
            }
            return res;
        }
    }

    private class MockCalloutError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Simulated network error');
        }
    }
}
