trigger TriggerOnContentDocument on ContentDocument (before delete, after undelete,after update,after insert,after delete) {
    
    Map<id, id> GlobalcvOppMap = new Map<id, id>();
    List <Id> GlobalcontentVersionIds = new List <Id>();
    
    List<ContentVersion> GloablListCV = new List <ContentVersion>();
    List<String> lst_GlobalQBIdWithoutQuotes = new List <String> ();
    Integer isDeleted = 0;
    
    if(Trigger.isAfter){
        if(Trigger.isUndelete){
          ContentDocumentTriggerHandler.revertBackPercentages(Trigger.new); 
             List <Opportunity> lst_opp =ContentDocumentTriggerHandler.getOpportunities(Trigger.new);
            OpportuniytSchedulerHandler.updateRecords(lst_opp,0,null);
        }        
        
           if(Trigger.isUpdate){			
            System.debug('Updated Content Version'+Trigger.new);
  			List <Opportunity> lst_opp = ContentDocumentTriggerHandler.getOpportunities(Trigger.new);
            OpportuniytSchedulerHandler.updateRecords(lst_opp,0,null);
        }
        else if(Trigger.isInsert){
            System.debug('Inserted Content Version');
            System.debug('Inserted Content Version'+Trigger.new);
            List <Opportunity> lst_opp =ContentDocumentTriggerHandler.getOpportunities(Trigger.new);
            OpportuniytSchedulerHandler.updateRecords(lst_opp,0,null);
        }
       /* else if(Trigger.isDelete){
            System.debug('Deleted Content Version'+Trigger.old);
            List <Opportunity> lst_opp =ContentDocumentTriggerHandler.getOpportunities(Trigger.old);
            System.debug('Opp List is '+lst_opp);
            OpportuniytSchedulerHandler.updateRecords(lst_opp);
        } */
    }
    
    if(Trigger.isDelete && Trigger.isBefore)
    {
        List <Opportunity> lst_opp =ContentDocumentTriggerHandler.getOpportunities(Trigger.old);
        System.debug('Opp List is '+lst_opp);
      
        isDeleted=1;
        List<id> invoiceCds = new List<id>();
        List<ContentVersion> processCvList = new List<ContentVersion>();
        List<id> linkedEntityIds = new List<id>();
        List<id> cdLists = new List<id>();
        Map<id, ContentVersion> cvMap = new Map<id, ContentVersion>();
        Map<id, id> tempMap = new Map<id, id>();
        Map<id, id> cdsOppMap = new Map<id, id>();
        Map<id, id> cvOppMap = new Map<id, id>();
        Map<id, id> cdMap = new Map<id, id>();
        for(ContentDocument cv: trigger.old)
        {
            if(cv.title.contains('Invoice'))
            {
                invoiceCds.add(cv.id);
                cdMap.put(cv.id,cv.id);
            }
        }
        
          OpportuniytSchedulerHandler.updateRecords(lst_opp,1,cdMap);
        for(ContentDocumentLink cdl:[Select id, ContentDocumentId, linkedEntityId from ContentDocumentLink where ContentDocumentId=:invoiceCds])
        {
            linkedEntityIds.add(cdl.linkedEntityId);
            String linkedid = cdl.linkedEntityId; 
            if(linkedid.startsWith('006'))
            {
                cvOppMap.put(cdl.ContentDocumentId, cdl.linkedEntityId);
                GlobalcvOppMap.put(cdl.ContentDocumentId, cdl.linkedEntityId);
            }
        }
        List <Id> contentVersionIds = new List <Id>();
        for(ContentVersion cvs:[SELECT Id, title, ContentDocumentId, Amount__c,Status__c, Days_Outstanding__c,QB_Id__c from ContentVersion where contentdocumentid=:cvOppMap.keySet()])
        {
            if(cvs.title.contains('Invoice#'))
            {
                if(cvs.Status__c != 'Paid'){
                    processCvList.add(cvs);
                    cvMap.put(cvs.ContentDocumentId, cvs);
                } 
                contentVersionIds.add(cvs.Id);
                GlobalcontentVersionIds.add(cvs.Id);
                GloablListCV.adD(cvs);
            }
        }
        
        if(processCvList.size()>0)
        {
            system.debug(processCvList);
            //OpportuniytSchedulerHandler.updateOppofInvoice(processCvList, cvMap, cvOppMap, 'delete');
        }
        
        Map<String,Id> mapQBtoCV = new Map <String,Id>(); 
        List<String> lst_QBId = new List <String> ();
        List<String> lst_QBIdWithoutQuotes = new List <String> ();
        for(ContentVersion content:GloablListCV){
            lst_QBId.add('\''+content.QB_Id__c+'\'');
            lst_QBIdWithoutQuotes.add(content.QB_Id__c);
            lst_GlobalQBIdWithoutQuotes.add(content.QB_Id__c);
            mapQBtoCV.put(content.QB_Id__c,content.ContentDocumentId);
        }
        OpportuniytSchedulerHandler.calculatePercentages(lst_QBId,lst_QBIdWithoutQuotes,GlobalcvOppMap,mapQBtoCV,1);
    }
    
    
    
    if( System.isFuture() == false){        
        if(isDeleted == 1){
            OpportuniytSchedulerHandler.deleteRelatedQbInvoice(lst_GlobalQBIdWithoutQuotes);        
        }
    }
}