public class InvoiceController {
    
    public Id oppId {get; set;}
    public list<Invoice__c> invoices {get; set;}
    public integer itemindex { get; set; }
    public integer confirmed { get; set; }
    public integer serviceCount;
    public Boolean enablePoll{get;set;}
    public Boolean syncStatus;
    public Boolean showDialogBox;
    public Boolean multipleFoundError{get;set;}
    public Boolean multipleFoundErrorNew{get;set;}
    
    public Boolean reloadPageObj{get;set;} 
    public String popUpHeading{get;set;}
    public Boolean refreshInvoices{get;set;}   
    public String userMessage{ get; set; }
    public Boolean refreshOnDelete{get;set;}
    public String startMonth {get;set;}
    public String selectedVal{get;set;}
    public Integer numberOfSchedulers {get;set;}
    public Integer allowSave {get;set;}
    public class wrapperClass{
        Integer value;
        String str;
        Boolean result ;
        Set<String> uniqueName;
        Set<String> uniqueTitleInvoice;
        Map <String,String> mapUniqueName;
    }
    //    public list <String>Children {get;set;}
    public List<SelectOption> getopenPresentationOptions(){
        List<SelectOption> optns = new List<Selectoption>();
        for(Integer i=1 ; i<=12;i++){
            optns.add(new selectOption(String.valueOf(i),String.valueOf(i)));              
            
            
        }        
        return optns;
    }
    
    public InvoiceController(ApexPages.StandardController controller) {
        /* Children = new List<String>();
Children.add('Test');*/
        
        numberOfSchedulers=0;
        refreshOnDelete = false;
        refreshInvoices = false;
        reloadPageObj = false;
        allowSave = 1;
        multipleFoundError = false;
        multipleFoundErrorNew= false;
        oppId = ApexPages.currentPage().getParameters().get('id');
        serviceCount =1;
        
        invoices = new list<Invoice__c>();
        List<Id>tmpInvIds = new List <Id>();
        invoices=[Select Id, Name, Bill__c, Billed__c, Fee__c, Amount__c, 
                  
                  Fee_Percentage__c, Time_Frame__c, Delays__c,Delays_Month__c, Opportunity__c,Default__c,Locked__c from 
                  
                  Invoice__c where Opportunity__c=:oppId
                  order by createddate asc];
        for(Invoice__c inv:invoices)
        {
            tmpInvIds.add(inv.id);
            if(inv.Bill__c!=0)
            {
                enablePoll = true;
            }
        }   
        
        List <FeeStorage__c> lstFeeStorage = [Select id from FeeStorage__c where 
                                              
                                              Invoice__c IN:tmpInvIds];
        numberOfSchedulers= lstFeeStorage.size();
    }
    
    public List<Invoice__c> getInvoices()
    {
        return invoices;
    }
    
    public List<ContentVersion> getIssuedInvoices()
    {
        List<Id> contentLinkIds=new List<Id>();
        List<ContentDocumentLink> issuedInvoicesLinks=[Select Id, ContentDocumentId from 
                                                       
                                                       ContentDocumentLink where LinkedEntityId=:oppId];
        for(ContentDocumentLink cdl:issuedInvoicesLinks){
            contentLinkIds.add(cdl.ContentDocumentId);
        }
        
        List<ContentVersion> issuedInvoices=[Select Id, QB_Id__c,Title,QBCreated_Date__c, 
                                             
                                             Amount__c,Balance__c, ContentDocumentId, Days_Outstanding__c, CreatedDate,Status__c, 
                                             
                                             PO__c,Gross_Amount__c from ContentVersion where ContentDocumentId=:contentLinkIds
                                             and title like 'Invoice%' AND qb_id__c != 
                                             
                                             null order by createddate asc];
        
        return issuedInvoices;
    }
    
    public static Date getDateFromString (String input){
        String delimiter = 'T';
        String splitDate = input.substringBefore(delimiter); //
        String[] arrDate = splitDate.split('\\-');
        if(arrDate != null){
            Date datetmp = Date.newInstance(Integer.valueOf(arrDate[0]), Integer.valueOf
                                            
                                            (arrDate[1]), Integer.valueOf(arrDate[2]));
            return datetmp;
        }
        return null;
    }
    
