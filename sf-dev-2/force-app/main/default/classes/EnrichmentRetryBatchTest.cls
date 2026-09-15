@IsTest
public class EnrichmentRetryBatchTest {

    @IsTest
    static void testBatchPicksUpFailedLeadAndRetries() {
        TestDataFactory.createFailedLead('https://stripe.com');
        TestDataFactory.createEnrichedLead('https://existing.com', Date.today());

        Test.setMock(HttpCalloutMock.class, EnrichmentHttpMock.success());

        Test.startTest();
        Database.executeBatch(new EnrichmentRetryBatch(), 1);
        Test.stopTest();

        Lead retried = [
            SELECT Enrichment_Status__c, Company_Name__c, Confidence_Score__c
            FROM Lead
            WHERE Website = 'https://stripe.com'
            LIMIT 1
        ];

        System.assertEquals('Enriched', retried.Enrichment_Status__c);
        System.assertEquals('Stripe', retried.Company_Name__c);
        System.assertEquals(0.92, retried.Confidence_Score__c);
    }

    @IsTest
    static void testBatchOnlyTargetsFailedLeads() {
        Lead newLead = TestDataFactory.createLead('https://new.com');
        Lead enrichedLead = TestDataFactory.createEnrichedLead('https://existing.com', Date.today());

        Test.startTest();
        Database.executeBatch(new EnrichmentRetryBatch(), 1);
        Test.stopTest();

        List<Lead> leads = [
            SELECT Enrichment_Status__c
            FROM Lead
            WHERE Id IN :new List<Id>{newLead.Id, enrichedLead.Id}
        ];

        for (Lead ld : leads) {
            System.assertNotEquals('In progress', ld.Enrichment_Status__c);
            System.assertNotEquals('Failed', ld.Enrichment_Status__c);
        }
    }
}