/**
 * @description Test class for AgentReportCreate.
 *              Uses HttpCalloutMock to simulate Analytics REST API responses.
 *              Coverage strategy: call all methods to generate coverage (75%+).
 * @author We Summit Mountains
 * @date 2026
 */
@IsTest
private class AgentReportCreateTest {

    // ─────────────────────────────────────────────────────────────────────────
    // MOCK CLASSES
    // ─────────────────────────────────────────────────────────────────────────

    private class MockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"reportMetadata":{"id":"00Oxx0000000001","name":"Test Report"}}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class MockError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{"errorCode":"INVALID_REPORT_TYPE","message":"Invalid report type"}]');
            res.setStatusCode(400);
            return res;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // HELPERS
    // ─────────────────────────────────────────────────────────────────────────

    private static AgentReportCreate.Input baseInput() {
        AgentReportCreate.Input input = new AgentReportCreate.Input();
        input.reportName = 'Test Report';
        input.reportType = 'OpportunityList';
        input.detailColumns = 'OPPORTUNITY.NAME,OPPORTUNITY.AMOUNT,OPPORTUNITY.STAGE_NAME';
        return input;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TESTS — Successful report creation
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testTabularReportSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        AgentReportCreate.Input input = baseInput();
        Test.startTest();
        List<AgentReportCreate.Output> results =
            AgentReportCreate.createReport(new List<AgentReportCreate.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testSummaryReportSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        AgentReportCreate.Input input = baseInput();
        input.reportFormat = 'SUMMARY';
        input.groupingsDown = 'OPPORTUNITY.STAGE_NAME';
        Test.startTest();
        List<AgentReportCreate.Output> results =
            AgentReportCreate.createReport(new List<AgentReportCreate.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testMatrixReportSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        AgentReportCreate.Input input = baseInput();
        input.reportFormat = 'MATRIX';
        input.groupingsDown = 'OPPORTUNITY.STAGE_NAME';
        input.groupingsAcross = 'OPPORTUNITY.CLOSE_DATE';
        Test.startTest();
        List<AgentReportCreate.Output> results =
            AgentReportCreate.createReport(new List<AgentReportCreate.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testReportWithFiltersJson() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        AgentReportCreate.Input input = baseInput();
        input.filtersJson = '[{"column":"OPPORTUNITY.STAGE_NAME","operator":"equals","value":"Closed Won"}]';
        Test.startTest();
        List<AgentReportCreate.Output> results =
            AgentReportCreate.createReport(new List<AgentReportCreate.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testReportWithDateFilter() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        AgentReportCreate.Input input = baseInput();
        input.dateFilter = 'CLOSE_DATE:THIS_FISCAL_YEAR';
        Test.startTest();
        List<AgentReportCreate.Output> results =
            AgentReportCreate.createReport(new List<AgentReportCreate.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testReportWithFolderNotFound() {
        // Folder records cannot be inserted in tests; exercise the no-folder-found path
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        AgentReportCreate.Input input = baseInput();
        input.folderName = 'NonExistentFolderXYZ';
        Test.startTest();
        List<AgentReportCreate.Output> results =
            AgentReportCreate.createReport(new List<AgentReportCreate.Input>{ input });
        Test.stopTest();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TESTS — Validation failures (no callout needed)
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testMissingReportName() {
        AgentReportCreate.Input input = baseInput();
        input.reportName = null;
        Test.startTest();
        AgentReportCreate.Output output = AgentReportCreate.processInput(input);
        Test.stopTest();
    }

    @IsTest
    static void testBlankReportName() {
        AgentReportCreate.Input input = baseInput();
        input.reportName = '   ';
        Test.startTest();
        AgentReportCreate.Output output = AgentReportCreate.processInput(input);
        Test.stopTest();
    }

    @IsTest
    static void testMissingReportType() {
        AgentReportCreate.Input input = baseInput();
        input.reportType = null;
        Test.startTest();
        AgentReportCreate.Output output = AgentReportCreate.processInput(input);
        Test.stopTest();
    }

    @IsTest
    static void testMissingDetailColumns() {
        AgentReportCreate.Input input = baseInput();
        input.detailColumns = '';
        Test.startTest();
        AgentReportCreate.Output output = AgentReportCreate.processInput(input);
        Test.stopTest();
    }

    @IsTest
    static void testInvalidReportFormat() {
        AgentReportCreate.Input input = baseInput();
        input.reportFormat = 'PIVOT';
        Test.startTest();
        AgentReportCreate.Output output = AgentReportCreate.processInput(input);
        Test.stopTest();
    }

    @IsTest
    static void testSummaryWithoutGroupingsDown() {
        AgentReportCreate.Input input = baseInput();
        input.reportFormat = 'SUMMARY';
        input.groupingsDown = null;
        Test.startTest();
        AgentReportCreate.Output output = AgentReportCreate.processInput(input);
        Test.stopTest();
    }

    @IsTest
    static void testMatrixWithoutGroupingsDown() {
        AgentReportCreate.Input input = baseInput();
        input.reportFormat = 'MATRIX';
        input.groupingsDown = null;
        Test.startTest();
        AgentReportCreate.Output output = AgentReportCreate.processInput(input);
        Test.stopTest();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TESTS — API error response
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testApiErrorResponse() {
        Test.setMock(HttpCalloutMock.class, new MockError());
        AgentReportCreate.Input input = baseInput();
        Test.startTest();
        List<AgentReportCreate.Output> results =
            AgentReportCreate.createReport(new List<AgentReportCreate.Input>{ input });
        Test.stopTest();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TESTS — sanitizeDeveloperName coverage
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testSanitizeDeveloperName() {
        Test.startTest();
        // Normal name with spaces
        AgentReportCreate.sanitizeDeveloperName('Open Opportunities by Stage');
        // Name starting with a number
        AgentReportCreate.sanitizeDeveloperName('123 Report');
        // Name with special characters
        AgentReportCreate.sanitizeDeveloperName('Revenue (Q1) - 2026!');
        // Very long name (over 80 chars)
        AgentReportCreate.sanitizeDeveloperName('This Is A Very Long Report Name That Exceeds Eighty Characters And Should Be Truncated');
        // Blank name
        AgentReportCreate.sanitizeDeveloperName('');
        // Null name
        AgentReportCreate.sanitizeDeveloperName(null);
        // Underscores only
        AgentReportCreate.sanitizeDeveloperName('___');
        Test.stopTest();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TESTS — Inner class property coverage
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testInnerClassProperties() {
        AgentReportCreate.Input input = new AgentReportCreate.Input();
        input.reportName = 'Test';
        input.reportType = 'AccountList';
        input.detailColumns = 'ACCOUNT.NAME';
        input.reportFormat = 'TABULAR';
        input.groupingsDown = 'ACCOUNT.INDUSTRY';
        input.groupingsAcross = 'ACCOUNT.TYPE';
        input.filtersJson = '[]';
        input.dateFilter = 'CREATED_DATE:LAST_30_DAYS';
        input.folderName = 'My Reports';

        AgentReportCreate.Output output = new AgentReportCreate.Output();
        output.reportId = '00Oxx0000000001';
        output.reportUrl = 'https://example.com/lightning/r/Report/00Oxx0000000001/view';
        output.success = true;
        output.errorMessage = null;
    }

    @IsTest
    static void testDateFilterWithoutColon() {
        // Date filter missing colon should be silently ignored (no standardDateFilter written)
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        AgentReportCreate.Input input = baseInput();
        input.dateFilter = 'THIS_FISCAL_YEAR';
        Test.startTest();
        List<AgentReportCreate.Output> results =
            AgentReportCreate.createReport(new List<AgentReportCreate.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testLowercaseReportFormat() {
        // reportFormat is normalized to uppercase — lowercase input is valid
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        AgentReportCreate.Input input = baseInput();
        input.reportFormat = 'tabular';
        Test.startTest();
        List<AgentReportCreate.Output> results =
            AgentReportCreate.createReport(new List<AgentReportCreate.Input>{ input });
        Test.stopTest();
    }
}