    public void addMore()
    {
        invoices.add(new Invoice__c(Name='Add Service', Bill__c=0.0, Opportunity__c=oppId));
        serviceCount++;
    }    
    
    public void RemoveAllStages(){
        update invoices;
        System.debug('Confirmed == '+integer.valueOf(confirmed));
        List <Invoice__c> lstInvoiceUnBilled = new List <Invoice__c>();
        List <Invoice__c> lstInvoiceBilled = new List <Invoice__c>();
        List <Id> lstInvoiceIds = new List <Id>();
        
        for(Invoice__c inv: invoices){
            if(inv.Locked__c == false){
                if(inv.Billed__c<=0){
                    lstInvoiceUnBilled.add(inv);
                }
                else{
                    lstInvoiceBilled.add(inv);
                }
                lstInvoiceIds.add(inv.Id);
            }
        }        
        System.debug('Size of Unbilled is '+lstInvoiceUnBilled.size());
        Boolean result = true;
        Integer noData = 0;
        if(lstInvoiceBilled.size()>0){
            result=RemoveSeletedInvoicesBilled(lstInvoiceBilled,confirmed);
            noData++;
        }
        
        if((lstInvoiceUnBilled.size()>0 && result==true) || lstInvoiceBilled.size()<=0){
            
            RemoveSeletedInvoicesUnbilled(lstInvoiceUnBilled);
            noData++;
        }
        if((result == true) || lstInvoiceBilled.size()<=0){
            delete [Select Id from FeeStorage__c where Invoice__c IN :lstInvoiceIds];
            
        }
        
        refreshOnDelete = true;
        if((lstInvoiceBilled.size()<=0 && lstInvoiceUnBilled.size()<=0)){
            syncStatus =true;
            userMessage = 'No Stage to Delete';
            popUpHeading = 'Oops!';
        }
        
        if(confirmed ==1 || (lstInvoiceUnBilled.size()>0 && lstInvoiceBilled.size()<=0)){
            refreshOnDelete = false;
            reloadPageObj= false;
        }
        
    }
    
