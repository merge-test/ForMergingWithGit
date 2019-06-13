trigger TriggerOnInvoice on Invoice__c (before update,before insert,after update, after insert, before delete,after undelete) {
    List <id> lst_opportunityId = new List <Id>();
    if(Trigger.isBefore){
        if(Trigger.isUpdate){
            InvoiceTriggerHandler.handleDefaultCheck(Trigger.new, Trigger.oldMap);
            InvoiceTriggerHandler.populateTimeAndDelays(Trigger.new);
            InvoiceTriggerHandler.preventDuplicateNames(Trigger.new);
            InvoiceTriggerHandler.calculateDatesOnUpdate(Trigger.new, Trigger.oldMap,false);
            InvoiceTriggerHandler.adjustBilledPercentages(Trigger.new, Trigger.oldMap);
        }
        else if(Trigger.isInsert){
            InvoiceTriggerHandler.handleDefaultCheck(Trigger.new, null);
            InvoiceTriggerHandler.populateTimeAndDelays(Trigger.new);
            InvoiceTriggerHandler.preventDuplicateNames(Trigger.new);
            InvoiceTriggerHandler.preventNullValues(Trigger.new);
            InvoiceTriggerHandler.calculateDates(Trigger.new);
        }
        else if(Trigger.isDelete){
            InvoiceTriggerHandler.calculateDatesOnUpdate(Trigger.new, Trigger.oldMap,true);
        }
    }
    if(Trigger.isAfter){
        if(Trigger.isDelete){
            
        }
    }
}