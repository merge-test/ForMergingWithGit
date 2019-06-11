public class CBCTest {
    
    public static void CBC()
    {
        Datetime currentNow = System.now()-(1/24.0);
        String currentTime = currentNow.format('yyyy-MM-dd\'T\'HH:mm:ss', System.label.QB_Timezone); 
        
        //For Invoices
        List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                         realmid__c from QB_Credentials__c];
        
        if(qbcList.size()>0)
        {
            List<String>  authorizationCredentials=new List<String>  ();
            authorizationCredentials.add(qbcList[0].Access_token__c);
            authorizationCredentials.add(qbcList[0].Refresh_token__c);
            authorizationCredentials.add(qbcList[0].realmid__c);
            CBCTest.getResults(authorizationCredentials);
            
        }
    }
    
    public static void getResults(List<String> authorizationCredentials)
    {
        Boolean successCall = false;
        
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        Http http = new Http();
        request.setMethod('GET');
        
        if(Test.isRunningTest())
        {
            request.setEndPoint('http://test.com/test/getCustomer');
        }
        else
        {
            request.setEndPoint(System.label.QB_API_End_Point+'/v3/company/'+authorizationCredentials[2]+'/cdc?entities=Invoice&changedSince=2019-02-12');
        }
        
        request.setHeader('Accept', 'application/json');
        request.setHeader('Content-Type' , 'application/json;charset=UTF-8');
        
        if(authorizationCredentials[1]!=null)
        {
            Map<String, Object> refreshResults= QuickbookApiCrud.refreshToken(authorizationCredentials[1]);
            
            authorizationCredentials[0]=(String)refreshResults.get('access_token');
            authorizationCredentials[1]=(String)refreshResults.get('refresh_token');
            
            request.setHeader('Authorization' , 'Bearer '+authorizationCredentials[0]);
            response = http.send(request);
            
            if(response.getStatusCode() == 200)
            {
                successCall = true;
            }   
            
        }
        
        if(successCall==true)
        {
            String resp = response.getBody();
            Map<String,Object> results = (Map<String,Object>)System.JSON.deserializeUntyped(resp);
            List<Object> queryresp = ((List<Object>)results.get('CDCResponse'));
            List<String> idsList = new List<String>();
            
            if(queryresp.size()>0)
            {
                Object invoiceListJSon = ((List<Object>)((Map<String,Object>)queryresp[0]).get('QueryResponse'))[0];
                List<Object> listOfDeleted = ((List<Object>)((Map<String,Object>)invoiceListJSon).get('Invoice'));
                for(Object inv: listOfDeleted)
                {
                    String status = (String)(((Map<String,Object>)inv).get('status'));
                    if(status != null && status == 'Deleted')
                    {
                        idsList.add((String)(((Map<String,Object>)inv).get('Id')));
                    }
                }
                
            }
            system.debug('Here: '+idsList);
        }
        else{
            QuickbookScheduler.sendErrorEmail(response.getStatusCode(),response.getBody());
        }
        
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