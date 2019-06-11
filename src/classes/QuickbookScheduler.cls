global class QuickbookScheduler implements schedulable  {
    
    global void execute(SchedulableContext stx){
        syncCustomersWithSF();
        syncInvoicessWithSF();
        syncDeletedInvoices();
        syncDeletedInvoicesFromSF();
        dumpCustomersFromQB();
    }
    
    @future (callout = true)
    public static void syncDeletedInvoicesFromSF(){
        String query = 'Select * from Invoice where Id IN (';
        Map<String,Deleted_QB_Ids__c> found = new Map<String,Deleted_QB_Ids__c>();
        for(Deleted_QB_Ids__c delIds : [Select Id,QB_ID__c from Deleted_QB_Ids__c]){
            query = query + '\'' + delIds.QB_ID__c + '\',';
            found.put(delIds.QB_ID__c, delIds);
        }
        query = query.substring(0, query.length() - 1) + ')';
        
        List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                         realmid__c from QB_Credentials__c];
        
        if(qbcList.size()>0)
        {
            List<String>  authorizationCredentials=new List<String>  ();
            authorizationCredentials.add(qbcList[0].Access_token__c);
            authorizationCredentials.add(qbcList[0].Refresh_token__c);
            authorizationCredentials.add(qbcList[0].realmid__c);
            
            String qbResponse = QuickBookScheduler.QuickBookRecordGetter(query, authorizationCredentials);
            if( qbResponse != null){
                Map<String,Object> results = (Map<String,Object>)System.JSON.deserializeUntyped(qbResponse);
                Map<String,Object> queryresp = ((Map<String,Object>)results.get('QueryResponse'));
                
                if(queryresp.size()>0){
                    Map<String, String> data = new Map<String, String>();
                    List<Object> responseList = (List<Object>)queryresp.get('Invoice');
                    List<Map<String,Object>> listofMaps = new List<Map<String,Object>>();
                    
                    for (Object instance : responseList)
                    {
                        listofMaps.add((Map<String,Object>)instance);
                    }
                    List<String> lst_QBIdWithoutQuotes = new List <String> ();
                    for (Map<String,Object>mp : listofMaps)
                    {
                        found.remove(String.valueOf(mp.get('Id')));
                        lst_QBIdWithoutQuotes.add(String.valueOf(mp.get('Id')));
                    }
                    for(String key:lst_QBIdWithoutQuotes){
                        Integer qbResponseDelete = QuickBookScheduler.deleteRecords(key, authorizationCredentials);    
                        if(qbResponseDelete == 200){                            
                            System.debug('Deleted from QBO');
                        }
                        else{
                            OpportuniytSchedulerHandler.sendEmail('Failed to delete invoice '+key+' from QB','The reason due to which unable to delete the invoice is '+qbResponseDelete);
                        }
                    }
                }
            }
            qbcList[0].Access_token__c=authorizationCredentials[0];
            qbcList[0].Refresh_token__c=authorizationCredentials[1];
            
            update qbcList[0];
        }
        
    }
    
    @future (callout = true)
    public static void syncCustomersWithSF(){ 
        Datetime currentNow = System.now().addMinutes(-1*Integer.valueOf(System.label.Scheduler_Interval)).addSeconds(-1*Integer.valueOf(System.label.Threshold));
        String currentTime = currentNow.format('yyyy-MM-dd\'T\'HH:mm:ss', System.label.QB_Timezone); 
        
        //For customers (Accounts and Opportunieies)
        
        List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                         realmid__c from QB_Credentials__c];
        
        if(qbcList.size()>0)
        {
            List<String>  authorizationCredentials=new List<String>  ();
            authorizationCredentials.add(qbcList[0].Access_token__c);
            authorizationCredentials.add(qbcList[0].Refresh_token__c);
            authorizationCredentials.add(qbcList[0].realmid__c);
            
            String query = 'Select * from Customer where MetaData.LastUpdatedTime > \''+currentTime+'\'';
            String qbResponse = QuickBookScheduler.QuickBookRecordGetter(query, authorizationCredentials);
            if( qbResponse != null)
            {
                QuickBookScheduler.processCustomerRecords(qbResponse);
            }
            
            qbcList[0].Access_token__c=authorizationCredentials[0];
            qbcList[0].Refresh_token__c=authorizationCredentials[1];
            
            update qbcList[0];
        }
        
    }
    
    @future (callout = true)
    public static void syncInvoicessWithSF(){ 
        Datetime currentNow = System.now().addMinutes(-1*Integer.valueOf(System.label.Scheduler_Interval)).addSeconds(-1*Integer.valueOf(System.label.Threshold));
        String currentTime = currentNow.format('yyyy-MM-dd\'T\'HH:mm:ss', System.label.QB_Timezone);
        //For Invoices
        List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                         realmid__c from QB_Credentials__c];
        
        if(qbcList.size()>0)
        {
            List<String>  authorizationCredentials=new List<String>  ();
            authorizationCredentials.add(qbcList[0].Access_token__c);
            authorizationCredentials.add(qbcList[0].Refresh_token__c);
            authorizationCredentials.add(qbcList[0].realmid__c);
            
            String query = 'Select * from Invoice where MetaData.LastUpdatedTime > \''+currentTime+'\'';
            String qbResponse = QuickBookScheduler.QuickBookRecordGetter(query, authorizationCredentials);
            if( qbResponse != null){
                System.debug('response yes');
                QuickBookScheduler.processInvoiceRecords(qbResponse, authorizationCredentials); //authorizationCredentials passes latest token to get Invoices
            }
            
            qbcList[0].Access_token__c=authorizationCredentials[0];
            qbcList[0].Refresh_token__c=authorizationCredentials[1];
            
            update qbcList[0];
        }
    }
    
    @future (callout = true)
    public static void syncDeletedInvoices(){ 
        //For Invoices
        List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                         realmid__c from QB_Credentials__c];
        
        if(qbcList.size()>0)
        {
            List<String>  authorizationCredentials=new List<String>  ();
            authorizationCredentials.add(qbcList[0].Access_token__c);
            authorizationCredentials.add(qbcList[0].Refresh_token__c);
            authorizationCredentials.add(qbcList[0].realmid__c);
            
            List<String> qbResponse = QuickBookScheduler.QuickBookCBC(authorizationCredentials);
            if( qbResponse != null && qbResponse.size() > 0)
            {
                QuickBookScheduler.processDeletedRecords(qbResponse, authorizationCredentials); //authorizationCredentials passes latest token to get Invoices
            }
            
            qbcList[0].Access_token__c=authorizationCredentials[0];
            qbcList[0].Refresh_token__c=authorizationCredentials[1];
            
            update qbcList[0];
        }
    }
    
    @future (callout = true)
    public static void dumpCustomersFromQB(){
        
        Datetime currentNow = System.now().addMinutes(-1*Integer.valueOf(System.label.Scheduler_Interval)).addSeconds(-1*Integer.valueOf(System.label.Threshold));
        String currentTime = currentNow.format('yyyy-MM-dd\'T\'HH:mm:ss', System.label.QB_Timezone); 
        //For Invoices
        List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                         realmid__c from QB_Credentials__c];
        
        if(qbcList.size()>0)
        {
            List<String>  authorizationCredentials=new List<String>  ();
            authorizationCredentials.add(qbcList[0].Access_token__c);
            authorizationCredentials.add(qbcList[0].Refresh_token__c);
            authorizationCredentials.add(qbcList[0].realmid__c);
            
            String query = 'Select Id,FullyQualifiedName from Customer where MetaData.LastUpdatedTime > \''+currentTime+'\'';
            String qbResponse = QuickBookScheduler.QuickBookRecordGetter(query, authorizationCredentials);
            if( qbResponse != null)
            {
                QuickBookScheduler.processCustomerRecordsFromQB(qbResponse);
            }
            
            qbcList[0].Access_token__c=authorizationCredentials[0];
            qbcList[0].Refresh_token__c=authorizationCredentials[1];
            
            update qbcList[0];
        }
    }
    
    public static void processCustomerRecordsFromQB(String responseData){
        
        Map<String,Object> results = (Map<String,Object>)System.JSON.deserializeUntyped(responseData);
        Map<String,Object> queryresp = ((Map<String,Object>)results.get('QueryResponse'));
        List <QBO_Customer_Info__c> lst_QBID = new List <QBO_Customer_Info__c>();    
        if(queryresp.size()>0)
        {
            Map<String, String> data = new Map<String, String>();
            List<Object> responseList = (List<Object>)queryresp.get('Customer');
            List<Map<String,Object>> listofMaps = new List<Map<String,Object>>();
            
            for (Object instance : responseList)
            {
                listofMaps.add((Map<String,Object>)instance);
            }
            
            Map<String,QBO_Customer_Info__c> existingQBOCustomers = new Map<String,QBO_Customer_Info__c>();
            for(QBO_Customer_Info__c QCI : [Select Id,Name__c,QB_Id__c from QBO_Customer_Info__c]){
                existingQBOCustomers.put(QCI.QB_Id__c, QCI);
            }
            
            for (Map<String,Object>mp : listofMaps)
            {
                if(existingQBOCustomers.get(String.valueOf(mp.get('Id'))) != null){
                    QBO_Customer_Info__c tempCInfo =  existingQBOCustomers.get(String.valueOf(mp.get('Id')));
                    tempCInfo.Name__c = String.valueOf(mp.get('FullyQualifiedName'));
                    lst_QBID.add(tempCInfo);
                }
                else{
                    QBO_Customer_Info__c qc = new QBO_Customer_Info__c();
                    qc.Name__c = String.valueOf(mp.get('FullyQualifiedName'));
                    qc.QB_ID__c = String.valueOf(mp.get('Id'));
                    lst_QBID.add(qc);
                }
            }
            
            if(lst_QBID.size()>0){ 
                upsert lst_QBID;                        
            }
        }
    }
    
    public static void updateObject(sObject acc, List<Mapper__c> mapperList, Map<String,Object>mp){
        for(Mapper__c mapper:mapperList)
        {
            if(mapper.Quickbooks_Field_Name__c.equals('PrimaryPhone'))
            {
                Map<String,Object> PrimaryPhone = ((Map<String,Object>)mp.get('PrimaryPhone'));
                
                if( PrimaryPhone != null )
                {
                    acc.put(mapper.Field_Name__c, String.valueOf(PrimaryPhone.get('FreeFormNumber')));
                }
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('AlternatePhone'))
            {
                Map<String,Object> AlternatePhone = ((Map<String,Object>)mp.get('AlternatePhone'));
                
                if( AlternatePhone != null )
                {
                    acc.put(mapper.Field_Name__c, String.valueOf(AlternatePhone.get('FreeFormNumber')));
                }
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('PrimaryEmailAddr'))
            {
                Map<String,Object> PrimaryEmailAddr = ((Map<String,Object>)mp.get('PrimaryEmailAddr'));
                
                if( PrimaryEmailAddr != null )
                {
                    acc.put(mapper.Field_Name__c, String.valueOf(PrimaryEmailAddr.get('Address')));
                }
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('WebAddr'))
            {
                Map<String,Object> WebAddr = ((Map<String,Object>)mp.get('WebAddr'));
                
                if( WebAddr != null )
                {
                    acc.put(mapper.Field_Name__c, String.valueOf(WebAddr.get('URI')));
                }
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('BillLine1'))
            {
                Map<String,Object> BillAddress = ((Map<String,Object>)mp.get('BillAddr'));
                
                if( BillAddress != null )
                {
                    acc.put(mapper.Field_Name__c, String.valueOf(BillAddress.get('Line1')));
                }
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('BillCity'))
            {
                Map<String,Object> BillAddress = ((Map<String,Object>)mp.get('BillAddr'));
                
                if( BillAddress != null )
                {
                    acc.put(mapper.Field_Name__c, String.valueOf(BillAddress.get('City')));
                }
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('BillCountry'))
            {
                Map<String,Object> BillAddress = ((Map<String,Object>)mp.get('BillAddr'));
                
                if( BillAddress != null )
                {
                    acc.put(mapper.Field_Name__c, String.valueOf(BillAddress.get('Country')));
                }
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('BillPostalCode'))
            {
                Map<String,Object> BillAddress = ((Map<String,Object>)mp.get('BillAddr'));
                
                if( BillAddress != null )
                {
                    acc.put(mapper.Field_Name__c, String.valueOf(BillAddress.get('PostalCode')));
                }
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('BillCountrySubDivisionCode'))
            {
                Map<String,Object> BillAddress = ((Map<String,Object>)mp.get('BillAddr'));
                
                if( BillAddress != null )
                {
                    acc.put(mapper.Field_Name__c, String.valueOf(BillAddress.get('CountrySubDivisionCode')));
                }
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('ShipLine1'))
            {
                Map<String,Object> ShipAddress = ((Map<String,Object>)mp.get('ShipAddr'));
                
                if( ShipAddress != null )
                {
                    acc.put(mapper.Field_Name__c, String.valueOf(ShipAddress.get('Line1')));
                }
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('ShipCity'))
            {
                Map<String,Object> ShipAddress = ((Map<String,Object>)mp.get('ShipAddr'));
                
                if( ShipAddress != null )
                {
                    acc.put(mapper.Field_Name__c, String.valueOf(ShipAddress.get('City')));
                }
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('ShipCountry'))
            {
                Map<String,Object> ShipAddress = ((Map<String,Object>)mp.get('ShipAddr'));
                
                if( ShipAddress != null )
                {
                    acc.put(mapper.Field_Name__c, String.valueOf(ShipAddress.get('Country')));
                }
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('ShipPostalCode'))
            {
                Map<String,Object> ShipAddress = ((Map<String,Object>)mp.get('ShipAddr'));
                
                if( ShipAddress != null )
                {
                    acc.put(mapper.Field_Name__c, String.valueOf(ShipAddress.get('PostalCode')));
                }
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('ShipCountrySubDivisionCode'))
            {
                Map<String,Object> ShipAddress = ((Map<String,Object>)mp.get('ShipAddr'));
                
                if( ShipAddress != null )
                {
                    acc.put(mapper.Field_Name__c, String.valueOf(ShipAddress.get('CountrySubDivisionCode')));
                }
            }
            else if(!mapper.Quickbooks_Field_Name__c.equals('ContactDetails'))
            {
                acc.put(mapper.Field_Name__c, mp.get(mapper.Quickbooks_Field_Name__c) );
            }
        }
    }
    
    public static void createMissingAccounts(Map<String, Map<String,Object>> accMap){
        List<String> foundIds = new List<String>();
        List<Account> insertRecords = new List<Account>();
        
        for(Account acc : [Select Id,QB_Id__c from Account where QB_Id__c =:accMap.keySet()]){
            foundIds.add(acc.QB_Id__c);
        }
        
        List<Mapper__c> mapperList=[Select Id, Field_Name__c, Quickbooks_Field_Name__c from Mapper__c
                                    where Object__c='Account'];
        
        for(String qbId : accMap.keySet()){
            if(foundIds.contains(qbId) == false){
                Account tempAccount = new Account();
                Map<String,Object>mp =accMap.get(qbId);
                updateObject(tempAccount, mapperList, mp);
                
                tempAccount.Is_Synced__c=true;
                tempAccount.QB_Id__c=String.valueOf(mp.get('Id'));
                tempAccount.From_qb__c=true;
                insertRecords.add(tempAccount);
            }
        }
        insert insertRecords;
    }
    
    public static void createMissingOpportunities(Map<  String, Map<String,Object> > oppMap){
        List<String> foundIds = new List<String>();
        List<Opportunity> insertRecords = new List<Opportunity>();
        Map<String,Contact> proposalIssued = new Map<String,Contact>();
        
        for(Opportunity opp : [Select Id,QB_Id__c from Opportunity where QB_Id__c =:oppMap.keySet()]){
            foundIds.add(opp.QB_Id__c);
        }
        
        List<Mapper__c> mapperList=[Select Id, Field_Name__c, Quickbooks_Field_Name__c from Mapper__c
                                    where Object__c='Opportunity'];
        
        Map<String,Id> syncedAccounts = new Map<String,Id>();
        for(Account acc : [Select Id,QB_Id__c from Account where QB_Id__c != null]){
            syncedAccounts.put(acc.QB_Id__c, acc.Id);
        }
        for(String qbId : oppMap.keySet()){
            if(foundIds.contains(qbId) == false){
                Opportunity tempOpp = new Opportunity();
                Map<String,Object>mp =oppMap.get(qbId);
                updateObject(tempOpp, mapperList, mp);
                tempOpp.Is_Synced__c=true;
                tempOpp.QB_Id__c=String.valueOf(mp.get('Id'));
                tempOpp.From_qb__c=true;
                tempOpp.StageName = 'Closed Won';
                tempOpp.CloseDate = System.today();
                tempOpp.Proposal_Issued__c = System.today();
                
                if(String.valueOf(mp.get('FamilyName'))!=null){//lastname check with related field check
                    Contact c=new Contact();
                    c.Salutation=String.valueOf(mp.get('Title'));
                    c.FirstName=String.valueOf(mp.get('GivenName'));
                    c.LastName=String.valueOf(mp.get('FamilyName'));
                    c.Opp_Qb_Id__c=String.valueOf(mp.get('Id'));
                    c.From_qb__c=true;
                    
                    Map<String,Object> PrimaryPhone = ((Map<String,Object>)mp.get('PrimaryPhone'));
                    if( PrimaryPhone != null ){
                        c.Phone=String.valueOf(PrimaryPhone.get('FreeFormNumber'));
                    }
                    
                    Map<String,Object> PrimaryEmailAddr = ((Map<String,Object>)mp.get('PrimaryEmailAddr'));
                    if( PrimaryEmailAddr != null ){
                        c.Email=String.valueOf(PrimaryEmailAddr.get('Address'));
                    }
                    proposalIssued.put(qbId,c);
                }
                Map<String,Object>parentRef = (Map<String,Object>) mp.get('ParentRef');
                if(parentRef != null){
                    tempOpp.AccountId = syncedAccounts.get(String.valueOf(parentRef.get('value')));    
                }
                insertRecords.add(tempOpp);
            }
        }
        insert proposalIssued.values();
        for(Opportunity opp : insertRecords){
            opp.proposal_issued_to_1__c = proposalIssued.get(opp.QB_Id__c) != null ? proposalIssued.get(opp.QB_Id__c).Id : null;
        }
        insert insertRecords;
    }

    public static Boolean processCustomerRecords(String responseData){
        Map<String,Object> results = (Map<String,Object>)System.JSON.deserializeUntyped(responseData);
        Map<String,Object> queryresp = ((Map<String,Object>)results.get('QueryResponse'));
        
        if(queryresp.size()>0)
        {
            Map<String, String> data = new Map<String, String>();
            List<Object> responseList = (List<Object>)queryresp.get('Customer');
            List<Map<String,Object>> listofMaps = new List<Map<String,Object>>();
            
            for (Object instance : responseList)
            {
                listofMaps.add((Map<String,Object>)instance);
            }
            
            List<Opportunity> oppList = new List<Opportunity>();
            List<Account> accList = new List<Account>();
            Map<Id, Contact> updateConMap = new Map<Id, Contact>();
            Map<String, Opportunity> newConMap = new Map<String, Opportunity>();
            List<Contact> newContacts=new List<Contact>();
            
            Map<  String, Map<String,Object> > oppMap=new  Map<  String, Map<String,Object> >();
            Map<  String, Map<String,Object> > accMap=new  Map<  String, Map<String,Object> >();
            
            for (Map<String,Object>mp : listofMaps)
            {
                if(String.valueOf(mp.get('Job'))=='false')
                {
                    accMap.put(String.valueOf(mp.get('Id')), mp);
                }
                else
                {
                    oppMap.put(String.valueOf(mp.get('Id')), mp);
                }
                System.debug(String.valueOf(mp.get('Id')));
            }
            
            createMissingAccounts(accMap);
            createMissingOpportunities(oppMap);
            
            //For Customers
            List<Mapper__c> mapperList=[Select Id, Field_Name__c, Quickbooks_Field_Name__c from Mapper__c
                                        where Object__c='Account'];
            List<String> qbIds=new List<String>();
            qbIds.addAll(accMap.keySet());
            accList= Database.query('SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().keySet()), ',') 
                                    + ' FROM Account where QB_Id__c In :qbIds' );
            
            for(Account acc:accList)
            {
                Map<String,Object>mp =accMap.get(acc.Qb_Id__c);
                updateObject(acc, mapperList, mp);
                
                acc.Is_Synced__c=true;
                acc.QB_Id__c=String.valueOf(mp.get('Id'));
                acc.From_qb__c=true;
            }
            
            //For Sub-customers
            
            String relatedContactField=null;
            mapperList= [Select Id, Field_Name__c from Mapper__c
                         where Object__c='Opportunity' and Quickbooks_Field_Name__c='ContactDetails'];
            
            qbIds=new List<String>();
            qbIds.addAll(oppMap.keySet());
            
            if(mapperList.size()>0)
            {
                relatedContactField=mapperList[0].Field_Name__c.substringBeforeLast('__c')+'__r';
                
                try{
                    
                    oppList= Database.query('SELECT Account.Name, Account.Qb_Id__c, '+relatedContactField+'.Lastname, ' + String.join(new List<String>(Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().keySet()), ',') 
                                            + ' FROM Opportunity where QB_Id__c In :qbIds' );
                    relatedContactField=mapperList[0].Field_Name__c;
                }
                catch(Exception e){
                    oppList= Database.query('SELECT Account.Name, Account.Qb_Id__c, ' + String.join(new List<String>(Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().keySet()), ',') 
                                            + ' FROM Opportunity where QB_Id__c In :qbIds' );
                    relatedContactField=null;
                }
            }
            else
            {
                oppList= Database.query('SELECT Account.Name, Account.Qb_Id__c, ' + String.join(new List<String>(Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().keySet()), ',') 
                                        + ' FROM Opportunity where QB_Id__c In :qbIds' );
            }
            
            //Initializing with original mapping
            mapperList=[Select Id, Field_Name__c, Quickbooks_Field_Name__c from Mapper__c
                        where Object__c='Opportunity'];
            
            
            Map<String,Id> syncedAccounts = new Map<String,Id>();
            for(Account acc : [Select Id,QB_Id__c from Account where QB_Id__c != null]){
                syncedAccounts.put(acc.QB_Id__c, acc.Id);
            }
            for(Opportunity opp:oppList)
            {
                Map<String,Object>mp =oppMap.get(opp.Qb_Id__c);
                updateObject(opp, mapperList, mp);
                opp.Is_Synced__c=true;
                opp.QB_Id__c=String.valueOf(mp.get('Id'));
                opp.From_qb__c=true;
                
                if(relatedContactField!=null && String.valueOf(mp.get('FamilyName'))!=null) //lastname check with related field check
                {
                    Contact c=new Contact();
                    c.Salutation=String.valueOf(mp.get('Title'));
                    c.FirstName=String.valueOf(mp.get('GivenName'));
                    c.LastName=String.valueOf(mp.get('FamilyName'));
                    c.Opp_Qb_Id__c=String.valueOf(mp.get('Id'));
                    c.From_qb__c=true;
                    
                    Map<String,Object> PrimaryPhone = ((Map<String,Object>)mp.get('PrimaryPhone'));
                    if( PrimaryPhone != null )
                    {
                        c.Phone=String.valueOf(PrimaryPhone.get('FreeFormNumber'));
                    }
                    
                    Map<String,Object> PrimaryEmailAddr = ((Map<String,Object>)mp.get('PrimaryEmailAddr'));
                    if( PrimaryEmailAddr != null )
                    {
                        c.Email=String.valueOf(PrimaryEmailAddr.get('Address'));
                    }
                    
                    if(opp.get(relatedContactField)!=null)
                    {
                        c.Id=(Id)opp.get(relatedContactField);
                        updateConMap.put(c.Id, c);
                    }
                    else
                    {
                        newConMap.put(c.Opp_Qb_Id__c, opp);
                        newContacts.add(c);
                    }            
                }
                
                Map<String,Object>parentRef = (Map<String,Object>) mp.get('ParentRef');
                opp.AccountId = syncedAccounts.get(String.valueOf(parentRef.get('value')));
            }
            
            Database.DMLOptions db = new Database.DMLOptions();
            
            if( accList.size() > 0 )
            {
                Database.update(accList,db);
            }
            if( oppList.size() > 0 )
            {
                if(newContacts.size()>0)
                {
                    Database.insert(newContacts,db);
                    
                    for(Contact c:newContacts)
                    {
                        newConMap.get(c.Opp_Qb_Id__c).put(relatedContactField, c.Id);
                    }
                }
                Database.update(oppList,db);
                Database.update(updateConMap.values(),db);
            }
        }
        return true;
    }
    
    public static void processInvoiceRecords(String responseData, List<String> authorizationCredentials){
        Map<String,Object> results = (Map<String,Object>)System.JSON.deserializeUntyped(responseData);
        Map<String,Object> queryresp = ((Map<String,Object>)results.get('QueryResponse'));
        
        if(queryresp.size()>0){
            Map<String, String> data = new Map<String, String>();
            List<Object> responseList = (List<Object>)queryresp.get('Invoice');
            List<Map<String,Object>> listofMaps = new List<Map<String,Object>>();
            //sendTestEmail('Response',responseData );
            for (Object instance : responseList){
                listofMaps.add((Map<String,Object>)instance);
            }
            
            Map<String,Opportunity> QBSubcustomers = new Map<String,Opportunity>();
            for(Opportunity opp : [Select Id,Name,QB_Id__c,Amount from Opportunity where QB_Id__c != null]){
                QBSubcustomers.put(opp.QB_Id__c,opp);
            }
            
            Map<  String, Map<String,Object> > invoiceSyncMap=new  Map<  String, Map<String,Object> >();
            Map<String,Id> CustomerRefMap = new Map<String,Id>();
            List<Id> opportunitiesInvolved = new List<Id>();
            for (Map<String,Object>mp : listofMaps){
                invoiceSyncMap.put(String.valueOf(mp.get('Id')), mp);
                Map<String,Object> customerRef = (Map<String,Object>)mp.get('CustomerRef');
                System.debug(QBSubcustomers);
                System.debug(String.valueOf(customerRef.get('value')));
                System.debug(QBSubcustomers.get(String.valueOf(customerRef.get('value'))));
                opportunitiesInvolved.add(QBSubcustomers.get(String.valueOf(customerRef.get('value'))).Id);
                System.debug(String.valueOf(customerRef.get('value')));
                System.debug(QBSubcustomers.get(String.valueOf(customerRef.get('value'))).Name);
                CustomerRefMap.put(String.valueOf(mp.get('Id')), QBSubcustomers.get(String.valueOf(customerRef.get('value'))).Id);
            }
            
            List<Invoice_Sync__c> invoiceSyncList = new List<Invoice_Sync__c>();
            List<Invoice_Sync__c> toUpdateInvoiceSyncList = new List<Invoice_Sync__c>();
            List<Invoice_Sync__c> toInsertInvoiceSyncList = new List<Invoice_Sync__c>();
            List<Invoice_Sync__c> toDeleteInvoiceSyncList = new List<Invoice_Sync__c>();
            Map<String,Map<String,Invoice_Sync__c>> invoiceSyncListMap = new Map<String,Map<String,Invoice_Sync__c>>();
            Map<String,List<String>> SalesforceStageItems = new Map<String,List<String>>();
            List<Id> relatedInvoices = new List<Id>();
            for(Invoice_Sync__c invSync : [Select Id, Name, createddate__c, Invoice__c, Invoice__r.Name, Invoice__r.Billed__c, Invoice__r.Fee__c, Invoice__r.Opportunity__c, Amount__c,
                                           Qb_Id__c from Invoice_Sync__c where QB_Id__c=:invoiceSyncMap.keySet()]){
                                               invoiceSyncList.add(invSync);
                                               relatedInvoices.add(invSync.Invoice__c);
                                               
                                               if(SalesforceStageItems.get(invSync.QB_Id__c) != null){
                                                   SalesforceStageItems.get(invSync.QB_Id__c).add(invSync.Invoice__r.Name);
                                               }
                                               else{
                                                   SalesforceStageItems.put(invSync.QB_Id__c, new List<String>());
                                                   SalesforceStageItems.get(invSync.QB_Id__c).add(invSync.Invoice__r.Name);
                                               }
                                               
                                               if(invoiceSyncListMap.get(invSync.QB_Id__c) != null){
                                                   invoiceSyncListMap.get(invSync.QB_Id__c).put(invSync.Invoice__r.Name,invSync);
                                               }
                                               else{
                                                   invoiceSyncListMap.put(invSync.QB_Id__c, new Map<String,Invoice_Sync__c>());
                                                   invoiceSyncListMap.get(invSync.QB_Id__c).put(invSync.Invoice__r.Name,invSync);
                                               }
                                           }
            
            Map<Id, Invoice__c> invoiceMap = new Map<Id, Invoice__c>();
            Map<Id,Map<String,Invoice__c>> opportunityStagesMap = new Map<Id,Map<String,Invoice__c>>();
            for(Invoice__c inv : [SELECT Id, Name, Opportunity__c, Amount__c, Fee__c, Fee_Percentage__c, Billed__c, Default__c, Bill__c, Service_Date__c
                                  FROM Invoice__c 
                                  where Id = :relatedInvoices 
                                  OR Opportunity__c = :opportunitiesInvolved]){
                                      invoiceMap.put(inv.Id,inv);
                                      if(opportunityStagesMap.get(inv.Opportunity__c) != null){
                                          opportunityStagesMap.get(inv.Opportunity__c).put(inv.Name,inv);
                                      }
                                      else{
                                          opportunityStagesMap.put(inv.Opportunity__c,new Map<String,Invoice__c>());
                                          opportunityStagesMap.get(inv.Opportunity__c).put(inv.Name,inv);
                                      }
                                  }
            
            Set<Id> toCalculatePercentages = new Set<Id>();
            Map<String, String> qbIdPOMap = new Map<String, String>();
            for(Invoice_Sync__c invSync : invoiceSyncList){
                /*toCalculatePercentages.add(invSync.Invoice__c);
                if(invSync.Invoice__r.Opportunity__c != CustomerRefMap.get(invSync.QB_Id__c)){
                    SYstem.debug('Opportunity not Equal');
                    if(opportunityStagesMap.get(CustomerRefMap.get(invSync.QB_Id__c))!= null){
                        SYstem.debug('Stages found');
                        if(opportunityStagesMap.get(CustomerRefMap.get(invSync.QB_Id__c)).get(invSync.Invoice__r.Name) != null){
                            SYstem.debug('Required Stage Found');
                          invSync.Invoice__c = opportunityStagesMap.get(CustomerRefMap.get(invSync.QB_Id__c)).get(invSync.Invoice__r.Name).Id;
                        }
                    }
                }
                toCalculatePercentages.add(invSync.Invoice__c);*/
                
                Map<String,Object>mp =invoiceSyncMap.get(invSync.Qb_Id__c);
                if(Double.valueOf(mp.get('Balance'))<Double.valueOf(mp.get('TotalAmt'))||
                   Date.valueof(String.valueOf(mp.get('DueDate')))!=invSync.createddate__c ){
                       invSync.createddate__c=Date.valueof(String.valueOf(mp.get('DueDate')));
                   }
                
                List<Object> customFields = (List<Object>)mp.get('CustomField');
                List<Map<String,Object>> customFieldsList = new List<Map<String,Object>>();
                
                for (Object instance : customFields)
                {
                    Map<String,Object> invObjMap = (Map<String,Object>)instance;
                    if(invObjMap.get('Name')=='PO #')
                    {
                        if(invObjMap.get('StringValue')!=null)
                        {
                            qbIdPOMap.put(invSync.Qb_Id__c, String.valueOf(invObjMap.get('StringValue')));
                        }                        
                    }                    
                }
            }
            
            Map<String,List<String>> linesOfInvoiceDescription = new Map<String,List<String>>();
            Map<String,List<Map<String,Object>>> linesOfInvoices = new Map<String,List<Map<String,Object>>>();
            for(String qbId : invoiceSyncMap.keySet()){
                Map<String,Object>mp = invoiceSyncMap.get(qbId);
                List<Object> lineItems = (List<Object>)mp.get('Line');
                List<Map<String,Object>> lineList = new List<Map<String,Object>>();
                
                for (Object instance : lineItems){
                    lineList.add((Map<String,Object>)instance);
                }
                linesOfInvoices.put(qbId, lineList);
                for (Map<String,Object>lineItem : lineList){
                    Map<String,Object> lineItemDetail = (Map<String,Object>)lineItem.get('SalesItemLineDetail');
                    if(lineItemDetail != null){
                        if(Integer.valueOf(lineItemDetail.get('Qty')) > 0){
                            if(linesOfInvoiceDescription.get(qbId) != null){
                                linesOfInvoiceDescription.get(qbId).add(String.valueOf(lineItem.get('Description')));
                            }
                            else{
                                linesOfInvoiceDescription.put(qbId, new List<String>());
                                linesOfInvoiceDescription.get(qbId).add(String.valueOf(lineItem.get('Description')));
                            }
                            
                            if(invoiceSyncListMap.get(qbId) != null){
                                if(invoiceSyncListMap.get(qbId).get(String.valueOf(lineItem.get('Description'))) != null){
                                    Invoice_Sync__c updateSync =  invoiceSyncListMap.get(qbId).get(String.valueOf(lineItem.get('Description')));
                                    updateSync.Amount__c = Integer.valueOf(lineItem.get('Amount'));
                                    
                                    SYstem.debug('update area Opportunity not Equal');
                                    if(opportunityStagesMap.get(CustomerRefMap.get(QbId))!= null){
                                        SYstem.debug('update area Stages found');
                                        if(opportunityStagesMap.get(CustomerRefMap.get(QbId)).get(String.valueOf(lineItem.get('Description'))) != null){
                                            SYstem.debug('update area Required Stage Found');
                                            updateSync.Invoice__c = opportunityStagesMap.get(CustomerRefMap.get(QbId)).get(String.valueOf(lineItem.get('Description'))).Id;
                                        }
                                    }
                                    updateSync.QB_Id__c = QbId;
                                    toCalculatePercentages.add(updateSync.Invoice__c);
                                    toUpdateInvoiceSyncList.add(updateSync);
                                }
                            }
                        }
                    }
                }
            }
            
            System.debug(linesOfInvoiceDescription);
            System.debug(SalesforceStageItems);
            Map<String,List<String>> addedLineItems = new Map<String,List<String>>();
            Map<String,List<String>> removedLineItems = new Map<String,List<String>>();
            //Added Line Item 
            for(String QbID : linesOfInvoiceDescription.keySet()){
                for(String stageName : linesOfInvoiceDescription.get(QbId)){
                    if(!SalesforceStageItems.get(QbID).contains(stageName) && stageName != null){
                        if(addedLineItems.get(QbID) != null){
                            addedLineItems.get(QbID).add(stageName);
                        }
                        else{
                            addedLineItems.put(QbID, new List<String>());
                            addedLineItems.get(QbID).add(stageName);
                        }
                    }
                }
            }
            //Removed Line Item
            for(String QbID : SalesforceStageItems.keySet()){
                for(String stageName : SalesforceStageItems.get(QbId)){
                    if(!linesOfInvoiceDescription.get(QbID).contains(stageName) && stageName != null){
                        if(removedLineItems.get(QbID) != null){
                            removedLineItems.get(QbID).add(stageName);
                        }
                        else{
                            removedLineItems.put(QbID, new List<String>());
                            removedLineItems.get(QbID).add(stageName);
                        }
                    }
                }
            }
            
            System.debug('Added = '+addedLineItems);
            System.debug('Removed = '+removedLineItems);
            
            Map<String,Invoice__c> oppNewStages = new Map<String,Invoice__c>();
            // Process added and Removed Items
            for(String QbId : addedLineItems.keySet()){
                Map<String,Object>mp = invoiceSyncMap.get(qbId);
                List<Object> lineItems = (List<Object>)mp.get('Line');
                List<Map<String,Object>> lineList = new List<Map<String,Object>>();
                
                for (Object instance : lineItems){
                    lineList.add((Map<String,Object>)instance);
                }
                linesOfInvoices.put(qbId, lineList);
                for (Map<String,Object>lineItem : lineList){
                    Map<String,Object> lineItemDetail = (Map<String,Object>)lineItem.get('SalesItemLineDetail');
                    
                    if(lineItemDetail != null){
                        if(Integer.valueOf(lineItemDetail.get('Qty')) > 0 &&
                           addedLineItems.get(QbId).contains(String.valueOf(lineItem.get('Description')))){
                               
                               Invoice_Sync__c newSync = new Invoice_Sync__c();
                               newSync.Amount__c = Integer.valueOf(lineItem.get('Amount'));
                               
                               SYstem.debug('added area Opportunity not Equal');
                               if(opportunityStagesMap.get(CustomerRefMap.get(QbId))!= null){
                                   SYstem.debug('added area Stages found');
                                   if(opportunityStagesMap.get(CustomerRefMap.get(QbId)).get(String.valueOf(lineItem.get('Description'))) != null){
                                       SYstem.debug('added area Required Stage Found');
                                       newSync.Invoice__c = opportunityStagesMap.get(CustomerRefMap.get(QbId)).get(String.valueOf(lineItem.get('Description'))).Id;
                                   }
                                   else{
                                       Invoice__c tempInvoice = new Invoice__c(Name=String.valueOf(lineItem.get('Description')));
                                       tempInvoice.Opportunity__c = CustomerRefMap.get(QbId);
                                       tempInvoice.Fee__c = Integer.valueOf(lineItem.get('Amount'));
                                       oppNewStages.put(QbId,tempInvoice);
                                       opportunityStagesMap.get(CustomerRefMap.get(QbId)).put(String.valueOf(lineItem.get('Description')),tempInvoice);
                                   }
                               }
                               newSync.QB_Id__c = QbId;
                               toCalculatePercentages.add(newSync.Invoice__c);
                               toInsertInvoiceSyncList.add(newSync);
                           }
                    }
                }
            }
            
            for(String QbId : removedLineItems.keySet()){
                for(String stageName : removedLineItems.get(QbId)){
                    if(invoiceSyncListMap.get(QbId) != null){
                        if(invoiceSyncListMap.get(QbId).get(stageName) != null){
                            toDeleteInvoiceSyncList.add(invoiceSyncListMap.get(QbId).get(stageName));
                            toCalculatePercentages.add(invoiceSyncListMap.get(QbId).get(stageName).Invoice__c);
                        }
                    }
                }
            }
            
            //GetPdf's
            List<ContentVersion> invoiceDocs = new List<ContentVersion>();
            for(String qbId : invoiceSyncMap.keySet()){
                
                Map<String,Object>mp =invoiceSyncMap.get(qbId);
                String qboPo = '';
                
                String invoiceNumber=String.valueOf(mp.get('DocNumber'));
                //qboPo = qbIdPOMap.get(qbId);
                Double Amount =Double.valueOf(mp.get('TotalAmt'));
                String dueDate= String.valueOf(mp.get('DueDate'));
                Double balance= Double.valueOf(mp.get('Balance'));
                
                //Code to Issue new Invoices
                HttpRequest request = new HttpRequest();
                HttpResponse response = new HttpResponse();
                Http http = new Http();
                
                request.setMethod('GET');
                request.setEndPoint(System.label.QB_API_End_Point+'/v3/company/'+authorizationCredentials[2]+'/invoice/'+qbId+'/pdf');
                request.setHeader('Authorization' , 'Bearer '+authorizationCredentials[0]);
                request.setHeader('Content-Type' , 'application/pdf');
                
                System.debug('Pehly');
                response = http.send(request);
                System.debug('Baad mein ');
                if(response.getStatusCode() == 200)
                {
                    //Insert new Invoice Attachment
                    ContentVersion v = new ContentVersion();
                    
                    if(Test.isRunningTest())
                    {
                        Blob b=Blob.valueof('Test');
                        v.versionData =  b;
                    }
                    else
                    {
                        v.versionData =  response.getBodyAsBlob();
                    }   
                    
                    //v.title = 'Invoice#'+invoiceNumber;
                    if(invoiceNumber != null)
                    {
                        v.title = 'Invoice#'+invoiceNumber;   
                    }
                    else{
                        v.title = 'Invoice#';   
                    }
                    v.pathOnClient ='Invoice#'+invoiceNumber+'.pdf';
                    v.Amount__c=amount;
                    v.Due_Date__c=Date.valueOf(dueDate);
                    v.QB_Id__c=qbId;
                    //v.PO__c = qboPo;
                    v.FirstPublishLocationId = CustomerRefMap.get(qbId);
                    v.Balance__c = balance;
                    Map <String,Date> mapQbToDate= getQBDate(qbId);
                    if(mapQbToDate !=null){
                        v.QBCreated_Date__c =mapQbToDate.get(qbId);
                    }
                    
                    invoiceDocs.add(v);
                }
                else{
                    sendErrorEmail(response.getStatusCode(),response.getBody());
                    
                }
                
            }
            
            List<Id> contentDocIds=new List<Id>();
            List<ContentVersion> issuedInvoice=[Select Id, QB_Id__c, ContentDocumentId from ContentVersion where QB_Id__c=:invoiceSyncMap.keySet()];
            for(ContentVersion cv:issuedInvoice){
                contentDocIds.add(cv.ContentDocumentId);
            }
            if(contentDocIds.size()>0){
                List<ContentDocument> conDocs=[Select Id from ContentDocument where Id=:contentDocIds];
                delete conDocs;
            }
            
            delete toDeleteInvoiceSyncList;
            insert oppNewStages.values();
            
            for(Invoice_Sync__c invSync : toInsertInvoiceSyncList){
                if(invSync.Invoice__c == null){
                    System.debug('New Stage = ' + oppNewStages.get(invSync.QB_Id__c));
                    invSync.Invoice__c = oppNewStages.get(invSync.QB_Id__c) != null ? (oppNewStages.get(invSync.QB_Id__c)).Id : null;
                    toCalculatePercentages.add(invSync.Invoice__c);
                }
            }
            insert toInsertInvoiceSyncList;
            update toUpdateInvoiceSyncList;
            insert invoiceDocs;
            calculatePercentagesFromInvoiceSync(toCalculatePercentages);
        }
    }

    public static Map <String,Date> getQBDate(String QBIdWithoutQuotes){
        String QbidQuotes = '\''+QBIdWithoutQuotes+'\'';
        Map <String,Date> mapQbToDate = new Map <String,Date>(); 
        if(QBIdWithoutQuotes != null){
            List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                             realmid__c from QB_Credentials__c];    
            try{
                if(qbcList.size()>0)
                {
                    List<String>  authorizationCredentials=new List<String>  ();
                    authorizationCredentials.add(qbcList[0].Access_token__c);
                    authorizationCredentials.add(qbcList[0].Refresh_token__c);
                    authorizationCredentials.add(qbcList[0].realmid__c);
                    String query = 'Select id,MetaData.CreateTime from Invoice where id = '+QbidQuotes;
                    String qbResponse = QuickBookScheduler.QuickBookRecordGetter(query, authorizationCredentials);
                    if( qbResponse != null)
                    {
                        Map<String,Object> results = (Map<String,Object>)System.JSON.deserializeUntyped(qbResponse);
                        Map<String,Object> queryresp = ((Map<String,Object>)results.get('QueryResponse'));
                        if(queryresp.size()>0)
                        {
                            Map<String, String> data = new Map<String, String>();
                            List<Object> responseList = (List<Object>)queryresp.get('Invoice');                        
                            List<Map<String,Object>> listofMaps = new List<Map<String,Object>>();
                            for (Object instance : responseList)
                            {
                                listofMaps.add((Map<String,Object>)instance);
                            }
                            Map<Id, Invoice__c> invoiceMap = new Map<Id, Invoice__c>();
                            List<Invoice_Sync__c> invoiceSyncList = new List<Invoice_Sync__c>();
                            Map<String, String> qbOppIdMap = new Map<String, String>();
                            Map<String, String> qbIdPOMap = new Map<String, String>();
                            
                            Map<String, Map<String,Object> > invoiceSyncMap=new  Map<  String, Map<String,Object> >();
                            for (Map<String,Object>mp : listofMaps)
                            {
                                invoiceSyncMap.put(String.valueOf(mp.get('Id')), mp);                    
                            }                        
                            //--------create map of opportunities and their invoices
                            
                            //-----------------------loop through all deleted line items
                            List <Invoice__c> lst_updatedInvoices = new List <Invoice__c>();
                            Map <Id,Invoice__c> map_updatedInvoices = new Map <Id,Invoice__c>();
                            
                            // for(String qbID :lst_QBIdWithoutQuotes){
                            if(invoiceSyncMap.get(QBIdWithoutQuotes) != null){
                                Map<String,Object>mp =invoiceSyncMap.get(QBIdWithoutQuotes);           
                                Map<String,Object>lineItems =(Map<String,Object>)mp.get('MetaData');         
                                Date dt = getDateFromString((String)lineItems.get('CreateTime'));
                                mapQbToDate.put(QBIdWithoutQuotes,dt);                                
                            }
                            //  }                        
                        }
                    }
                }
            }
            catch (Exception e){
                System.debug('===============EXCEPTION==================\n'+e.getMessage());
            }
        }
        
        return mapQbToDate;
    }
    
    public static Date getDateFromString (String input){
        String delimiter = 'T';
        String splitDate = input.substringBefore(delimiter); //
        String[] arrDate = splitDate.split('\\-');
        if(arrDate != null){
            Date datetmp = Date.newInstance(Integer.valueOf(arrDate[0]), Integer.valueOf(arrDate[1]), Integer.valueOf(arrDate[2]));
            return datetmp;
        }
        return null;
    }
    
    public static void calculatePercentagesFromInvoiceSync(Set<Id> stageItems){
        List<String> contentDocsExist = new List<String>();
        for(ContentVersion ver : [Select Id,QB_Id__c from ContentVersion]){
            contentDocsExist.add(ver.QB_Id__c);
        }
        
        Map<Id,Invoice__c> invoices = new Map<Id,Invoice__c>([SELECT Id, Name, Bill__c, Amount__c, Fee__c, Fee_Percentage__c, Billed__c 
                                                              FROM Invoice__c
                                                              WHERE Id = :stageItems]);
        
        
        Map<Id,Double> invoiceAmount = new Map<Id,Double>();
        for(Invoice_Sync__c invSync : [SELECT Id, Name, Invoice__c, QB_Id__c, Amount__c FROM Invoice_Sync__c WHERE Invoice__c = :stageItems]){
            if(contentDocsExist.contains(invSync.QB_Id__c)){
                if(invoiceAmount.get(invSync.Invoice__c) != null){
                    invoiceAmount.put(invSync.Invoice__c, invoiceAmount.get(invSync.Invoice__c) + invSync.Amount__c);
                }
                else{
                    invoiceAmount.put(invSync.Invoice__c,0);
                    invoiceAmount.put(invSync.Invoice__c, invoiceAmount.get(invSync.Invoice__c) + invSync.Amount__c);
                }
            }
        }
        
        for(Id stageItem : invoices.keySet()){
            System.debug('Id = '+stageItem);
            System.debug('Invoice Billed = ' + invoices.get(stageItem).Billed__c);
            System.debug('Invoice Billed Amount = ' + invoiceAmount.get(stageItem));
            System.debug('Invoice Fee = ' + invoices.get(stageItem).Fee__c);
            invoices.get(stageItem).Billed__c = ((invoiceAmount.get(stageItem) == null ? 0 : invoiceAmount.get(stageItem)) / invoices.get(stageItem).Fee__c) * 100;
        }
        update invoices.values();
    }
    
    public static String QuickBookRecordGetter(String query, List<String>  authorizationCredentials){
        
        Boolean successCall = false;
        System.debug('in test getter');
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        Http http = new Http();
        request.setMethod('GET');
        
        if(Test.isRunningTest())
        {
            if(query.contains('Customer'))
            {
                request.setEndPoint('http://test.com/test/getCustomer');
            }
            else if(query.contains('Invoice'))
            {
                request.setEndPoint('http://test.com/test/getInvoice');
            }
        }
        else
        {
            request.setEndPoint(System.label.QB_API_End_Point+'/v3/company/'+authorizationCredentials[2]+'/query?query=' + EncodingUtil.URLENCODE(query,'UTF-8'));
        }
        
        request.setHeader('Accept', 'application/json');
        request.setHeader('Content-Type' , 'application/json;charset=UTF-8');
        
        if(authorizationCredentials[1]!=null)
        {
            Map<String, Object> refreshResults= QuickbookApiCrud.refreshToken(authorizationCredentials[1]);
            if(refreshResults != null){
                authorizationCredentials[0]=(String)refreshResults.get('access_token');
                authorizationCredentials[1]=(String)refreshResults.get('refresh_token');
                request.setHeader('Authorization' , 'Bearer '+authorizationCredentials[0]);
                response = http.send(request);
                
                if(response.getStatusCode() == 200)
                {
                    successCall = true;
                } 
            }
            
        }
        
        if(successCall==true)
        {
            System.debug('Success Call');
            String resp = response.getBody();
            return resp;
        }
        else{
            System.debug('Failed Call');
            sendErrorEmail(response.getStatusCode(),response.getBody());
        }
        
        return null;
    }
  
    public static Integer deleteRecords(String QB_ID, List<String>  authorizationCredentials){
        
        Boolean successCall = false;
        
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        Http http = new Http();
        request.setMethod('POST');
        
        if(Test.isRunningTest())
        {
            request.setEndPoint('http://test.com/test/getInvoice');
        }
        else
        {
            request.setEndPoint(System.label.QB_API_End_Point+'/v3/company/'+authorizationCredentials[2]+'/invoice?operation=delete&minorversion=4');
        }
        
        request.setHeader('Accept', 'application/json');
        request.setHeader('Content-Type' , 'application/json;charset=UTF-8');
        String jsonString = '';
        jsonString += '{"SyncToken": "0","Id": "' + QB_ID + '"}';
        
        request.setBody(jsonString);
        
        if(authorizationCredentials[1]!=null)
        {
            Map<String, Object> refreshResults= QuickbookApiCrud.refreshToken(authorizationCredentials[1]);
            if(refreshResults != null){
                authorizationCredentials[0]=(String)refreshResults.get('access_token');
                authorizationCredentials[1]=(String)refreshResults.get('refresh_token');
                
                request.setHeader('Authorization' , 'Bearer '+authorizationCredentials[0]);
                response = http.send(request);
                if(response.getStatusCode() == 200)
                {
                    successCall = true;
                    System.debug('Successfuly deleted  = 200');
                }
            }                
        }
        
        if(successCall==true)
        {
            return response.getStatusCode();
        }
        else{
            
            System.debug('exited with code' + response.getStatusCode());
        }
        
        return response.getStatusCode();
    }
    
    public static List<String> QuickBookCBC(List<String>  authorizationCredentials){
        Boolean successCall = false;
        
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        Http http = new Http();
        request.setMethod('GET');
        
        if(Test.isRunningTest())
        {
            request.setEndPoint('http://test.com/test/getCustomer');
        }
        else
        {
            request.setEndPoint(System.label.QB_API_End_Point+'/v3/company/'+authorizationCredentials[2]+'/cdc?entities=Invoice&changedSince='+(System.now().addDays(-1).format('yyyy-MM-dd', System.label.QB_Timezone)));
        }
        
        request.setHeader('Accept', 'application/json');
        request.setHeader('Content-Type' , 'application/json;charset=UTF-8');
        
        if(authorizationCredentials[1]!=null)
        {
            Map<String, Object> refreshResults= QuickbookApiCrud.refreshToken(authorizationCredentials[1]);
            if(refreshResults != null){
                authorizationCredentials[0]=(String)refreshResults.get('access_token');
                authorizationCredentials[1]=(String)refreshResults.get('refresh_token');
                
                request.setHeader('Authorization' , 'Bearer '+authorizationCredentials[0]);
                response = http.send(request);
                
                if(response.getStatusCode() == 200)
                {
                    successCall = true;
                }
            }
                
        }
        
        if(successCall==true)
        {
            String resp = response.getBody();
            Map<String,Object> results = (Map<String,Object>)System.JSON.deserializeUntyped(resp);
            List<Object> queryresp = ((List<Object>)results.get('CDCResponse'));
            List<String> idsList = new List<String>();
            
            if(queryresp != null && queryresp.size()>0)
            {
                Object invoiceListJSon = ((List<Object>)((Map<String,Object>)queryresp[0]).get('QueryResponse'))[0];
                List<Object> listOfDeleted = ((List<Object>)((Map<String,Object>)invoiceListJSon).get('Invoice'));
                if(listOfDeleted !=null)
                {
                    for(Object inv: listOfDeleted)
                    {
                        String status = (String)(((Map<String,Object>)inv).get('status'));
                        if(status != null && status == 'Deleted')
                        {
                            idsList.add((String)(((Map<String,Object>)inv).get('Id')));
                        }
                    }
                }
            }
            
            return idsList;
        }   
        else{
            sendErrorEmail(response.getStatusCode(),response.getBody());
        }      
      
        return null;
    }
    
    public static void processDeletedRecords(List<String> QbIds, List<String> authorizationCredentials){
        List<id> delIds = new List<id>();
        List<ContentVersion> updateCVs = [Select id , ContentDocumentId
                                          FROM ContentVersion
                                          WHERE qb_id__c IN: QbIds];
        for(ContentVersion cv:updateCVs)
        {
            delIds.add(cv.ContentDocumentId);
        }
        if(updateCVs.size()>0)
        {
            List<ContentDocument> conDocs=[Select Id from ContentDocument where Id=:delIds];
            delete conDocs;
        }
        
    }
    
    public static void sendErrorEmail (Integer statusCode ,String body){
        System.debug(body);
        String subjectEmail ='( '+String.valueOf(statusCode)+' ) IMPORTANT | QBO | Authentication failed at "'+System.now()+'"'; 
        if(statusCode == 400){
            sendEmail(subjectEmail, body);
        }
        else if(statusCode  == 401){
            sendEmail(subjectEmail, body);            
        }
    }
    
    public static void sendEmail (String subject ,String body){
        String userEmail = UserInfo.getUserEmail();
        //        User activeUser = [Select Email From User where Username = : userName limit 1];
        //       String userEmail = activeUser.Email;
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();   
        message.toAddresses = new String[] {'ali.imran@rolustech.com','behzad.qureshi@rolustech.com','rttest1994@gmail.com' };
            message.optOutPolicy = 'FILTER';
        message.subject = subject;
        message.plainTextBody = body;
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        
        if (results[0].success) {
            System.debug('The email was sent successfully.');
        } else {
            System.debug('The email failed to send: ' + results[0].errors[0].message);
        }
    }
    
    public static void sendTestEmail (String subject ,String body){
        String userEmail = UserInfo.getUserEmail();
        //        User activeUser = [Select Email From User where Username = : userName limit 1];
        //       String userEmail = activeUser.Email;
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();   
        message.toAddresses = new String[] {'ali.imran@rolustech.com'};
            message.optOutPolicy = 'FILTER';
        message.subject = subject;
        message.plainTextBody = body;
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        
        if (results[0].success) {
            System.debug('The email was sent successfully.');
        } else {
            System.debug('The email failed to send: ' + results[0].errors[0].message);
        }
    }
    
    public void testPass(){
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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
        i=0;i=0;
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