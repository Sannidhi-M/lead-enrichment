@IsTest
public class EnrichmentServiceTest {

    @IsTest
    static void testGetDomain_stripsProtocolAndWww() {
        System.assertEquals('stripe.com', EnrichmentService.getDomain('https://www.stripe.com'));
        System.assertEquals('stripe.com', EnrichmentService.getDomain('http://stripe.com'));
        System.assertEquals('stripe.com', EnrichmentService.getDomain('www.stripe.com'));
        System.assertEquals('stripe.com', EnrichmentService.getDomain('stripe.com'));
    }

    @IsTest
    static void testGetDomain_stripsPath() {
        System.assertEquals('stripe.com', EnrichmentService.getDomain('https://www.stripe.com/pricing'));
    }

    @IsTest
    static void testGetDomain_handlesSpacesAndCase() {
        System.assertEquals('stripe.com', EnrichmentService.getDomain('  HTTPS://WWW.STRIPE.COM/pricing  '));
    }

    @IsTest
    static void testGetDomain_blankThrows() {
        try {
            EnrichmentService.getDomain('');
            System.assert(false, 'Expected IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Website is blank', e.getMessage());
        }
    }

    @IsTest
    static void testGetQueryParams_containsExpectedFields() {
        Lead ld = TestDataFactory.createLead('https://stripe.com');

        String queryParams = EnrichmentService.getQueryParams(ld.Id);

        System.assert(queryParams.contains('domain=stripe.com'));
        System.assert(queryParams.contains('fields='));
        System.assert(queryParams.contains('company_name'));
        System.assert(queryParams.contains('industry'));
        System.assert(queryParams.contains('employee_count'));
        System.assert(queryParams.contains('employee_range'));
        System.assert(queryParams.contains('country'));
        System.assert(queryParams.contains('logo'));
        System.assert(queryParams.contains('confidence_score'));
    }

    @IsTest
    static void testSaveEnrichedLead_highConfidence_clearsNotes() {
        Lead ld = TestDataFactory.createFailedLead('https://stripe.com');

        EnrichmentResponse data = new EnrichmentResponse();
        data.domain = 'stripe.com';
        data.company_name = 'Stripe';
        data.industry = 'Fintech';
        data.employee_count = 5000;
        data.employee_range = '1001-5000';
        data.country = 'United States';
        data.logo = 'https://img.logo.dev/stripe.com';
        data.confidence_score = 0.9;

        Test.startTest();
        EnrichmentService.saveEnrichedLead(ld.Id, data);
        Test.stopTest();

        Lead updated = [
            SELECT Enrichment_Status__c, Enrichment_Domain__c, Company_Name__c, Enriched_industry__c,
                Employee_count__c, Employee_range__c, Enriched_Country__c, Eriched_logo__c,
                Confidence_Score__c, Last_Enriched_Date__c, Enrichment_Notes__c
            FROM Lead
            WHERE Id = :ld.Id
        ];

        System.assertEquals('Enriched', updated.Enrichment_Status__c);
        System.assertEquals('stripe.com', updated.Enrichment_Domain__c);
        System.assertEquals('Stripe', updated.Company_Name__c);
        System.assertEquals('Fintech', updated.Enriched_industry__c);
        System.assertEquals(5000, updated.Employee_count__c);
        System.assertEquals('1001-5000', updated.Employee_range__c);
        System.assertEquals('United States', updated.Enriched_Country__c);
        System.assertEquals('https://img.logo.dev/stripe.com', updated.Eriched_logo__c);
        System.assertEquals(0.9, updated.Confidence_Score__c);
        System.assertEquals(Date.today(), updated.Last_Enriched_Date__c);
        System.assertEquals(null, updated.Enrichment_Notes__c);
    }

