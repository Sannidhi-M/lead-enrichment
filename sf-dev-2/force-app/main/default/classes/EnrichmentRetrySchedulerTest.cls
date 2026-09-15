@IsTest
public class EnrichmentRetrySchedulerTest {

    @IsTest
    static void testSchedulerSchedulesJob() {
        String cronExpr = '0 0 2 * * ?';

        Test.startTest();
        String jobId = System.schedule('Test Enrichment Retry', cronExpr, new EnrichmentRetryScheduler());
        Test.stopTest();

        CronTrigger scheduledJob = [
            SELECT Id, CronExpression
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        System.assertEquals(jobId, scheduledJob.Id);
        System.assertEquals(cronExpr, scheduledJob.CronExpression);
    }
}