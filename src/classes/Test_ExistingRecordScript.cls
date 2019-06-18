@isTest
public class Test_ExistingRecordScript {
    
    @TestSetup static void createData()
    {
        Account a=new Account(Name='New York Engineers', Phone='0000000000', Website='http://www.test.com');
        insert a;
        
        Contact con=new Contact(FirstName='Test', LastName='Contact', Email='test@test.com', Phone='000000000', Salutation='Mr', AccountId=a.Id);
        insert con;
        
        Opportunity opp=new Opportunity(Name='Test Opportunity', StageName='Closed Won', Proposal_Issued__c=System.today(), Amount=1000, Qb_Id__c='1',
                                        CloseDate=System.today(), AccountId=a.Id, Proposal_Issued_to_1__c=con.Id, Project_Manager_c__c=con.Id);
        insert opp;
        
        List<Invoice__c> invoiceList = [Select Id from Invoice__c where Opportunity__c=:opp.Id];
        delete invoiceList;
    }
    
    @isTest
    public static void TriggerOnCustomEventAction()
    {
        List<Opportunity> oppList=[Select Id, Name from Opportunity];
        
        ExistingRecordScript batch=new ExistingRecordScript();
        Database.executeBatch(batch, 1000);
    }
    
}