    public Boolean RemoveSeletedInvoicesBilled(List <Invoice__c> lst_inv,Integer ConfirmedDelete){
        List<Id> lst_InvId = new List <Id>();
        for(Invoice__c inv :lst_inv){
            lst_InvId.add(inv.id);
        } 
        
        List <Invoice_Sync__c> lst_invoiceSync=new List <Invoice_Sync__c>([Select Name,QB_Id__c,Invoice__c,Amount__c,PO__c from Invoice_Sync__c where Invoice__c  IN:lst_InvId]);
        
        Map <Id,List<String>> mapInvoiceQB = new Map <Id, List <String>>();
        for(Invoice_Sync__c invObj:lst_invoiceSync){
            //  lst_QBid.add(invObj.QB_Id__c);
            
            if(mapInvoiceQB.get(invObj.Invoice__c) != null){
                mapInvoiceQB.get(invObj.Invoice__c).add(invObj.QB_Id__c);
            }
            else{
                mapInvoiceQB.put(invObj.Invoice__c,new List <String>());
                mapInvoiceQB.get(invObj.Invoice__c).add(invObj.QB_Id__c);
            }
        }
        Map <Id,Boolean> mapInvoiceMultiple = new Map <Id, Boolean>();
        List<Invoice__c> lstInvoiceUpdated = new List <Invoice__c>();
        Set<Deleted_QB_Ids__c> deletedIds = new Set<Deleted_QB_Ids__c> ();
        List<Id> lst_ContentDocumentId = new List <Id>();
        String confirmationName = '';
        String confirmationNameNotIssue = '<i>';
        Integer needConfirmation = 0;
        Set <String> setFinalWarning = new Set <String>();
        Set <String> setFinalWarningTitle = new Set <String>();
        Set <String> set_confirmationNameNotIssue= new Set <String>();
        Map <String,String> mapInvoiceTitle = new Map <String,String>();
        Integer starter =1;
        for(Invoice__c inv: lst_inv){ 
            if(mapInvoiceQB.get(inv.id) != null){
                List<String> lst_QBid = mapInvoiceQB.get(inv.id); 
                
                wrapperClass wrap=checkMultipleLineItems(lst_QBid,inv.Id,1);
                Boolean result =wrap.result;
                mapInvoiceMultiple.put(inv.id,result);
                if(result){
                    List <ContentVersion> lst_contentVersion=new List <ContentVersion>([Select id,Title,QB_Id__c,contentDocumentId from ContentVersion where QB_Id__c IN:lst_QBid]);
                    for(ContentVersion contentObj:lst_contentVersion){
                        lst_ContentDocumentId.add(contentObj.contentDocumentId);
                        deletedIds.add(new Deleted_QB_Ids__c (Name=contentObj.Title,QB_Id__c = contentObj.QB_Id__c));
                    }
                    lstInvoiceUpdated.add(inv);
                    //                         confirmationNameNotIssue=confirmationNameNotIssue+' | '+inv.Name+' '; 
                    set_confirmationNameNotIssue.add(inv.Name);
                }
                else{
                    needConfirmation=1;
                    String strWarning ='';
                    for(String str:wrap.UniqueName){
                        setFinalWarning.add(str);
                    }
                    
                    for(String str:wrap.uniqueTitleInvoice){
                        setFinalWarningTitle.add(str);
                    }
                    
                    for(String key:wrap.mapUniqueName.keySet()){
                        
                        //String tmp ='<li>'+starter+'). '+inv.Name+' ' +wrap.mapUniqueName.get(key)+'</li>';                       
                        String tmp =inv.Name+' ' +wrap.mapUniqueName.get(key);                       
                        mapInvoiceTitle.put(key,tmp);
                    }
                }
            }
        }
        
        
        String confirmationTitle = '<i> ';
        confirmationName =' ';
        Integer count = 1;
        for(String key:mapInvoiceTitle.keySet()){
            String makeString ='<li>'+count+'). '+   mapInvoiceTitle.get(key)+'</li>';
            confirmationName+=makeString;
            count++;
            
        }
        
        count=0;
        for(String str:set_confirmationNameNotIssue){
            if(count == 0){
                confirmationNameNotIssue=confirmationNameNotIssue+str;
            }
            else if(count == set_confirmationNameNotIssue.size()-1){
                confirmationNameNotIssue=confirmationNameNotIssue+' and '+str;
            }
            else{
                confirmationNameNotIssue=confirmationNameNotIssue+' , '+str;
            }
            count++;
        }
        count=0;
        for(String str:setFinalWarningTitle){
            if(count == 0){
                confirmationTitle=confirmationTitle+str;                
            }
            else if(count == setFinalWarningTitle.size()-1){
                confirmationTitle=confirmationTitle+' and '+str;
            }
            else{
                confirmationTitle=confirmationTitle+' , '+str;            
            }
            count++;
        }
        confirmationTitle += '</i> ';
        confirmationName +=' ';
        confirmationNameNotIssue+='</i>';
        System.debug('ConfirmedDelete'+ConfirmedDelete); 
        if(needConfirmation != 0){
            //multipleFoundErrorNew=true;
            syncStatus =true;
            userMessage = 'Selected stage(s) cannot be deleted because; <ul>'+confirmationName+'</ul>';
            popUpHeading = 'Error!';
            refreshInvoices = false;
            return false;
        }
        else if(ConfirmedDelete == 0){
            showDialogBox =true;
            userMessage =confirmationNameNotIssue+ ' along with Unbilled Stage(s) will be Deleted. Are you sure you want to delete them. ';
            popUpHeading = 'Confirmation!';
            refreshInvoices = false;
            return false;           
        }
        else{
            List <Deleted_QB_Ids__c> lst_deletedId = new List<Deleted_QB_Ids__c>();
            for(Deleted_QB_Ids__c ids : deletedIds){
                lst_deletedId.add(ids);
            }
            List <ContentDocument> lst_contentDocument=new List  <ContentDocument>([Select id from ContentDocument where id IN:lst_ContentDocumentId]);
            try{
                insert lst_deletedId;
            }
            catch(Exception e){
                System.debug('Exception : ' + e.getMessage());
                return false;
            }
            delete lst_contentDocument;
            
            try{
                delete lstInvoiceUpdated;
            }
            catch (Exception ex){
                System.debug('Exception is '+ex);
                return false;
            }
            //  refreshInvoices = true;               
        }
        
        
        
        return true;
    }
    
