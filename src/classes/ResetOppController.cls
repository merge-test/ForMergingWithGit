public class ResetOppController {
    Id oppId;
    
    public ResetOppController(ApexPages.StandardController stdController){
        oppId = stdController.getRecord().Id;
    }
    
    public PageReference resetOpp(){
        delete [Select Id from Invoice__c where Opportunity__c = :oppId];
        delete [Select Id from FeeStorage__c where Opportunity__c = :oppId];
        createNewInvoices();
        deleteIssuedInvoices();
        return redirectToRecord();
    }
    
    public void createNewInvoices(){
        List<Invoice__c> defaultInvoices=new List<Invoice__c>();
        Opportunity targetOpp = [SELECT Id, Construction_Admin__c, DOB_Filing_Set_1__c, DOB_Approval_1__c, Retainer1__c, TF_CA__c, TF_DD_CD__c, TF_DOB_App__c,
                                 TF_DOB_Filing__c, TF_Punch__c, TF_SD__c, Schematic_Design_SD_1__c, Bid_Documents_Construction_Documents__c, Punchlist__c 
                                 FROM Opportunity
                                Where Id = :oppId];
        defaultInvoices.add(new Invoice__c(Name=System.label.Default_Stage_1, Time_Frame__c='To Start Project', Default__c=true,
                                           Fee__c=targetOpp.Retainer1__c, Opportunity__c=oppId));
        
        defaultInvoices.add(new Invoice__c(Name=System.label.Default_Stage_2, Time_Frame__c=String.valueof(targetOpp.TF_SD__c), Default__c=true,
                                           Fee__c=targetOpp.Schematic_Design_SD_1__c, Opportunity__c=oppId));
        
        defaultInvoices.add(new Invoice__c(Name=System.label.Default_Stage_3, Time_Frame__c=String.valueof(targetOpp.TF_DOB_Filing__c), Default__c=true,
                                           Fee__c=targetOpp.DOB_Filing_Set_1__c, Opportunity__c=oppId));
        
        defaultInvoices.add(new Invoice__c(Name=System.label.Default_Stage_4, Time_Frame__c=String.valueof(targetOpp.TF_DOB_App__c), Default__c=true,
                                           Fee__c=targetOpp.DOB_Approval_1__c, Opportunity__c=oppId));
        
        defaultInvoices.add(new Invoice__c(Name=System.label.Default_Stage_5, Time_Frame__c=String.valueof(targetOpp.TF_DD_CD__c), Default__c=true,
                                           Fee__c=targetOpp.Bid_Documents_Construction_Documents__c, Opportunity__c=oppId));
        
        defaultInvoices.add(new Invoice__c(Name=System.label.Default_Stage_6, Time_Frame__c=String.valueof(targetOpp.TF_CA__c), Default__c=true,
                                           Fee__c=targetOpp.Construction_Admin__c, Opportunity__c=oppId));
        
        defaultInvoices.add(new Invoice__c(Name=System.label.Default_Stage_7, Time_Frame__c=String.valueof(targetOpp.TF_Punch__c), Default__c=true,
                                           Fee__c=targetOpp.Punchlist__c, Opportunity__c=oppId));
        
        insert defaultInvoices;
    }
    
    public void deleteIssuedInvoices(){
        List<Id> contentLinkIds=new List<Id>();
        List<Id> idsToDelete=new List<Id>();
        List<Deleted_QB_Ids__c> deletedIds = new List<Deleted_QB_Ids__c>();
        List<ContentDocumentLink> issuedInvoicesLinks=[Select Id, ContentDocumentId from ContentDocumentLink where LinkedEntityId=:oppId];
        for(ContentDocumentLink cdl:issuedInvoicesLinks){
            contentLinkIds.add(cdl.ContentDocumentId);
        }
        
        for(ContentVersion cvs:[SELECT Id, title, ContentDocumentId, Amount__c,Status__c, Days_Outstanding__c,QB_Id__c from ContentVersion where contentdocumentid=:contentLinkIds]){
            if(cvs.title.contains('Invoice#')){
                idsToDelete.add(cvs.ContentDocumentId);
                deletedIds.add(new Deleted_QB_Ids__c(Name=cvs.QB_Id__c,QB_ID__c = cvs.QB_Id__c));
            }
        }
        try{
            insert deletedIds;
        }
        catch(Exception e){
            System.debug('Exception : ' + e.getMessage());
        }
        delete [Select Id from ContentDocument where Id =:idsToDelete];
    }
    
    public PageReference redirectToRecord(){
        PageReference reference = new PageReference('/'+oppId);
        reference.setRedirect(true);
        return reference;
    }

}