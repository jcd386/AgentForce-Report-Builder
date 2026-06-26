@IsTest
public class AgentCreateReportTest {

    @IsTest
    static void testTabularReportSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        AgentCreateReport.Input inp = new AgentCreateReport.Input();
        inp.reportName = 'All Accounts Tabular';
        inp.reportType = 'AccountList';
        inp.columns = 'ACCOUNT.NAME,ACCOUNT.INDUSTRY,ACCOUNT.ANNUAL_REVENUE';

        Test.startTest();
        List<AgentCreateReport.Output> results = AgentCreateReport.createReport(
            new List<AgentCreateReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
        System.assertEquals('00Og5000003TESTEA0', results[0].reportId);
        System.assert(results[0].reportUrl.contains('lightning.force.com'));
        System.assert(results[0].reportPath.startsWith('/lightning/r/Report/'));
    }

    @IsTest
    static void testSummaryReportWithSingleFilter() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        AgentCreateReport.Input inp = new AgentCreateReport.Input();
        inp.reportName = 'Cases by Category';
        inp.reportType = 'CaseList';
        inp.columns = 'CASE_NUMBER,SUBJECT,STATUS';
        inp.reportFormat = 'SUMMARY';
        inp.groupingsDown = 'Case.Case_Category__c';
        inp.filterColumn = 'STATUS';
        inp.filterOperator = 'notEqual';
        inp.filterValue = 'Closed';

        Test.startTest();
        List<AgentCreateReport.Output> results = AgentCreateReport.createReport(
            new List<AgentCreateReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
    }

    @IsTest
    static void testMatrixReport() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        AgentCreateReport.Input inp = new AgentCreateReport.Input();
        inp.reportName = 'Opps by Stage and Close';
        inp.reportType = 'Opportunity';
        inp.columns = 'OPPORTUNITY.NAME,AMOUNT';
        inp.reportFormat = 'MATRIX';
        inp.groupingsDown = 'STAGE_NAME';
        inp.groupingsAcross = 'CLOSE_DATE';

        Test.startTest();
        List<AgentCreateReport.Output> results = AgentCreateReport.createReport(
            new List<AgentCreateReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
    }

    @IsTest
    static void testMultiFiltersJson() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        AgentCreateReport.Input inp = new AgentCreateReport.Input();
        inp.reportName = 'Filtered Opps';
        inp.reportType = 'Opportunity';
        inp.columns = 'OPPORTUNITY.NAME,AMOUNT';
        inp.filtersJson = '[{"column":"STAGE_NAME","operator":"equals","value":"Closed Won"},{"column":"CLOSE_DATE","operator":"greaterThan","value":"2026-01-01"}]';

        Test.startTest();
        List<AgentCreateReport.Output> results = AgentCreateReport.createReport(
            new List<AgentCreateReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
    }

    @IsTest
    static void testDateFilter() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        AgentCreateReport.Input inp = new AgentCreateReport.Input();
        inp.reportName = 'This Year Opps';
        inp.reportType = 'Opportunity';
        inp.columns = 'OPPORTUNITY.NAME,AMOUNT';
        inp.dateFilter = 'CLOSE_DATE:THIS_FISCAL_YEAR';

        Test.startTest();
        List<AgentCreateReport.Output> results = AgentCreateReport.createReport(
            new List<AgentCreateReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
    }

    @IsTest
    static void testDateFilterWithoutColon() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        AgentCreateReport.Input inp = new AgentCreateReport.Input();
        inp.reportName = 'Bad Date Filter';
        inp.reportType = 'Opportunity';
        inp.columns = 'OPPORTUNITY.NAME';
        inp.dateFilter = 'THIS_FISCAL_YEAR';

        Test.startTest();
        List<AgentCreateReport.Output> results = AgentCreateReport.createReport(
            new List<AgentCreateReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
    }

    @IsTest
    static void testScopeUser() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        AgentCreateReport.Input inp = new AgentCreateReport.Input();
        inp.reportName = 'My Accounts';
        inp.reportType = 'AccountList';
        inp.columns = 'ACCOUNT.NAME';
        inp.scope = 'mine';

        Test.startTest();
        List<AgentCreateReport.Output> results = AgentCreateReport.createReport(
            new List<AgentCreateReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
    }

    @IsTest
    static void testFolderNotFound() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        AgentCreateReport.Input inp = new AgentCreateReport.Input();
        inp.reportName = 'Folder Report';
        inp.reportType = 'AccountList';
        inp.columns = 'ACCOUNT.NAME';
        inp.folderName = 'NonExistentFolderXYZ';

        Test.startTest();
        List<AgentCreateReport.Output> results = AgentCreateReport.createReport(
            new List<AgentCreateReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
    }

    @IsTest
    static void testLowercaseFormat() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        AgentCreateReport.Input inp = new AgentCreateReport.Input();
        inp.reportName = 'Lowercase Format';
        inp.reportType = 'AccountList';
        inp.columns = 'ACCOUNT.NAME';
        inp.reportFormat = 'tabular';

        Test.startTest();
        List<AgentCreateReport.Output> results = AgentCreateReport.createReport(
            new List<AgentCreateReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
    }

