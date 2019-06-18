@isTest
public class Test_InvoiceController {
    @TestSetup
    public static void createData(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());        
        Account a=new Account(Name='New York Engineers', Phone='0000000000', Website='http://www.test.com');
        insert a;
        Contact con=new Contact(FirstName='Test', LastName='Contact', Email='test@test.com', Phone='000000000', Salutation='Mr', AccountId=a.Id);
        insert con;
        List <Opportunity> lst_Opportunity= new    List <Opportunity> ();
        Opportunity opp=new Opportunity(Name='Test Opportunity', StageName='Closed Won', Proposal_Issued__c=System.today(), Amount=1000, 
                                        CloseDate=System.today(), AccountId=a.Id, Proposal_Issued_to_1__c=con.Id, Project_Manager_c__c=con.Id);
        lst_Opportunity.add(opp);
        Opportunity opp1=new Opportunity(Name='TestOPP', StageName='Qualification', Proposal_Issued__c=System.today(), Amount=1000, 
                                         CloseDate=System.today(), AccountId=a.Id, Proposal_Issued_to_1__c=con.Id, Project_Manager_c__c=con.Id);
        lst_Opportunity.add(opp1);
        insert lst_Opportunity;
        lst_Opportunity.get(0).Qb_Id__c='1';
        lst_Opportunity.get(1).Qb_Id__c='2';
        update lst_Opportunity;
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
        ContentVersion cdi1=[SELECT Id, ContentDocumentId from ContentVersion where id=:v1.id];
        ContentDocumentLink cdl1=new ContentDocumentLink(ContentDocumentId=cdi.ContentDocumentId, LinkedEntityId=opp1.Id, ShareType='I', Visibility = 'AllUsers');
        insert cdl1;
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
        mappingList.add(new Mapper__c(Field_Name__c='Site_Street_Address__c', Quickbooks_Field_Name__c='ShipLine1', Object__c='Opportunity'));            
        mappingList.add(new Mapper__c(Field_Name__c='site_zip_or_code__c', Quickbooks_Field_Name__c='ShipPostalCode', Object__c='Opportunity'));
        mappingList.add(new Mapper__c(Field_Name__c='Site_State__c', Quickbooks_Field_Name__c='ShipCountrySubDivisionCode', Object__c='Opportunity')); 
        mappingList.add(new Mapper__c(Field_Name__c='site_country__c', Quickbooks_Field_Name__c='ShipCountry', Object__c='Opportunity')); 
        mappingList.add(new Mapper__c(Field_Name__c='Site_City__c', Quickbooks_Field_Name__c='ShipCity', Object__c='Opportunity')); 
        mappingList.add(new Mapper__c(Field_Name__c='phone', Quickbooks_Field_Name__c='AlternatePhone', Object__c='Account'));   
        mappingList.add(new Mapper__c(Field_Name__c='phone', Quickbooks_Field_Name__c='AlternatePhone', Object__c='Account'));
        insert mappingList;
        List <Invoice__c> lst_Inv = [Select Id, Bill__c, Amount__c,Locked__c from Invoice__c where Opportunity__c=:opp.Id];
        for(Invoice__c invObj:lst_Inv){
            invObj.Locked__c = false;
        }
        update lst_Inv;
        lst_Inv = [Select Id, Bill__c, Amount__c,Locked__c from Invoice__c where Opportunity__c=:opp1.Id];
        for(Invoice__c invObj:lst_Inv){
            invObj.Locked__c = false;
        }
        update lst_Inv;
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
        ic.RemoveBilledItem();
        ic.RefreshWindow();
        ic.resetFlags();
        InvoiceController.getDateFromString('2019-03-29T08:31:46-07:00');
        Test.stopTest();
    }  
    
    @isTest
    public static void TestInvoiceStageNotClosedWon(){
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
        Invoice__c inv=[Select Id, Bill__c, Amount__c from Invoice__c where Opportunity__c=:opp.Id and name='Schematic Design' Limit 1];
        inv.Billed__c=50;
        update inv;           
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
        ic.RemoveBilledItem();
        ic.RefreshWindow();
        ic.resetFlags();
        ic.RemoveAllStages();
        InvoiceController.getDateFromString('2019-03-29T08:31:46-07:00');
        Test.stopTest();
    }  
    
    @isTest
    public static void TestInvoiceAutoBilling(){
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
        Invoice__c inv=[Select Id, Bill__c, Amount__c from Invoice__c where Opportunity__c=:opp.Id and name='Schematic Design' Limit 1];
        inv.Bill__c = 10;
        inv.Billed__c=50;
        update inv;   
        Invoice_Sync__c invSync = new Invoice_Sync__c();
        invSync.Invoice__c = inv.id;
        invSync.Amount__c = 10;
        insert invSync;
        Invoice_Sync__c invSync1 = new Invoice_Sync__c();
        invSync1.Invoice__c = inv.id;
        invSync1.Amount__c = 10;
        insert invSync1;
        InvoiceController ic=new InvoiceController(new ApexPages.StandardController(opp));
        ic.itemindex=1;
        ic.getInvoices();
        ic.getIssuedInvoices();
        ic.addMore();
        ic.selectedVal='1';
        ic.startMonth = '2019-09-09';
        ic.runSchedule();
        ic.RemoveAllStages();
        Test.stopTest();
    }  
    
    @isTest
    public static void TestInvoiceAutoBillingLockedInvoice(){
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
        List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                         realmid__c from QB_Credentials__c];
        Account a=[Select Id, Name, Phone, Website, Qb_Id__c from Account where name='New York Engineers'];
        Opportunity opp=[Select Id, Name, QB_Id__c from Opportunity where name='Test Opportunity'];
        Test.setCurrentPage(new pageReference('/apex/Invoice?id='+opp.id));
        List<ContentDocumentLink> issuedInvoicesLinks=[Select Id, ContentDocumentId,LinkedEntityId, LinkedEntity.name from ContentDocumentLink where 
                                                       LinkedEntityId =:opp.Id and ContentDocument.title like 'Invoice%'];
        List<ContentVersion> issuedInvoices=[Select Id, Title, Amount__c, ContentDocumentId, Days_Outstanding__c from ContentVersion where ContentDocumentId=:issuedInvoicesLinks[0].ContentDocumentId
                                             and title like 'Invoice%' order by createddate asc];
        Invoice__c inv=[Select Id, Bill__c, Amount__c from Invoice__c where Opportunity__c=:opp.Id and name='Schematic Design' Limit 1];
        inv.Bill__c = 10;
        inv.Billed__c=50;
        update inv;   
        List <Invoice_Sync__c> lstInvoiceSync = new List <Invoice_Sync__c>();
        Invoice_Sync__c invSync = new Invoice_Sync__c();
        invSync.Invoice__c = inv.id;
        invSync.Amount__c = 10;
        invSync.QB_Id__c  = '1';
        lstInvoiceSync.add(invSync);
        Invoice__c invObj = new Invoice__c();
        invObj.Opportunity__c= opp.id;
        invObj.Name = 'Service';
        invObj.Bill__c = 10;
        invObj.Billed__c=50;
        invObj.Delays_Month__c=0;
        invObj.Locked__c = true;
        insert invObj;
        Test.startTest();
        Invoice_Sync__c invSync1 = new Invoice_Sync__c();
        invSync1.Invoice__c = invObj.id;
        invSync1.Amount__c = 10;
        invSync1.QB_Id__c  = '1';
        lstInvoiceSync.add(invSync1);
        Invoice_Sync__c invSync2 = new Invoice_Sync__c();
        invSync2.Invoice__c = inv.id;
        invSync2.Amount__c = 10;
        invSync2.QB_Id__c  = '1';
        lstInvoiceSync.add(invSync2);       
        insert lstInvoiceSync;
        InvoiceController ic=new InvoiceController(new ApexPages.StandardController(opp));
        ic.itemindex=1;
        ic.getInvoices();
        ic.getIssuedInvoices();
        ic.addMore();
        ic.selectedVal='1';
        ic.startMonth = '2019-09-09';
        ic.runSchedule();
        ic.RemoveAllStages();
        Test.stopTest();
    }  
    
    @isTest
    public static void TestInvoice(){
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
        Invoice__c inv=[Select Id,Name, Bill__c, Amount__c from Invoice__c where Opportunity__c=:opp.Id and name='Schematic Design' Limit 1];
       
        inv.Billed__c=10;
        inv.Bill__c = 10;
        update inv;                  
           
        InvoiceController ic=new InvoiceController(new ApexPages.StandardController(opp));
        ic.itemindex=1; 
        ic.selectedVal = '1';
       ic.startMonth = '1';
        ic.save();        
        ic.runSchedule();        
        ic.getopenPresentationOptions();
        ic.calculateDate('2019/03/29');
        InvoiceController.getDateFromString('2019-03-29T08:31:46-07:00');
        Test.stopTest();
    }  
    
      @isTest
    public static void TestInvoiceDuplicateInvoice(){
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
        Invoice__c inv=[Select Id,Name, Bill__c, Amount__c from Invoice__c where Opportunity__c=:opp.Id and name='Schematic Design' Limit 1];
        inv.Name = 'null';
        inv.Billed__c=0;
        inv.Bill__c = 100;
        inv.Fee__c = 10;
        inv.Time_Frame__c = '10';                        
        Invoice__c inv1=[Select Id,Name, Bill__c, Amount__c from Invoice__c where Opportunity__c=:opp.Id and name='Punchlist' Limit 1];
        inv1.Name = 'null';
        inv1.Billed__c=0;
        inv1.Bill__c = 100;
        inv1.Fee__c = 10;
        inv1.Time_Frame__c = '10';                   
           
        InvoiceController ic=new InvoiceController(new ApexPages.StandardController(opp));
        ic.itemindex=1; 
        ic.selectedVal = '1';
        ic.startMonth = '1';
        ic.invoices.add(inv);
        ic.invoices.add(inv1);
        ic.save();        
        ic.runSchedule();        
        ic.getopenPresentationOptions();
        ic.calculateDate('2019/03/29');
        InvoiceController.getDateFromString('2019-03-29T08:31:46-07:00');
        Test.stopTest();
    }  
    
    @isTest
    public static void TestInvoiceControllerWithBillNonZero(){
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
        Invoice__c inv=[Select Id,Name, Bill__c, Amount__c from Invoice__c where Opportunity__c=:opp.Id and name='Schematic Design' Limit 1];
        inv.Name = 'null';
        inv.Billed__c=0;
        inv.Bill__c = 100;
        inv.Fee__c = 10;
        update inv;                  
        Invoice__c inv1=[Select Id,Name, Bill__c, Amount__c from Invoice__c where Opportunity__c=:opp.Id and name='Punchlist' Limit 1];
        inv1.Name = 'null3';
        inv1.Billed__c=0;
        inv1.Bill__c = -100;
        inv1.Fee__c = 10;
        update inv1;                  
        InvoiceController ic=new InvoiceController(new ApexPages.StandardController(opp));
        ic.itemindex=1;        
        ic.save();        
        ic.getopenPresentationOptions();
        ic.calculateDate('2019/03/29');
        InvoiceController.getDateFromString('2019-03-29T08:31:46-07:00');
        Test.stopTest();
    }  
    
    @isTest
    public static void TestSaveException(){
        Test.startTest();
        List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                         realmid__c from QB_Credentials__c];
        Account a=[Select Id, Name, Phone, Website, Qb_Id__c from Account where name='New York Engineers'];
        Opportunity opp=[Select Id, Name, QB_Id__c from Opportunity where name='TestOPP'];
        Test.setCurrentPage(new pageReference('/apex/Invoice?id='+opp.id));          
        InvoiceController ic=new InvoiceController(new ApexPages.StandardController(opp));
        ic.itemindex=1;        
        ic.selectedVal = '1';
        ic.save(); 
        ic.runSchedule();  
        Invoice__c inv1=[Select Id,Name, Bill__c, Amount__c from Invoice__c where Opportunity__c=:opp.Id and name='Punchlist' Limit 1];
        inv1.Name = 'null2';
        inv1.Billed__c=0;
        inv1.Bill__c = 100;
        inv1.Fee__c = 10;
        update inv1;  
        opp.StageName = 'Closed Won';
        update opp;
        ic.save(); 
        ic.runSchedule();           
        opp.QB_Id__c = null;      
        update opp;
        ic.save();   
        ic.runSchedule(); 
        ic.getopenPresentationOptions();
        ic.calculateDate('2019/03/29');
        InvoiceController.getDateFromString('2019-03-29T08:31:46-07:00');
        Test.stopTest();
    }
}