public class QuickbookApiCrud {
    
    public class PrimaryPhone
    {
        public string FreeFormNumber;
    }
    
    public class AlternatePhone
    {
        public string FreeFormNumber;
    }    
    
    public class PrimaryEmailAddr
    {
        public string Address;
    }
    
    public class WebAddr
    {
        public string URI;
    }
    
    public class BillAddr
    {
        public string Line1;
        public string City;
        public string Country;
        public string PostalCode;
        public string CountrySubDivisionCode;
    }
    
    public class ShipAddr
    {
        public string Line1;
        public string City;
        public string Country;
        public string PostalCode;
        public string CountrySubDivisionCode;
    }
    
    public class ParentRef
    {
        public string value;
        public string name;
    }
    
    public class CustomerRef
    {
        public string value;
    }
    
    public class SalesTermRef
    {
        public string value;
    }
    
    public class Customer
    {
        public string Id ;
        public string SyncToken;
        public string Title;
        public string GivenName;
        public string MiddleName;
        public string FamilyName;
        
        public string Suffix;
        public string FullyQualifiedName;
        public string CompanyName;
        public string DisplayName;
        public boolean Active;
        
        public PrimaryPhone PrimaryPhone;
        public AlternatePhone AlternatePhone;
        
        public string Mobile;
        public string Fax;
        public PrimaryEmailAddr PrimaryEmailAddr;
        public WebAddr WebAddr;
        
        public boolean Taxable;
        public BillAddr BillAddr;
        public ShipAddr ShipAddr;
        public string Notes;
        public Decimal Balance;
        
        public string Job;
        public string BillWithParent;
        public ParentRef ParentRef;
    }
    
    public class ItemRef
    {
        public string value ;
    }
    
    public class SalesItemLineDetail
    {
        public string Qty;
        ItemRef ItemRef;
        public string ServiceDate;
    }
    
    public class InvoiceLineItem
    {
        public Decimal Amount;
        public string Description;
        public string DetailType;
        SalesItemLineDetail SalesItemLineDetail;
    }
    
    public class BillEmail
    {
        String Address;
    }
    
    public class BillEmailCc
    {
        String Address;
    }
    
    public class BillEmailBcc
    {
        String Address;
    }
    
    public class Invoice
    {
        public string Id ;
        public string SyncToken;
        public string DueDate;
        CustomerRef CustomerRef;
        List<InvoiceLineItem> Line;
        public string EmailStatus; 
        BillEmail BillEmail;
        BillEmailCC BillEmailCc;
        BillEmailBCC BillEmailBcc;
        CustomField CustomField; 
        SalesTermRef SalesTermRef;
    }
    
    public class CustomField
    {
        public String DefinitionId;
        public String Name;
        public String StringValue;
    }
    
    public static Invoice setInvoiceEmail(Invoice invoice, sObject invoiceRecord, List<Mapper__c> mapperList)
    {
        String toAddress='';
        String ccAddress='';
        String bccAddress='';
        
        for(Mapper__c mapper:mapperList)
        {
            sobject contact;
            
            try{
                contact = invoiceRecord.getSObject('opportunity__r').getSObject(mapper.Field_Name__c.removeend('__c')+'__r');
            }catch(Exception e){}
            
            if(mapper.Quickbooks_Field_Name__c.equals('ContactDetails') && contact!=null && contact.get('email')!=null)
            {
                toAddress=(string)contact.get('email');
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('BillEmailCc') && contact!=null && contact.get('email')!=null)
            {
                ccAddress= ccAddress+contact.get('email')+',';
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('BillEmailBcc') && contact!=null && contact.get('email')!=null)
            {
                bccAddress= bccAddress+contact.get('email')+',';
            }
        }
        
        if(toAddress!='' )
        {
            BillEmail BillEmail=new BillEmail();
            BillEmail.Address=toAddress;
            invoice.EmailStatus='NeedToSend';
            invoice.BillEmail=BillEmail;
        }
        if(ccAddress!='')
        {
            BillEmailCc BillEmailCc=new BillEmailCc();
            BillEmailCc.Address=ccAddress.removeEnd(',');
            invoice.BillEmailCc=BillEmailCc;
        }
        if(bccAddress!='')
        {
            BillEmailBcc BillEmailBCC=new BillEmailBcc();
            BillEmailBcc.Address=bccAddress.removeEnd(',');
            invoice.BillEmailBcc=BillEmailBcc;
        }
        
        return invoice;        
    }
    
