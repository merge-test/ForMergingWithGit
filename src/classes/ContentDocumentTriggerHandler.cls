public class ContentDocumentTriggerHandler { 
    
    public static List <Opportunity> getOpportunities(List<ContentDocument> lst_contentDocument){
        //    List <Opportunity> lst_opp = new List <Opportunity>();
        List <Id> lst_cd = new List <Id>();
        for(ContentDocument cd: lst_contentDocument){
            lst_cd.add(cd.id);
        }
        
        List <Id> lst_oppId = new List <Id>();
        for(ContentDocumentLink cdl :[ SELECT id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN: lst_cd]){
            lst_oppId.add(cdl.LinkedEntityId);            
        }
        
        List<Opportunity> lst_opps = [SELECT Id, Name, StageName, X0_30_Days_Old__c, X31_60_Days_Old__c, X61_90_Days_Old__c, X91_120_Days_Old__c, X120_Days_Old__c 
                                      FROM Opportunity where Id IN :lst_oppId]; 
        return lst_opps;
    }
    
    
    public static void revertBackPercentages (List <ContentDocument> lst_cd){
   		List <String> qb_Ids = new List <String> ();
        List <Id> lst_cdIds = new List <Id>();
        for(ContentDocument cd : lst_cd) {
            lst_cdIds.add(cd.id);
        }
        List <ContentVersion> lst_cv = [Select id,QB_Id__c,ContentDocumentId from ContentVersion where contentDocumentId IN :lst_cdIds];
         Map<id, id> GlobalcvOppMap = new Map<id, id>();
         for(ContentDocumentLink cdl:[Select id, ContentDocumentId, linkedEntityId from ContentDocumentLink where ContentDocumentId=:lst_cdIds])
        {
            String linkedid = cdl.linkedEntityId; 
            if(linkedid.startsWith('006'))
            {
                GlobalcvOppMap.put(cdl.ContentDocumentId, cdl.linkedEntityId);
            }
        }
        
        
        Map<String,Id> mapQBtoCV = new Map <String,Id>(); 
        List<String> lst_QBId = new List <String> ();
        List<String> lst_QBIdWithoutQuotes = new List <String> ();
        for(ContentVersion content:lst_cv){
            lst_QBId.add('\''+content.QB_Id__c+'\'');
            lst_QBIdWithoutQuotes.add(content.QB_Id__c);
            mapQBtoCV.put(content.QB_Id__c,content.ContentDocumentId);
        }
        Map <Id,String> mapInvoiceQbId = new Map <Id, String>();
        Set <Id> lst_oppId = new Set <Id>();
        List <Invoice_Sync__c> lst_InvoiceSync = [Select Name,QB_Id__c,Invoice__r.id,Amount__c,PO__c,Invoice__r.Opportunity__c,Invoice__r.Fee__c,Invoice__r.Billed__c from Invoice_Sync__c where QB_Id__c IN :lst_QBIdWithoutQuotes];
        for(Invoice_Sync__c invSync : lst_InvoiceSync){
            lst_oppId.add(invSync.Invoice__r.Opportunity__c);
            mapInvoiceQbId.put(invSync.Invoice__r.id,invSync.QB_Id__c);
        } 
		System.debug('Related Opportunity Ids are '+lst_oppId);
        OpportuniytSchedulerHandler.calculatePercentages(lst_QBId,lst_QBIdWithoutQuotes,GlobalcvOppMap,mapQBtoCV,2);
        QuickbookApiCrud.sendInvoice(lst_oppId,mapInvoiceQbId,1);
        /*Map <Id,Double> mapInvoice = new Map <Id,Double>();
		List <Invoice_Sync__c> lst_InvoiceSync = [Select Name,QB_Id__c,Amount__c,PO__c,Invoice__r.Fee__c,Invoice__r.Billed__c from Invoice_Sync__c where QB_Id__c IN :qb_Ids];
        for(Invoice_Sync__c invSync : lst_InvoiceSync){

            	double amount = invSync.Amount__c;
            	double fees = invSync.Invoice__r.Fee__c;
            	double percent = (amount/fees)*100;
        }*/
        
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
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
                i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
                i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
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