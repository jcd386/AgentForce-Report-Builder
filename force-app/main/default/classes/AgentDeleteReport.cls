public with sharing class AgentDeleteReport {

    private static final String API_VERSION = 'v65.0';

    public class Input {
        @InvocableVariable(required=true label='Report ID' description='Salesforce ID of the report to delete.')
        public String reportId;
    }

    public class Output {
        @InvocableVariable(label='Success' description='True if the report was deleted successfully.')
        public Boolean success;

        @InvocableVariable(label='Error Message' description='Error details when success is false.')
        public String errorMessage;
    }

    @InvocableMethod(
        label='Delete Salesforce Report'
        description='Deletes a report by ID via the Analytics REST API. Internal utility for cleanup.'
        category='Agent Reporting'
        callout=true
    )
    public static List<Output> deleteReport(List<Input> inputs) {
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
            if (String.isBlank(inp.reportId)) {
                out.success = false;
                out.errorMessage = 'reportId is required';
                return out;
            }
            String sessionId = getSessionId();
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/services/data/' + API_VERSION + '/analytics/reports/' + inp.reportId);
            req.setMethod('DELETE');
            req.setHeader('Authorization', 'Bearer ' + sessionId);
            req.setTimeout(15000);
            HttpResponse res = new Http().send(req);
            out.success = (res.getStatusCode() == 200 || res.getStatusCode() == 204);
            if (!out.success) {
                out.errorMessage = 'Delete failed (HTTP ' + res.getStatusCode() + '): ' + res.getBody().abbreviate(200);
            }
        } catch (Exception e) {
            out.success = false;
            out.errorMessage = e.getMessage();
        }
        return out;
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
