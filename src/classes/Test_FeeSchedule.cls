@isTest
public class Test_FeeSchedule {

   @TestSetup static void createData()
    {
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
        mappingList.add(new Mapper__c(Field_Name__c='Site_Street_Address__c	', Quickbooks_Field_Name__c='BillLine1', Object__c='Opportunity'));            
        mappingList.add(new Mapper__c(Field_Name__c='site_zip_or_code__c', Quickbooks_Field_Name__c='BillPostalCode', Object__c='Opportunity'));
        mappingList.add(new Mapper__c(Field_Name__c='Site_State__c', Quickbooks_Field_Name__c='BillCountrySubDivisionCode', Object__c='Opportunity')); 
        mappingList.add(new Mapper__c(Field_Name__c='site_country__c', Quickbooks_Field_Name__c='BillCountry', Object__c='Opportunity')); 
        mappingList.add(new Mapper__c(Field_Name__c='Site_City__c', Quickbooks_Field_Name__c='BillCity', Object__c='Opportunity'));   
        mappingList.add(new Mapper__c(Field_Name__c='Site_Street_Address__c	', Quickbooks_Field_Name__c='ShipLine1', Object__c='Opportunity'));            
        mappingList.add(new Mapper__c(Field_Name__c='site_zip_or_code__c', Quickbooks_Field_Name__c='ShipPostalCode', Object__c='Opportunity'));
        mappingList.add(new Mapper__c(Field_Name__c='Site_State__c', Quickbooks_Field_Name__c='ShipCountrySubDivisionCode', Object__c='Opportunity')); 
        mappingList.add(new Mapper__c(Field_Name__c='site_country__c', Quickbooks_Field_Name__c='ShipCountry', Object__c='Opportunity')); 
        mappingList.add(new Mapper__c(Field_Name__c='Site_City__c', Quickbooks_Field_Name__c='ShipCity', Object__c='Opportunity')); 
        mappingList.add(new Mapper__c(Field_Name__c='phone', Quickbooks_Field_Name__c='AlternatePhone', Object__c='Account'));   
        mappingList.add(new Mapper__c(Field_Name__c='phone', Quickbooks_Field_Name__c='AlternatePhone', Object__c='Account'));
        insert mappingList;
        
        QB_Credentials__c qb=new QB_Credentials__c(Access_token__c='123', Refresh_token__c='123', realmid__c='123');
        insert qb;
        
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());       
        Account a=new Account(Name='Test Account', Phone='0000000000', Website='http://www.test.com');
        insert a;
        
        Contact con=new Contact(FirstName='Test', LastName='Contact', Email='test@test.com', Phone='000000000', Salutation='Mr');
        insert con;
        
        Opportunity opp=new Opportunity(Name='Test Opportunity', StageName='Closed Won', Proposal_Issued__c=System.today(), Amount=1000,
                                        CloseDate=System.today(), AccountId=a.Id,Proposal_Issued_to_1__c=con.Id);
        Test.startTest(); 
        insert opp;
        
          //Insert new Invoice Attachment
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
        
        ContentVersion v1 = new ContentVersion();        
        Blob b1=Blob.valueof('Test');        
        v1.versionData =  b1;
        v1.title = 'Invoice#123';
        v1.pathOnClient ='Invoice#123.pdf';
        v1.Amount__c=1000;
        v1.Balance__c=500;
        v1.Due_Date__c=Date.valueOf('2016-08-08');
        v1.QB_Id__c='1';       
        insert v1;
        
        Test.stopTest();    
    }
    
    
      @isTest static void TestFeeScheduler()
    {
        Test.startTest();
          Datetime dt = System.now();
        Date dateObj = dt.date();
        Opportunity opp=[Select Id, Name, QB_Id__c from Opportunity where name='Test Opportunity'];  
        Invoice__c inv=[Select Id, Bill__c, Amount__c,Opportunity__c from Invoice__c where Opportunity__c=:opp.Id and name='Schematic Design' Limit 1];
        FeeStorage__c feeObj = new FeeStorage__c();
        feeObj.Bill__c = 10;
        feeObj.Duration__c=1;
        feeObj.Invoice__c= inv.id;
       // feeObj.lastUpdated__c = null;
        feeObj.NumberOfTimes__c=0;
        feeObj.Opportunity__c = inv.Opportunity__c;
        feeObj.startDate__c = dateObj;
        insert feeObj;
        FeeScheduler.scheduleClassMethod();
        Test.stopTest();      
    }
}