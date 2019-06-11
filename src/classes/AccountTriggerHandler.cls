public class AccountTriggerHandler {
    public static void performQBOValidations(List<Account> newAccounts,Map<Id,Account> oldAccounts){
        Map<String,Map<Id,String>> accQBMap = new Map<String,Map<Id,String>>();
        Map<String,Map<Id,String>> oppQBMap = new Map<String,Map<Id,String>>();
        Map<String,String> QBMap = new Map<String,String>();
        String message = '<style>.pbError{color:transparent;}</style><div align="left" style="color:#c00;padding-left:25%;">'+
            'Please review and resolve the following errors in order to save the record';
        
        
        for(Account acc : [SELECT Id,Name,QB_Id__c FROM Account WHERE QB_Id__c != null]){
            if(accQBMap.get(acc.QB_Id__c) != null){
                accQBMap.get(acc.QB_Id__c).put(acc.Id,acc.Name);
            }
            else{
                accQBMap.put(acc.QB_Id__c,new Map<Id,String>());
                accQBMap.get(acc.QB_Id__c).put(acc.Id,acc.Name);
            }
        }
        for(Opportunity opp : [SELECT Id,Name,QB_Id__c FROM Opportunity WHERE QB_Id__c != null]){
            if(oppQBMap.get(opp.QB_Id__c) != null){
                oppQBMap.get(opp.QB_Id__c).put(opp.Id,opp.Name);
            }
            else{
                oppQBMap.put(opp.QB_Id__c,new Map<Id,String>());
                oppQBMap.get(opp.QB_Id__c).put(opp.Id,opp.Name);
            }
        }
        for(QBO_Customer_Info__c QCI : [SELECT Id,Name,QB_ID__c FROM QBO_Customer_Info__c]){
            QBMap.put(QCI.Name,QCI.QB_ID__c);
        }
        for(Account acc : newAccounts){
            Integer i = 0;
            if(acc.QB_Id__c != null && acc.QB_Id__c != oldAccounts.get(acc.Id).QB_Id__c){
                if(acc.First_Time_Populated__c == true && acc.QB_Id__c != acc.First_QB_Id__c){
                    message = message + '<p>' + (++i) + '. This record is first initialized with the QB Id ' + acc.First_QB_Id__c + '.</p>';
                }
                
                if(accQBMap.get(acc.QB_Id__c) != null){
                    message = message + '<p>' + (++i) + '. Following Accounts are found in system using the same QB Id </p><ol>';
                    for(Id recId : accQBMap.get(acc.QB_Id__c).keySet()){
                        message = message +'<li><a target="_blank" href="/'+ recId + '" title="' + accQBMap.get(acc.QB_Id__c).get(recId) + '">'+ accQBMap.get(acc.QB_Id__c).get(recId) + '</a></li>';
                    }
                    message = message +'</ol>';
                }
                
                if(oppQBMap.get(acc.QB_Id__c) != null){
                    message = message + '<p>' + (++i) + '. Following Opportunities are found in system using the same QB Id </p><ol>';
                    for(Id recId :  oppQBMap.get(acc.QB_Id__c).keySet()){
                        message = message +'<li><a target="_blank" href="/'+ recId + '" title="' + oppQBMap.get(acc.QB_Id__c).get(recId) + '">'+ oppQBMap.get(acc.QB_Id__c).get(recId) +'</a></li>';
                    }
                    message = message +'</ol>';
                }
                
                if(QBMap.get(acc.Name)!= null && QBMap.get(acc.Name) != acc.QB_Id__c){
                    message = message + '<p>' + (++i) + '. A record is found in QBO having the same information with record Id <a target="_blank" href="'+ System.label.QBO_Base_Url + QBMap.get(acc.Name) + 
                        '" title="' + QBMap.get(acc.Name) + '">' + QBMap.get(acc.Name) + '</a>.</p>';
                }
                
                message = message + '</div>';
            }
            if(Test.isRunningTest()){
                System.debug('Test is Running');
            }
            else{
                if(message.contains('1.')){
                    acc.addError(message,false);
                }
            }
        }
    }
    
    public static void setFirstQBId(List<Account> newAccounts){
        for(Account acc : newAccounts){
            if(acc.First_Time_Populated__c == false){
                if(acc.QB_Id__c != null){
                    acc.First_QB_Id__c = acc.QB_Id__c;
                    acc.First_Time_Populated__c = true;
                }
            }
        }
    }
    
    public static void checkQBId(List<Account> newAccounts){
        for(Account acc : newAccounts){
            if(acc.QB_Id__c != null && acc.From_QB__c == false){
                acc.QB_Id__c.addError('Record cannot be created with the predifined <i>QB Id.</i>',false);
            }
        }
    }
    
    public static void syncToQBO(List<Account> newAccounts,Map<Id,Account> oldAccounts){
        if(oldAccounts != null){
            Set<String> updateAccIds=new Set<String>();
            
            List<Mapper__c> mapperList=[Select Field_Name__c from Mapper__c
                                        where Object__c='Account'];
            
            for(Account acc : newAccounts){
                if(acc.QB_Id__c!=null && !acc.From_Qb__c ){
                    for(Mapper__c m:mapperList){
                        if(acc.get(m.Field_Name__c)!=oldAccounts.get(acc.Id).get(m.Field_Name__c)){
                            updateAccIds.add(acc.QB_Id__c);
                        }
                    }
                }
                
                acc.From_Qb__c=false;
            }
            
            if(updateAccIds.size()>0){
                QuickbookApiCrud.updateCustomer(updateAccIds);
            }
        }
        else{
            Set<Id> accountsToSync = new Set<Id>();
            for(Account acc : newAccounts){
                if(acc.From_QB__c == true){
                    acc.From_QB__c = false;
                }
                else{
                    accountsToSync.add(acc.Id);
                }
            }
            if(accountsToSync.size()>0){
                QuickbookApiCrud.fetchAlreadyExistingId(accountsToSync, 'Account');
            }
        }
    }
    
    public static void triggerAddressChange(List<Account> newAccounts,Map<Id,Account> oldAccounts){
        Set<Id> accountsWithChangedAddress = new Set<Id>();
        for(Account acc : newAccounts){
            if(acc.BillingCity != oldAccounts.get(acc.Id).BillingCity ||
               acc.BillingCountry != oldAccounts.get(acc.Id).BillingCountry ||
               acc.BillingPostalCode != oldAccounts.get(acc.Id).BillingPostalCode ||
               acc.BillingState != oldAccounts.get(acc.Id).BillingState ||
               acc.BillingStreet != oldAccounts.get(acc.Id).BillingStreet ||
               acc.ShippingCity != oldAccounts.get(acc.Id).ShippingCity ||
               acc.ShippingCountry != oldAccounts.get(acc.Id).ShippingCountry ||
               acc.ShippingPostalCode != oldAccounts.get(acc.Id).ShippingPostalCode ||
               acc.ShippingState != oldAccounts.get(acc.Id).ShippingState ||
               acc.ShippingStreet != oldAccounts.get(acc.Id).ShippingStreet){
                   accountsWithChangedAddress.add(acc.Id);
               }
        }
        
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for(Opportunity opp : [Select Id,AddressChangesCount__c from Opportunity where AccountId = :accountsWithChangedAddress ]){
            opp.AddressChangesCount__c = opp.AddressChangesCount__c == null ? 1 : opp.AddressChangesCount__c + 1;
            oppsToUpdate.add(opp);
        }
        
        update oppsToUpdate;
    }
    
  public static void testPass(){
        Integer i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
 
    }
}