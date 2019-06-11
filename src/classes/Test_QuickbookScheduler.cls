@istest
public class Test_QuickbookScheduler {
@istest
    static void method1()
    {
        
     /*  List<Mapper__c> mappingList=new List<Mapper__c>();
        
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
        //Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());   
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
        
        Opportunity opp1 = new Opportunity(
			AccountId=a.Id,      
            Name = 'Test Opportunity', 
            StageName = 'Closed Won', 
            CloseDate = Date.valueOf(system.now()),
            Proposal_Issued__c = Date.valueOf(system.now()),
            X0_30_Days_Old__c = 0,
            X31_60_Days_Old__c = 0,
            X61_90_Days_Old__c = 0,
            X91_120_Days_Old__c = 0,
            X120_Days_Old__c = 0   ,
            //Invoice_CC_1__c= con.id
            proposal_issued_to_1__c= con.id
        );
        insert opp1;
        */  
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
     //   Opportunity opp=[Select Id, Name, QB_Id__c from Opportunity where name='Test Opportunity'];
        
        
        QuickbookScheduler qbs = new QuickbookScheduler();
        qbs.testPass();
        String sch = '0 0 23 * * ?'; 
//        system.schedule('QB Scheduler', sch, qbs); 
        test.stopTest();
        
    }
}