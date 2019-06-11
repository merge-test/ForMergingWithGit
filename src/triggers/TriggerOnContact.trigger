trigger TriggerOnContact on Contact (before update,after update) {
    
    if(Trigger.isUpdate && Trigger.isBefore)
    {
        Set<Id> updateContactIds=new Set<Id>();
        
        for(Integer i=0; i<trigger.new.size();i++)
        {
            if(!trigger.new[i].From_Qb__c && (trigger.new[i].Salutation!=trigger.old[i].Salutation ||
                                              trigger.new[i].FirstName!=trigger.old[i].FirstName ||
                                              trigger.new[i].LastName!=trigger.old[i].LastName ||
                                              trigger.new[i].Phone!=trigger.old[i].Phone ||
                                              trigger.new[i].Email!=trigger.old[i].Email 
                                             )
              )
            {
                updateContactIds.add(trigger.new[i].Id);
            }
            
            trigger.new[i].From_Qb__c=false;
        }
        
        

        if(updateContactIds.size()>0)
        {
            Set<String> oppQbIds=new Set<String>();
            
            
            String relatedContactField=null;
            List<Mapper__c>mapperList= [Select Id, Field_Name__c from Mapper__c
                         where Object__c='Opportunity' and Quickbooks_Field_Name__c='ContactDetails'];
            
            if(mapperList.size()>0)
            {
                relatedContactField=mapperList[0].Field_Name__c;
                
                List<Opportunity> oppList=new List<Opportunity>();
                    
                try{
                    oppList=  Database.query('SELECT  Id, Qb_Id__c from Opportunity where '+relatedContactField+'=:updateContactIds and Qb_Id__c!=null' );
                }
                catch(Exception e)
                {
                    //do nothing
                }
                 
                for(Opportunity o:oppList)
                {
                    oppQbIds.add(o.Qb_Id__c);
                }
                
                if(oppQbIds.size()>0)
                {
                    QuickbookApiCrud.updateSubCustomer(oppQbIds);
                }
                
            }
            
        }
        
    }
      
    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            ContactTriggerHandler.triggerAddressChange(Trigger.new, Trigger.oldMap);
        }
    }
}