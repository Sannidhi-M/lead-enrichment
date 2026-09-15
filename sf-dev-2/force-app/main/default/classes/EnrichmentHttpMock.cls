@isTest
public class EnrichmentHttpMock implements HttpCalloutMock {

    private Integer statusCode;
    private String responseBody;

    public EnrichmentHttpMock(Integer statusCode, String responseBody) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }

    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(statusCode);
        res.setBody(responseBody);
        res.setHeader('Content-Type', 'application/json');
        return res;
    }

    // convenience factory for a typical success payload
    public static EnrichmentHttpMock success() {
        String body = '{'
            + '"domain":"stripe.com",'
            + '"company_name":"Stripe",'
            + '"industry":"Financial Services",'
            + '"employee_count":5000,'
            + '"employee_range":"1001-5000",'
            + '"country":"United States",'
            + '"logo":"https://img.logo.dev/stripe.com",'
            + '"confidence_score":0.92'
            + '}';
        return new EnrichmentHttpMock(200, body);
    }

    public static EnrichmentHttpMock lowConfidence() {
        String body = '{'
            + '"domain":"smallco.com",'
            + '"company_name":"SmallCo",'
            + '"industry":"Unknown",'
            + '"employee_count":3,'
            + '"employee_range":"1-10",'
            + '"country":"United States",'
            + '"logo":null,'
            + '"confidence_score":0.4'
            + '}';
        return new EnrichmentHttpMock(200, body);
    }

    public static EnrichmentHttpMock serverError() {
        return new EnrichmentHttpMock(503, 'Service Unavailable');
    }
}