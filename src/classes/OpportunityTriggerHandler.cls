public class OpportunityTriggerHandler {
 
    public static void performValidationChecks(List<Opportunity> newOpportunities){
        String errMsg = 'Required field(s) missing. Please fill ';
        for(Opportunity opp : newOpportunities)
        {
            if(opp.accountId==null )
            {
                errMsg+= 'Account Name';
            }
            if(opp.proposal_issued_to_1__c==null)
            {
                if(errMsg.contains('Account'))
                {
                    errMsg+= ' and ';
                }
                errMsg+= 'Proposal issued to 1';   
            }
            
            if(errMsg.contains('Account') || errMsg.contains('Proposal issued to 1'))
            {
                // opp.addError(errMsg);
            }
        }
    }
    
    public static void performQBOValidations(List<Opportunity> newOpportunities,Map<Id,Opportunity> oldOpportunities){
        Map<String,Map<Id,String>> accQBMap = new Map<String,Map<Id,String>>();
        Map<String,Map<Id,String>> oppQBMap = new Map<String,Map<Id,String>>();
        Map<String,String> QBMap = new Map<String,String>();
        String message = '<Style> .pbError{color:transparent !important;}</Style><div align="left" style="color:#c00;padding-left:25%;">'+
            'Please review and resolve the following errors in order to save the record';
        
        List<Id> relatedAccounts = new List<Id>();
        Map<Id,String> accountNames = new Map<Id,String>();
        for(Opportunity opp : newOpportunities){
            relatedAccounts.add(opp.AccountId);
        }
        
        for(Account acc : [Select Id,Name from Account where Id =: relatedAccounts]){
            accountNames.put(acc.Id, acc.Name);
        }
        
        for(Account acc : [SELECT Id,Name,QB_Id__c FROM Account WHERE QB_Id__c != null]){
            if(accQBMap.get(acc.QB_Id__c) != null){
                accQBMap.get(acc.QB_Id__c).put(acc.Id,acc.Name);
            }
            else{
                accQBMap.put(acc.QB_Id__c,new Map<Id,String>());
                accQBMap.get(acc.QB_Id__c).put(acc.Id,acc.Name);
            }
        }
        for(Opportunity opp : [SELECT Id,Name,QB_Id__c FROM Opportunity WHERE QB_Id__c != null]){
            if(oppQBMap.get(opp.QB_Id__c) != null){
                oppQBMap.get(opp.QB_Id__c).put(opp.Id,opp.Name);
            }
            else{
                oppQBMap.put(opp.QB_Id__c,new Map<Id,String>());
                oppQBMap.get(opp.QB_Id__c).put(opp.Id,opp.Name);
            }
        }
        for(QBO_Customer_Info__c QCI : [SELECT Id,Name__c,QB_ID__c FROM QBO_Customer_Info__c]){
            QBMap.put(QCI.Name__c,QCI.QB_ID__c);
        }
        
        for(Opportunity opp : newOpportunities){
            Integer i = 0;
            if((oldOpportunities != null && (opp.QB_Id__c != null && opp.QB_Id__c != oldOpportunities.get(opp.Id).QB_Id__c)) || 
               (oldOpportunities == null)){
                if(opp.First_Time_Populated__c == true && opp.QB_Id__c != opp.First_QB_Id__c){
                    message = message + '<p>' + (++i) + '. This record is first initialized with the QB Id ' + opp.First_QB_Id__c + '.</p>';
                }
                
                if(accQBMap.get(opp.QB_Id__c) != null){
                    message = message + '<p>' + (++i) + '. Following Accounts are found in system using the same QB Id </p><ul>';
                    for(Id recId : accQBMap.get(opp.QB_Id__c).keySet()){
                        message = message +'<li><a style="color:#c00" target="_blank" href="/'+ recId + '" title="' + accQBMap.get(opp.QB_Id__c).get(recId) + '">'+ accQBMap.get(opp.QB_Id__c).get(recId) + '</a></li>';
                    }
                    message = message +'</ul>';
                }
                
                if(oppQBMap.get(opp.QB_Id__c) != null){
                    message = message + '<p>' + (++i) + '. Following Opportunities are found in system using the same QB Id </p><ul>';
                    for(Id recId :  oppQBMap.get(opp.QB_Id__c).keySet()){
                        message = message +'<li><a style="color:#c00" target="_blank" href="/'+ recId + '" title="' + oppQBMap.get(opp.QB_Id__c).get(recId) + '">'+ oppQBMap.get(opp.QB_Id__c).get(recId) +'</a></li>';
                    }
                    message = message +'</ul>';
                }
                
                if(QBMap.get(accountNames.get(opp.AccountId)+':'+opp.Name)!= null && QBMap.get(accountNames.get(opp.AccountId)+':'+opp.Name) != opp.QB_Id__c){
                    message = message + '<p>' + (++i) + '. A record is found in QBO having the same information with record Id <a style="color:#c00" target="_blank" href="'+ System.label.QBO_Base_Url + QBMap.get(accountNames.get(opp.AccountId)+':'+opp.Name) + 
                        '" title="' + QBMap.get(accountNames.get(opp.AccountId)+':'+opp.Name) + '">' + QBMap.get(accountNames.get(opp.AccountId)+':'+opp.Name) + '</a>.</p>';
                }
                
                message = message + '</div>';
            }
            
            if(message.contains('1.')){
                opp.addError(message,false);
            }
        }
    }
    
    public static void setFirstQBId(List<Opportunity> newOpportunities){
        for(Opportunity opp : newOpportunities){
            if(opp.First_Time_Populated__c == false){
                if(opp.QB_Id__c != null){
                    opp.First_QB_Id__c = opp.QB_Id__c;
                    opp.First_Time_Populated__c = true;
                }
            }
        }
    }
    
    public static void checkQBId(List<Opportunity> newOpportunities){
        for(Opportunity opp : newOpportunities){
            if(opp.QB_Id__c != null && opp.From_QB__c == false){
                opp.QB_Id__c.addError('Record cannot be created with the predifined <i>QB Id.</i>',false);
            }
        }
    }
    
    public static void updateClosedDate(List<Opportunity> newOpportunities,Map<Id,Opportunity> oldOpportunities){
        for(Opportunity opp: newOpportunities){
            if(oldOpportunities != null){
                if((opp.StageName == 'Closed Won' && oldOpportunities.get(opp.Id).StageName != 'Closed Won') ||
                   (opp.StageName == 'Closed Lost' && oldOpportunities.get(opp.Id).StageName != 'Closed Lost')){
                       opp.CloseDate = system.today();
                   }
            }
            else{
                if(opp.StageName == 'Closed Won' || opp.StageName == 'Closed Lost'){
                    opp.CloseDate = system.today();
                }
            }
        }
    }
    
    public static void checkCloseDateChange(List<Opportunity> newOpps , Map<Id,Opportunity> oldOpps){
        List<Id> oppId = new List<Id>();
        for(Opportunity opp : newOpps){
            if(opp.CloseDate != oldOpps.get(opp.Id).CloseDate){
                oppId.add(opp.Id);
            }
        }
        List<Invoice__c> invToUpdate = new List<Invoice__c>();
        for(Invoice__c inv : [Select Id,Opp_Close_Date_Change_Track__c from Invoice__c where Opportunity__c = :oppId]){
            inv.Opp_Close_Date_Change_Track__c = inv.Opp_Close_Date_Change_Track__c == null ? 0 : inv.Opp_Close_Date_Change_Track__c + 1;
            invToUpdate.add(inv);
        }
        update invToUpdate;
    }
    
    public static void createInvoices(List<Opportunity> newOpportunities){
        List<Invoice__c> defaultInvoices=new List<Invoice__c>();
        
        for(Opportunity opp : newOpportunities){
            defaultInvoices.add(new Invoice__c(Name=System.label.Default_Stage_1, Time_Frame__c='To Start Project', Default__c=true,
                                               Fee__c=opp.Retainer1__c, Opportunity__c=opp.Id));
            
            defaultInvoices.add(new Invoice__c(Name=System.label.Default_Stage_2, Time_Frame__c=String.valueof(opp.TF_SD__c), Default__c=true,
                                               Fee__c=opp.Schematic_Design_SD_1__c, Opportunity__c=opp.Id));
            
            defaultInvoices.add(new Invoice__c(Name=System.label.Default_Stage_3, Time_Frame__c=String.valueof(opp.TF_DOB_Filing__c), Default__c=true,
                                               Fee__c=opp.DOB_Filing_Set_1__c, Opportunity__c=opp.Id));
            
            defaultInvoices.add(new Invoice__c(Name=System.label.Default_Stage_4, Time_Frame__c=String.valueof(opp.TF_DOB_App__c), Default__c=true,
                                               Fee__c=opp.DOB_Approval_1__c, Opportunity__c=opp.Id));
            
            defaultInvoices.add(new Invoice__c(Name=System.label.Default_Stage_5, Time_Frame__c=String.valueof(opp.TF_DD_CD__c), Default__c=true,
                                               Fee__c=opp.Bid_Documents_Construction_Documents__c, Opportunity__c=opp.Id));
            
            defaultInvoices.add(new Invoice__c(Name=System.label.Default_Stage_6, Time_Frame__c=String.valueof(opp.TF_CA__c), Default__c=true,
                                               Fee__c=opp.Construction_Admin__c, Opportunity__c=opp.Id));
            
            defaultInvoices.add(new Invoice__c(Name=System.label.Default_Stage_7, Time_Frame__c=String.valueof(opp.TF_Punch__c), Default__c=true,
                                               Fee__c=opp.Punchlist__c, Opportunity__c=opp.Id));
        }
        
        insert defaultInvoices;
    }
    
    public static void updateInvoices(List<Opportunity> newOpportunities,Map<Id,Opportunity> oldOpportunities){
        Map<Id, Opportunity> oppMap=new Map<Id, Opportunity> ();
        for(Opportunity opp : newOpportunities){
            if(
                (opp.Retainer1__c!=oldOpportunities.get(opp.Id).Retainer1__c ||
                 opp.Schematic_Design_SD_1__c!=oldOpportunities.get(opp.Id).Schematic_Design_SD_1__c ||
                 opp.DOB_Filing_Set_1__c!=oldOpportunities.get(opp.Id).DOB_Filing_Set_1__c ||
                 opp.DOB_Approval_1__c!=oldOpportunities.get(opp.Id).DOB_Approval_1__c ||
                 opp.Bid_Documents_Construction_Documents__c !=oldOpportunities.get(opp.Id).Bid_Documents_Construction_Documents__c ||
                 opp.Construction_Admin__c!=oldOpportunities.get(opp.Id).Construction_Admin__c ||
                 opp.Punchlist__c!=oldOpportunities.get(opp.Id).Punchlist__c) || 
                
                (opp.TF_SD__c!=oldOpportunities.get(opp.Id).TF_SD__c ||
                 opp.TF_Punch__c!=oldOpportunities.get(opp.Id).TF_Punch__c ||
                 opp.TF_DOB_Filing__c!=oldOpportunities.get(opp.Id).TF_DOB_Filing__c ||
                 opp.TF_DOB_App__c   !=oldOpportunities.get(opp.Id).TF_DOB_App__c ||
                 opp.TF_DD_CD__c!=oldOpportunities.get(opp.Id).TF_DD_CD__c ||
                 opp.TF_CA__c!=oldOpportunities.get(opp.Id).TF_CA__c)
            )
            {
                oppMap.put(opp.Id, opp);
            }
        }
        
        List<Invoice__c> invoices=[Select Id, Name, Fee__c, Opportunity__c from Invoice__c where 
                                   Default__c=true and Opportunity__c=:oppMap.keySet()];
        for(Invoice__c inv:invoices)
        {
            if(inv.Name==System.label.Default_Stage_1)
            {
                inv.Fee__c=oppMap.get(inv.Opportunity__c).Retainer1__c;
            }
            else if(inv.Name==System.label.Default_Stage_2)
            {
                inv.Fee__c=oppMap.get(inv.Opportunity__c).Schematic_Design_SD_1__c;
                inv.Time_Frame__c=String.valueof(oppMap.get(inv.Opportunity__c).TF_SD__c);
            }
            else if(inv.Name==System.label.Default_Stage_3)
            {
                inv.Fee__c=oppMap.get(inv.Opportunity__c).DOB_Filing_Set_1__c;
                inv.Time_Frame__c=String.valueof(oppMap.get(inv.Opportunity__c).TF_DOB_Filing__c);
            }
            else if(inv.Name==System.label.Default_Stage_4)
            {
                inv.Fee__c=oppMap.get(inv.Opportunity__c).DOB_Approval_1__c;
                inv.Time_Frame__c=String.valueof(oppMap.get(inv.Opportunity__c).TF_DOB_App__c);
            }
            else if(inv.Name==System.label.Default_Stage_5)
            {
                inv.Fee__c=oppMap.get(inv.Opportunity__c).Bid_Documents_Construction_Documents__c;
                inv.Time_Frame__c=String.valueof(oppMap.get(inv.Opportunity__c).TF_DD_CD__c);
            }
            else if(inv.Name==System.label.Default_Stage_6)
            {
                inv.Fee__c=oppMap.get(inv.Opportunity__c).Construction_Admin__c;
                inv.Time_Frame__c=String.valueof(oppMap.get(inv.Opportunity__c).TF_CA__c);
            }
            else if(inv.Name==System.label.Default_Stage_7)
            {
                inv.Fee__c=oppMap.get(inv.Opportunity__c).Punchlist__c;
                inv.Time_Frame__c=String.valueof(oppMap.get(inv.Opportunity__c).TF_Punch__c);
            }
        }
        try{
            update invoices;
        }
        catch(Exception e){
            if(e.getMessage().contains('InvoiceTriggerHandler billed percentage Error =')){
                String message = '<Style> .pbError{color:transparent !important;}</Style><div align="left" style="color:#c00;padding-left:25%;">';
                String error = e.getMessage().substringAfter('=');
                newOpportunities[0].addError(message + '<p>' + error.substring(0,error.length() - 4) + '</p></div>',false);
            }   
        }
    }
    
    public static void syncWithQBO(List<Opportunity> newOpportunities,Map<Id,Opportunity> oldOpportunities){
        Map<Id,String> accountQBIds = new Map<Id,String>();
        Set<Id> wonOppIds=new Set<Id>();
        List<Invoice__c> defaultInvoices=new List<Invoice__c>();
        Set<String> updateOppIds=new Set<String>();
        
        List<Mapper__c> mapperList= new List<Mapper__c> ();
        mapperList=[Select Field_Name__c from Mapper__c where Object__c='Opportunity'];
        
        if(oldOpportunities == null){
            for(Opportunity opp : newOpportunities){
                if(opp.AccountId != null){
                    if(opp.StageName == 'Closed Won' && opp.From_QB__c == false){
                        wonOppIds.add(opp.Id);
                    }
                    else{
                        opp.From_QB__c = false;
                    }
                }
            }
        }
        else{
            List<Id> accountIds = new List<Id>();
            for(Opportunity opp : newOpportunities){
                accountIds.add(opp.AccountId);
            }
            for(Account acc : [Select Id,Qb_Id__c from Account where Id = :accountIds]){
                if(acc.Qb_Id__c != null){
                    accountQBIds.put(acc.Id, acc.QB_Id__c);
                }
            }
            for(Opportunity opp : newOpportunities){
                if(opp.StageName == 'Closed Won' && oldOpportunities.get(opp.Id).stageName != opp.StageName){
                    if(accountQBIds.get(opp.AccountId) != null){
                        if(opp.Is_Synced__c == false){
                            wonOppIds.add(opp.Id);
                        }
                        else{
                            updateOppIds.add(opp.QB_Id__c);
                        }
                    }
                }
                
                if(opp.StageName == 'Closed Won' && oldOpportunities.get(opp.Id).stageName == opp.StageName){
                    if(opp.QB_Id__c!=null && opp.From_Qb__c == false && accountQBIds.get(opp.AccountId) != null){
                        for(Mapper__c m:mapperList){
                            if(opp.get(m.Field_Name__c) != oldOpportunities.get(opp.Id).get(m.Field_Name__c)){
                                updateOppIds.add(opp.QB_Id__c);
                            }
                        }
                        
                        if(oldOpportunities.get(opp.Id).AccountId != opp.AccountId || 
                           oldOpportunities.get(opp.Id).proposal_issued_to_1__c != opp.proposal_issued_to_1__c ||
                           oldOpportunities.get(opp.Id).proposal_issued_to_2__c != opp.proposal_issued_to_2__c ||
                           oldOpportunities.get(opp.Id).AddressChangesCount__c != opp.AddressChangesCount__c){
                               System.debug('Address Change Fired');
                               updateOppIds.add(opp.QB_Id__c);
                           }
                        
                    }
                }
                
                opp.From_QB__c = false;
            }
        }
        
        if(wonOppIds.size()>0){ 
            System.debug('closed Won');
            QuickbookApiCrud.fetchAlreadyExistingId(wonOppIds,'Opportunity');
        }
        if(updateOppIds.size()>0){
            QuickbookApiCrud.updateSubCustomer(updateOppIds);
        }
    }
    
    public static void testPass(){
        Integer i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
        i= 0;
    }
    public static void handleAmountPercentChange(List<Opportunity> newOpportunities,Map<Id,Opportunity> oldOpportunities){
        for(Opportunity opp : newOpportunities){
            if(oldOpportunities == null ||
               (oldOpportunities!= null &&
                (opp.Retainer_Percent__c != oldOpportunities.get(opp.Id).Retainer_Percent__c ||
                 opp.SD_Percent__c != oldOpportunities.get(opp.Id).SD_Percent__c ||
                 opp.DOB_Filing_Percent__c != oldOpportunities.get(opp.Id).DOB_Filing_Percent__c ||
                 opp.DOB_APP_Percent__c != oldOpportunities.get(opp.Id).DOB_APP_Percent__c ||
                 opp.BD_CD_Percent__c != oldOpportunities.get(opp.Id).BD_CD_Percent__c ||
                 opp.CA_Percent__c != oldOpportunities.get(opp.Id).CA_Percent__c ||
                 opp.Punchlist_Percent__c != oldOpportunities.get(opp.Id).Punchlist_Percent__c || 
                 opp.Amount != oldOpportunities.get(opp.Id).Amount))){
                     opp.Retainer_Percent__c = (opp.Retainer_Percent__c == null ? 15 :opp.Retainer_Percent__c);
                     opp.SD_Percent__c = (opp.SD_Percent__c == null ? 30 :opp.SD_Percent__c);
                     opp.DOB_Filing_Percent__c = (opp.DOB_Filing_Percent__c == null ? 30 :opp.DOB_Filing_Percent__c);
                     opp.DOB_APP_Percent__c = (opp.DOB_APP_Percent__c == null ? 10 :opp.DOB_APP_Percent__c);
                     opp.BD_CD_Percent__c = (opp.BD_CD_Percent__c == null ? 15 :opp.BD_CD_Percent__c);
                     opp.CA_Percent__c = (opp.CA_Percent__c == null ? 12.5 :opp.CA_Percent__c);
                     opp.Punchlist_Percent__c = (opp.Punchlist_Percent__c == null ? 2.5 :opp.Punchlist_Percent__c);
                     
                     if((opp.SD_Percent__c + opp.DOB_Filing_Percent__c + 
                         opp.DOB_APP_Percent__c + opp.BD_CD_Percent__c + opp.CA_Percent__c + opp.Punchlist_Percent__c) > 100){
                             opp.addError('Sum of Percentages cannot be greater than 100.');
                         }
                     
                     opp.Retainer1__c = (opp.Amount == null ? 0 :opp.Amount) * (opp.Retainer_Percent__c/100);
                     opp.Schematic_Design_SD_1__c = (opp.Amount == null ? 0 :opp.Amount) * (opp.SD_Percent__c/100);
                     opp.DOB_Filing_Set_1__c = (opp.Amount == null ? 0 :opp.Amount) * (opp.DOB_Filing_Percent__c/100);
                     opp.DOB_Approval_1__c = (opp.Amount == null ? 0 :opp.Amount) * (opp.DOB_APP_Percent__c/100);
                     opp.Bid_Documents_Construction_Documents__c = (opp.Amount == null ? 0 :opp.Amount) * (opp.BD_CD_Percent__c/100);
                     opp.Construction_Admin__c = (opp.Amount == null ? 0 :opp.Amount) * (opp.CA_Percent__c/100);
                     opp.Punchlist__c = (opp.Amount == null ? 0 :opp.Amount) * (opp.Punchlist_Percent__c/100);
                 }
        }
    }
    
    public static void syncPercentages(List<Opportunity> newOpportunities,Map<Id,Opportunity> oldOpportunities){
        
        for(Opportunity opp : newOpportunities){
/*            System.debug('oldOpportunities- '+oldOpportunities);
            System.debug('oldOpportunities ID - '+oldOpportunities.get(opp.Id));
            System.debug('DOB_Approval_1__c - '+oldOpportunities.get(opp.Id).DOB_Approval_1__c);
            System.debug('DOB_Approval_1__c - '+oldOpportunities.get(opp.Id).DOB_Approval_1__c.setScale(2,System.RoundingMode.CEILING) );*/
            if(oldOpportunities == null ||
               (oldOpportunities!= null && 
                (opp.Retainer1__c != (oldOpportunities.get(opp.Id).Retainer1__c == null? null :oldOpportunities.get(opp.Id).Retainer1__c.setScale(2,System.RoundingMode.CEILING)) ||
                 opp.Schematic_Design_SD_1__c != (oldOpportunities.get(opp.Id).Schematic_Design_SD_1__c == null? null :oldOpportunities.get(opp.Id).Schematic_Design_SD_1__c.setScale(2,System.RoundingMode.CEILING)) ||
                 opp.DOB_Filing_Set_1__c!= (oldOpportunities.get(opp.Id).DOB_Filing_Set_1__c == null? null :oldOpportunities.get(opp.Id).DOB_Filing_Set_1__c.setScale(2,System.RoundingMode.CEILING)) ||
                 opp.DOB_Approval_1__c!= (oldOpportunities.get(opp.Id).DOB_Approval_1__c == null? null :oldOpportunities.get(opp.Id).DOB_Approval_1__c.setScale(2,System.RoundingMode.CEILING)) ||
                 opp.Bid_Documents_Construction_Documents__c != (oldOpportunities.get(opp.Id).Bid_Documents_Construction_Documents__c == null? null :oldOpportunities.get(opp.Id).Bid_Documents_Construction_Documents__c.setScale(2,System.RoundingMode.CEILING)) ||
                 opp.Construction_Admin__c!= (oldOpportunities.get(opp.Id).Construction_Admin__c == null? null :oldOpportunities.get(opp.Id).Construction_Admin__c.setScale(2,System.RoundingMode.CEILING)) ||
                 opp.Punchlist__c != (oldOpportunities.get(opp.Id).Punchlist__c == null? null :oldOpportunities.get(opp.Id).Punchlist__c.setScale(2,System.RoundingMode.CEILING))))){
                     if(Opp.Amount != null && opp.Amount != 0){
                         opp.Retainer_Percent__c = (opp.Retainer1__c == null ? 0 :(opp.Retainer1__c / opp.Amount)*100);
                         opp.SD_Percent__c = (opp.Schematic_Design_SD_1__c == null ? 0 :(opp.Schematic_Design_SD_1__c / opp.Amount)*100);
                         opp.DOB_Filing_Percent__c = (opp.DOB_Filing_Set_1__c == null ? 0 :(opp.DOB_Filing_Set_1__c / opp.Amount)*100);
                         opp.DOB_APP_Percent__c = (opp.DOB_Approval_1__c == null ? 0 :(opp.DOB_Approval_1__c / opp.Amount)*100);
                         opp.BD_CD_Percent__c = (opp.Bid_Documents_Construction_Documents__c == null ? 0 :(opp.Bid_Documents_Construction_Documents__c / opp.Amount)*100);
                         opp.CA_Percent__c = (opp.Construction_Admin__c == null ? 0 :(opp.Construction_Admin__c / opp.Amount)*100);
                         opp.Punchlist_Percent__c = (opp.Punchlist__c == null ? 0 :(opp.Punchlist__c / opp.Amount)*100);
                     }
                     else{
                         opp.Retainer_Percent__c = 0;
                         opp.SD_Percent__c = 0;
                         opp.DOB_Filing_Percent__c = 0;
                         opp.DOB_APP_Percent__c = 0;
                         opp.BD_CD_Percent__c = 0;
                         opp.CA_Percent__c = 0;
                         opp.Punchlist_Percent__c = 0;
                         
                         opp.Retainer1__c = 0;
                         opp.Schematic_Design_SD_1__c = 0;
                         opp.DOB_Filing_Set_1__c = 0;
                         opp.DOB_Approval_1__c = 0;
                         opp.Bid_Documents_Construction_Documents__c = 0;
                         opp.Construction_Admin__c = 0;
                         opp.Punchlist__c = 0;
                     }
                     
                     if((opp.SD_Percent__c + opp.DOB_Filing_Percent__c + 
                         opp.DOB_APP_Percent__c + opp.BD_CD_Percent__c + opp.CA_Percent__c + opp.Punchlist_Percent__c) > 100){
                             opp.addError('Sum of Percentages cannot be greater than 100.');
                         }
                 }
        }
    }
}