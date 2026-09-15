@isTest
public class TestDataFactory {

    public static Lead createLead(String website) {
        Lead ld = new Lead(
            LastName = 'TestLead',
            Company = 'Test Company',
            Website = website,
            Status = 'Open - Not Contacted',
            Enrichment_Status__c = 'New'
        );
        insert ld;
        return ld;
    }

    public static Lead createEnrichedLead(String website, Date lastEnrichedDate) {
        Lead ld = new Lead(
            LastName = 'TestLead',
            Company = 'Test Company',
            Website = website,
            Status = 'Open - Not Contacted',
            Enrichment_Status__c = 'Enriched',
            Last_Enriched_Date__c = lastEnrichedDate,
            Company_Name__c = 'Existing Co'
        );
        insert ld;
        return ld;
    }

    public static Lead createFailedLead(String website) {
        Lead ld = new Lead(
            LastName = 'TestLead',
            Company = 'Test Company',
            Website = website,
            Status = 'Open - Not Contacted',
            Enrichment_Status__c = 'Failed',
            Enrichment_Notes__c = 'Previous failure'
        );
        insert ld;
        return ld;
    }
}