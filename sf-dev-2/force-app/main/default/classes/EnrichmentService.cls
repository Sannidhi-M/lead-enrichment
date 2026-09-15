public with sharing class EnrichmentService {
    
    public static String getDomain(String website){
        if(String.isBlank(website)){
            throw new IllegalArgumentException('Website is blank');
        }

        String cleaned = website.toLowerCase().trim();
        cleaned = cleaned.replaceFirst('^https?://', '');
        cleaned = cleaned.replaceFirst('^www\\.', '');
        Integer slashIdx = cleaned.indexOf('/');
        return slashIdx > -1 ? cleaned.substring(0, slashIdx) : cleaned;
    }



    public static String getQueryParams(Id leadId){
        Lead leadrecord = [SELECT Id, Website FROM Lead WHERE Id = :leadId LIMIT 1];
        List<String> DEFAULT_FIELDS = new List<String>{
            'domain',
            'company_name',
            'industry',
            'employee_count',
            'employee_range',
            'country',
            'logo',
            'confidence_score'
        };

         String domain = getDomain(leadrecord.Website);
         String fieldsParam = String.join(DEFAULT_FIELDS, ',');
         String queryParams = 'domain=' + EncodingUtil.urlEncode(domain, 'UTF-8') + '&fields=' + EncodingUtil.urlEncode(fieldsParam, 'UTF-8');

         return queryParams; 
    }



    public static void saveEnrichedLead(Id leadId, EnrichmentResponse enrichedData){
        Lead leadRecord = [SELECT Id, Enrichment_Status__c, Enrichment_Domain__c, Company_Name__c, Enriched_industry__c, Employee_count__c, Employee_range__c, Enriched_Country__c, Eriched_logo__c, Confidence_Score__c FROM Lead WHERE Id = :leadId LIMIT 1];
        leadRecord.Enrichment_Status__c = 'Enriched';
        leadRecord.Enrichment_Domain__c = enrichedData.domain;
        leadRecord.Company_Name__c = enrichedData.company_name;
        leadRecord.Enriched_industry__c = enrichedData.industry;
        leadRecord.Employee_count__c = enrichedData.employee_count;
        leadRecord.Employee_range__c = enrichedData.employee_range;
        leadRecord.Enriched_Country__c = enrichedData.country;
        leadRecord.Eriched_logo__c = enrichedData.logo;
        leadRecord.Confidence_Score__c = enrichedData.confidence_score;
        leadRecord.Last_Enriched_Date__c = System.now().date();
        if(leadRecord.Confidence_Score__c < 0.6){
            leadRecord.Enrichment_Notes__c = 'Low confidence in enriched data';
        }
        else {
            leadRecord.Enrichment_Notes__c = null;
        }
       

        try{
            update leadRecord;
            System.debug('Lead record updated successfully for Lead Id: ' + leadRecord.Id);
        } catch (Exception e) {
            System.debug('Error updating lead record: ' + e.getMessage());
            throw new EnrichmentException('Error updating lead record: ' + e.getMessage());
        }   
    }



    public static void markLeadFailed(Id leadId, String errorMessage) {
        String safeMessage = 'Enrichment failed: ' + errorMessage;
        if (safeMessage.length() > 32768) {
            safeMessage = safeMessage.substring(0, 32765) + '...';
        }

        Lead leadRecord = new Lead(
            Id = leadId,
            Enrichment_Status__c = 'Failed',
            Enrichment_Notes__c = safeMessage
        );
        try {
            update leadRecord;
        } catch (Exception e) {
            System.debug('Could not even mark lead as Failed: ' + e.getMessage());
        }
    }


    public static void incrementUserEnrichmentCount(Id userId) {
        User u = [
            SELECT Id, Monthly_Enrichment_Count__c, Enrichment_Count_Month__c
            FROM User WHERE Id = :userId LIMIT 1
        ];

        Date currentMonthStart = Date.today().toStartOfMonth();

        if (u.Enrichment_Count_Month__c == null || u.Enrichment_Count_Month__c != currentMonthStart) {
            u.Monthly_Enrichment_Count__c = 1;
            u.Enrichment_Count_Month__c = currentMonthStart;
        } else {
            u.Monthly_Enrichment_Count__c = (u.Monthly_Enrichment_Count__c == null ? 0 : u.Monthly_Enrichment_Count__c) + 1;
        }

        try {
            update u;
        } catch (Exception e) {
            System.debug('Could not update user enrichment count: ' + e.getMessage());
        }
    }


   
    public static void performEnrichment(Id leadId) {
        try {
            String queryParams = getQueryParams(leadId);
            String endpoint = 'callout:Lead_Enrichment_API/v2?' + queryParams;

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setTimeout(10000);

            HttpResponse res = new Http().send(req);

            if (res.getStatusCode() != 200) {
                throw new EnrichmentException('Enrichment API returned status ' + res.getStatusCode());
            }

            EnrichmentResponse enrichedData = (EnrichmentResponse) JSON.deserialize(res.getBody(), EnrichmentResponse.class);
            saveEnrichedLead(leadId, enrichedData);
            if (!System.isBatch()) {
               System.enqueueJob(new AdoptionTrackerQueueable(UserInfo.getUserId()));
            }

            EventPublisher.publish(leadId, 'Enriched', null);

        } catch (Exception e) {
            
            System.debug('ENRICHMENT ERROR: ' + e.getMessage());
            System.debug('ENRICHMENT STACK: ' + e.getStackTraceString());
            String safeMessage = e.getMessage();
            if (safeMessage.length() > 255) {
                safeMessage = safeMessage.substring(0, 252) + '...';
            }
            markLeadFailed(leadId, safeMessage);
            EventPublisher.publish(leadId, 'Failed', safeMessage);
        }
    }
}