    @IsTest
    static void testSaveEnrichedLead_lowConfidence_addsWarning() {
        Lead ld = TestDataFactory.createLead('https://smallco.com');

        EnrichmentResponse data = new EnrichmentResponse();
        data.domain = 'smallco.com';
        data.company_name = 'SmallCo';
        data.industry = 'Unknown';
        data.employee_count = 3;
        data.employee_range = '1-10';
        data.country = 'United States';
        data.confidence_score = 0.4;

        Test.startTest();
        EnrichmentService.saveEnrichedLead(ld.Id, data);
        Test.stopTest();

        Lead updated = [SELECT Enrichment_Status__c, Confidence_Score__c, Enrichment_Notes__c FROM Lead WHERE Id = :ld.Id];

        System.assertEquals('Enriched', updated.Enrichment_Status__c);
        System.assertEquals(0.4, updated.Confidence_Score__c);
        System.assertEquals('Low confidence in enriched data', updated.Enrichment_Notes__c);
    }

    @IsTest
    static void testMarkLeadFailed_setsStatusAndMessage() {
        Lead ld = TestDataFactory.createLead('https://stripe.com');

        Test.startTest();
        EnrichmentService.markLeadFailed(ld.Id, 'API temporarily unavailable');
        Test.stopTest();

        Lead updated = [SELECT Enrichment_Status__c, Enrichment_Notes__c FROM Lead WHERE Id = :ld.Id];

        System.assertEquals('Failed', updated.Enrichment_Status__c);
        System.assertEquals('Enrichment failed: API temporarily unavailable', updated.Enrichment_Notes__c);
    }

    @IsTest
    static void testMarkLeadFailed_truncatesLongMessage() {
        Lead ld = TestDataFactory.createLead('https://stripe.com');

        String longMessage = '';
        for (Integer i = 0; i < 33000; i++) {
            longMessage += 'x';
        }

        Test.startTest();
        EnrichmentService.markLeadFailed(ld.Id, longMessage);
        Test.stopTest();

        Lead updated = [SELECT Enrichment_Status__c, Enrichment_Notes__c FROM Lead WHERE Id = :ld.Id];

        System.assertEquals('Failed', updated.Enrichment_Status__c);
        System.assertEquals(32768, updated.Enrichment_Notes__c.length());
        System.assert(updated.Enrichment_Notes__c.endsWith('...'));
    }

    @IsTest
    static void testIncrementUserEnrichmentCount_firstTimeThisMonth() {
        User u = [SELECT Id, Monthly_Enrichment_Count__c, Enrichment_Count_Month__c FROM User WHERE Id = :UserInfo.getUserId()];

        u.Monthly_Enrichment_Count__c = null;
        u.Enrichment_Count_Month__c = null;
        update u;

        Test.startTest();
        EnrichmentService.incrementUserEnrichmentCount(u.Id);
        Test.stopTest();

        User updated = [SELECT Monthly_Enrichment_Count__c, Enrichment_Count_Month__c FROM User WHERE Id = :u.Id];

        System.assertEquals(1, updated.Monthly_Enrichment_Count__c);
        System.assertEquals(Date.today().toStartOfMonth(), updated.Enrichment_Count_Month__c);
    }

    @IsTest
    static void testIncrementUserEnrichmentCount_incrementsWithinSameMonth() {
        User u = [SELECT Id, Monthly_Enrichment_Count__c, Enrichment_Count_Month__c FROM User WHERE Id = :UserInfo.getUserId()];

        u.Monthly_Enrichment_Count__c = 5;
        u.Enrichment_Count_Month__c = Date.today().toStartOfMonth();
        update u;

        Test.startTest();
        EnrichmentService.incrementUserEnrichmentCount(u.Id);
        Test.stopTest();

        User updated = [SELECT Monthly_Enrichment_Count__c, Enrichment_Count_Month__c FROM User WHERE Id = :u.Id];

        System.assertEquals(6, updated.Monthly_Enrichment_Count__c);
        System.assertEquals(Date.today().toStartOfMonth(), updated.Enrichment_Count_Month__c);
    }

