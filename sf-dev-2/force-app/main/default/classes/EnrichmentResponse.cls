public class EnrichmentResponse {
    @AuraEnabled public Boolean isCached;
    @AuraEnabled public String status;       
    @AuraEnabled public String domain;
    @AuraEnabled public String company_name;
    @AuraEnabled public String industry;
    @AuraEnabled public Decimal employee_count;
    @AuraEnabled public String employee_range;
    @AuraEnabled public String country;
    @AuraEnabled public String logo;
    @AuraEnabled public Decimal confidence_score;
    @AuraEnabled public Date lastEnrichedDate;
}