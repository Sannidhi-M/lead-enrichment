public with sharing class EnrichmentRetryScheduler implements Schedulable {

    public void execute(SchedulableContext context) {
        Database.executeBatch(new EnrichmentRetryBatch(), 1);
    }
}