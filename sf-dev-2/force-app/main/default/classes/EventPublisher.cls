public class EventPublisher {
    public static void publish(Id leadId, String status, String errorMessage) {
        Lead_Enrichment_Complete__e evt = new Lead_Enrichment_Complete__e(
            Lead_Id__c = leadId,
            Status__c = status,
            Error_Message__c = errorMessage
        );
        Database.SaveResult result = EventBus.publish(evt);
        if (!result.isSuccess()) {
            for (Database.Error err : result.getErrors()) {
                System.debug('Error publishing event: ' + err.getMessage());
            }
        }
    }
}