trigger TriggerOnOpportunity on Opportunity (before insert, before update, after insert, after update) {
    if(Trigger.isBefore) {
        if(Trigger.isUpdate) {
            OpportunityTriggerHandler.performValidationChecks (Trigger.new);
            OpportunityTriggerHandler.performQBOValidations(Trigger.new, Trigger.oldMap);
            OpportunityTriggerHandler.setFirstQBId(Trigger.new);
            OpportunityTriggerHandler.updateClosedDate(Trigger.new, Trigger.oldMap);
            OpportunityTriggerHandler.syncWithQBO(Trigger.new, Trigger.oldMap);
            OpportunityTriggerHandler.handleAmountPercentChange(Trigger.new, Trigger.oldMap);
            OpportunityTriggerHandler.syncPercentages(Trigger.new, Trigger.oldMap);
        }
        else if(Trigger.isInsert){       
            OpportunityTriggerHandler.performValidationChecks(Trigger.new);
            OpportunityTriggerHandler.checkQBId(Trigger.new);
            OpportunityTriggerHandler.updateClosedDate(Trigger.new, null);
            OpportunityTriggerHandler.syncWithQBO(Trigger.new, null);
            OpportunityTriggerHandler.handleAmountPercentChange(Trigger.new, null);
            OpportunityTriggerHandler.syncPercentages(Trigger.new, null);
        }
    }
    else if(Trigger.isAfter){
        if(Trigger.isUpdate){
            OpportunityTriggerHandler.checkCloseDateChange(Trigger.new, Trigger.oldMap);
            OpportunityTriggerHandler.updateInvoices(Trigger.new, Trigger.oldMap);
        }
        else if(Trigger.isInsert) {
            OpportunityTriggerHandler.createInvoices(Trigger.new);
        } 
    }
}