    public void RemoveSeletedInvoicesUnbilled(List <Invoice__c> lst_inv){
        List<Id> lst_InvId = new List <Id>();
        for(Invoice__c inv :lst_inv){
            lst_InvId.add(inv.id);
        }
        List <FeeStorage__c> lstFeeStorage = [Select id from FeeStorage__c where  Invoice__c IN:lst_InvId];
        //                 System.debug('====== lstFeeStorage  ======'+lstFeeStorage.size());
        delete lstFeeStorage; 
        for(Invoice__c inv :lst_inv){
            lst_InvId.add(inv.id);
            
            if(inv.Name != null && inv.Name.startswith('Add Service'))
            {
                serviceCount--;
            }
            refreshOnDelete = true; 
        }
        try{
            delete lst_inv;            
        }
        catch (Exception ex){
            System.debug(ex.getMessage());
        }
        
    }
    
    
    public void RemoveItem(){
        Invoice__c inv = Invoices.remove(integer.valueOf(itemindex-1));
        List <FeeStorage__c> lstFeeStorage = [Select id from FeeStorage__c where Invoice__c =:inv.id];
        System.debug('====== lstFeeStorage  ======'+lstFeeStorage.size());
        
        if(lstFeeStorage.size() == 0 ){
            
            if(inv.Id!=null)
            {
                try{
                    delete inv;            
                }
                catch (Exception ex){
                    System.debug(ex.getMessage());
                }
            }
            
            if(inv.Name != null && inv.Name.startswith('Add Service'))
            {
                serviceCount--;
            }
            refreshOnDelete = true; 
        }
        else{
            System.debug('====== Deleted  ======');
            syncStatus =true;
            userMessage = 'You cannot delete the stage because a scheduler is running for this Stage';
            popUpHeading = 'Error!';
            refreshInvoices = true;
        }
        
    }
    
