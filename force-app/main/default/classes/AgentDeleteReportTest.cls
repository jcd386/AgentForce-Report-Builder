@IsTest
public class AgentDeleteReportTest {

    @IsTest
    static void testDeleteSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        AgentDeleteReport.Input inp = new AgentDeleteReport.Input();
        inp.reportId = '00Oxx0000000001';
        Test.startTest();
        List<AgentDeleteReport.Output> results = AgentDeleteReport.deleteReport(
            new List<AgentDeleteReport.Input>{ inp }
        );
        Test.stopTest();
        System.assertEquals(true, results[0].success);
    }

    @IsTest
    static void testDeleteError() {
        Test.setMock(HttpCalloutMock.class, new MockError());
        AgentDeleteReport.Input inp = new AgentDeleteReport.Input();
        inp.reportId = '00Oxx0000000001';
        Test.startTest();
        List<AgentDeleteReport.Output> results = AgentDeleteReport.deleteReport(
            new List<AgentDeleteReport.Input>{ inp }
        );
        Test.stopTest();
        System.assertEquals(false, results[0].success);
        System.assertNotEquals(null, results[0].errorMessage);
    }

    @IsTest
    static void testMissingReportId() {
        AgentDeleteReport.Input inp = new AgentDeleteReport.Input();
        AgentDeleteReport.Output out = AgentDeleteReport.execute(inp);
        System.assertEquals(false, out.success);
    }

    @IsTest
    static void testCalloutException() {
        Test.setMock(HttpCalloutMock.class, new MockCalloutError());
        AgentDeleteReport.Input inp = new AgentDeleteReport.Input();
        inp.reportId = '00Oxx0000000001';
        Test.startTest();
        List<AgentDeleteReport.Output> results = AgentDeleteReport.deleteReport(
            new List<AgentDeleteReport.Input>{ inp }
        );
        Test.stopTest();
        System.assertEquals(false, results[0].success);
    }

    @IsTest
    static void testInnerClassProperties() {
        AgentDeleteReport.Input inp = new AgentDeleteReport.Input();
        inp.reportId = '00Oxx0000000001';
        AgentDeleteReport.Output out = new AgentDeleteReport.Output();
        out.success = true;
        out.errorMessage = null;
    }

    private class MockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(204);
            res.setBody('');
            return res;
        }
    }

    private class MockError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(404);
            res.setBody('[{"errorCode":"NOT_FOUND","message":"Report not found"}]');
            return res;
        }
    }

    private class MockCalloutError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Simulated network error');
        }
    }
}
