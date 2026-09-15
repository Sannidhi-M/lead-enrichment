public with sharing class EnrichmentController {

    private static final Integer CACHE_VALIDITY_DAYS = 7;

    @AuraEnabled
    public static EnrichmentResponse enrichLead(Id leadId, Boolean forceEnrich) {

        Lead leadRecord = [
            SELECT Id, Enrichment_Status__c, Enrichment_Domain__c, Company_Name__c,
                   Enriched_industry__c, Employee_count__c, Employee_range__c,
                   Enriched_Country__c, Eriched_logo__c, Confidence_Score__c,
                   Last_Enriched_Date__c
            FROM Lead WHERE Id = :leadId LIMIT 1 FOR UPDATE
        ];

        // 1. Cached path — return final data immediately, no async needed
        if (!forceEnrich && isWithinCacheWindow(leadRecord.Last_Enriched_Date__c, leadRecord.Enrichment_Status__c)) {
            return buildCachedResponse(leadRecord);
        }

        // 2. Already in progress — don't double-enqueue
        if (leadRecord.Enrichment_Status__c == 'In progress') {
            throw new AuraHandledException('Lead is already being enriched.');
        }

        // 3. Lock the record before enqueueing the async job
        leadRecord.Enrichment_Status__c = 'In progress';
        try {
            update leadRecord;
        } catch (Exception e) {
            throw new AuraHandledException('Could not lock lead for enrichment: ' + e.getMessage());
        }

        System.enqueueJob(new EnrichmentQueueable(leadId));

        // 4. Return immediately — this is NOT final data, just an acknowledgment
        EnrichmentResponse response = new EnrichmentResponse();
        response.isCached = false;
        response.status = 'In progress';
        return response;
    }

    private static EnrichmentResponse buildCachedResponse(Lead leadRecord) {
        EnrichmentResponse response = new EnrichmentResponse();
        response.isCached = true;
        response.status = leadRecord.Enrichment_Status__c;
        response.domain = leadRecord.Enrichment_Domain__c;
        response.company_name = leadRecord.Company_Name__c;
        response.industry = leadRecord.Enriched_industry__c;
        response.employee_count = leadRecord.Employee_count__c;
        response.employee_range = leadRecord.Employee_range__c;
        response.country = leadRecord.Enriched_Country__c;
        response.logo = leadRecord.Eriched_logo__c;
        response.confidence_score = leadRecord.Confidence_Score__c;
        response.lastEnrichedDate = leadRecord.Last_Enriched_Date__c;
        return response;
    }

    public static Boolean isWithinCacheWindow(Date lastEnrichedDate, String enrichmentStatus) {
        if (lastEnrichedDate == null || enrichmentStatus != 'Enriched') {
            return false;
        }
        Integer daysSinceLastEnriched = lastEnrichedDate.daysBetween(System.today());
        return daysSinceLastEnriched <= CACHE_VALIDITY_DAYS;
    }
}