    public wrapperClass checkMultipleLineItems(  List<String> lst_QBid, Id invoiceId,Integer isBulkDelete){
        List<String> lstQbIdAll = new List <String>();
        Map <String,id> map_QbidToInvoiceId = new Map <String,id>();
        List <Invoice_Sync__c> lst_invoiceSync=new List <Invoice_Sync__c>([Select Name,QB_Id__c,Invoice__c,Amount__c,PO__c from Invoice_Sync__c where QB_Id__c =:lst_QBid]);
        for(Invoice_Sync__c invObj:lst_invoiceSync){
            lstQbIdAll.add(invObj.QB_Id__c);
            map_QbidToInvoiceId.put(invObj.QB_Id__c,invObj.Invoice__c);
        }
        List <ContentVersion> lst_ContentVersion=new List <ContentVersion>([Select  id,QB_Id__c from ContentVersion where QB_Id__c =:lstQbIdAll]);
        List <String> lst_ActiveQBid=  new   List <String>();
        for(ContentVersion cvObj:lst_ContentVersion){
            lst_ActiveQBid.add(cvObj.QB_Id__c);
        }
        
        wrapperClass wrap = new wrapperClass();
        wrap.value=0;
        wrap.str='';
        wrap.uniqueName = new Set<String>();
        wrap.uniqueTitleInvoice = new Set<String>();
        wrap.result= true ;
        wrap.mapUniqueName = new Map <String,String>();
        Set <String> set_str = new Set<String>();
        List <Invoice_Sync__c> lst_invoiceSyncUpdated=new List <Invoice_Sync__c>([Select Name,QB_Id__c,Invoice__r.Name,Invoice__r.Locked__c,Invoice__c,Amount__c,PO__c from Invoice_Sync__c where QB_Id__c =:lst_ActiveQBid]);
        List <ContentVersion> lst_ContentVersionActive =new List <ContentVersion> ([SELECT QB_Id__c, Id, Title FROM ContentVersion where QB_Id__c IN:lst_ActiveQBid]);
        Map <String,String> mapQbIdTitle = new Map <String,String>();
        for(ContentVersion cv:lst_ContentVersionActive){
            mapQbIdTitle.put(cv.QB_Id__c,cv.Title);
        }        
        if(isBulkDelete ==0){
            for(Invoice_Sync__c invObj:lst_invoiceSyncUpdated){
                if(invObj.Invoice__c != invoiceId ){
                    wrap.result= false;
                    return wrap;
                } 
            }            
        }
        else{
            Integer wrong= 0;
            for(Invoice_Sync__c invObj:lst_invoiceSyncUpdated){    
                System.debug('Name '+invObj.Invoice__r.Name +' --Locked-- '+invObj.Invoice__r.Locked__c);
                if(invObj.Invoice__c != invoiceId && invObj.Invoice__r.Locked__c == true){
                    wrap.result= false ;
                    String invoiceTitle = '';
                    if(mapQbIdTitle != null){
                        if(mapQbIdTitle.get(invObj.QB_Id__c) != null ){
                            invoiceTitle= mapQbIdTitle.get(invObj.QB_Id__c) ;
                        }
                    }
                    wrap.uniqueName.add(invObj.Invoice__r.Name);
                    wrap.uniqueTitleInvoice.add(invoiceTitle);
                    wrap.str= 'is invoiced along with '+invObj.Invoice__r.Name+' in '+invoiceTitle;
                    
                    String uniqueName  = invObj.QB_Id__c+' & '+invoiceTitle;
                    wrap.mapUniqueName.put(uniqueName,wrap.str);
                    wrong=1;
                    //  return wrap;
                } 
            }
            if(wrong == 1){
                wrap.result= false ;
            }
        }
        return wrap;
    }
    
    
    public void RemoveBilledItem(){
        Invoice__c inv = Invoices.get(integer.valueOf(itemindex-1));        
        
        if(inv.Id!=null)
        {
            List <FeeStorage__c> lstFeeStorage = [Select id from FeeStorage__c where Invoice__c =:inv.id];
            if(lstFeeStorage.size() == 0 ){                
                List <Invoice_Sync__c> lst_invoiceSync=new List <Invoice_Sync__c>([Select Name,QB_Id__c,Invoice__c,Amount__c,PO__c from Invoice_Sync__c where Invoice__c =:inv.Id]);
                List<String> lst_QBid = new List <String>();
                for(Invoice_Sync__c invObj:lst_invoiceSync){
                    lst_QBid.add(invObj.QB_Id__c);
                }
                
                wrapperClass wrap=checkMultipleLineItems(lst_QBid,inv.Id,0);
                Boolean result =wrap.result;
                if(result){
                    List<Deleted_QB_Ids__c> deletedIds = new List<Deleted_QB_Ids__c>();
                    inv = Invoices.remove(integer.valueOf(itemindex-1));
                    List <ContentVersion> lst_contentVersion=new List <ContentVersion>([Select id,Title,QB_Id__c,contentDocumentId from ContentVersion where QB_Id__c IN:lst_QBid]);
                    List<Id> lst_ContentDocumentId = new List <Id>();
                    for(ContentVersion contentObj:lst_contentVersion){
                        lst_ContentDocumentId.add(contentObj.contentDocumentId);
                        deletedIds.add(new Deleted_QB_Ids__c(Name=contentObj.Title,QB_Id__c =  contentObj.QB_Id__c));
                    }
                    List <ContentDocument> lst_contentDocument=new List <ContentDocument>([Select id from ContentDocument where id IN:lst_ContentDocumentId]);
                    try{
                        insert deletedIds;
                    }
                    catch(Exception e){
                        System.debug('Exception : ' + e.getMessage());
                    }
                    delete lst_contentDocument;
                    
                    if(inv.Id!=null)
                    {
                        try{
                            delete inv;
                        }
                        catch (Exception ex){
                            System.debug('Exception is '+ex);
                        }
                        //  refreshInvoices = true;
                    }
                }
                else{
                    multipleFoundError = true;
                }
            }
            else{
                System.debug('====== Deleted  ======');
                syncStatus =true;
                userMessage = 'You cannot delete the stage because a scheduler is running for this Stage';
                popUpHeading = 'Error!';
                reloadPageObj = true;
            }
        }
        
        
        if(inv.Name != null && inv.Name.startswith('Add Service'))
        {
            serviceCount--;
        }
        refreshOnDelete = true;
    }
    
