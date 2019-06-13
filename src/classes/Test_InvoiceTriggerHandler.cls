@isTest
public class Test_InvoiceTriggerHandler {
    @TestSetup static void createData(){
        Test_TriggerOnInvoice.createData();
    }
    @isTest static void TestIssuedInvoiceReportController(){
        Test_TriggerOnInvoice.TestIssuedInvoiceReportController();   
    }    
    @isTest static void TestInvoiceController(){
        Test_TriggerOnInvoice.TestInvoiceController();
    }    
}