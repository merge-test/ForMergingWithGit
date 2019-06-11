global class OpportunityOldDaysSchedluer implements schedulable  {
    global void execute(SchedulableContext stx)
    {
        checkAndUpdateDaysField();
    }
    
    public static void checkAndUpdateDaysField()
    {
        List<ContentVersion> processCvList = new List<ContentVersion>();
        List<id> ContentDocumentIds = new List<id>();
        Map<id, ContentVersion> cvMap = new Map<id, ContentVersion>();
        Map<id, id> cdlMap = new Map<id, id>();
        Map<id, id> cvOppMap = new Map<id, id>();
        
        List<id> cdLists = new List<id>();
        
        for(ContentVersion cvs:[SELECT Id, title, ContentDocumentId, Amount__c, Days_Outstanding__c from ContentVersion])
        {
            if(cvs.title.contains('Invoice#'))
            {
                cdLists.add(cvs.ContentDocumentId);
                processCvList.add(cvs);
                cvMap.put(cvs.id, cvs);
            }
        }
        
        for(ContentDocumentLink cdl: [Select id, ContentDocumentId, linkedEntityId from ContentDocumentLink where ContentDocumentId=:cdLists])
        {
            ContentDocumentIds.add(cdl.ContentDocumentId);
            cdlMap.put(cdl.ContentDocumentId, cdl.linkedEntityId);
        }
        
        for(ContentVersion cv:processCvList)
        {
            cvOppMap.put(cv.id, cdlMap.get(cv.ContentDocumentId));
        }
        
        if(processCvList.size()>0)
        {
             List<Opportunity> opps = [SELECT Id, Name, StageName,Balance_Outstanding__c, X0_30_Days_Old__c, X31_60_Days_Old__c, X61_90_Days_Old__c, X91_120_Days_Old__c, X120_Days_Old__c 
                                          FROM Opportunity];  
            OpportuniytSchedulerHandler.updateRecords(opps,0,null);
//            OpportuniytSchedulerHandler.updateOppofInvoice(processCvList, cvMap, cvOppMap,'');
        }
    }
}