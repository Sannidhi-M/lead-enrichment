@IsTest
public class EnrichmentQueueableTest {

    @IsTest
    static void testSuccessPath() {
        Lead ld = TestDataFactory.createLead('https://stripe.com');
        ld.Enrichment_Status__c = 'In progress';
        update ld;

        Test.setMock(HttpCalloutMock.class, EnrichmentHttpMock.success());

        Test.startTest();
        System.enqueueJob(new EnrichmentQueueable(ld.Id));
        Test.stopTest();

        Lead updated = [SELECT Enrichment_Status__c, Company_Name__c, Confidence_Score__c,Enrichment_Notes__c FROM Lead WHERE Id = :ld.Id];

        System.debug('STATUS: ' + updated.Enrichment_Status__c);
        System.debug('NOTES: ' + updated.Enrichment_Notes__c);
        System.assertEquals('Enriched', updated.Enrichment_Status__c);
        System.assertEquals('Stripe', updated.Company_Name__c);
        System.assertEquals(0.92, updated.Confidence_Score__c);
    }

    @IsTest
    static void testFailurePath() {
        Lead ld = TestDataFactory.createLead('https://stripe.com');
        ld.Enrichment_Status__c = 'In progress';
        update ld;

        Test.setMock(HttpCalloutMock.class, EnrichmentHttpMock.serverError());

        Test.startTest();
        System.enqueueJob(new EnrichmentQueueable(ld.Id));
        Test.stopTest();

        Lead updated = [SELECT Enrichment_Status__c, Enrichment_Notes__c FROM Lead WHERE Id = :ld.Id];

        System.assertEquals('Failed', updated.Enrichment_Status__c);
        System.assert(updated.Enrichment_Notes__c.contains('Enrichment API returned status 503'));
    }

    @IsTest
    static void testMissingWebsite() {
        Lead ld = new Lead(
            LastName = 'Test',
            Company = 'Test Company',
            Enrichment_Status__c = 'In progress'
        );
        insert ld;

        Test.startTest();
        System.enqueueJob(new EnrichmentQueueable(ld.Id));
        Test.stopTest();

        Lead updated = [SELECT Enrichment_Status__c, Enrichment_Notes__c FROM Lead WHERE Id = :ld.Id];

        System.assertEquals('Failed', updated.Enrichment_Status__c);
        System.assert(updated.Enrichment_Notes__c.contains('Website is blank'));
    }
}