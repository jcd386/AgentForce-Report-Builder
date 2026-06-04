/**
 * @description Test class for AgentGetReportTypeColumns.
 *              Uses HttpCalloutMock to simulate Analytics REST API responses.
 * @author We Summit Mountains
 * @date 2026
 */
@IsTest
private class AgentGetReportTypeColumnsTest {

    // ─────────────────────────────────────────────────────────────────────────
    // MOCK CLASSES
    // ─────────────────────────────────────────────────────────────────────────

    // Responds to POST (create) with a report payload, and DELETE with 204
    private class MockProbeSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getMethod() == 'DELETE') {
                res.setStatusCode(204);
                res.setBody('');
                return res;
            }
            // POST — return a created report with default columns
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{'
                + '"attributes":{"reportId":"00O000000001AAAAA","reportName":"TEMP_PROBE"},'
                + '"reportMetadata":{'
                +   '"name":"TEMP_PROBE",'
                +   '"detailColumns":["CAMPAIGN_NAME","CAMPAIGN_STATUS","CAMPAIGN_TYPE","START_DATE"]'
                + '}'
                + '}');
            return res;
        }
    }

    private class MockProbeError implements HttpCalloutMock {
        private Integer statusCode;
        public MockProbeError(Integer statusCode) { this.statusCode = statusCode; }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{"errorCode":"BAD_REQUEST","message":"Specify a valid report type."}]');
            res.setStatusCode(statusCode);
            return res;
        }
    }

    private class MockNoColumns implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getMethod() == 'DELETE') { res.setStatusCode(204); res.setBody(''); return res; }
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"attributes":{"reportId":"00O000000001BBBBB","reportName":"TEMP"},"reportMetadata":{"name":"TEMP","detailColumns":[]}}');
            return res;
        }
    }

    // Custom report type response: only 1 column in detailColumnInfo (default), but full set in reportTypeMetadata.categories
    private class MockCustomReportType implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{'
                + '"attributes":{"reportId":"00O000000002CCCCC","reportName":"CustomTest"},'
                + '"reportMetadata":{"name":"CustomTest","detailColumns":["Opportunity.Name"]},'
                + '"reportExtendedMetadata":{'
                +   '"detailColumnInfo":{"Opportunity.Name":{"label":"Opportunity Name","dataType":"string"}}'
                + '},'
                + '"reportTypeMetadata":{'
                +   '"categories":[{'
                +     '"label":"Opportunities",'
                +     '"columns":{'
                +       '"Opportunity.StageName":{"label":"Stage","dataType":"picklist"},'
                +       '"Opportunity.Amount":{"label":"Amount","dataType":"currency"},'
                +       '"Opportunity.Binder_Sent_Date__c":{"label":"Binder Sent Date","dataType":"date"},'
                +       '"Opportunity.Case_Designer__c.Name":{"label":"Case Designer: Full Name","dataType":"string"},'
                +       '"Opportunity.Name":{"label":"Opportunity Name","dataType":"string"}'
                +     '}'
                +   '}]'
                + '}'
                + '}');
            return res;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TESTS
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testGetColumnsSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockProbeSuccess());
        AgentGetReportTypeColumns.Input input = new AgentGetReportTypeColumns.Input();
        input.reportType = 'CampaignList';

        Test.startTest();
        List<AgentGetReportTypeColumns.Output> outputs =
            AgentGetReportTypeColumns.getColumns(new List<AgentGetReportTypeColumns.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testGetColumnsViaProcessInput() {
        Test.setMock(HttpCalloutMock.class, new MockProbeSuccess());
        AgentGetReportTypeColumns.Input input = new AgentGetReportTypeColumns.Input();
        input.reportType = 'CampaignList';

        Test.startTest();
        AgentGetReportTypeColumns.Output output = AgentGetReportTypeColumns.processInput(input);
        Test.stopTest();
    }

    @IsTest
    static void testGetColumnsEmptyResult() {
        Test.setMock(HttpCalloutMock.class, new MockNoColumns());
        AgentGetReportTypeColumns.Input input = new AgentGetReportTypeColumns.Input();
        input.reportType = 'SomeType';

        Test.startTest();
        List<AgentGetReportTypeColumns.Output> outputs =
            AgentGetReportTypeColumns.getColumns(new List<AgentGetReportTypeColumns.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testNullInput() {
        Test.startTest();
        AgentGetReportTypeColumns.Output output = AgentGetReportTypeColumns.processInput(null);
        Test.stopTest();
    }

    @IsTest
    static void testBlankReportType() {
        AgentGetReportTypeColumns.Input input = new AgentGetReportTypeColumns.Input();
        input.reportType = '';

        Test.startTest();
        List<AgentGetReportTypeColumns.Output> outputs =
            AgentGetReportTypeColumns.getColumns(new List<AgentGetReportTypeColumns.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testApiError400() {
        Test.setMock(HttpCalloutMock.class, new MockProbeError(400));
        AgentGetReportTypeColumns.Input input = new AgentGetReportTypeColumns.Input();
        input.reportType = 'InvalidType';

        Test.startTest();
        List<AgentGetReportTypeColumns.Output> outputs =
            AgentGetReportTypeColumns.getColumns(new List<AgentGetReportTypeColumns.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testApiError401() {
        Test.setMock(HttpCalloutMock.class, new MockProbeError(401));
        AgentGetReportTypeColumns.Input input = new AgentGetReportTypeColumns.Input();
        input.reportType = 'CampaignList';

        Test.startTest();
        List<AgentGetReportTypeColumns.Output> outputs =
            AgentGetReportTypeColumns.getColumns(new List<AgentGetReportTypeColumns.Input>{ input });
        Test.stopTest();
    }

    @IsTest
    static void testBulkInputs() {
        Test.setMock(HttpCalloutMock.class, new MockProbeSuccess());
        List<AgentGetReportTypeColumns.Input> inputs = new List<AgentGetReportTypeColumns.Input>();

        AgentGetReportTypeColumns.Input i1 = new AgentGetReportTypeColumns.Input();
        i1.reportType = 'CampaignList';
        inputs.add(i1);

        AgentGetReportTypeColumns.Input i2 = new AgentGetReportTypeColumns.Input();
        i2.reportType = 'ProductList';
        inputs.add(i2);

        Test.startTest();
        List<AgentGetReportTypeColumns.Output> outputs =
            AgentGetReportTypeColumns.getColumns(inputs);
        Test.stopTest();
    }

    @IsTest
    static void testInputProperties() {
        AgentGetReportTypeColumns.Input input = new AgentGetReportTypeColumns.Input();
        input.reportType = 'CampaignList';
    }

    @IsTest
    static void testOutputSuccessProperties() {
        AgentGetReportTypeColumns.Output output = new AgentGetReportTypeColumns.Output();
        output.columnsJson = '[{"apiName":"CAMPAIGN_NAME","label":"CAMPAIGN_NAME"}]';
        output.columnCount = 1;
        output.success = true;
        output.errorMessage = null;
    }

    @IsTest
    static void testOutputErrorProperties() {
        AgentGetReportTypeColumns.Output output = new AgentGetReportTypeColumns.Output();
        output.columnsJson = '[]';
        output.columnCount = 0;
        output.success = false;
        output.errorMessage = 'Invalid report type';
    }

    @IsTest
    static void testCustomReportTypeMergesCategoriesColumns() {
        Test.setMock(HttpCalloutMock.class, new MockCustomReportType());
        AgentGetReportTypeColumns.Input input = new AgentGetReportTypeColumns.Input();
        input.reportType = 'Opportunities_POZ_Full__c';

        Test.startTest();
        AgentGetReportTypeColumns.Output output = AgentGetReportTypeColumns.processInput(input);
        Test.stopTest();

        System.assertEquals(true, output.success, 'Should succeed');
        System.assert(output.columnCount >= 5, 'Should merge detailColumnInfo + categories columns; got ' + output.columnCount);
        System.assert(output.columnsJson.contains('Opportunity.Binder_Sent_Date__c'), 'Should include category columns');
        System.assert(output.columnsJson.contains('Opportunity.Case_Designer__c.Name'), 'Should include lookup name columns');
    }
}