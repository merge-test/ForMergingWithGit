trigger TriggerOnAccount on Account (after insert, before update, before insert,after update) {
    if(Trigger.isBefore){
        if(Trigger.isUpdate){
            AccountTriggerHandler.syncToQBO(Trigger.new, Trigger.oldMap); 
            AccountTriggerHandler.performQBOValidations(Trigger.new, Trigger.oldMap);
            AccountTriggerHandler.setFirstQBId(Trigger.new);
        }
        else if(Trigger.isInsert){
            AccountTriggerHandler.checkQBId(Trigger.new);
            AccountTriggerHandler.syncToQBO(Trigger.new, null); 
        }
    }
    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            AccountTriggerHandler.triggerAddressChange(Trigger.new, Trigger.oldMap);
        }
    }
}