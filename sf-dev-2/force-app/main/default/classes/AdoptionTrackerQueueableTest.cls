@IsTest
public class AdoptionTrackerQueueableTest {

    @IsTest
    static void testFirstEnrichmentInMonth() {
        User u = [SELECT Id, Monthly_Enrichment_Count__c, Enrichment_Count_Month__c FROM User WHERE Id = :UserInfo.getUserId()];

        u.Monthly_Enrichment_Count__c = null;
        u.Enrichment_Count_Month__c = null;
        update u;

        Test.startTest();
        System.enqueueJob(new AdoptionTrackerQueueable(u.Id));
        Test.stopTest();

        User updated = [SELECT Monthly_Enrichment_Count__c, Enrichment_Count_Month__c FROM User WHERE Id = :u.Id];

        System.assertEquals(1, updated.Monthly_Enrichment_Count__c);
        System.assertEquals(Date.today().toStartOfMonth(), updated.Enrichment_Count_Month__c);
    }

    @IsTest
    static void testIncrementExistingCount() {
        User u = [SELECT Id, Monthly_Enrichment_Count__c, Enrichment_Count_Month__c FROM User WHERE Id = :UserInfo.getUserId()];

        u.Monthly_Enrichment_Count__c = 3;
        u.Enrichment_Count_Month__c = Date.today().toStartOfMonth();
        update u;

        Test.startTest();
        System.enqueueJob(new AdoptionTrackerQueueable(u.Id));
        Test.stopTest();

        User updated = [SELECT Monthly_Enrichment_Count__c FROM User WHERE Id = :u.Id];

        System.assertEquals(4, updated.Monthly_Enrichment_Count__c);
    }

    @IsTest
    static void testNewMonthResetsCount() {
        User u = [SELECT Id, Monthly_Enrichment_Count__c, Enrichment_Count_Month__c FROM User WHERE Id = :UserInfo.getUserId()];

        u.Monthly_Enrichment_Count__c = 5;
        u.Enrichment_Count_Month__c = Date.today().addMonths(-1).toStartOfMonth();
        update u;

        Test.startTest();
        System.enqueueJob(new AdoptionTrackerQueueable(u.Id));
        Test.stopTest();

        User updated = [SELECT Monthly_Enrichment_Count__c, Enrichment_Count_Month__c FROM User WHERE Id = :u.Id];

        System.assertEquals(1, updated.Monthly_Enrichment_Count__c);
        System.assertEquals(Date.today().toStartOfMonth(), updated.Enrichment_Count_Month__c);
    }
}