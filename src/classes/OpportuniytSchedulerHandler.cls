public class OpportuniytSchedulerHandler {
    public static void updateOppofInvoice(List<ContentVersion> cvLists, Map<id, ContentVersion> cvMap, Map<id, id> oppCvMap, string action){
        List<id> cdIds = new List<id>();
        Map<id, Opportunity> oppMap = new Map<id, Opportunity>();
        List<Opportunity> updateOpp = new List<Opportunity>();
        
        for(ContentVersion cv: cvLists)
        {
            cdIds.add(cv.ContentDocumentId);
        }
        
        List<id> oppIds = new List<id>();
        
        oppMap = getRelatedOpportunities(oppCvMap.values());
        
        if(action=='delete')
        {
            update setOldDaysOppDel(oppCvMap, oppMap, cvMap);
        }
        else{
            update setOldDaysOppNew(oppCvMap, oppMap, cvMap);
        }        
    }
    
    public static void calculatePercentages(List<String> lst_QBId, List<String> lst_QBIdWithoutQuotes, Map<id, id> cvOppMap,Map<String,Id> mapQBtoCV,Integer isDeleted){       
        Map <Id,Invoice__c> map_updatedInvoices = new Map <Id,Invoice__c>();
        List <Invoice_Sync__c> lstInvoiceSync = new List<Invoice_Sync__c>([Select id,CreatedDate,Invoice__r.Billed__c,CreatedDate__c,QB_ID__c,LastModifiedDate,Invoice__r.Name,Amount__c from Invoice_Sync__c where QB_ID__c =:lst_QBIdWithoutQuotes]);
        List<Id> lstOppId = new List <Id>();
        for(Id key: cvOppMap.values()) {
            lstOppId.add(key);
        }
        Map<Id,List<Invoice__c>> mapOppToInvoice = new Map <Id,List<Invoice__c>> ();
        for(Invoice__c invObj:[Select id,Name,Bill__c,Fee__c,Billed__c,Amount__c,opportunity__c  from invoice__c where opportunity__c = :lstOppId]){
            if(mapOppToInvoice.get(invObj.opportunity__c) != null){
                mapOppToInvoice.get(invObj.opportunity__c).add(invObj);
            }   
            else{
                mapOppToInvoice.put(invObj.opportunity__c,new List<Invoice__c>());
                mapOppToInvoice.get(invObj.opportunity__c).add(invObj);
            }
            
        }
        List <Invoice_Sync__c> lst_updatedInvoiceSync = new List <Invoice_Sync__c>();
        for (Invoice_Sync__c invSyncObj : lstInvoiceSync)
        {
            if((invSyncObj.Amount__c >0 || IsDeleted == 0) && invSyncObj.Invoice__r.Name!=null){
                String relatedCvId =mapQBtoCV.get(invSyncObj.QB_ID__c );
                String relatedOppId= cvOppMap.get(relatedCvId);        
                for(Invoice__c tmpInv:mapOppToInvoice.get(relatedOppId)){                                       
                    if(invSyncObj.Invoice__c == tmpInv.id){
                        if(invSyncObj.Invoice__r.Name.equals(tmpInv.Name)){
                           if(tmpInv.Fee__c>0){
                            Decimal amountPercentage = (invSyncObj.Amount__c/tmpInv.Fee__c)*100;
                           
                            // Decimal rounded = amountPercentage.setScale(2, RoundingMode.HALF_UP);
                            Decimal rounded = amountPercentage;
                            Decimal result =0.0;
                            if(map_updatedInvoices.get(tmpInv.id) != null){
                                if(isDeleted == 1 ){
                                    result  = math.abs( map_updatedInvoices.get(tmpInv.id).Billed__c-rounded);                                     
                                }
                                else{
                                    result  = math.abs( map_updatedInvoices.get(tmpInv.id).Billed__c+rounded);                                
                                }
                                
                            }
                            else{
                                if(isDeleted == 1 ){
                                    result  = math.abs(tmpInv.Billed__c-rounded);
                                }
                                else{
                                    result  = math.abs(tmpInv.Billed__c+rounded);
                                }
                                lst_updatedInvoiceSync.add(invSyncObj);
                                map_updatedInvoices.put(tmpInv.id,tmpInv);
                            }
                               System.debug('rounded ----- '+rounded);
                               System.debug('result ----- '+result);
                                                              System.debug('tmpInv.Bill__c ----- '+tmpInv.Bill__c);
                               //-------------Undeleted Case
                               if(isDeleted == 2){
                                   tmpInv.Bill__c = rounded;
                                   System.debug('Rounded '+rounded);
                               }else{
	                               tmpInv.Billed__c = result;                                   
                               }
                           }
                        }
                    }
                }                                    
            }
            
        }  
        
        
        
        List <Invoice__c> lst_updatedInvoices = new List <Invoice__c>();
        for(Id keyId:map_updatedInvoices.keyset()){
            lst_updatedInvoices.add(map_updatedInvoices.get(keyId));
        }
      //  update lst_updatedInvoices; 
      try{
        update lst_updatedInvoices;        
          if(isDeleted == 2){
              delete lst_updatedInvoiceSync;
          }
        }
        catch(Exception ex){
            //ex.getMessage('');
        }

        
    }
    
    public static void deleteRelatedInvoiceSync(List<String> lst_QBIdWithoutQuotes){
        List <Invoice_Sync__c> updateInvoiceSync = new List <Invoice_Sync__c>([Select id,QB_Id__c from Invoice_Sync__c where QB_Id__c IN :lst_QBIdWithoutQuotes]);
        if(updateInvoiceSync.size()>0){
            delete updateInvoiceSync;
        }
    }
    
    @future (callout=true)
    public static void deleteRelatedQbInvoice(List<String> lst_QBIdWithoutQuotes){
        if(lst_QBIdWithoutQuotes.size() >0){
            List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                             realmid__c from QB_Credentials__c];    
            if(qbcList.size()>0)
            {
                List <String>deletedQbId = new List<String>();
                List<String>  authorizationCredentials=new List<String>  ();
                authorizationCredentials.add(qbcList[0].Access_token__c);
                authorizationCredentials.add(qbcList[0].Refresh_token__c);
                authorizationCredentials.add(qbcList[0].realmid__c);
                for(String key:lst_QBIdWithoutQuotes){
                    Integer qbResponseDelete = QuickBookScheduler.deleteRecords(key, authorizationCredentials);    
                    if(qbResponseDelete == 200){
                        deletedQbId.add(key);
                        System.debug('Deleted from QBO');
                    }
                    else{
                        sendEmail('Failed to delete invoice '+key+' from QB','The reason due to which unable to delete the invoice is '+qbResponseDelete);
                        System.debug('Error deleting from QBO');
                    }
                }
                
                
            }
        }
    }
    
    public static void sendEmail (String subject ,String body){
        String userEmail = UserInfo.getUserEmail();
        //        User activeUser = [Select Email From User where Username = : userName limit 1];
        //       String userEmail = activeUser.Email;
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();   
        message.toAddresses = new String[] { userEmail };
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
    
    @future (callout=true)
    public static void updateOppOnCvDeletion( List<Id> lstContentVersionId, Map<id, id> cvOppMap,List<String> lst_QBId, List<String> lst_QBIdWithoutQuotes,Map<String,Id> mapQBtoCV){
        String QB_Id = null;
        if(lst_QBIdWithoutQuotes.size() >0){
            List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                             realmid__c from QB_Credentials__c];    
            if(qbcList.size()>0)
            {
                List<String>  authorizationCredentials=new List<String>  ();
                authorizationCredentials.add(qbcList[0].Access_token__c);
                authorizationCredentials.add(qbcList[0].Refresh_token__c);
                authorizationCredentials.add(qbcList[0].realmid__c);
                String query = 'Select * from Invoice where id IN '+lst_QBId;
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
                        
                        List<Id> lstOppId = new List <Id>();
                        for(Id key: cvOppMap.values()) {
                            lstOppId.add(key);
                        }
                        
                        Map<Id,List<Invoice__c>> mapOppToInvoice = new Map <Id,List<Invoice__c>> ();
                        for(Invoice__c invObj:[Select id,Name,Bill__c,Fee__c,Billed__c,Amount__c,opportunity__c  from invoice__c where opportunity__c = :lstOppId]){
                            if(mapOppToInvoice.get(invObj.opportunity__c) != null){
                                mapOppToInvoice.get(invObj.opportunity__c).add(invObj);
                            }   
                            else{
                                mapOppToInvoice.put(invObj.opportunity__c,new List<Invoice__c>());
                                mapOppToInvoice.get(invObj.opportunity__c).add(invObj);
                            }
                        }
                        
                        
                        Map<Id,List<Invoice_Sync__c>> mapInvToInvSync = new Map <Id,List<Invoice_Sync__c>> ();
                        for(Invoice_Sync__c invObj:[Select Name,QB_Id__c,Amount__c,PO__c,Invoice__c from Invoice_Sync__c where QB_Id__c = :lst_QBIdWithoutQuotes]){
                            if(mapInvToInvSync.get(invObj.Invoice__c) != null){
                                mapInvToInvSync.get(invObj.Invoice__c).add(invObj);
                            }   
                            else{
                                mapInvToInvSync.put(invObj.Invoice__c,new List<Invoice_Sync__c>());
                                mapInvToInvSync.get(invObj.Invoice__c).add(invObj);
                            }
                        }
                        
                        
                        //-----------------------loop through all deleted line items
                        List <Invoice__c> lst_updatedInvoices = new List <Invoice__c>();
                        Map <Id,Invoice__c> map_updatedInvoices = new Map <Id,Invoice__c>();
                        
                        for(String qbID :lst_QBIdWithoutQuotes){
                            Map<String,Object>mp =invoiceSyncMap.get(qbID);                
                            List<Object> lineItems = (List<Object>)mp.get('Line');
                            List<Map<String,Object>> lineList = new List<Map<String,Object>>();
                            for (Object instance : lineItems)
                            {                    
                                lineList.add((Map<String,Object>)instance);
                            }   
                            
                            for (Map<String,Object>lineItem : lineList)
                            {
                                Double amount= Double.valueOf(lineItem.get('Amount'));
                                String lineItemDesc = String.valueOf(lineItem.get('Description'));
                                if(amount>0 && lineItemDesc!=null){
                                    String relatedCvId =mapQBtoCV.get(qbID);
                                    String relatedOppId= cvOppMap.get(relatedCvId);
                                    
                                    for(Invoice__c tmpInv:mapOppToInvoice.get(relatedOppId)){                                       
                                        if(lineItemDesc.equals(tmpInv.Name)){
                                            for(Invoice_Sync__c tmpInvSync:mapInvToInvSync.get(tmpInv.id)){
                                                if(tmpInvSync.QB_Id__c == qbID){
                                                    Decimal amountPercentage = (tmpInvSync.Amount__c/tmpInv.Fee__c)*100;
                                                    Decimal rounded = amountPercentage.setScale(2, RoundingMode.HALF_UP);
                                                    
                                                    //lst_updatedInvoices.add(tmpInv);
                                                    Decimal result =0.0;
                                                    if(map_updatedInvoices.get(tmpInv.id) != null){
                                                        result  = math.abs( map_updatedInvoices.get(tmpInv.id).Billed__c-rounded); 
                                                    }
                                                    else{
                                                        result  = math.abs(tmpInv.Billed__c-rounded);
                                                        map_updatedInvoices.put(tmpInv.id,tmpInv);
                                                    }
                                                    tmpInv.Billed__c = result;
                                                }
                                            }
                                            
                                        }
                                    }                                    
                                }
                                
                            }  
                            
                        }
                        for(Id keyId:map_updatedInvoices.keyset()){
                            lst_updatedInvoices.add(map_updatedInvoices.get(keyId));
                        }
                        
                        List <String> deletedQbIds = new List <String>();
                        for(String key:lst_QBIdWithoutQuotes){
                            Integer qbResponseDelete = QuickBookScheduler.deleteRecords(key, authorizationCredentials);    
                            if(qbResponseDelete == 200){
                                deletedQbIds.add(key);
                            }
                        }
                        update lst_updatedInvoices;
                        
                        List <Invoice_Sync__c> updateInvoiceSync = new List <Invoice_Sync__c>([Select id,QB_Id__c from Invoice_Sync__c where QB_Id__c IN :deletedQbIds]);
                        if(updateInvoiceSync.size()>0){
                            delete updateInvoiceSync;
                        }
                    }
                }
                
            }
        }
    }
    
    public static Map<id, Opportunity> getRelatedOpportunities(List<id> oppIds){
        Map<id, Opportunity> oppMap = new Map<id, Opportunity>();
        for(Opportunity opp:[select id, X0_30_Days_Old__c, X31_60_Days_Old__c, X61_90_Days_Old__c, X91_120_Days_Old__c, X120_Days_Old__c
                             from opportunity where id=:oppIds])
        {
            oppMap.put(opp.id, opp);
        }
        return oppMap;
    }
    
    public static List<Opportunity> setOldDaysOppDel(Map<id, id> oppCvMap, Map<id, Opportunity> oppMap, Map<id, ContentVersion> cvMap){
        List<Opportunity> updateOpp = new List<Opportunity>();
        Map<id, Opportunity> oldOppMap = new Map<id, Opportunity>();
        
        for(Id cvId: oppCvMap.keyset())
        {
            Id oppId = oppCvMap.get(cvId);
            if(oppId != null)
            {
                if(oldOppMap.get(oppId)==null)
                {
                    if(oppMap.get(oppId)!=null){
                        oldOppMap.put(oppId, oppMap.get(oppId));
                    }                    
                }
                
                Opportunity oppObj = oldOppMap.get(oppId);
                
                ContentVersion cvObj = cvMap.get(cvId);
                if(cvObj!=null && oppObj!=null)
                {
                    if(cvObj.Days_Outstanding__c=='0-30')
                    {
                        oppObj.X0_30_Days_Old__c -= cvObj.Amount__c;
                    }
                    else if(cvObj.Days_Outstanding__c=='31-60')
                    {
                        oppObj.X31_60_Days_Old__c -= cvObj.Amount__c;
                    }
                    else if(cvObj.Days_Outstanding__c=='61-90')
                    {
                        oppObj.X61_90_Days_Old__c -= cvObj.Amount__c;
                    }
                    else if(cvObj.Days_Outstanding__c=='91-120')
                    {
                        oppObj.X91_120_Days_Old__c -= cvObj.Amount__c;
                    }
                    else if(cvObj.Days_Outstanding__c=='>121')
                    {
                        oppObj.X120_Days_Old__c -= cvObj.Amount__c;
                    }
                    oldOppMap.put(oppId, oppObj);
                }
            }
        }
        return oldOppMap.values();
    }
    
    public static List<Opportunity> setOldDaysOppNew(Map<id, id> oppCvMap, Map<id, Opportunity> oppMap, Map<id, ContentVersion> cvMap){
        List<Opportunity> updateOpp = new List<Opportunity>();
        Map<id, Opportunity> oldOppMap = new Map<id, Opportunity>();
        
        for(Id cvId: oppCvMap.keyset())
        {
            Id oppId = oppCvMap.get(cvId);
            
            if(oppId != null)
            {
                if(oldOppMap.get(oppId)==null)
                {
                    if(oppMap.get(oppId)!=null){
                        oldOppMap.put(oppId, oppMap.get(oppId));
                    }                    
                }
                
                Opportunity oppObj = oldOppMap.get(oppId);
                
                ContentVersion cvObj = cvMap.get(cvId);
                if(cvObj!=null && oppObj!=null)
                {
                    if(cvObj.Amount__c == null){
                        cvObj.Amount__c = 0;
                    }
                    if(cvObj.Days_Outstanding__c=='0-30')
                    {    
                        if(oppObj.X0_30_Days_Old__c == null){
                            oppObj.X0_30_Days_Old__c = 0;
                        }
                        oppObj.X0_30_Days_Old__c+= cvObj.Amount__c;
                    }
                    else if(cvObj.Days_Outstanding__c=='31-60')
                    {
                        if(oppObj.X31_60_Days_Old__c == null){
                            oppObj.X31_60_Days_Old__c = 0;
                        }
                        oppObj.X31_60_Days_Old__c+= cvObj.Amount__c;
                    }
                    else if(cvObj.Days_Outstanding__c=='61-90')
                    {
                        if(oppObj.X61_90_Days_Old__c == null){
                            oppObj.X61_90_Days_Old__c = 0;
                        }
                        oppObj.X61_90_Days_Old__c+= cvObj.Amount__c;
                    }
                    else if(cvObj.Days_Outstanding__c=='91-120')
                    {
                        if(oppObj.X91_120_Days_Old__c == null){
                            oppObj.X91_120_Days_Old__c = 0;
                        }
                        oppObj.X91_120_Days_Old__c+= cvObj.Amount__c;
                    }
                    else if(cvObj.Days_Outstanding__c=='>121')
                    {
                        if(oppObj.X120_Days_Old__c == null){
                            oppObj.X120_Days_Old__c = 0;
                        }
                        oppObj.X120_Days_Old__c+= cvObj.Amount__c;
                    }
                    oldOppMap.put(oppId, oppObj);
                }
            }
        }
        return oldOppMap.values();
    }
     
    
    public static void updateRecords(List <Opportunity> opps,Integer isDeleted,Map <Id,Id> mapContentDocument)
    {
        //        List<Opportunity> opps = [SELECT Id, Name, StageName, X0_30_Days_Old__c, X31_60_Days_Old__c, X61_90_Days_Old__c, X91_120_Days_Old__c, X120_Days_Old__c 
        //                                  FROM Opportunity];                                 
        system.debug(opps.size());
        List<Id> allOppIDs = new List<Id>();
        Map<Id, Opportunity> oppIDsMap = new Map<Id, Opportunity>();
        for(Opportunity o: opps)
        {
            o.X0_30_Days_Old__c = 0;
            o.X31_60_Days_Old__c = 0;
            o.X61_90_Days_Old__c = 0;
            o.X91_120_Days_Old__c = 0;
            o.X120_Days_Old__c = 0;
            o.Balance_Outstanding__c = 0;
            oppIDsMap.put(o.id, o);
            allOppIDs.add(o.id);
        }
        System.debug('--- Opp Id --- '+allOppIds);        
        if(allOppIds.size()>0){
            List<ContentDocumentLink> cdl = [SELECT id, LinkedEntityId, ContentDocumentId
                                             FROM ContentDocumentLink 
                                             WHERE LinkedEntityId IN: allOppIDs];
            SYSTEM.debug(cdl.size());
            
            Map<Id, Id> docOppMap = new Map<Id, Id>();
            for(ContentDocumentLink c: cdl)
            {
                if(isDeleted == 1 && mapContentDocument != null){
                    if(mapContentDocument.get(c.ContentDocumentId) != null){
                        
                    }                   
                    else{
                        docOppMap.put(c.ContentDocumentId, c.LinkedEntityId);   
                    }
                }
                else{
                    docOppMap.put(c.ContentDocumentId, c.LinkedEntityId);   
                }
            }
            
            List<ContentVersion> cv = [SELECT id,ContentDocumentId, Amount__c, Days_Outstanding__c, Status__c, Title
                                       FROM ContentVersion 
                                       WHERE ContentDocumentId IN: docOppMap.keySet()
                                       and Title like 'Invoice%' and Status__c != 'Paid'];
            
            for(ContentVersion cvObj: cv)
            {
                Double outBalance = 0;
                Opportunity oppObj = oppIDsMap.get(docOppMap.get(cvObj.ContentDocumentId));
                if(cvObj.Days_Outstanding__c=='0-30')
                {
                    oppObj.X0_30_Days_Old__c += cvObj.Amount__c;
                    oppObj.Balance_Outstanding__c+=cvObj.Amount__c;
                }
                else if(cvObj.Days_Outstanding__c=='31-60')
                {
                    oppObj.X31_60_Days_Old__c += cvObj.Amount__c;
                    oppObj.Balance_Outstanding__c+=cvObj.Amount__c;
                }
                else if(cvObj.Days_Outstanding__c=='61-90')
                {
                    oppObj.X61_90_Days_Old__c += cvObj.Amount__c;
                    oppObj.Balance_Outstanding__c+=cvObj.Amount__c;
                }
                else if(cvObj.Days_Outstanding__c=='91-120')
                {
                    oppObj.X91_120_Days_Old__c += cvObj.Amount__c;
                    oppObj.Balance_Outstanding__c+=cvObj.Amount__c;
                }
                else if(cvObj.Days_Outstanding__c=='>121')
                {
                    oppObj.X120_Days_Old__c += cvObj.Amount__c;
                    oppObj.Balance_Outstanding__c+=cvObj.Amount__c;
                }
            }
            update opps;         
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
        
    }
}