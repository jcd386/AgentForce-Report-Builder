@IsTest
public class AgentCreateReportTest {

    @IsTest
    static void testCreateReportSuccess() {
        // Mock the Analytics REST API response
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        AgentCreateReport.Input inp = new AgentCreateReport.Input();
        inp.reportName = 'Test Report';
        inp.reportType = 'CaseList';
        inp.columns = 'CASE_NUMBER,SUBJECT,STATUS';
        inp.filterColumn = 'STATUS';
        inp.filterOperator = 'notEqual';
        inp.filterValue = 'Closed';
        inp.groupByColumn = 'Case.Case_Category__c';

        Test.startTest();
        List<AgentCreateReport.Output> results = AgentCreateReport.createReport(
            new List<AgentCreateReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].success);
        System.assertEquals('00Og5000003TESTEA0', results[0].reportId);
        System.assertNotEquals(null, results[0].reportUrl);
        System.assert(results[0].reportUrl.contains('00Og5000003TESTEA0'));
        System.assert(results[0].reportUrl.contains('lightning.force.com'), 'URL must use lightning.force.com domain');
        System.assertNotEquals(null, results[0].reportPath);
        System.assert(results[0].reportPath.startsWith('/lightning/r/Report/'));
    }

    @IsTest
    static void testCreateReportApiError() {
        Test.setMock(HttpCalloutMock.class, new MockError());

        AgentCreateReport.Input inp = new AgentCreateReport.Input();
        inp.reportName = 'Test Report';
        inp.reportType = 'CaseList';
        inp.columns = 'CASE_NUMBER';

        Test.startTest();
        List<AgentCreateReport.Output> results = AgentCreateReport.createReport(
            new List<AgentCreateReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success);
        System.assertNotEquals(null, results[0].errorMessage);
    }

    @IsTest
    static void testCreateTabularReport() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        AgentCreateReport.Input inp = new AgentCreateReport.Input();
        inp.reportName = 'All Accounts Tabular';
        inp.reportType = 'AccountList';
        inp.columns = 'ACCOUNT.NAME,ACCOUNT.INDUSTRY,ACCOUNT.ANNUAL_REVENUE';
        // No group by — should produce TABULAR format

        Test.startTest();
        List<AgentCreateReport.Output> results = AgentCreateReport.createReport(
            new List<AgentCreateReport.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);
    }

    @IsTest
    static void testExceptionHandling() {
        Test.setMock(HttpCalloutMock.class, new MockCalloutError());

        AgentCreateReport.Input inp = new AgentCreateReport.Input();
        inp.reportName = 'Test Report';
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
