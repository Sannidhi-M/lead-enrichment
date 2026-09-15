// EnrichmentQueueable.cls simplifies down to just delegating
public with sharing class EnrichmentQueueable implements Queueable, Database.AllowsCallouts {
    private Id leadId;
    public EnrichmentQueueable(Id leadId) {
        this.leadId = leadId;
    }
    public void execute(QueueableContext context) {
        EnrichmentService.performEnrichment(leadId);
    }
}