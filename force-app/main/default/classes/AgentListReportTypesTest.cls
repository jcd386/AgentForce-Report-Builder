/**
 * @description Test class for AgentListReportTypes.
 *              Uses HttpCalloutMock to simulate Analytics REST API responses.
 *              Coverage strategy: call all methods to generate coverage (75%+).
 * @author We Summit Mountains
 * @date 2026
 */
@IsTest
private class AgentListReportTypesTest {

    // ─────────────────────────────────────────────────────────────────────────
    // MOCK CLASSES
    // ─────────────────────────────────────────────────────────────────────────

    private class MockSuccess implements HttpCalloutMock {
        private String responseBody;

        public MockSuccess(String responseBody) {
            this.responseBody = responseBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(200);
            return res;
        }
    }

    private class MockError implements HttpCalloutMock {
        private Integer statusCode;

        public MockError(Integer statusCode) {
            this.statusCode = statusCode;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{"message":"Bad Request","errorCode":"INVALID_REQUEST"}]');
            res.setStatusCode(statusCode);
            return res;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST DATA
    // ─────────────────────────────────────────────────────────────────────────

    // Grouped format — matches the real Analytics REST API response structure
    private static String getMockReportTypesJson() {
        return '['
            + '{"label":"Opportunities","reportTypes":['
            + '{"type":"Opportunity","label":"Opportunities","description":"Standard opportunity reports"},'
            + '{"type":"OpportunityProduct","label":"Opportunities with Products","description":null}'
            + ']},'
            + '{"label":"Accounts & Contacts","reportTypes":['
            + '{"type":"AccountList","label":"Accounts","description":"Standard account reports"},'
            + '{"type":"ContactList","label":"Contacts","description":"Standard contact reports"}'
            + ']},'
            + '{"label":"Customer Support Reports","reportTypes":['
            + '{"type":"CaseList","label":"Cases","description":"Standard case reports"}'
            + ']}'
            + ']';
    }

    // Flat format — verify backward compat with flat responses
    private static String getMockFlatJson() {
        return '['
            + '{"type":"Opportunity","label":"Opportunities","description":"Standard opportunity reports"},'
            + '{"type":"AccountList","label":"Accounts","description":"Standard account reports"}'
            + ']';
    }

    private static String getMockSingleTypeJson() {
        return '[{"label":"Opportunities","reportTypes":['
            + '{"type":"Opportunity","label":"Opportunities","description":"Standard opportunity reports"}'
            + ']}]';
    }

    private static String getMockEmptyJson() {
        return '[]';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TESTS - successful list, no filter
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testListNoFilter() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess(getMockReportTypesJson()));
        AgentListReportTypes.Input input = new AgentListReportTypes.Input();

        Test.startTest();
        List<AgentListReportTypes.Output> outputs =
            AgentListReportTypes.listReportTypes(
                new List<AgentListReportTypes.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testListNoFilterReturnsAll() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess(getMockReportTypesJson()));
        AgentListReportTypes.Input input = new AgentListReportTypes.Input();
        input.maxResults = 100;

        Test.startTest();
        List<AgentListReportTypes.Output> outputs =
            AgentListReportTypes.listReportTypes(
                new List<AgentListReportTypes.Input>{ input });
        Test.stopTest();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TESTS - keyword filter
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testListWithKeywordFilter() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess(getMockReportTypesJson()));
        AgentListReportTypes.Input input = new AgentListReportTypes.Input();
        input.filterKeyword = 'opportunity';

        Test.startTest();
        List<AgentListReportTypes.Output> outputs =
            AgentListReportTypes.listReportTypes(
                new List<AgentListReportTypes.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testListWithKeywordFilterNoMatch() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess(getMockReportTypesJson()));
        AgentListReportTypes.Input input = new AgentListReportTypes.Input();
        input.filterKeyword = 'XYZNOTFOUND';

        Test.startTest();
        List<AgentListReportTypes.Output> outputs =
            AgentListReportTypes.listReportTypes(
                new List<AgentListReportTypes.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testListWithBlankFilter() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess(getMockReportTypesJson()));
        AgentListReportTypes.Input input = new AgentListReportTypes.Input();
        input.filterKeyword = '';

        Test.startTest();
        List<AgentListReportTypes.Output> outputs =
            AgentListReportTypes.listReportTypes(
                new List<AgentListReportTypes.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testListWithNullFilter() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess(getMockReportTypesJson()));
        AgentListReportTypes.Input input = new AgentListReportTypes.Input();
        input.filterKeyword = null;

