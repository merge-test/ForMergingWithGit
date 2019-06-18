@isTest
public class Test_InvoiceDateUpdateScheduler {
    @isTest
    public static void testScheduler(){
        Map<Id,Date> schedulerData = new Map<Id,Date>();

        Test.startTest();
        InvoiceDateUpdateScheduler s = new InvoiceDateUpdateScheduler(schedulerData); 
        System.enqueueJob(s);
        Test.stopTest();
    }
}