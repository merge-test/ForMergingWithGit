@isTest
public class Test_QuickbookConnection {
    
    @TestSetup static void createData()
    {
        QB_Credentials__c qb=new QB_Credentials__c(Access_token__c='123', Refresh_token__c='123', realmid__c='123');
        insert qb;
    }
    
    
    @isTest static void Test1()
    {
        Test.startTest();
        List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                         realmid__c from QB_Credentials__c];
        
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.setCurrentPage(new PageReference('apex/QuickbookAuthentication')); 
        ApexPages.currentPage().getParameters().put('code', '123');
        ApexPages.currentPage().getParameters().put('realmid', '456');        
        
        QuickbookConnection qc=new QuickbookConnection();
        qc.getQbCred();
        qc.doFetchAccessToken();
        qc.doAuthorizationQuickBooks();
        Test.stopTest();
    }
    
}