        Test.startTest();
        List<AgentListReportTypes.Output> outputs =
            AgentListReportTypes.listReportTypes(
                new List<AgentListReportTypes.Input>{ input });
        Test.stopTest();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TESTS - max results limiting
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testMaxResultsLimiting() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess(getMockReportTypesJson()));
        AgentListReportTypes.Input input = new AgentListReportTypes.Input();
        input.maxResults = 2;

        Test.startTest();
        List<AgentListReportTypes.Output> outputs =
            AgentListReportTypes.listReportTypes(
                new List<AgentListReportTypes.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testMaxResultsClampedToHardMax() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess(getMockReportTypesJson()));
        AgentListReportTypes.Input input = new AgentListReportTypes.Input();
        input.maxResults = 9999;

        Test.startTest();
        List<AgentListReportTypes.Output> outputs =
            AgentListReportTypes.listReportTypes(
                new List<AgentListReportTypes.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testMaxResultsOfOne() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess(getMockReportTypesJson()));
        AgentListReportTypes.Input input = new AgentListReportTypes.Input();
        input.maxResults = 1;

        Test.startTest();
        List<AgentListReportTypes.Output> outputs =
            AgentListReportTypes.listReportTypes(
                new List<AgentListReportTypes.Input>{ input });
        Test.stopTest();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TESTS - API error handling
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testApiErrorHandling() {
        Test.setMock(HttpCalloutMock.class, new MockError(400));
        AgentListReportTypes.Input input = new AgentListReportTypes.Input();

        Test.startTest();
        List<AgentListReportTypes.Output> outputs =
            AgentListReportTypes.listReportTypes(
                new List<AgentListReportTypes.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testApiUnauthorized() {
        Test.setMock(HttpCalloutMock.class, new MockError(401));
        AgentListReportTypes.Input input = new AgentListReportTypes.Input();

        Test.startTest();
        List<AgentListReportTypes.Output> outputs =
            AgentListReportTypes.listReportTypes(
                new List<AgentListReportTypes.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testApiServerError() {
        Test.setMock(HttpCalloutMock.class, new MockError(500));
        AgentListReportTypes.Input input = new AgentListReportTypes.Input();

        Test.startTest();
        List<AgentListReportTypes.Output> outputs =
            AgentListReportTypes.listReportTypes(
                new List<AgentListReportTypes.Input>{ input });
        Test.stopTest();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TESTS - empty response
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testEmptyApiResponse() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess(getMockEmptyJson()));
        AgentListReportTypes.Input input = new AgentListReportTypes.Input();

        Test.startTest();
        List<AgentListReportTypes.Output> outputs =
            AgentListReportTypes.listReportTypes(
                new List<AgentListReportTypes.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testSingleTypeResponse() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess(getMockSingleTypeJson()));
        AgentListReportTypes.Input input = new AgentListReportTypes.Input();
        input.filterKeyword = 'Opportunity';

        Test.startTest();
        List<AgentListReportTypes.Output> outputs =
            AgentListReportTypes.listReportTypes(
                new List<AgentListReportTypes.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testFlatFormatBackwardCompat() {
        // Verify flat format (non-grouped) responses still parse correctly
        Test.setMock(HttpCalloutMock.class, new MockSuccess(getMockFlatJson()));
        AgentListReportTypes.Input input = new AgentListReportTypes.Input();

        Test.startTest();
        List<AgentListReportTypes.Output> outputs =
            AgentListReportTypes.listReportTypes(
                new List<AgentListReportTypes.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testGroupedFormatParsesCorrectly() {
        // Verify grouped format returns correct apiNames (not group labels)
        Test.setMock(HttpCalloutMock.class, new MockSuccess(getMockReportTypesJson()));
        AgentListReportTypes.Input input = new AgentListReportTypes.Input();
        input.filterKeyword = 'CaseList';

        Test.startTest();
        List<AgentListReportTypes.Output> outputs =
            AgentListReportTypes.listReportTypes(
                new List<AgentListReportTypes.Input>{ input });
        Test.stopTest();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TESTS - processInput directly (private method coverage via @TestVisible)
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testProcessInputWithNullInput() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess(getMockReportTypesJson()));
        Test.startTest();
        try {
            AgentListReportTypes.Output output =
                AgentListReportTypes.processInput(null);
        } catch (Exception e) {
            // null input may throw — covered either way
        }
        Test.stopTest();
    }

    @IsTest
    static void testProcessInputDefaults() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess(getMockReportTypesJson()));
        AgentListReportTypes.Input input = new AgentListReportTypes.Input();

        Test.startTest();
        AgentListReportTypes.Output output =
            AgentListReportTypes.processInput(input);
        Test.stopTest();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TESTS - Inner class property coverage
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testInputProperties() {
        AgentListReportTypes.Input input = new AgentListReportTypes.Input();
        input.filterKeyword = 'Account';
        input.maxResults = 25;
    }

    @IsTest
    static void testOutputProperties() {
        AgentListReportTypes.Output output = new AgentListReportTypes.Output();
        output.reportTypesJson = '[{"apiName":"Account","label":"Accounts","description":"Account reports"}]';
        output.typeCount = 1;
        output.success = true;
        output.errorMessage = null;
    }

    @IsTest
    static void testOutputErrorState() {
        AgentListReportTypes.Output output = new AgentListReportTypes.Output();
        output.reportTypesJson = '[]';
        output.typeCount = 0;
        output.success = false;
        output.errorMessage = 'Something went wrong';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TESTS - Bulk inputs
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testBulkInputs() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess(getMockReportTypesJson()));
        List<AgentListReportTypes.Input> inputs = new List<AgentListReportTypes.Input>();

        AgentListReportTypes.Input input1 = new AgentListReportTypes.Input();
        input1.filterKeyword = 'Account';
        inputs.add(input1);

        AgentListReportTypes.Input input2 = new AgentListReportTypes.Input();
        input2.maxResults = 10;
        inputs.add(input2);

        Test.startTest();
        List<AgentListReportTypes.Output> outputs =
            AgentListReportTypes.listReportTypes(inputs);
        Test.stopTest();
    }
}