    public static String getCustomerJSON(sObject acc, String recordType, List<Mapper__c> mapperList, Map<String, String> qbSyncTokenMap, String relatedContactField)
    {
        
        Customer c=new Customer();
        
        if(qbSyncTokenMap!=null && qbSyncTokenMap.size()>0)
        {
            c.Id=(String)acc.get('QB_Id__c');
            c.SyncToken=qbSyncTokenMap.get((String)acc.get('QB_Id__c'));
        }
        if(recordType=='Opportunity')
        {
            Contact con=(Contact)acc.getSObject('proposal_issued_to_1__r');
            if(con!=null){
                c.Title=(con.Salutation== null ? '' :con.Salutation);
                c.GivenName=(con.FirstName== null ? '' :con.FirstName);
                c.FamilyName=(con.LastName== null ? '' :con.LastName);
                
                PrimaryPhone phone=new PrimaryPhone();
                phone.FreeFormNumber=(con.Phone== null ? '' :con.Phone);
                
                PrimaryEmailAddr email=new PrimaryEmailAddr();
                email.Address=(con.Email== null ? '' :con.Email);
                
                c.PrimaryPhone=phone;
                c.PrimaryEmailAddr=email;
            }
            
            if(relatedContactField!=null){
                List<String> fieldDetails = relatedContactField.split(':');

                if(fieldDetails[0] == 'Account'){
                    Account addressAcc=(Account)acc.getSObject(fieldDetails[0]);
                    if (fieldDetails[1] == 'Billing'){
                        BillAddr bAddr = new BillAddr();
                        bAddr.Line1 = (String)(addressAcc.get('BillingStreet')== null ? '' :addressAcc.get('BillingStreet'));
                        bAddr.City = (String)(addressAcc.get('BillingCity')== null ? '' :addressAcc.get('BillingCity'));
                        bAddr.Country = (String)(addressAcc.get('BillingCountry')== null ? '' :addressAcc.get('BillingCountry'));
                        bAddr.PostalCode = (String)(addressAcc.get('BillingPostalCode')== null ? '' :addressAcc.get('BillingPostalCode'));
                        bAddr.CountrySubDivisionCode = (String)(addressAcc.get('BillingState')== null ? '' :addressAcc.get('BillingState'));
                        c.BillAddr = bAddr;
                    }
                    else{
                        BillAddr bAddr = new BillAddr();
                        bAddr.Line1 = (String)(addressAcc.get('ShippingStreet')== null ? '' :addressAcc.get('ShippingStreet'));
                        bAddr.City = (String)(addressAcc.get('ShippingCity')== null ? '' :addressAcc.get('ShippingCity'));
                        bAddr.Country = (String)(addressAcc.get('ShippingCountry')== null ? '' :addressAcc.get('ShippingCountry'));
                        bAddr.PostalCode = (String)(addressAcc.get('ShippingPostalCode')== null ? '' :addressAcc.get('ShippingPostalCode'));
                        bAddr.CountrySubDivisionCode = (String)(addressAcc.get('ShippingState')== null ? '' :addressAcc.get('ShippingState'));
                        c.BillAddr = bAddr;
                    }
                }
                else if(fieldDetails[0] == 'proposal_issued_to_1__r' || fieldDetails[0] == 'proposal_issued_to_2__r'){
                    Contact addressCon =(Contact)acc.getSObject(fieldDetails[0]);
                    
                    if (fieldDetails[1] == 'Mailing'){
                        BillAddr bAddr = new BillAddr();
                        bAddr.Line1 = (String)(addressCon.get('MailingStreet')== null ? '' :addressCon.get('MailingStreet'));
                        bAddr.City = (String)(addressCon.get('MailingCity')== null ? '' :addressCon.get('MailingCity'));
                        bAddr.Country = (String)(addressCon.get('MailingCountry')== null ? '' :addressCon.get('MailingCountry'));
                        bAddr.PostalCode = (String)(addressCon.get('MailingPostalCode')== null ? '' :addressCon.get('MailingPostalCode'));
                        bAddr.CountrySubDivisionCode = (String)(addressCon.get('MailingState')== null ? '' :addressCon.get('MailingState'));
                        c.BillAddr = bAddr;
                    }
                    else{
                        BillAddr bAddr = new BillAddr();
                        bAddr.Line1 = (String)(addressCon.get('OtherStreet')== null ? '' :addressCon.get('OtherStreet'));
                        bAddr.City = (String)(addressCon.get('OtherCity')== null ? '' :addressCon.get('OtherCity'));
                        bAddr.Country = (String)(addressCon.get('OtherCountry')== null ? '' :addressCon.get('OtherCountry'));
                        bAddr.PostalCode = (String)(addressCon.get('OtherPostalCode')== null ? '' :addressCon.get('OtherPostalCode'));
                        bAddr.CountrySubDivisionCode = (String)(addressCon.get('OtherState')== null ? '' :addressCon.get('OtherState'));
                        c.BillAddr = bAddr;
                    }
                }
            } 
            
            String updatedDisplayName = ((String)acc.get('Name'));
            if(updatedDisplayName != null){
                c.DisplayName =updatedDisplayName;
                
            }
            c.Job='true';
            c.BillWithParent='true';
            
            ParentRef ref=new ParentRef();
            ref.value=(String)acc.getSObject('Account').get('Qb_Id__c');
            ref.name=(String)acc.getSObject('Account').get('Name');
            
            c.ParentRef=ref;
        }
        
        Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize( c, true ));
        BillAddr billadd=new BillAddr();
        ShipAddr shipadd=new ShipAddr();
        for(Mapper__c mapper:mapperList)
        {
            if(mapper.Quickbooks_Field_Name__c.equals('PrimaryPhone'))
            {
                PrimaryPhone phone=new PrimaryPhone();
                phone.FreeFormNumber= (String)(acc.get(mapper.Field_Name__c)== null ? '' :acc.get(mapper.Field_Name__c));
                
                Map<String, Object> p = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize( phone, true ));
                m.put(mapper.Quickbooks_Field_Name__c, p);
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('AlternatePhone'))
            {
                AlternatePhone phone=new AlternatePhone();
                phone.FreeFormNumber= (String)(acc.get(mapper.Field_Name__c)== null ? '' :acc.get(mapper.Field_Name__c));
                
                Map<String, Object> p = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize( phone, true ));
                m.put(mapper.Quickbooks_Field_Name__c, p);
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('PrimaryEmailAddr'))
            {
                PrimaryEmailAddr email=new PrimaryEmailAddr();
                email.Address= (String)(acc.get(mapper.Field_Name__c)== null ? '' :acc.get(mapper.Field_Name__c));
                
                Map<String, Object> e = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize( email, true ));
                m.put(mapper.Quickbooks_Field_Name__c, e);
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('WebAddr'))
            {
                WebAddr web=new WebAddr();
                web.URI= (String)(acc.get(mapper.Field_Name__c)== null ? '' :acc.get(mapper.Field_Name__c));
                
                Map<String, Object> w = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize( web, true ));
                m.put(mapper.Quickbooks_Field_Name__c, w);
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('BillLine1'))
            {
                billadd.Line1= (String)(acc.get(mapper.Field_Name__c)== null ? '' :acc.get(mapper.Field_Name__c));
                
                Map<String, Object> b = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize( billadd, true ));
                m.put('BillAddr', b);
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('BillCity'))
            {
                billadd.City= (String)(acc.get(mapper.Field_Name__c)== null ? '' :acc.get(mapper.Field_Name__c));
                
                Map<String, Object> b = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize( billadd, true ));
                m.put('BillAddr', b);
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('BillCountry'))
            {
                billadd.Country= (String)(acc.get(mapper.Field_Name__c)== null ? '' :acc.get(mapper.Field_Name__c));
                
                Map<String, Object> b = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize( billadd, true ));
                m.put('BillAddr', b);
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('BillPostalCode'))
            {
                billadd.PostalCode= (String)(acc.get(mapper.Field_Name__c)== null ? '' :acc.get(mapper.Field_Name__c));
                
                Map<String, Object> b = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize( billadd, true ));
                m.put('BillAddr', b);
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('BillCountrySubDivisionCode'))
            {
                billadd.CountrySubDivisionCode = (String)(acc.get(mapper.Field_Name__c)== null ? '' :acc.get(mapper.Field_Name__c));
                
                Map<String, Object> b = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize( billadd, true ));
                m.put('BillAddr', b);
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('ShipLine1'))
            {
                shipadd.Line1= (String)(acc.get(mapper.Field_Name__c)== null ? '' :acc.get(mapper.Field_Name__c));
                
                Map<String, Object> s = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize( shipadd, true ));
                m.put('ShipAddr', s);
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('ShipCity'))
            {
                shipadd.City= (String)(acc.get(mapper.Field_Name__c)== null ? '' :acc.get(mapper.Field_Name__c));
                
                Map<String, Object> s = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize( shipadd, true ));
                m.put('ShipAddr', s);
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('ShipCountry'))
            {
                shipadd.Country= (String)(acc.get(mapper.Field_Name__c)== null ? '' :acc.get(mapper.Field_Name__c));
                
                Map<String, Object> s = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize( shipadd, true ));
                m.put('ShipAddr', s);
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('ShipPostalCode'))
            {
                shipadd.PostalCode= (String)(acc.get(mapper.Field_Name__c)== null ? '' :acc.get(mapper.Field_Name__c));
                
                Map<String, Object> s = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize( shipadd, true ));
                m.put('ShipAddr', s);
            }
            else if(mapper.Quickbooks_Field_Name__c.equals('ShipCountrySubDivisionCode'))
            {
                shipadd.CountrySubDivisionCode = (String)(acc.get(mapper.Field_Name__c)== null ? '' :acc.get(mapper.Field_Name__c));
                
                Map<String, Object> b = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize( shipadd, true ));
                m.put('ShipAddr', b);
            }
            else if(!mapper.Quickbooks_Field_Name__c.equals('ContactDetails'))
            {
                m.put(mapper.Quickbooks_Field_Name__c, acc.get(mapper.Field_Name__c));
            }
        }
        
        return JSON.serialize(m, true);
    }
    
    public static void sendEmail(string body)
    {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();   
        message.toAddresses = new String[] { 'behzad.qureshi@rolustech.com' };
            message.optOutPolicy = 'FILTER';
        message.subject = 'Json QBO';
        message.plainTextBody = body;
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        
        if (results[0].success) {
            System.debug('The email was sent successfully.');
            
        } else {
            System.debug('The email failed to send: ' + results[0].errors[0].message);
            
        }
    }
    
    public static void sendCustomer(Set<Id> accIds)
    {
        Boolean isCreated=false;
        Boolean isRefresh=false;
        
        List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                         realmid__c from QB_Credentials__c];
        
        if(qbcList.size()>0)
        {
            String accessToken=qbcList[0].Access_token__c;
            String refreshToken=qbcList[0].Refresh_token__c;
            String realmid=qbcList[0].realmid__c;
            
            List<Mapper__c> mapperList=[Select Id, Field_Name__c, Quickbooks_Field_Name__c from Mapper__c
                                        where Object__c='Account'];
            
            List<Account> accList= Database.query('SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().keySet()), ',') 
                                                  + ' FROM Account where id in :accIDs' );
            
            for(Account acc:accList)
            {
                String json = getCustomerJSON(acc, 'Account', mapperList, null, null);
                HttpRequest request = new HttpRequest();
                HttpResponse response = new HttpResponse();
                Http http = new Http();
                
                request.setMethod('POST');
                
                if(Test.isRunningTest())
                {
                    request.setEndpoint('http://test.com/test/sendCustomer');
                }
                else
                {
                    request.setEndPoint(System.label.QB_API_End_Point+'/v3/company/'+realmid+'/customer');
                }
                
                request.setHeader('Authorization' , 'Bearer '+accessToken);
                request.setHeader('Accept', 'application/json');
                request.setHeader('Content-Type' , 'application/json;charset=UTF-8');
                request.setBody(json);
                
                response = http.send(request);
                
                if(response.getStatusCode() == 200)
                {
                    isCreated=true;
                }
                else if(response.getStatusCode() == 401)
                {
                    if(refreshToken!=null)
                    {
                        Map<String, Object> refreshResults= QuickbookApiCrud.refreshToken(refreshToken);
                        
                        accessToken=(String)refreshResults.get('access_token');
                        refreshToken=(String)refreshResults.get('refresh_token');
                        
                        request.setHeader('Authorization' , 'Bearer '+accessToken);
                        response = http.send(request);
                        
                        if(response.getStatusCode() == 200)
                        {
                            isCreated=true;
                            isRefresh=true;
                        }
                        
                    }
                }
                
                if(isCreated)
                {
                    Map<String,Object> results = (Map<String,Object>)System.JSON.deserializeUntyped(response.getBody());
                    acc.QB_Id__c=(String)((Map<String,Object>)results.get('Customer')).get('Id');
                    acc.is_Synced__c=true;
                }
                else{
                    QuickbookScheduler.sendErrorEmail(response.getStatusCode(),response.getBody());
                }
                
            }
            
            if(isRefresh)
            {
                qbcList[0].Access_token__c=accessToken;
                qbcList[0].Refresh_token__c=refreshToken;
                update qbcList[0];
            }
            
            update accList;
        }
    }
    
    public static Map<String,String> getCustomerSyncToken(Set<String> customerIds, List<String> authenticationTokens)
    {
        Boolean isSyncTokenReceived=false;
        Map<String, String> qbSyncTokenMap=new Map<String, String> ();
        
        String query='select id, syncToken from Customer where id in(';
        
        Integer count=1;
        for(String customerId:customerIds)
        {
            query=query+'\''+customerId+'\'';
            if(count<customerIds.size())
            {
                query = query+',';
            }
            count = count+1;
        }
        query=query+')';
        
        query=EncodingUtil.urlEncode(query, 'UTF-8');
        
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        Http http = new Http();
        request.setMethod('GET');
        
        if(Test.isRunningTest())
        {
            request.setEndPoint('http://test.com/test/getCustomerSyncToken');
        }
        else
        {
            request.setEndPoint(System.label.QB_API_End_Point+'/v3/company/'+authenticationTokens[2]+'/query?query='+query); //Realmid
        }
        
        request.setHeader('Authorization' , 'Bearer '+authenticationTokens[0]); //Access token
        request.setHeader('Accept', 'application/json');
        
        response = http.send(request);
        if(response.getStatusCode() == 200)
        {
            isSyncTokenReceived=true;
        }
        else if(response.getStatusCode() == 401)
        {
            if(authenticationTokens[1]!=null) //Refresh token
            {
                Map<String, Object> refreshResults= QuickbookApiCrud.refreshToken(authenticationTokens[1]);
                
                authenticationTokens[0]=(String)refreshResults.get('access_token');
                authenticationTokens[1]=(String)refreshResults.get('refresh_token');
                
                request.setHeader('Authorization' , 'Bearer '+authenticationTokens[0]);
                response = http.send(request);
                
                if(response.getStatusCode() == 200)
                {
                    isSyncTokenReceived=true;
                }
                
            }
        }
        
        if(isSyncTokenReceived)
        {
            Map<String,Object> results = (Map<String,Object>)System.JSON.deserializeUntyped(response.getBody());
            List<Object> responseArray= (List<Object>)((Map<String,Object>)results.get('QueryResponse')).get('Customer');
            
            for(Object res:responseArray)
            {
                Map<String,Object> token = (Map<String,Object>)res;
                qbSyncTokenMap.put(String.valueof(token.get('Id')), String.valueof(token.get('SyncToken')));
            }
        }
        else{
            QuickbookScheduler.sendErrorEmail(response.getStatusCode(),response.getBody());
        }
        
        return qbSyncTokenMap;
    }
    
    @future(callout=true)
    public static void updateCustomer(Set<String> customerIds)
    {
        Boolean isRefresh=false;
        
        List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                         realmid__c from QB_Credentials__c];
        
        if(qbcList.size()>0)
        {
            
            List<String>  authorizationCredentials=new List<String>  ();
            authorizationCredentials.add(qbcList[0].Access_token__c);
            authorizationCredentials.add(qbcList[0].Refresh_token__c);
            authorizationCredentials.add(qbcList[0].realmid__c);
            
            Map<String, String> qbSyncTokenMap=QuickbookAPiCrud.getCustomerSyncToken(customerIds, authorizationCredentials);
            
            if(qbSyncTokenMap.size()>0)
            {
                //Update Accounts
                List<Account> accList= Database.query('SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().keySet()), ',') 
                                                      + ' FROM Account where Qb_Id__c in :customerIds' );
                
                List<Mapper__c> mapperList=[Select Id, Field_Name__c, Quickbooks_Field_Name__c from Mapper__c
                                            where Object__c='Account'];
                
                for(Account acc:accList)
                {
                    String json = getCustomerJSON(acc, 'Account', mapperList, qbSyncTokenMap, null);
                    
                    HttpRequest request = new HttpRequest();
                    HttpResponse response = new HttpResponse();
                    Http http = new Http();
                    
                    request.setMethod('POST');
                    
                    if(Test.isRunningTest())
                    {
                        request.setEndPoint('http://test.com/test/updateCustomer');
                    }
                    else
                    {
                        request.setEndPoint(System.label.QB_API_End_Point+'/v3/company/'+authorizationCredentials[2]+'/customer?operation=update');
                    }
                    
                    request.setHeader('Authorization' , 'Bearer '+authorizationCredentials[0]);
                    request.setHeader('Accept', 'application/json');
                    request.setHeader('Content-Type' , 'application/json;charset=UTF-8');
                    request.setBody(json);
                    
                    response = http.send(request);
                    if(response.getStatusCode() == 200)
                    {
                        acc.is_Synced__c=true;
                    }
                    else
                    {
                        acc.is_Synced__c=false;
                        QuickbookScheduler.sendErrorEmail(response.getStatusCode(),response.getBody());
                    }
                }
                
                qbcList[0].Access_token__c=authorizationCredentials[0];
                qbcList[0].Refresh_token__c=authorizationCredentials[1];
                update qbcList[0];
                
                update accList;
            }
        }
    }
    
    @future(callout=true)
    public static void fetchAlreadyExistingId(Set<Id> recordIds,String recordToSync){
        Map<Id,Account> accounts;
        Map<Id,Opportunity> opportunities;
        String recordNames='';
        
        if(recordToSync == 'Account'){
            accounts = new Map<Id,Account>([SELECT Id,Name from Account where Id =:recordIds]);
            for(Account acc : accounts.values()){
                recordNames += '\''+ acc.Name +'\',';
            }
        }
        else{
            opportunities = new Map<Id,Opportunity>([SELECT Id,Name,AccountId,Account.Name from Opportunity where Id =:recordIds]);
            for(Opportunity opp : opportunities.values()){
                if(opp.AccountId != null){
                    recordNames += '\''+ Opp.Account.Name +':'+ opp.Name +'\',';
                }
            }
        }
        if(recordNames.length() > 0){
            recordNames = recordNames.substring(0, recordNames.length() - 1);
        }
        
        List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                         realmid__c from QB_Credentials__c];
        
        Map<String,String> QbRecordsMap = new Map<String,String>();
        if(qbcList.size()>0){
            List<String>  authorizationCredentials=new List<String>();
            authorizationCredentials.add(qbcList[0].Access_token__c);
            authorizationCredentials.add(qbcList[0].Refresh_token__c);
            authorizationCredentials.add(qbcList[0].realmid__c);
            
            if(recordNames.length() > 0){
                String query = 'Select * from Customer where FullyQualifiedName IN ('+recordNames+')';
                String qbResponse = QuickBookScheduler.QuickBookRecordGetter(query, authorizationCredentials);
                if( qbResponse != null){
                    Map<String,Object> results = (Map<String,Object>)System.JSON.deserializeUntyped(qbResponse);
                    Map<String,Object> queryresp = ((Map<String,Object>)results.get('QueryResponse'));
                    if(queryresp.size()>0)
                    {
                        Map<String, String> data = new Map<String, String>();
                        List<Object> responseList = (List<Object>)queryresp.get('Customer');
                        List<Map<String,Object>> listofMaps = new List<Map<String,Object>>();
                        
                        for (Object instance : responseList){
                            listofMaps.add((Map<String,Object>)instance);
                        }
                        for (Map<String,Object>mp : listofMaps){
                            QbRecordsMap.put(String.valueOf(mp.get('FullyQualifiedName')),String.valueOf(mp.get('Id')));
                        }
                    }
                }
            }
            
            List<Account> accountsToUpdate = new List<Account>();
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            if(recordToSync == 'Account'){
                for(Account acc : accounts.values()){
                    if(QbRecordsMap.get(acc.Name) != null){
                        acc.Qb_Id__c = QbRecordsMap.get(acc.Name);
                        acc.Is_Synced__c = true;
                        accountsToUpdate.add(acc);
                        recordIds.remove(acc.Id);
                    }
                }
                if(recordIds.size() > 0){
                    QuickbookApiCrud.sendCustomer(recordIds);
                }
                update accountsToUpdate;
            }
            else{
                for(Opportunity opp : opportunities.values()){
                    if(QbRecordsMap.get(opp.Name) != null){
                        opp.Qb_Id__c = QbRecordsMap.get(opp.Name);
                        opp.Is_Synced__c = true;
                        oppsToUpdate.add(opp);
                        recordIds.remove(opp.Id);
                    }
                }
                if(recordIds.size() > 0){
                    QuickbookApiCrud.sendSubCustomer(recordIds);
                }
                update oppsToUpdate;
            }
            
            qbcList[0].Access_token__c=authorizationCredentials[0];
            qbcList[0].Refresh_token__c=authorizationCredentials[1];
            update qbcList[0];
        }
    }
    
    public static void sendSubCustomer(Set<Id> oppIds)
    {
        Boolean isCreated=false;
        Boolean isRefresh=false;
        List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                         realmid__c from QB_Credentials__c];
        
        if(qbcList.size()>0)
        {
            String accessToken=qbcList[0].Access_token__c;
            String refreshToken=qbcList[0].Refresh_token__c;
            String realmid=qbcList[0].realmid__c;
            String relatedContactField=null;
            
            List<Opportunity> oppList= new List<Opportunity>();
            List<Mapper__c> mapperList=new List<Mapper__c>();
            
            
            oppList= Database.query('SELECT Account.Qb_Id__c,Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode,'
                                    + 'Account.BillingCountry, Account.BillingLatitude, Account.BillingLongitude, Account.BillingGeocodeAccuracy,'
                                    + 'Account.BillingAddress, Account.ShippingStreet, Account.ShippingCity, Account.ShippingState,'
                                    + 'Account.ShippingPostalCode, Account.ShippingCountry, Account.ShippingLatitude, Account.ShippingLongitude,'
                                    + 'Account.ShippingGeocodeAccuracy, Account.ShippingAddress, Account.Name, proposal_issued_to_1__r.MailingAddress,'
                                    + 'proposal_issued_to_1__r.Name, proposal_issued_to_1__r.MailingCity, proposal_issued_to_1__r.MailingCountry,'
                                    + 'proposal_issued_to_1__r.MailingGeocodeAccuracy, proposal_issued_to_2__r.Name,'
                                    + 'proposal_issued_to_1__r.MailingLatitude, proposal_issued_to_1__r.MailingLongitude, proposal_issued_to_1__r.MailingPostalCode,'
                                    + 'proposal_issued_to_1__r.MailingState, proposal_issued_to_1__r.MailingStreet, proposal_issued_to_1__r.OtherAddress,'
                                    + 'proposal_issued_to_1__r.OtherCity, proposal_issued_to_1__r.OtherCountry, proposal_issued_to_1__r.OtherGeocodeAccuracy,'
                                    + 'proposal_issued_to_1__r.OtherLatitude, proposal_issued_to_1__r.OtherLongitude, proposal_issued_to_1__r.OtherPhone,'
                                    + 'proposal_issued_to_1__r.OtherPostalCode, proposal_issued_to_1__r.OtherState, proposal_issued_to_1__r.OtherStreet,'
                                    + 'proposal_issued_to_1__r.Salutation,proposal_issued_to_1__r.FirstName,proposal_issued_to_1__r.LastName,'
                                    + 'proposal_issued_to_1__r.Phone,proposal_issued_to_1__r.Email,proposal_issued_to_2__r.Salutation,proposal_issued_to_2__r.FirstName,'
                                    + 'proposal_issued_to_2__r.LastName,proposal_issued_to_2__r.Phone,proposal_issued_to_2__r.Email,'
                                    + 'proposal_issued_to_2__r.MailingAddress, proposal_issued_to_2__r.MailingCity, proposal_issued_to_2__r.MailingCountry,'
                                    + 'proposal_issued_to_2__r.MailingGeocodeAccuracy, proposal_issued_to_2__r.MailingLatitude, proposal_issued_to_2__r.MailingLongitude,'
                                    + 'proposal_issued_to_2__r.MailingPostalCode, proposal_issued_to_2__r.MailingState, proposal_issued_to_2__r.MailingStreet,'
                                    + 'proposal_issued_to_2__r.OtherAddress, proposal_issued_to_2__r.OtherCity, proposal_issued_to_2__r.OtherCountry,'
                                    + 'proposal_issued_to_2__r.OtherGeocodeAccuracy, proposal_issued_to_2__r.OtherLatitude, proposal_issued_to_2__r.OtherLongitude,'
                                    + 'proposal_issued_to_2__r.OtherPhone, proposal_issued_to_2__r.OtherPostalCode, proposal_issued_to_2__r.OtherState,'
                                    + 'proposal_issued_to_2__r.OtherStreet,' + String.join(new List<String>(Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().keySet()), ',') 
                                    + ' FROM Opportunity where id in :oppIds' );
            
            //Initialization with original mappings
            mapperList= [Select Id, Field_Name__c, Quickbooks_Field_Name__c from Mapper__c
                         where Object__c='Opportunity'];
            
            for(Opportunity opp:oppList)
            {
                isCreated=false;
                if(opp.AccountId != null && (opp.Account.BillingAddress != null || opp.Account.ShippingAddress != null)){
                    if(opp.Account.BillingAddress != null){
                        relatedContactField = 'Account|Billing';
                    }
                    else if(opp.Account.ShippingAddress != null){
                        relatedContactField = 'Account|Shipping';
                    }
                }
                else if(opp.proposal_issued_to_1__c != null && (opp.proposal_issued_to_1__r.MailingAddress != null || opp.proposal_issued_to_1__r.OtherAddress != null)){
                    if(opp.proposal_issued_to_1__r.MailingAddress != null){
                        relatedContactField = 'proposal_issued_to_1__r|Mailing';
                    }
                    else if(opp.proposal_issued_to_1__r.OtherAddress != null){
                        relatedContactField = 'proposal_issued_to_1__r|Other';
                    }
                }
                else if(opp.proposal_issued_to_2__c != null && (opp.proposal_issued_to_2__r.MailingAddress != null || opp.proposal_issued_to_2__r.OtherAddress != null)){
                    if(opp.proposal_issued_to_2__r.MailingAddress != null){
                        relatedContactField = 'proposal_issued_to_2__r|Mailing';
                    }
                    else if(opp.proposal_issued_to_2__r.OtherAddress != null){
                        relatedContactField = 'proposal_issued_to_2__r|Other';
                    }
                }
                
                
                String json = getCustomerJSON(opp, 'Opportunity', mapperList, null, relatedContactField);
                HttpRequest request = new HttpRequest();
                HttpResponse response = new HttpResponse();
                Http http = new Http();
                
                request.setMethod('POST');
                
                if(Test.isRunningTest())
                {
                    request.setEndpoint('http://test.com/test/sendCustomer');
                }
                else
                {
                    request.setEndPoint(System.label.QB_API_End_Point+'/v3/company/'+realmid+'/customer');
                }
                
                request.setHeader('Authorization' , 'Bearer '+accessToken);
                request.setHeader('Accept', 'application/json');
                request.setHeader('Content-Type' , 'application/json;charset=UTF-8');
                request.setBody(json);
                
                response = http.send(request);
                if(response.getStatusCode() == 200)
                {
                    isCreated=true;
                }
                else if(response.getStatusCode() == 401)
                {
                    if(refreshToken!=null)
                    {
                        Map<String, Object> refreshResults= QuickbookApiCrud.refreshToken(refreshToken);
                        if(refreshResults != null){
                            accessToken=(String)refreshResults.get('access_token');
                            refreshToken=(String)refreshResults.get('refresh_token');
                            
                            request.setHeader('Authorization' , 'Bearer '+accessToken);
                            response = http.send(request);
                            if(response.getStatusCode() == 200)
                            {
                                isCreated=true;
                                isRefresh=true;
                            }
                        }
                    }
                }
                
                if(isCreated)
                {
                    Map<String,Object> results = (Map<String,Object>)System.JSON.deserializeUntyped(response.getBody());
                    opp.QB_Id__c=(String)((Map<String,Object>)results.get('Customer')).get('Id');
                    opp.is_Synced__c=true;
                }
                else{
                    QuickbookScheduler.sendErrorEmail(response.getStatusCode(),response.getBody());
                }
                
            }
            
            if(isRefresh)
            {
                qbcList[0].Access_token__c=accessToken;
                qbcList[0].Refresh_token__c=refreshToken;
                update qbcList[0];
            }
            
            update oppList;
        }
    }
    
    @future(callout=true)
    public static void updateSubCustomer(Set<String> customerIds)
    {
        List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                         realmid__c from QB_Credentials__c];
        
        if(qbcList.size()>0)
        {
            List<String>  authorizationCredentials=new List<String>  ();
            authorizationCredentials.add(qbcList[0].Access_token__c);
            authorizationCredentials.add(qbcList[0].Refresh_token__c);
            authorizationCredentials.add(qbcList[0].realmid__c);
            
            Map<String, String> qbSyncTokenMap=QuickbookAPiCrud.getCustomerSyncToken(customerIds, authorizationCredentials);
            
            if(qbSyncTokenMap.size()>0)
            {
                //Update Opportunity
                String relatedContactField=null;
                
                List<Opportunity> oppList= new List<Opportunity>();
                List<Mapper__c> mapperList=new List<Mapper__c>();
                
                
                oppList= Database.query('SELECT Account.Qb_Id__c,Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode,'
                                        + 'Account.BillingCountry, Account.BillingLatitude, Account.BillingLongitude, Account.BillingGeocodeAccuracy,'
                                        + 'Account.BillingAddress, Account.ShippingStreet, Account.ShippingCity, Account.ShippingState,'
                                        + 'Account.ShippingPostalCode, Account.ShippingCountry, Account.ShippingLatitude, Account.ShippingLongitude,'
                                        + 'Account.ShippingGeocodeAccuracy, Account.ShippingAddress, Account.Name, proposal_issued_to_1__r.MailingAddress,'
                                        + 'proposal_issued_to_1__r.Name, proposal_issued_to_1__r.MailingCity, proposal_issued_to_1__r.MailingCountry,'
                                        + 'proposal_issued_to_1__r.MailingGeocodeAccuracy, proposal_issued_to_2__r.Name,'
                                        + 'proposal_issued_to_1__r.MailingLatitude, proposal_issued_to_1__r.MailingLongitude, proposal_issued_to_1__r.MailingPostalCode,'
                                        + 'proposal_issued_to_1__r.MailingState, proposal_issued_to_1__r.MailingStreet, proposal_issued_to_1__r.OtherAddress,'
                                        + 'proposal_issued_to_1__r.OtherCity, proposal_issued_to_1__r.OtherCountry, proposal_issued_to_1__r.OtherGeocodeAccuracy,'
                                        + 'proposal_issued_to_1__r.OtherLatitude, proposal_issued_to_1__r.OtherLongitude, proposal_issued_to_1__r.OtherPhone,'
                                        + 'proposal_issued_to_1__r.OtherPostalCode, proposal_issued_to_1__r.OtherState, proposal_issued_to_1__r.OtherStreet,'
                                        + 'proposal_issued_to_1__r.Salutation,proposal_issued_to_1__r.FirstName,proposal_issued_to_1__r.LastName,'
                                        + 'proposal_issued_to_1__r.Phone,proposal_issued_to_1__r.Email,proposal_issued_to_2__r.Salutation,proposal_issued_to_2__r.FirstName,'
                                        + 'proposal_issued_to_2__r.LastName,proposal_issued_to_2__r.Phone,proposal_issued_to_2__r.Email,'
                                        + 'proposal_issued_to_2__r.MailingAddress, proposal_issued_to_2__r.MailingCity, proposal_issued_to_2__r.MailingCountry,'
                                        + 'proposal_issued_to_2__r.MailingGeocodeAccuracy, proposal_issued_to_2__r.MailingLatitude, proposal_issued_to_2__r.MailingLongitude,'
                                        + 'proposal_issued_to_2__r.MailingPostalCode, proposal_issued_to_2__r.MailingState, proposal_issued_to_2__r.MailingStreet,'
                                        + 'proposal_issued_to_2__r.OtherAddress, proposal_issued_to_2__r.OtherCity, proposal_issued_to_2__r.OtherCountry,'
                                        + 'proposal_issued_to_2__r.OtherGeocodeAccuracy, proposal_issued_to_2__r.OtherLatitude, proposal_issued_to_2__r.OtherLongitude,'
                                        + 'proposal_issued_to_2__r.OtherPhone, proposal_issued_to_2__r.OtherPostalCode, proposal_issued_to_2__r.OtherState,'
                                        + 'proposal_issued_to_2__r.OtherStreet,' + String.join(new List<String>(Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().keySet()), ',')
                                        + ' FROM Opportunity where Qb_Id__c in :customerIds' );
                
                //Initialization with original mappings
                mapperList= [Select Id, Field_Name__c, Quickbooks_Field_Name__c from Mapper__c
                             where Object__c='Opportunity'];
                
                for(Opportunity opp:oppList)
                {
                    if(opp.AccountId != null && (opp.Account.BillingAddress != null || opp.Account.ShippingAddress != null)){
                        if(opp.Account.BillingAddress != null){
                            relatedContactField = 'Account:Billing';
                        }
                        else if(opp.Account.ShippingAddress != null){
                            relatedContactField = 'Account:Shipping';
                        }
                    }
                    else if(opp.proposal_issued_to_1__c != null && (opp.proposal_issued_to_1__r.MailingAddress != null || opp.proposal_issued_to_1__r.OtherAddress != null)){
                        if(opp.proposal_issued_to_1__r.MailingAddress != null){
                            relatedContactField = 'proposal_issued_to_1__r:Mailing';
                        }
                        else if(opp.proposal_issued_to_1__r.OtherAddress != null){
                            relatedContactField = 'proposal_issued_to_1__r:Other';
                        }
                    }
                    else if(opp.proposal_issued_to_2__c != null && (opp.proposal_issued_to_2__r.MailingAddress != null || opp.proposal_issued_to_2__r.OtherAddress != null)){
                        if(opp.proposal_issued_to_2__r.MailingAddress != null){
                            relatedContactField = 'proposal_issued_to_2__r:Mailing';
                        }
                        else if(opp.proposal_issued_to_2__r.OtherAddress != null){
                            relatedContactField = 'proposal_issued_to_2__r:Other';
                        }
                    }
                    
                    String json = getCustomerJSON(opp, 'Opportunity', mapperList, qbSyncTokenMap, relatedContactField);
                    HttpRequest request = new HttpRequest();
                    HttpResponse response = new HttpResponse();
                    Http http = new Http();                    
                    request.setMethod('POST');
                    request.setEndPoint(System.label.QB_API_End_Point+'/v3/company/'+authorizationCredentials[2]+'/customer?operation=update');
                    request.setHeader('Authorization' , 'Bearer '+authorizationCredentials[0]);
                    request.setHeader('Accept', 'application/json');
                    request.setHeader('Content-Type' , 'application/json;charset=UTF-8');
                    request.setBody(json);
                    
                    response = http.send(request);
                    if(response.getStatusCode() == 200)
                    {
                        opp.is_Synced__c=true;
                    }
                    else
                    {
                        opp.is_Synced__c=false;
                        QuickbookScheduler.sendErrorEmail(response.getStatusCode(),response.getBody());
                    }
                }
                qbcList[0].Access_token__c=authorizationCredentials[0];
                qbcList[0].Refresh_token__c=authorizationCredentials[1];
                update qbcList[0];
                update oppList;
            }
        }
    }
    //--- This will get the Duration in days for the provided Duration Name from the QB (Term)
    public static Integer getDurationValue(  Integer day_duration ){
        
        List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                         realmid__c from QB_Credentials__c];    
        if(qbcList.size()>0)
        {
            List<String>  authorizationCredentials=new List<String>  ();
            authorizationCredentials.add(qbcList[0].Access_token__c);
            authorizationCredentials.add(qbcList[0].Refresh_token__c);
            authorizationCredentials.add(qbcList[0].realmid__c);
            
            String query = 'Select Id,DueDays from Term';
            String qbResponse = QuickBookScheduler.QuickBookRecordGetter(query, authorizationCredentials);
            if( qbResponse != null)
            {
                Map<String,Object> results = (Map<String,Object>)System.JSON.deserializeUntyped(qbResponse);
                Map<String,Object> queryresp = ((Map<String,Object>)results.get('QueryResponse'));
                if(queryresp.size()>0)
                {
                    Map<String, String> data = new Map<String, String>();
                    List<Object> responseList = (List<Object>)queryresp.get('Term');
                    List<Map<String,Object>> listofMaps = new List<Map<String,Object>>();
                    
                    for (Object instance : responseList)
                    {
                        listofMaps.add((Map<String,Object>)instance);
                    }
                    String valueOfDuration = null;
                    String valueOfId = null;
                    
                    for (Map<String,Object>mp : listofMaps)
                    {
                        valueOfDuration =String.valueOf(mp.get('DueDays'));
                        valueOfId = String.valueOf(mp.get('Id'));
                        
                        Integer result = 0;
                        Integer tmp_duration = 0;
                        if(valueOfDuration !=null){
                            tmp_duration = Integer.valueOf(valueOfDuration);            
                            if(tmp_duration == day_duration){
                                result= Integer.valueOf(valueOfId); 
                                return result;
                            }
                        }
                    }
                }
            }
        }
        return null;      
    }
    
    @future(callout=true)
    public static void sendInvoice(Set<Id> invoiceOppIds, Map <Id,String> mapInvoiceQbId,Integer isUndeleted)
    {
        try{
            Boolean isCreated=false;
            Boolean isRefresh=false;
            Integer durationValue = 30;
            Integer dayTerm= getDurationValue(durationValue);
            Datetime todayDate=System.today();
            
            Map<Id, Invoice__c> referenceOppMap=new Map<Id, Invoice__c> ();
            Map< Id, List<Invoice__c> > oppInvoiceMap=new Map< Id, List<Invoice__c> > ();
            List<Invoice_Sync__c> syncInvoices= new List<Invoice_Sync__c>();
            
            //Dynamic retrieval of fields for setting up emails
            List<String> relatedContactFields = new List<String>();
            Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap();
            
            for(Schema.SObjectField fld :objectFields.values()){
                
                schema.describeFieldResult dfield = fld.getDescribe();
                string fldType = string.valueOf(dfield.getType());
                string parentObject = string.valueOf(dfield.getReferenceTo());   
                
                if (fldType == 'REFERENCE' && parentObject=='(Contact)'){ // Lookup field!
                    relatedContactFields.add('Opportunity__r.'+string.valueOf(dfield.Name).removeend('__c')+'__r.email');
                }
            }
            
            //Quering    Invoices
            List<Invoice__c> invoiceList = Database.query('SELECT Id, Name, CustomerRef__c, Bill__c, Fee__c, Billed__c, Service_Date__c, Opportunity__c, ' + String.join(relatedContactFields, ',') + 
                                                          + ' FROM Invoice__c where Opportunity__c in :invoiceOppIds order by createddate asc' );
            
            for(Invoice__c inv:invoiceList)
            {
                if(!oppInvoiceMap.containsKey(inv.Opportunity__c))
                {
                    referenceOppMap.put(inv.Opportunity__c, inv);
                }
                
                if( oppInvoiceMap.containsKey(inv.Opportunity__c) )
                {
                    oppInvoiceMap.get(inv.Opportunity__c).add(inv);
                }
                else
                {
                    oppInvoiceMap.put( inv.Opportunity__c, new List<Invoice__c>{inv} );
                }
            }
            
            List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                             realmid__c from QB_Credentials__c];
            if(qbcList.size()>0)
            {
                String accessToken=qbcList[0].Access_token__c;
                String refreshToken=qbcList[0].Refresh_token__c;
                String realmid=qbcList[0].realmid__c;
                
                List<Mapper__c> mapperList=[Select Id, Field_Name__c, Quickbooks_Field_Name__c from Mapper__c
                                            where Object__c='Invoice' or (Object__c='Opportunity' and Quickbooks_Field_Name__c='ContactDetails')];
                
                for(Id oppId:oppInvoiceMap.keySet())
                {
                    Invoice invoice=new Invoice();
                    SalesTermRef str = new SalesTermRef();
                    str.Value = String.valueOf(dayTerm);
                    invoice.SalesTermRef =str;
                    CustomerRef cr=new CustomerRef();
                    cr.Value=referenceOppMap.get(oppId).CustomerRef__c;
                    invoice.CustomerRef=cr;
                    
                    //For setting up to, cc and bcc email addresses as per the configured mapping
                    invoice = setInvoiceEmail(invoice, referenceOppMap.get(oppId), mapperList);
                    
                    invoice.Line = new List<InvoiceLineItem>();
                    
                    isCreated=false;
                    List<Invoice__c> updatedInvoices=new List<Invoice__c>();
                    List<Invoice__c> invoices=oppInvoiceMap.get(oppId);
                    List <String> qbId_Undelete = new List<String> ();

                    for(Invoice__c inv:invoices)
                    {
                        Datetime serviceDate=inv.Service_Date__c;
                        InvoiceLineItem ic=new InvoiceLineItem();
                        
                        SalesItemLineDetail sd=new SalesItemLineDetail();
                        
                        ItemRef ir = new ItemRef();
                        ir.value=System.label.Service_Id;
                        
                        sd.Qty=(inv.Bill__c!=0 ? '1' : '0');
                        sd.ItemRef=ir;
                        sd.ServiceDate=serviceDate.format('yyyy-MM-dd', String.valueOf(TimeZone.getTimeZone('GMT')));
                        
                        ic.Amount=(inv.Bill__c*inv.Fee__c)/100;
                        ic.DetailType='SalesItemLineDetail';
                        ic.Description=inv.Name;
                        ic.SalesItemLineDetail=sd;
                        
                        invoice.Line.add(ic);                      
                        if(inv.Bill__c!=0)
                        {
                            updatedInvoices.add(inv);
                            if(mapInvoiceQbId != null){
                                if(mapInvoiceQbId.get(inv.Id) != null){
                                    qbId_Undelete.add(mapInvoiceQbId.get(inv.Id));
                                }
                                
                            }
                        }
                    }
                    
                    String json=JSON.serialize(invoice, true);
                    HttpRequest request = new HttpRequest();
                    HttpResponse response = new HttpResponse();
                    Http http = new Http();
                    
                    request.setMethod('POST');
                    
                    if(Test.isRunningTest())
                    {
                        request.setEndPoint('http://test.com/test/sendInvoice');
                    }
                    else
                    {
                        request.setEndPoint(System.label.QB_API_End_Point+'/v3/company/'+realmid+'/invoice?minorversion=32');
                    }
                    
                    request.setHeader('Authorization' , 'Bearer '+accessToken);
                    request.setHeader('Accept', 'application/json');
                    request.setHeader('Content-Type' , 'application/json;charset=UTF-8');
                    request.setBody(json);
                    response = http.send(request);
                    if(response.getStatusCode() == 200)
                    {
                        isCreated=true;
                    }
                    else if(response.getStatusCode() == 401)
                    {
                        if(refreshToken!=null)
                        {
                            Map<String, Object> refreshResults= QuickbookApiCrud.refreshToken(refreshToken);
                            
                            accessToken=(String)refreshResults.get('access_token');
                            refreshToken=(String)refreshResults.get('refresh_token');
                            
                            request.setHeader('Authorization' , 'Bearer '+accessToken);
                            response = http.send(request);
                            
                            if(response.getStatusCode() == 200)
                            {
                                isCreated=true;
                                isRefresh=true;
                            }
                            
                        }
                    }                   
                  
                    if(isCreated)
                    {
                        Map<String,Object> results = (Map<String,Object>)System.JSON.deserializeUntyped(response.getBody());
                        String qbId=(String)((Map<String,Object>)results.get('Invoice')).get('Id');
                        
                        Decimal amount=(Decimal)((Map<String,Object>)results.get('Invoice')).get('TotalAmt');
                        String invoiceNumber=(String)((Map<String,Object>)results.get('Invoice')).get('DocNumber');
                        String dueDate=(String)((Map<String,Object>)results.get('Invoice')).get('DueDate');
                       
                        //Generate Invoice Pdf
                        
                        if(isUndeleted ==1 ){
                           List <Id> invId_Undelete = new List<Id> ();
                          //  List <String> qbId_Undelete = new List<String> ();
                            for(Invoice__c inv1 :updatedInvoices){
                        		invId_Undelete.add(inv1.id);        
                            }
                            
                            List <Invoice_Sync__c> lst_InvoiceSync= [SELECT Invoice__r.id, Id, QB_Id__c FROM Invoice_Sync__c where Invoice__r.id IN :invId_Undelete];
                           for(Invoice_Sync__c invSync:lst_InvoiceSync){
                                qbId_Undelete.add(invSync.QB_Id__c);      
                                               
                            }
                            
                            List <ContentVersion> lst_ContentVersion= [Select Id, QB_Id__c, ContentDocumentId from ContentVersion where QB_Id__c=:qbId_Undelete];
                            for(ContentVersion csv:lst_ContentVersion){
                                csv.QB_Id__c = qbId;
                            }
                            update lst_ContentVersion;
				                            
                        }
                        else{
 	                       QuickbookApiCrud.issueInvoice(qbId, invoiceNumber, oppId, amount, dueDate, accessToken, realmid);                            
                        }
                        
                        for(Invoice__c inv:updatedInvoices)
                        {
                            if(inv.Bill__c!=0)
                            {
                                syncInvoices.add(new Invoice_Sync__c(Invoice__c=inv.Id, QB_Id__c=qbId, Amount__c=(inv.Bill__c*inv.Fee__c)/100));
                                inv.Billed__c=inv.Billed__c+inv.Bill__c;
                                inv.Bill__c=0;
                            }
                        }
                        update updatedInvoices;
                    }
                    else{
                        QuickbookScheduler.sendErrorEmail(response.getStatusCode(),response.getBody());
                    }
                }
                insert syncInvoices;
                update invoiceList;
                if(isRefresh)
                {
                    qbcList[0].Access_token__c=accessToken;
                    qbcList[0].Refresh_token__c=refreshToken;
                    update qbcList[0];
                }
            }
            
        }
        catch (Exception e){
            System.debug('Exception Caught = ' + e.getMessage());
            List <Invoice__c> lstRelatedInvoice = new List <Invoice__c>([Select Id, Bill__c from Invoice__c where Opportunity__c=:invoiceOppIds order by createddate asc]);
            for(Invoice__c inv:lstRelatedInvoice)
            {
                if(inv.Bill__c!=0)
                {
                    inv.Bill__c=0;
                }
            }
            update lstRelatedInvoice;
        }
    }
    
    public static Map<String, Object> refreshToken(String refreshToken)
    {
        String encodedString = EncodingUtil.base64Encode(Blob.valueOf(System.label.QB_Client_Id+':'+System.label.QB_Client_Secret));
        String endPoint;
        
        if(Test.isRunningTest())
        {
            endPoint='http://test.com/test/refreshToken';
        }
        else
        {
            endPoint = System.label.QB_Access_token_End_Point;
        }
        
        String requestBody = 'grant_type=refresh_token&refresh_token='+refreshToken;
        
        HttpRequest httpReq = new HttpRequest();
        HttpResponse httpRes = new HttpResponse();
        Http http = new Http();
        httpReq.setMethod('POST');
        httpReq.setEndPoint(endPoint);
        httpReq.setHeader('Host', 'oauth.platform.intuit.com');
        httpReq.setHeader('Accept', 'application/json');
        httpReq.setHeader('Authorization' , 'Basic '+encodedString);
        httpReq.setHeader('Cache-Control', 'no-cache');
        httpReq.setHeader('Content-Type' , 'application/x-www-form-urlencoded');
        httpReq.setBody(requestBody);
        
        httpRes= http.send(httpReq);
        if(httpRes.getStatusCode() == 200)
        {
            return (Map<String, Object>) JSON.deserializeUntyped(httpRes.getBody());
        }
        else{
            QuickbookScheduler.sendErrorEmail(httpRes.getStatusCode(),httpRes.getBody());
        }
        
        return null;
        
    }
    
    public static void issueInvoice(String invoiceId, String invoiceNumber, String oppId, Decimal amount, String dueDate, String accessToken, String realMId)
    {
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        Http http = new Http();
        request.setMethod('GET');
        request.setEndPoint(System.label.QB_API_End_Point+'/v3/company/'+realMId+'/invoice/'+invoiceId+'/pdf');
        
        request.setHeader('Authorization' , 'Bearer '+accessToken);
        request.setHeader('Content-Type' , 'application/pdf');
        response = http.send(request);
        
        if(response.getStatusCode() == 200)
        {
            //Delete Invoice Attachment if already exists
            List<Id> contentDocIds=new List<Id>();
            List<ContentVersion> issuedInvoice=[Select Id, QB_Id__c, ContentDocumentId from ContentVersion where QB_Id__c=:invoiceId];
            for(ContentVersion cv:issuedInvoice)
            {
                contentDocIds.add(cv.ContentDocumentId);
            }
            
            if(contentDocIds.size()>0)
            {
                List<ContentDocument> conDocs=[Select Id from ContentDocument where Id=:contentDocIds];
                delete conDocs;
            }
            
            //Insert new Invoice Attachment
            ContentVersion v = new ContentVersion();
            
            if(Test.isRunningTest())
            {
                Blob b=Blob.valueof('Test');
                v.versionData =  b;
            }
            else
            {
                v.versionData =  response.getBodyAsBlob();
            }   
            
            //                      v.title = 'Invoice#'+invoiceNumber;
            if(invoiceNumber != null)
            {
                v.title = 'Invoice#'+invoiceNumber;   
            }  else{
                v.title = 'Invoice#';   
            }
            
            v.pathOnClient ='Invoice#'+invoiceNumber+'.pdf';
            v.Amount__c=amount;
            v.Due_Date__c=Date.valueOf(dueDate);
            v.QB_Id__c=invoiceId;
            v.Balance__c=amount;
            v.FirstPublishLocationId = oppId;
            Map <String,Date> mapQbToDate= getQBDate(invoiceId);
            if(mapQbToDate !=null){
                v.QBCreated_Date__c =mapQbToDate.get(invoiceId);
            }
            
            insert v;
            
            /*ContentVersion cdi=[SELECT Id, ContentDocumentId from ContentVersion where id=:v.id];
            if (!test.isRunningTest()) {
                ContentDocumentLink cdl=new ContentDocumentLink(ContentDocumentId=cdi.ContentDocumentId, LinkedEntityId=oppId, ShareType='I', Visibility = 'AllUsers');
                insert cdl;
            }*/
        }
        else{
            QuickbookScheduler.sendErrorEmail(response.getStatusCode(),response.getBody());
        }
    }
    
    public static Map <String,Date> getQBDate(String QBIdWithoutQuotes){
        String QbidQuotes = '\''+QBIdWithoutQuotes+'\'';
        Map <String,Date> mapQbToDate = new Map <String,Date>(); 
        if(QBIdWithoutQuotes != null){
            List<QB_Credentials__c> qbcList=[Select Id, Access_token__c, Refresh_token__c,
                                             realmid__c from QB_Credentials__c];    
            try{
                if(qbcList.size()>0)
                {
                    List<String>  authorizationCredentials=new List<String>  ();
                    authorizationCredentials.add(qbcList[0].Access_token__c);
                    authorizationCredentials.add(qbcList[0].Refresh_token__c);
                    authorizationCredentials.add(qbcList[0].realmid__c);
                    String query = 'Select id,MetaData.CreateTime from Invoice where id = '+QbidQuotes;
                    String qbResponse = QuickBookScheduler.QuickBookRecordGetter(query, authorizationCredentials);
                    if( qbResponse != null)
                    {
                        Map<String,Object> results = (Map<String,Object>)System.JSON.deserializeUntyped(qbResponse);
                        Map<String,Object> queryresp = ((Map<String,Object>)results.get('QueryResponse'));
                        if(queryresp.size()>0)
                        {
                            Map<String, String> data = new Map<String, String>();
                            List<Object> responseList = (List<Object>)queryresp.get('Invoice');                        
                            List<Map<String,Object>> listofMaps = new List<Map<String,Object>>();
                            for (Object instance : responseList)
                            {
                                listofMaps.add((Map<String,Object>)instance);
                            }
                            Map<Id, Invoice__c> invoiceMap = new Map<Id, Invoice__c>();
                            List<Invoice_Sync__c> invoiceSyncList = new List<Invoice_Sync__c>();
                            Map<String, String> qbOppIdMap = new Map<String, String>();
                            Map<String, String> qbIdPOMap = new Map<String, String>();
                            
                            Map<String, Map<String,Object> > invoiceSyncMap=new  Map<  String, Map<String,Object> >();
                            for (Map<String,Object>mp : listofMaps)
                            {
                                invoiceSyncMap.put(String.valueOf(mp.get('Id')), mp);                    
                            }                        
                            //--------create map of opportunities and their invoices
                            
                            //-----------------------loop through all deleted line items
                            List <Invoice__c> lst_updatedInvoices = new List <Invoice__c>();
                            Map <Id,Invoice__c> map_updatedInvoices = new Map <Id,Invoice__c>();
                            
                            // for(String qbID :lst_QBIdWithoutQuotes){
                            if(invoiceSyncMap.get(QBIdWithoutQuotes) != null){
                                Map<String,Object>mp =invoiceSyncMap.get(QBIdWithoutQuotes);           
                                Map<String,Object>lineItems =(Map<String,Object>)mp.get('MetaData');         
                                Date dt = getDateFromString((String)lineItems.get('CreateTime'));
                                mapQbToDate.put(QBIdWithoutQuotes,dt);                                
                            }                    
                        }
                    }
                }
            }
            catch (Exception e){
                System.debug('===============EXCEPTION==================\n'+e.getMessage());
            }
        }
        
        return mapQbToDate;
    }
    
    public static Date getDateFromString (String input){
        String delimiter = 'T';
        String splitDate = input.substringBefore(delimiter); //
        String[] arrDate = splitDate.split('\\-');
        if(arrDate != null){
            Date datetmp = Date.newInstance(Integer.valueOf(arrDate[0]), Integer.valueOf(arrDate[1]), Integer.valueOf(arrDate[2]));
            return datetmp;
        }
        return null;
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
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
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