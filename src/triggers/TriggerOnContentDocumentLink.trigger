trigger TriggerOnContentDocumentLink on ContentDocumentLink (before insert) {
    if(Trigger.isInsert && Trigger.isBefore)
    {
        List<id> invoiceCds = new List<id>();
        List<ContentVersion> processCvList = new List<ContentVersion>();
        List<id> linkedEntityIds = new List<id>();
        List<id> cdLists = new List<id>();
        Map<id, ContentVersion> cvMap = new Map<id, ContentVersion>();
        Map<id, id> tempMap = new Map<id, id>();
        Map<id, id> cdsOppMap = new Map<id, id>();
        Map<id, id> cvOppMap = new Map<id, id>();
        
        for(ContentDocumentLink cdl:trigger.new)
        {
            String linkedid = cdl.linkedEntityId; 
            if(linkedid.startsWith('006'))
            {
                linkedEntityIds.add(cdl.linkedEntityId);
                cvOppMap.put(cdl.ContentDocumentId, cdl.linkedEntityId);
            }
        }
        
        for(ContentVersion cvs:[SELECT Id, title, ContentDocumentId, Amount__c, Days_Outstanding__c from ContentVersion where contentdocumentid=:cvOppMap.keySet() and Status__c NOT IN ('Paid')])
        {
            if(cvs.title.contains('Invoice#'))
            {
                processCvList.add(cvs);
                cvMap.put(cvs.ContentDocumentId, cvs);
            }
        }
        
        if(processCvList.size()>0)
        {
            OpportuniytSchedulerHandler.updateOppofInvoice(processCvList, cvMap, cvOppMap,'');
        }
    }
}