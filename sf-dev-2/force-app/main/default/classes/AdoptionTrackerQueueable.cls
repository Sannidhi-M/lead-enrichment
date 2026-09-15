public with sharing class AdoptionTrackerQueueable implements Queueable {
    private Id userId;

    public AdoptionTrackerQueueable(Id userId) {
        this.userId = userId;
    }

    public void execute(QueueableContext context) {
        EnrichmentService.incrementUserEnrichmentCount(userId);
    }
}