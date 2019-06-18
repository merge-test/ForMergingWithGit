global class ExistingRecordScript implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('Select Id, TF_SD__c, TF_DOB_Filing__c, TF_DOB_App__c, TF_DD_CD__c, TF_CA__c, TF_Punch__c, Retainer1__c,'+
                                        'Schematic_Design_SD_1__c, DOB_Filing_Set_1__c,'+
                                        'DOB_Approval_1__c, Bid_Documents_Construction_Documents__c, Construction_Admin__c, Punchlist__c from '+
                                        'Opportunity where Fee_Schedule_Stage_Count__c=0');
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> records){
        
        List<Invoice__c> defaultInvoices=new List<Invoice__c>();
        
        for(Opportunity opp: records) {
            
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
    
    global void finish(Database.BatchableContext BC){
    }
    
}