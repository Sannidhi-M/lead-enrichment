@IsTest
public class EventPublisherTest {

    @IsTest
    static void testPublishSuccessEvent() {
        Lead ld = TestDataFactory.createLead('https://stripe.com');

        Test.startTest();
        EventPublisher.publish(ld.Id, 'Enriched', null);
        Test.getEventBus().deliver();
        Test.stopTest();
    }

    @IsTest
    static void testPublishFailureEvent() {
        Lead ld = TestDataFactory.createLead('https://stripe.com');

        Test.startTest();
        EventPublisher.publish(ld.Id, 'Failed', 'API returned status 503');
        Test.getEventBus().deliver();
        Test.stopTest();
    }
}