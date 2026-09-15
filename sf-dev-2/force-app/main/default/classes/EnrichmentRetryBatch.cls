public with sharing class EnrichmentRetryBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id FROM Lead WHERE Enrichment_Status__c = 'Failed'
        ]);
    }

    public void execute(Database.BatchableContext context, List<Lead> scope) {
        for (Lead ld : scope) {
            EnrichmentService.performEnrichment(ld.Id);
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug('EnrichmentRetryBatch completed.');
    }
}