    @IsTest
    static void testApiError() {
        Test.setMock(HttpCalloutMock.class, new MockError());

        AgentCreateReport.Input inp = new AgentCreateReport.Input();
        inp.reportName = 'Fail Report';
        inp.reportType = 'CaseList';
        inp.columns = 'CASE_NUMBER';

        Test.startTest();
        List<AgentCreateReport.Output> results = AgentCreateReport.createReport(
            new List<AgentCreateReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].success);
        System.assertNotEquals(null, results[0].errorMessage);
    }

    @IsTest
    static void testCalloutException() {
        Test.setMock(HttpCalloutMock.class, new MockCalloutError());

        AgentCreateReport.Input inp = new AgentCreateReport.Input();
        inp.reportName = 'Exception Report';
        inp.reportType = 'CaseList';
        inp.columns = 'CASE_NUMBER';

        Test.startTest();
        List<AgentCreateReport.Output> results = AgentCreateReport.createReport(
            new List<AgentCreateReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].success);
    }

    @IsTest
    static void testMissingReportName() {
        AgentCreateReport.Output output = AgentCreateReport.execute(buildInput(null, 'CaseList', 'CASE_NUMBER'));
        System.assertEquals(false, output.success);
    }

    @IsTest
    static void testMissingReportType() {
        AgentCreateReport.Output output = AgentCreateReport.execute(buildInput('Test', null, 'CASE_NUMBER'));
        System.assertEquals(false, output.success);
    }

    @IsTest
    static void testMissingColumns() {
        AgentCreateReport.Output output = AgentCreateReport.execute(buildInput('Test', 'CaseList', ''));
        System.assertEquals(false, output.success);
    }

    @IsTest
    static void testInvalidFormat() {
        AgentCreateReport.Input inp = buildInput('Test', 'CaseList', 'CASE_NUMBER');
        inp.reportFormat = 'PIVOT';
        AgentCreateReport.Output output = AgentCreateReport.execute(inp);
        System.assertEquals(false, output.success);
    }

    @IsTest
    static void testSummaryWithoutGroupings() {
        AgentCreateReport.Input inp = buildInput('Test', 'CaseList', 'CASE_NUMBER');
        inp.reportFormat = 'SUMMARY';
        AgentCreateReport.Output output = AgentCreateReport.execute(inp);
        System.assertEquals(false, output.success);
    }

    @IsTest
    static void testInvalidFiltersJson() {
        AgentCreateReport.Input inp = buildInput('Test', 'CaseList', 'CASE_NUMBER');
        inp.filtersJson = 'not-valid-json';
        AgentCreateReport.Output output = AgentCreateReport.execute(inp);
        System.assertEquals(false, output.success);
    }

    @IsTest
    static void testSanitizeDeveloperName() {
        Test.startTest();
        AgentCreateReport.sanitizeDeveloperName('Open Opportunities by Stage');
        AgentCreateReport.sanitizeDeveloperName('123 Report');
        AgentCreateReport.sanitizeDeveloperName('Revenue (Q1) - 2026!');
        AgentCreateReport.sanitizeDeveloperName('This Is A Very Long Report Name That Exceeds Eighty Characters And Should Be Truncated By The Method');
        AgentCreateReport.sanitizeDeveloperName('');
        AgentCreateReport.sanitizeDeveloperName(null);
        AgentCreateReport.sanitizeDeveloperName('___');
        Test.stopTest();
    }

    @IsTest
    static void testInnerClassProperties() {
        AgentCreateReport.Input inp = new AgentCreateReport.Input();
        inp.reportName = 'Test';
        inp.reportType = 'AccountList';
        inp.columns = 'ACCOUNT.NAME';
        inp.reportFormat = 'MATRIX';
        inp.groupingsDown = 'ACCOUNT.INDUSTRY';
        inp.groupingsAcross = 'ACCOUNT.TYPE';
        inp.filterColumn = 'STATUS';
        inp.filterOperator = 'equals';
        inp.filterValue = 'Active';
        inp.filtersJson = '[]';
        inp.dateFilter = 'CREATED_DATE:LAST_30_DAYS';
        inp.scope = 'organization';
        inp.folderName = 'My Reports';

        AgentCreateReport.Output out = new AgentCreateReport.Output();
        out.reportId = '00Oxx0000000001';
        out.reportUrl = 'https://example.lightning.force.com/lightning/r/Report/00Oxx0000000001/view';
        out.reportPath = '/lightning/r/Report/00Oxx0000000001/view';
        out.reportName = 'Test';
        out.success = true;
        out.errorMessage = null;
    }

    // ---- Helpers ----

    private static AgentCreateReport.Input buildInput(String name, String reportType, String columns) {
        AgentCreateReport.Input inp = new AgentCreateReport.Input();
        inp.reportName = name;
        inp.reportType = reportType;
        inp.columns = columns;
        return inp;
    }

    // ---- Mocks ----

    private class MockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(JSON.serialize(new Map<String, Object>{
                'attributes' => new Map<String, Object>{
                    'reportId' => '00Og5000003TESTEA0',
                    'reportName' => 'Test Report',
                    'type' => 'Report'
                },
                'reportMetadata' => new Map<String, Object>{
                    'id' => '00Og5000003TESTEA0',
                    'standardDateFilter' => new Map<String, Object>{
                        'column' => 'CREATED_DATE',
                        'durationValue' => 'THIS_FISCAL_QUARTER',
                        'startDate' => '2026-04-01',
                        'endDate' => '2026-06-30'
                    }
                }
            }));
            return res;
        }
    }

    private class MockError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('[{"errorCode":"BAD_REQUEST","message":"Invalid column name"}]');
            return res;
        }
    }

    private class MockCalloutError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Simulated network error');
        }
    }
}
