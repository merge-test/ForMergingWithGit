@isTest
public class Test_TriggerOnInvoice {
    @TestSetup
    public static void createData(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Account a=new Account(Name='New York Engineers', Phone='0000000000', Website='http://www.test.com');
        insert a;
        
        Contact con=new Contact(FirstName='Test', LastName='Contact', Email='test@test.com', Phone='000000000', Salutation='Mr', AccountId=a.Id);
        insert con;
        
        Opportunity opp=new Opportunity(Name='Test Opportunity', StageName='Closed Won', Proposal_Issued__c=System.today(), Amount=1000,
                                        CloseDate=System.today(), AccountId=a.Id, Proposal_Issued_to_1__c=con.Id, Project_Manager_c__c=con.Id);
        insert opp;
        
        Invoice__c inv  = new Invoice__c();
        inv.Name = 'Test Stage';
        inv.Opportunity__c= opp.Id;
        inv.Fee__c=10;
        inv.Bill__c=10;
        inv.Time_Frame__c ='1';
        inv.Delays_Month__c=2;
        insert inv;
        inv.Delays_Month__c = 3;
        update inv;
        ContentVersion v = new ContentVersion();
        Blob b=Blob.valueof('Test');
        v.versionData =  b;
        v.title = 'Invoice#123';
        v.pathOnClient ='Invoice#123.pdf';
        v.Amount__c=1000;
        v.Balance__c=500;
        v.Due_Date__c=Date.valueOf('2016-08-08');
        v.QB_Id__c='1';
        
        insert v;
        
        ContentVersion cdi=[SELECT Id, ContentDocumentId from ContentVersion where id=:v.id];
        ContentDocumentLink cdl=new ContentDocumentLink(ContentDocumentId=cdi.ContentDocumentId, LinkedEntityId=opp.Id, ShareType='I', Visibility = 'AllUsers');
        insert cdl;
        
        List<Mapper__c> mappingList=new List<Mapper__c>();
        
        mappingList.add(new Mapper__c(Field_Name__c='name', Quickbooks_Field_Name__c='DisplayName', Object__c='Opportunity'));
        mappingList.add(new Mapper__c(Field_Name__c='name', Quickbooks_Field_Name__c='CompanyName', Object__c='Opportunity'));
        mappingList.add(new Mapper__c(Field_Name__c='name', Quickbooks_Field_Name__c='FullyQualifiedName', Object__c='Opportunity'));  
        mappingList.add(new Mapper__c(Field_Name__c='name', Quickbooks_Field_Name__c='FullyQualifiedName', Object__c='Account'));            
        mappingList.add(new Mapper__c(Field_Name__c='name', Quickbooks_Field_Name__c='CompanyName', Object__c='Account'));            
        mappingList.add(new Mapper__c(Field_Name__c='name', Quickbooks_Field_Name__c='DisplayName', Object__c='Account'));            
        mappingList.add(new Mapper__c(Field_Name__c='website', Quickbooks_Field_Name__c='WebAddr', Object__c='Account'));            
        mappingList.add(new Mapper__c(Field_Name__c='proposal_issued_to_1__c', Quickbooks_Field_Name__c='ContactDetails', Object__c='Opportunity'));         
        mappingList.add(new Mapper__c( Field_Name__c='shippingstreet', Quickbooks_Field_Name__c='ShipLine1', Object__c='Account'));   
        mappingList.add(new Mapper__c(Field_Name__c='shippingstate', Quickbooks_Field_Name__c='ShipCountrySubDivisionCode', Object__c='Account')); 
        mappingList.add(new Mapper__c(Field_Name__c='shippingpostalcode', Quickbooks_Field_Name__c='ShipPostalCode', Object__c='Account'));
        mappingList.add(new Mapper__c(Field_Name__c='shippingcity', Quickbooks_Field_Name__c='ShipCity', Object__c='Account')); 
        mappingList.add(new Mapper__c(Field_Name__c='shippingcountry', Quickbooks_Field_Name__c='ShipCountry', Object__c='Account')); 
        mappingList.add(new Mapper__c(Field_Name__c='billingstreet', Quickbooks_Field_Name__c='BillLine1', Object__c='Account'));   
        mappingList.add(new Mapper__c(Field_Name__c='billingstate', Quickbooks_Field_Name__c='BillCountrySubDivisionCode', Object__c='Account')); 
        mappingList.add(new Mapper__c(Field_Name__c='billingpostalcode', Quickbooks_Field_Name__c='BillPostalCode', Object__c='Account'));
        mappingList.add(new Mapper__c(Field_Name__c='billingcity', Quickbooks_Field_Name__c='BillCity', Object__c='Account')); 
        mappingList.add(new Mapper__c(Field_Name__c='billingcountry', Quickbooks_Field_Name__c='BillCountry', Object__c='Account')); 
        mappingList.add(new Mapper__c(Field_Name__c='Site_Street_Address__c', Quickbooks_Field_Name__c='BillLine1', Object__c='Opportunity'));            
        mappingList.add(new Mapper__c(Field_Name__c='site_zip_or_code__c', Quickbooks_Field_Name__c='BillPostalCode', Object__c='Opportunity'));
        mappingList.add(new Mapper__c(Field_Name__c='Site_State__c', Quickbooks_Field_Name__c='BillCountrySubDivisionCode', Object__c='Opportunity')); 
        mappingList.add(new Mapper__c(Field_Name__c='site_country__c', Quickbooks_Field_Name__c='BillCountry', Object__c='Opportunity')); 
        mappingList.add(new Mapper__c(Field_Name__c='Site_City__c', Quickbooks_Field_Name__c='BillCity', Object__c='Opportunity'));   
        mappingList.add(new Mapper__c(Field_Name__c='Site_Street_Address__c ', Quickbooks_Field_Name__c='ShipLine1', Object__c='Opportunity'));            
        mappingList.add(new Mapper__c(Field_Name__c='site_zip_or_code__c', Quickbooks_Field_Name__c='ShipPostalCode', Object__c='Opportunity'));
        mappingList.add(new Mapper__c(Field_Name__c='Site_State__c', Quickbooks_Field_Name__c='ShipCountrySubDivisionCode', Object__c='Opportunity')); 
        mappingList.add(new Mapper__c(Field_Name__c='site_country__c', Quickbooks_Field_Name__c='ShipCountry', Object__c='Opportunity')); 
        mappingList.add(new Mapper__c(Field_Name__c='Site_City__c', Quickbooks_Field_Name__c='ShipCity', Object__c='Opportunity')); 
        mappingList.add(new Mapper__c(Field_Name__c='phone', Quickbooks_Field_Name__c='AlternatePhone', Object__c='Account'));   
        mappingList.add(new Mapper__c(Field_Name__c='phone', Quickbooks_Field_Name__c='AlternatePhone', Object__c='Account'));
        insert mappingList;
    }
    
