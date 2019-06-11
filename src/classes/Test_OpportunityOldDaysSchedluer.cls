@isTest
public class Test_OpportunityOldDaysSchedluer {
    @isTest
    public static void oldDaysSchedluer()
    {
        ContentVersion cv=new Contentversion();
        cv.title='Invoice#1234';
        cv.PathOnClient ='test';
        Blob b=Blob.valueOf('Unit Test Attachment Body');
        cv.versiondata=EncodingUtil.base64Decode('Unit Test Attachment Body');
        cv.Due_Date__c=Date.valueOf(system.now()+2);
        cv.Amount__c = 1200;
        insert cv;
        Account a=new Account(Name='Test Account', Phone='0000000000', Website='http://www.test.com');
        insert a;
        
        Contact con=new Contact(FirstName='Test', LastName='Contact', Email='test@test.com', Phone='000000000', Salutation='Mr');
        insert con;
               
        Opportunity opp = new Opportunity(
			AccountId=a.Id,      
            Name = 'Test Opp', 
            StageName = 'Closed Won', 
            CloseDate = Date.valueOf(system.now()),
            Proposal_Issued__c = Date.valueOf(system.now()),
            X0_30_Days_Old__c = 0,
            X31_60_Days_Old__c = 0,
            X61_90_Days_Old__c = 0,
            X91_120_Days_Old__c = 0,
            X120_Days_Old__c = 0   ,
         //   Invoice_CC_1__c= con.id
            proposal_issued_to_1__c= con.id       
        );
        insert opp;
        
        ContentVersion cdi=[SELECT Id, ContentDocumentId from ContentVersion where id=:cv.id];  
        ContentDocumentLink cdl=new ContentDocumentLink(ContentDocumentId=cdi.ContentDocumentId, LinkedEntityId=opp.id, ShareType='I', Visibility = 'AllUsers');
        insert cdl;
        
        Test.StartTest();
        OpportunityOldDaysSchedluer sh1 = new OpportunityOldDaysSchedluer(); 
        String sch = '0 0 23 * * ?'; 
        system.schedule('Opportunity Days Field Scheduler', sch, sh1); 
        Test.stopTest();
    }
}