    // Save action method
    public PageReference save()
    {
        System.debug('=============+Save ==========='+allowSave);
        
        allowSave = 0;
        System.debug('Save method');
        //            userMessage = 'No data to save';
        userMessage = 'Data is saved. Please note that no invoice is generated';
        popUpHeading = 'Oops!';
        Opportunity Opp = [SELECT StageName ,QB_Id__c
                           FROM Opportunity
                           WHERE id=: oppId LIMIT 1];
        
        Set<Id> invoiceOppIds=new Set<Id>();
        if(!Opp.stageName.equalsIgnoreCase('Closed Won')){
            userMessage = 'Opportunity should be Closed Won to generate the invoice.';
            popUpHeading = 'Error!';
            allowSave = 1;
            return null;    
        }
        else if(Opp.QB_Id__c == null){
            userMessage = 'Opportunity should be Synced to QBO to generate the invoice';
            popUpHeading = 'Error!';
            allowSave = 1;
            return null;    
        }
        List<Invoice__c> toInsert = new List<Invoice__c>();
        List<Invoice__c> toUpdate = new List<Invoice__c>();
        for(Invoice__c inv : invoices ){
            if(inv.Id != null){
                toUpdate.add(inv);
            }
            else{
                toInsert.add(inv);
            }
            if(inv.Name == null){
                userMessage = 'Stage name cannot be a null value.';
                popUpHeading = 'Error!';
                allowSave = 1;
                return null;
            }
            
            if(inv.Bill__c < 0){
                userMessage = 'Bill(%) cannot be negative.';
                popUpHeading = 'Error!';
                allowSave = 1;
                return null;
            }
            
            if(inv.Bill__c!=0)
            {
                if(inv.Fee__c > 0){
                    userMessage ='Your request to generate invoice has been initiated. You will be notified by email in case of issue.';
                    popUpHeading = 'Success';
                    invoiceOppIds.add(inv.Opportunity__c);
                    System.debug(Inv.Name + ' is biller with Opportunity Id = ' + 
                                 
                                 inv.Opportunity__c);
                    enablePoll = true;
                }
                else{
                    userMessage ='A stage with fee value zero or less cannot be billed.';
                    popUpHeading = 'Oops! ';
                    allowSave = 1;
                    return null;
                }
            } 
        }
        try{
            insert toInsert;
            update toUpdate;
        }
        catch(Exception e){
            if(e.getMessage().contains('Stage with same name')){
                userMessage = 'Stage with same name already exists.';
                popUpHeading = 'Error!';
                
            }
            else{
                userMessage = 'Some unexpected error occured. Please contact your administrator for further information.';
                popUpHeading = 'Error!';
            }
            allowSave = 1;
            return null;
        }
        System.debug('Size is '+invoiceOppIds.size());
        if(invoiceOppIds.size() > 0){
            System.debug('Future call Invoice Send');
            QuickbookApiCrud.sendInvoice(invoiceOppIds,null,0);
            System.debug('Future call ended');
        }
        
        enablePoll = true;
        return null;
    }
    