    @IsTest
    static void testIncrementUserEnrichmentCount_resetsForNewMonth() {
        User u = [SELECT Id, Monthly_Enrichment_Count__c, Enrichment_Count_Month__c FROM User WHERE Id = :UserInfo.getUserId()];

        u.Monthly_Enrichment_Count__c = 50;
        u.Enrichment_Count_Month__c = Date.today().addMonths(-1).toStartOfMonth();
        update u;

        Test.startTest();
        EnrichmentService.incrementUserEnrichmentCount(u.Id);
        Test.stopTest();

        User updated = [SELECT Monthly_Enrichment_Count__c, Enrichment_Count_Month__c FROM User WHERE Id = :u.Id];

        System.assertEquals(1, updated.Monthly_Enrichment_Count__c);
        System.assertEquals(Date.today().toStartOfMonth(), updated.Enrichment_Count_Month__c);
    }

    @IsTest
    static void testPerformEnrichment_success() {
        Lead ld = TestDataFactory.createLead('https://stripe.com');

        Test.setMock(HttpCalloutMock.class, EnrichmentHttpMock.success());

        Test.startTest();
        EnrichmentService.performEnrichment(ld.Id);
        Test.stopTest();

        Lead updated = [
            SELECT Enrichment_Status__c, Enrichment_Domain__c, Company_Name__c,
                Enriched_industry__c, Employee_count__c, Employee_range__c,
                Enriched_Country__c, Eriched_logo__c, Confidence_Score__c,
                Last_Enriched_Date__c
            FROM Lead
            WHERE Id = :ld.Id
        ];

        System.assertEquals('Enriched', updated.Enrichment_Status__c);
        System.assertEquals('stripe.com', updated.Enrichment_Domain__c);
        System.assertEquals('Stripe', updated.Company_Name__c);
        System.assertEquals('Financial Services', updated.Enriched_industry__c);
        System.assertEquals(5000, updated.Employee_count__c);
        System.assertEquals('1001-5000', updated.Employee_range__c);
        System.assertEquals('United States', updated.Enriched_Country__c);
        System.assertEquals('https://img.logo.dev/stripe.com', updated.Eriched_logo__c);
        System.assertEquals(0.92, updated.Confidence_Score__c);
        System.assertEquals(Date.today(), updated.Last_Enriched_Date__c);
    }

    @IsTest
    static void testPerformEnrichment_lowConfidence() {
        Lead ld = TestDataFactory.createLead('https://smallco.com');

        Test.setMock(HttpCalloutMock.class, EnrichmentHttpMock.lowConfidence());

        Test.startTest();
        EnrichmentService.performEnrichment(ld.Id);
        Test.stopTest();

        Lead updated = [SELECT Enrichment_Status__c, Confidence_Score__c, Enrichment_Notes__c FROM Lead WHERE Id = :ld.Id];

        System.assertEquals('Enriched', updated.Enrichment_Status__c);
        System.assertEquals(0.4, updated.Confidence_Score__c);
        System.assertEquals('Low confidence in enriched data', updated.Enrichment_Notes__c);
    }

    @IsTest
    static void testPerformEnrichment_apiFailure() {
        Lead ld = TestDataFactory.createLead('https://stripe.com');

        Test.setMock(HttpCalloutMock.class, EnrichmentHttpMock.serverError());

        Test.startTest();
        EnrichmentService.performEnrichment(ld.Id);
        Test.stopTest();

        Lead updated = [SELECT Enrichment_Status__c, Enrichment_Notes__c FROM Lead WHERE Id = :ld.Id];

        System.assertEquals('Failed', updated.Enrichment_Status__c);
        System.assert(updated.Enrichment_Notes__c.contains('Enrichment API returned status 503'));
    }

    @IsTest
    static void testPerformEnrichment_missingWebsite() {
        Lead ld = new Lead(LastName = 'TestLead', Company = 'Test Company', Enrichment_Status__c = 'New');
        insert ld;

        Test.startTest();
        EnrichmentService.performEnrichment(ld.Id);
        Test.stopTest();

        Lead updated = [SELECT Enrichment_Status__c, Enrichment_Notes__c FROM Lead WHERE Id = :ld.Id];

        System.assertEquals('Failed', updated.Enrichment_Status__c);
        System.assert(updated.Enrichment_Notes__c.contains('Website is blank'));
    }
}