    @isTest
    public static void TestIssuedInvoiceReportController(){
        Test.startTest();
        List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                         realmid__c from QB_Credentials__c];
        
        Account a=[Select Id, Name, Phone, Website, Qb_Id__c from Account where name='New York Engineers'];
        Opportunity opp=[Select Id, Name, QB_Id__c from Opportunity where name='Test Opportunity'];
        
        List<ContentDocumentLink> issuedInvoicesLinks=[Select Id, ContentDocumentId,LinkedEntityId, LinkedEntity.name from ContentDocumentLink where 
                                                       LinkedEntityId =:opp.Id and ContentDocument.title like 'Invoice%'];
        
        List<ContentVersion> issuedInvoices=[Select Id, Title, Amount__c, ContentDocumentId, Days_Outstanding__c from ContentVersion where ContentDocumentId=:issuedInvoicesLinks[0].ContentDocumentId
                                             and title like 'Invoice%' order by createddate asc];
        
        IssuedInvoiceReportController iirc=new IssuedInvoiceReportController();
        Test.stopTest();
    }    
    @isTest
    public static void TestInvoiceController(){
        Test.startTest();
        List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                         realmid__c from QB_Credentials__c];
        
        Account a=[Select Id, Name, Phone, Website, Qb_Id__c from Account where name='New York Engineers'];
        Opportunity opp=[Select Id, Name, QB_Id__c from Opportunity where name='Test Opportunity'];
        
        Test.setCurrentPage(new pageReference('/apex/Invoice?id='+opp.id));
        List<ContentDocumentLink> issuedInvoicesLinks=[Select Id, ContentDocumentId,LinkedEntityId, LinkedEntity.name from ContentDocumentLink where 
                                                       LinkedEntityId =:opp.Id and ContentDocument.title like 'Invoice%'];
        
        List<ContentVersion> issuedInvoices=[Select Id, Title, Amount__c, ContentDocumentId, Days_Outstanding__c from ContentVersion where ContentDocumentId=:issuedInvoicesLinks[0].ContentDocumentId
                                             and title like 'Invoice%' order by createddate asc];
        
        InvoiceController ic=new InvoiceController(new ApexPages.StandardController(opp));
        ic.itemindex=1;
        
        ic.getInvoices();
        ic.getIssuedInvoices();
        ic.addMore();
        ic.RemoveItem();
        ic.save();
        ic.returnPage();
        ic.invoiceBillStatus();
        ic.getIsEnabled();
        ic.getShowDialogue();
        ic.closePopeUp();
        Test.stopTest();
    }    
}