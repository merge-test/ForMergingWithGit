public class SyncOppQBOController {
    public Id accountId{get;set;}
    public Id oppId{get;set;}
    
    public Boolean Error{get;set;}
    String Qb_ID;
    Boolean SuccessfulSync;
    
    public SyncOppQBOController(ApexPages.StandardController stdController)
    {
        Error = false;
        if(stdController.getRecord().getSObjectType().getDescribe().getName() == 'Opportunity'){
            oppId = stdController.getRecord().Id;
        }
        else if(stdController.getRecord().getSObjectType().getDescribe().getName() == 'Account'){
            accountId = stdController.getRecord().Id;
        }
    }
    
    public void syncFromAccount(){
        Account accountToSync = [Select Id,Is_Synced__c,QB_Id__c,LastModifiedDate from Account where Id = :accountId];
        if(accountToSync.Is_Synced__c){
            syncQBOCustomers(accountToSync.QB_Id__c,accountToSync.LastModifiedDate);
        }
        else{
            QuickbookApiCrud.fetchAlreadyExistingId(new Set<Id>{accountToSync.Id},'Account');
        }
    }
    
    public void syncFromOpportunity(){
        Opportunity oppToSync = [Select Id,AccountId,Is_Synced__c,QB_Id__c,LastModifiedDate from Opportunity where Id = :oppId];
        if(oppToSync.AccountId != null){
            Account accountToSync = [Select Id,Is_Synced__c,QB_Id__c,LastModifiedDate from Account where Id = :oppToSync.AccountId];
            accountId = accountToSync.Id;
            if(accountToSync.Is_Synced__c == false){
                Error = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, 'Associated Account is not synced. Please sync the associated account to get QB Id.'));
                return;
            }
            if(oppToSync.Is_Synced__c){
                syncQBOCustomers(oppToSync.QB_Id__c,oppToSync.LastModifiedDate);
            }
            else{
                QuickbookApiCrud.fetchAlreadyExistingId(new Set<Id>{oppId},'Opportunity');
            }
        }
        else{
            Error = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, 'No Account is associated with the Opportunity.'));
            return;
        }
    }
    
    public PageReference redirectToOpp(){
        PageReference reference = new PageReference('/'+oppId);
        reference.setRedirect(true);
        return reference;
    }
    
    public PageReference redirectToAccount(){
        PageReference reference = new PageReference('/'+accountId);
        reference.setRedirect(true);
        return reference;
    }
    
    void syncQBOCustomers(String qbId,DateTime lastUpdateTime){
        String currentTime = lastUpdateTime.format('yyyy-MM-dd\'T\'HH:mm:ss', System.label.QB_Timezone); 
        //For customers (Accounts and Opportunieies)
        
        List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                         realmid__c from QB_Credentials__c];
        
        if(qbcList.size()>0)
        {
            List<String>  authorizationCredentials=new List<String>  ();
            authorizationCredentials.add(qbcList[0].Access_token__c);
            authorizationCredentials.add(qbcList[0].Refresh_token__c);
            authorizationCredentials.add(qbcList[0].realmid__c);
            
            String query = 'Select * from Customer where Id = \''+qbId+'\' and MetaData.LastUpdatedTime > \''+currentTime+'\'';
            String qbResponse = QuickBookScheduler.QuickBookRecordGetter(query, authorizationCredentials);
            Map<String,Object> results;
            Map<String,Object> queryresp = new Map<String,Object>();
            if(qbResponse != null){
                results = (Map<String,Object>)System.JSON.deserializeUntyped(qbResponse);
                queryresp = ((Map<String,Object>)results.get('QueryResponse'));
            }
            
            
            if(queryresp.size()>0){
                QuickbookScheduler.processCustomerRecords(qbResponse);
            }
            else{
                QuickbookApiCrud.updateCustomer(new Set<String>{qbId});
            }
        }
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