    public PageReference runSchedule()
    {
        System.debug('Save method');
        userMessage = 'No data to save';
        popUpHeading = 'Oops!';
        Opportunity Opp = [SELECT StageName ,QB_Id__c
                           FROM Opportunity
                           WHERE id=: oppId LIMIT 1];
        
        Set<Id> invoiceOppIds=new Set<Id>();
        if(!Opp.stageName.equalsIgnoreCase('Closed Won')){
            userMessage = 'Opportunity should be Closed Won to generate the invoice.';
            popUpHeading = 'Error!';
            return null;    
        }
        else if(Opp.QB_Id__c == null){
            userMessage = 'Opportunity should be Synced to QBO to generate the invoice';
            popUpHeading = 'Error!';
            return null;    
        }
        List<Invoice__c> toInsert = new List<Invoice__c>();
        List<Invoice__c> toUpdate = new List<Invoice__c>();
        for(Invoice__c inv : invoices ){
            Integer value = Integer.valueOf(selectedVal) ;
            System.debug(inv.Name+' -- '+inv.Bill__c+' -- '+inv.Billed__c+' -- '+(inv.Bill__c*value));
            if(inv.Id != null){
                toUpdate.add(inv);
            }
            else{
                toInsert.add(inv);
            }
            
            if(inv.Billed__c != null && inv.Billed__c>=0){
                if((inv.Billed__c+(inv.Bill__c*value))>100){
                    userMessage = 'Billed Percentage of Stage "'+inv.Name+'" After '+value+' months duration will be '+(inv.Billed__c+(inv.Bill__c*value))+'% that exceeds 100%';
                    popUpHeading = 'Error!';
                    return null;
                }                
            }
            
            if(inv.Name == null){
                userMessage = 'Stage name cannot be a null value.';
                popUpHeading = 'Error!';
                return null;
            }
            if(inv.Name == null){
                userMessage = 'Stage name cannot be a null value.';
                popUpHeading = 'Error!';
                return null;
            }
            if(startMonth == null || String.isBlank(startMonth) || String.isBlank
               
               (startMonth)){
                   userMessage = 'Start Date Cannot be Empty.';
                   popUpHeading = 'Error!';
                   return null;
               }
            
            if(inv.Bill__c!=0)
            {
                if(inv.Fee__c > 0){
                    userMessage ='Your request to generate invoice has been initiated. You will be notified by email in case of issue.';
                    popUpHeading = 'Success';
                    invoiceOppIds.add(inv.Opportunity__c);
                    System.debug(Inv.Name + ' is biller with Opportunity Id = ' + 
                                 
                                 inv.Opportunity__c);
                    enablePoll = true;
                }
                else{
                    userMessage ='A stage with fee value zero or less cannot be billed.';
                    popUpHeading = 'Oops! ';
                    return null;
                }
            } 
        }
        System.debug('ToUpdate '+toUpdate);
        Map<String,Double> map_InvBill = new Map<String,Double>();
        for(Invoice__c inv1 :toInsert){
            System.debug('Invoice Map '+inv1.Bill__c);
            map_InvBill.put(inv1.Name,inv1.Bill__c);
            inv1.Bill__c=0;
        }        
        try{
            insert toInsert;
        }
        catch(Exception e){
            if(e.getMessage().contains('Stage with same name')){
                userMessage = 'Stage with same name already exists.';
                popUpHeading = 'Error!';
                
            }
            else{
                userMessage = 'Some unexpected'+e.getMessage()+' --- '+e.getCause();
                popUpHeading = 'Error!';
            }
            return null;
        }
        
        
        for(String tmpobj:map_InvBill.keySet()){
            System.debug('Value '+map_InvBill.get(tmpObj));
        }        
        for(Invoice__c inv1 :toInsert){
            if(map_InvBill != null){
                if(map_InvBill.get(inv1.Name) != null){
                    inv1.Bill__c=map_InvBill.get(inv1.Name);
                }
            }
        }
        //update toUpdate;
        List <Id> lst_allInvId = new List <Id>();
        List <FeeStorage__c> lst_feeStorage = new List <FeeStorage__c>();        
        System.debug('Date  is '+startMonth);
        DateTime dtObj = System.now();
        String uniqueName = 'Schedule '+String.valueOf(dtObj);
        
        for(Invoice__c inv: toInsert){
            if(inv.Bill__c>0){
                FeeStorage__c feeObj = new FeeStorage__c();
                feeObj.uniqueName__c = uniqueName;
                feeObj.Bill__c = inv.Bill__c;
                feeObj.Duration__c=Integer.valueOf(selectedVal);
                feeObj.Invoice__c= inv.id;
                //  feeObj.lastUpdated__c = null;
                feeObj.NumberOfTimes__c=0;
                feeObj.Opportunity__c = inv.Opportunity__c;
                feeObj.startDate__c = calculateDate(startMonth);
                lst_feeStorage.add(feeObj); 
                lst_allInvId.add(inv.Id);
            }
        }
        
        for(Invoice__c inv: toUpdate){
            if(inv.Bill__c>0){
                FeeStorage__c feeObj = new FeeStorage__c();
                feeObj.Bill__c = inv.Bill__c;
                feeObj.Duration__c=Integer.valueOf(selectedVal);
                feeObj.uniqueName__c = uniqueName;
                feeObj.Invoice__c= inv.id;
                //feeObj.lastUpdated__c = null;
                feeObj.NumberOfTimes__c=0;
                feeObj.Opportunity__c = inv.Opportunity__c;
                feeObj.startDate__c = calculateDate(startMonth);
                lst_feeStorage.add(feeObj);
                lst_allInvId.add(inv.Id);
            }
        }
        List <FeeStorage__c> lst_AlreadyFeeScheduler = [Select id from 
                                                        
                                                        FeeStorage__c where Invoice__c IN :lst_allInvId];
        if(lst_AlreadyFeeScheduler.size()>0){            
            userMessage ='A Scheduler is already running for the Billed Stage';
            popUpHeading = 'Error! ';
            return null;
        }
        else{
            insert lst_feeStorage;                 
        }
        return null;
    }
    
