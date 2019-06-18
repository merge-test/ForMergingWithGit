public class IssuedInvoiceReportController {
    
    public double category030{ get; set; }    
    public double category3160{ get; set; }
    public double category6190{ get; set; }    
    public double category91120{ get; set; }
    public double categoryGt120{ get; set; }
    
    public Map< string,List<ContentVersion> > oppInvoiceMapp { get; set; } //oppnames-list of Contents Invoices
    public Map<string, Set<String> > accountOppMap { get; set; } //accnames-list of opps
    public Map<string, Set<String> > contactAccountMap { get; set; } //Contactnames-list of accs
    public Set<String> contactNames { get; set; } 
    
    public IssuedInvoiceReportController() {
        
        contactAccountMap=new Map<string, Set<String> >();
        accountOppMap=new Map<string, Set<String> >();
        oppInvoiceMapp=new Map< string,List<ContentVersion> >();
        
        
        Map<Id, Opportunity> oppMap = new Map<Id, opportunity>([select id, name, Account.Name, Project_Manager_c__r.Name 
                                                                from opportunity where StageName = 'Closed Won']);
        
        List<Id> contentLinkIds=new List<Id>();
        Set<Id> unpaidContentLinkIds=new Set<Id>();
        Map<id,string> oppContentMapping = new Map<id,string>();
        
        List<Id> oppIds=new List<Id>();
        oppIds.addAll(oppMap.keySet());
        
        if(oppIds.size()>0)
        {
            List<ContentDocumentLink> issuedInvoicesLinks=[Select Id, ContentDocumentId,LinkedEntityId, LinkedEntity.name from ContentDocumentLink where 
                                                           LinkedEntityId In :oppIds and ContentDocument.title like 'Invoice%'];
            for(ContentDocumentLink cdl:issuedInvoicesLinks)
            {
                contentLinkIds.add(cdl.ContentDocumentId);
            }
            
            List<ContentVersion> issuedInvoices=[Select Id, Title, Amount__c, ContentDocumentId, Days_Outstanding__c from ContentVersion 
                                                 where ContentDocumentId=:contentLinkIds and Status__c!='Paid' and title like 'Invoice%' order by createddate asc];
            for(ContentVersion cv:issuedInvoices)
            {
                unpaidContentLinkIds.add(cv.ContentDocumentId);
            }
            
            for(ContentDocumentLink cdl:issuedInvoicesLinks)
            {
                if(unpaidContentLinkIds.contains(cdl.ContentDocumentId))
                {
                    String contactName=oppMap.get(cdl.LinkedEntityId).Project_Manager_c__r.Name;
                    String accountName='<b>&nbsp&nbspAccount Name: </b>'+oppMap.get(cdl.LinkedEntityId).Account.Name;
                    String oppName='&nbsp&nbsp&nbsp&nbsp'+oppMap.get(cdl.LinkedEntityId).Name;
                    
                    if(contactName !=null)
                    {
                        contactname='<b>Project Manager: </b>'+contactName;
                        if(contactAccountMap.containskey(contactName))
                        {
                            contactAccountMap.get(contactName).add(accountName);
                        }
                        else
                        {
                            contactAccountMap.put( contactName, new Set<String>{accountName});
                        }
                        
                    }
                    else
                    {
                        contactName='<b>Project Manager: </b>Not assigned';
                        if(contactAccountMap.containskey(contactName))
                        {
                            contactAccountMap.get(contactName).add(accountName);
                        }
                        else
                        {
                            contactAccountMap.put(contactName, new Set<String>{accountName});
                        }
                        
                        
                    }
                    
                    if(accountOppMap.containskey(accountName))
                    {
                        accountOppMap.get(accountName).add(oppName);
                    }
                    else
                    {
                        accountOppMap.put( accountName, new Set<String>{oppName});
                    }
                    
                    oppContentMapping.put(cdl.ContentDocumentId, oppName); 
                }
            }
            
            Set<string> allKeys = contactAccountMap.keySet();
            for(string k:allkeys )
            {
                Set<string> tempList = contactAccountMap.get(k);
                contactAccountMap.remove(k);
                contactAccountMap.put(k +'<b> ('+tempList.size()+ (tempList.size()>1 ? ' records':' record')+') </b>', tempList);
            }
        
            //If there are no documents in the system, clear the primary contact map to show zero records on the report.
            if(issuedInvoices.size()==0)
            {
                contactAccountMap.clear();
            }
            
            category030 = 0;
            category3160 = 0;
            category6190 = 0;
            category91120 = 0;
            categoryGt120 = 0;
            
            for (ContentVersion cv:issuedInvoices)
            {
                String oppName=oppContentMapping.get(cv.ContentDocumentId);
                
                if(oppInvoiceMapp.containskey(oppName))
                {
                    oppInvoiceMapp.get(oppName).add(cv);
                }
                else
                {
                    oppInvoiceMapp.put( oppName, new List<ContentVersion>{cv});
                }
                
                if(cv.Days_Outstanding__c == '0-30')
                {
                    category030 += cv.Amount__c;
                }
                else if(cv.Days_Outstanding__c == '31-60')
                {
                    category3160 += cv.Amount__c;
                }
                else if(cv.Days_Outstanding__c == '61-90')
                {
                    category6190 += cv.Amount__c;
                }
                else if(cv.Days_Outstanding__c == '91-120')
                {
                    category91120 += cv.Amount__c;
                }
                else 
                {
                    categoryGt120 += cv.Amount__c;
                }
            }
        }
    }
    
}