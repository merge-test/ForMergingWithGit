public class TriggerOnInvoiceHandler {
    public static void preventNullValues(List<Invoice__c> newInvoices){
        for(Invoice__c invoice : newInvoices){
            invoice.Fee__c = ((invoice.Fee__c == null)?0:invoice.Fee__c);
        }
    }
}