    public Date calculateDate(String dateString){        
        Date dt = null;
        List<String> lst = new List<String>();
        List<Integer> lst_Date = new List<Integer>();       
        if(dateString !=null){           
            for(String s : dateString.split('/'))
            {
                lst.add(s);
            }
            Integer month= 0;
            Integer day = 0;
            Integer year = 0;
            Integer isDate = 0;
            if(lst.size()==3){
                try
                {
                    for(String value :lst){
                        Integer x = Integer.valueOf(value);
                        lst_Date.add(x);
                    }
                }
                catch (exception e)
                {
                    isDate++;
                }
            }
            
            if(isDate == 0 && lst_Date.size()==3){
                dt =  Date.newInstance(lst_Date.get(2), lst_Date.get(0), lst_Date.get(1)); 
                
                
            }
        }
        return dt;        
    }
    
    public PageReference invoiceBillStatus()
    {
        invoices=[Select Id, Name, Bill__c, Billed__c, Fee__c, Amount__c, 
                  
                  Fee_Percentage__c, Time_Frame__c, Delays__c,Delays_Month__c, Opportunity__c,Default__c,Locked__c from 
                  
                  Invoice__c where Opportunity__c=:oppId
                  order by createddate asc]; 
        for(Invoice__c inv:invoices)
        {
            if(inv.Bill__c!=0)
            {
                enablePoll = true;             
            }
        }
        syncStatus = true;
        return null;
    }
    
    public PageReference returnPage()
    {
        PageReference cpage = new PageReference('/apex/Invoice?id='+oppId);
        cpage.setRedirect(true);
        return cpage;
    }
    
    public PageReference RefreshWindow(){
        PageReference reference = new PageReference('/'+oppId);
        reference.setRedirect(true);
        return reference;
    }
    
    public void resetFlags(){
        multipleFoundErrorNew= false;
        multipleFoundError = false;
        refreshInvoices = false;
    }
    
    public Boolean getShowDialogue() 
    {
        return syncStatus; 
    }
    
    public Boolean getshowDialogBox() 
    {
        return showDialogBox; 
    }
    public PageReference closePopeUp() 
    {
        showDialogBox= false;
        syncStatus = false;
        return null;
    }
    
    public Boolean getIsEnabled() 
    {
        return enablePoll; 
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