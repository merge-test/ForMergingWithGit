@isTest
public class Test_ResetOppController {
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
        
    //    mappingList.add(new Mapper__c(Field_Name__c='Invoice_CC_1__c', Quickbooks_Field_Name__c='ContactDetails', Object__c='Opportunity'));            
        
        
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
                                        CloseDate=System.today(), AccountId=a.Id, Proposal_Issued_to_1__c=con.Id);
        
        //   Opportunity opp=new Opportunity(Name='Test Opportunity', StageName='Closed Won', Proposal_Issued__c=System.today(), Amount=1000,
        //                                CloseDate=System.today(), AccountId=a.Id, Invoice_CC_1__c=con.Id);
        insert opp;
      
    }
    
    @isTest
    public static void TestResetOppController(){
        Opportunity opp = [Select Id from Opportunity Limit 1];
        
        ApexPages.StandardController std = new ApexPages.StandardController(opp);
        ResetOppController ctrl = new ResetOppController(std);
        ctrl.resetOpp();
    }
}