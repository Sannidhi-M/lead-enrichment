@IsTest
public class EnrichmentControllerTest {

    @IsTest
    static void testCachedPathReturnsStoredData() {
        Lead ld = TestDataFactory.createEnrichedLead('https://stripe.com', Date.today().addDays(-2));

        Test.startTest();
        EnrichmentResponse response = EnrichmentController.enrichLead(ld.Id, false);
        Test.stopTest();

        System.assertEquals(true, response.isCached);
        System.assertEquals('Existing Co', response.company_name);
        System.assertEquals('Enriched', response.status);
    }

    @IsTest
    static void testStaleDataTriggersEnrichment() {
        Lead ld = TestDataFactory.createEnrichedLead('https://stripe.com', Date.today().addDays(-10));

        Test.setMock(HttpCalloutMock.class, EnrichmentHttpMock.success());

        Test.startTest();
        EnrichmentResponse response = EnrichmentController.enrichLead(ld.Id, false);

        System.assertEquals(false, response.isCached);
        System.assertEquals('In progress', response.status);

        Lead updated = [SELECT Enrichment_Status__c FROM Lead WHERE Id = :ld.Id];
        System.assertEquals('In progress', updated.Enrichment_Status__c);

        Test.stopTest();
    }

    @IsTest
    static void testForceEnrichBypassesCache() {
        Lead ld = TestDataFactory.createEnrichedLead('https://stripe.com', Date.today());

        Test.setMock(HttpCalloutMock.class, EnrichmentHttpMock.success());

        Test.startTest();
        EnrichmentResponse response = EnrichmentController.enrichLead(ld.Id, true);

        System.assertEquals(false, response.isCached);
        System.assertEquals('In progress', response.status);

        Lead updated = [SELECT Enrichment_Status__c FROM Lead WHERE Id = :ld.Id];
        System.assertEquals('In progress', updated.Enrichment_Status__c);

        Test.stopTest();
    }

    @IsTest
    static void testAlreadyInProgressThrowsException() {
        Lead ld = TestDataFactory.createLead('https://stripe.com');
        ld.Enrichment_Status__c = 'In progress';
        update ld;

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            EnrichmentController.enrichLead(ld.Id, false);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown);
    }

    @IsTest
    static void testNewLeadLocksAndEnqueues() {
        Lead ld = TestDataFactory.createLead('https://stripe.com');

        Test.setMock(HttpCalloutMock.class, EnrichmentHttpMock.success());

        Test.startTest();
        EnrichmentResponse response = EnrichmentController.enrichLead(ld.Id, false);

        System.assertEquals(false, response.isCached);
        System.assertEquals('In progress', response.status);

        Lead updated = [SELECT Enrichment_Status__c FROM Lead WHERE Id = :ld.Id];
        System.assertEquals('In progress', updated.Enrichment_Status__c);

        Test.stopTest();
    }

    @IsTest
    static void testCacheWindowExactlySevenDays() {
        Boolean result = EnrichmentController.isWithinCacheWindow(Date.today().addDays(-7), 'Enriched');

        System.assertEquals(true, result);
    }

    @IsTest
    static void testCacheWindowOlderThanSevenDays() {
        Boolean result = EnrichmentController.isWithinCacheWindow(Date.today().addDays(-8), 'Enriched');

        System.assertEquals(false, result);
    }

    @IsTest
    static void testCacheWindowNullDate() {
        Boolean result = EnrichmentController.isWithinCacheWindow(null, 'Enriched');

        System.assertEquals(false, result);
    }

    @IsTest
    static void testCacheWindowWrongStatus() {
        Boolean result = EnrichmentController.isWithinCacheWindow(Date.today(), 'Failed');

        System.assertEquals(false, result);
    }
}