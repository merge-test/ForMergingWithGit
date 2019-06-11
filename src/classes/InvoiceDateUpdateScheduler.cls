public class InvoiceDateUpdateScheduler implements Queueable{
    
    public Map<Id,Date> invoicesToUpdate {get;set;}
    
    public InvoiceDateUpdateScheduler(Map<Id,Date> newInvoices){
        invoicesToUpdate = newInvoices;
    }
    
    public void execute(QueueableContext QC){
        List<Invoice__c> toUpdate = new List<Invoice__c>();
        for(Invoice__c inv : [Select Id,Excpected_Billing_Date__c from Invoice__c where Id =:invoicesToUpdate.keySet()]){
            inv.Excpected_Billing_Date__c = invoicesToUpdate.get(inv.Id);
            toUpdate.add(inv);
        }
        update toUpdate;
    }
}