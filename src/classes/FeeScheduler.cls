global class FeeScheduler implements Schedulable{
    
    global void execute(SchedulableContext SC) {
        scheduleClassMethod();
    }
    
    public static void scheduleClassMethod(){
        List <FeeStorage__c> lst_FeeStorage = [SELECT Id, Name, Opportunity__c,uniqueName__c, Invoice__c, Bill__c, NumberOfTimes__c, startDate__c,  Duration__c FROM FeeStorage__c where lastUpdated__c <= TODAY ];
        List <FeeStorage__c> lst_FeeToUpdate = new List<FeeStorage__c>();
        List <Id> lst_InvoiceId = new List <Id>();
        Map<Id,String> map_OppUniqueName = new Map <Id,String>(); 
        List<FeeStorage__c> lst_toDeleteFeeStorage = new List<FeeStorage__c>();
        List<FeeStorage__c> lst_toUpdateFeeStorage = new List<FeeStorage__c>();
        /*for(FeeStorage__c feeObj:lst_FeeStorage){
            map_OppUniqueName.put(feeObj.Opportunity__c,feeObj.uniqueName__c);
        }*/
        for(FeeStorage__c feeObj:lst_FeeStorage){
            Date startDate = feeObj.startDate__c;
            Integer val = Integer.valueOf(feeObj.NumberOfTimes__c);
            Date updateDate = startDate.addMonths(val) ;
            DateTime dt = System.now() ;
            Date currentDate = dt.Date();
            Integer duplicateOpportunityId = 0;
            boolean dueNow = currentDate.isSameDay(updateDate);
            System.debug('Curr '+currentDate+' Start'+startDate+' dueDate'+dueNow);
            if(dueNow == true){
                if(map_OppUniqueName.get(feeObj.Opportunity__c) != null){
                    if(map_OppUniqueName.get(feeObj.Opportunity__c).equals(feeObj.uniqueName__c)){       
                    }
                    else{
                        duplicateOpportunityId++;
                    }
                }
          
                
                if(duplicateOpportunityId == 0){
                    lst_FeeToUpdate.add(feeObj);
                    lst_InvoiceId.add(feeObj.Invoice__c);
                    feeObj.NumberOfTimes__c = feeObj.NumberOfTimes__c +1 ;
                    if(feeObj.NumberOfTimes__c >= feeObj.Duration__c){
                        lst_toDeleteFeeStorage.add(feeObj);
                    }
                    else{
                        lst_toUpdateFeeStorage.add(feeObj);   
                    }   
                      map_OppUniqueName.put(feeObj.Opportunity__c,feeObj.uniqueName__c);
                }
            }
        }
        
        Set<Id> set_oppId = new Set <Id>(); 
        Map <Id,Invoice__c> map_Invoice = new Map<Id,Invoice__c>([SELECT Id, Bill__c, Fee__c, Amount__c, Billed__c, Opportunity__c FROM Invoice__c where Id IN : lst_InvoiceId]); 
        for(FeeStorage__c feeObj: lst_FeeToUpdate){
            if(map_Invoice != null){
                if(map_Invoice.get(feeObj.Invoice__c) !=null){
                    map_Invoice.get(feeObj.Invoice__c).Bill__c = feeObj.Bill__c;
                }   
            }
        }

        List<Invoice__c> lst_Inv = new List <Invoice__c>();
        for(Invoice__c invObj: map_Invoice.values()) {
            lst_Inv.add(invObj);
            set_oppId.add(invObj.Opportunity__c);
        }
        update lst_toUpdateFeeStorage;
        delete lst_toDeleteFeeStorage;
        update lst_Inv;
        System.debug('Lst lst_toUpdateFeeStorage '+lst_toUpdateFeeStorage);        
        System.debug('Lst lst_toDeleteFeeStorage '+lst_toDeleteFeeStorage);        
        System.debug('Lst Inv '+lst_Inv);        
        
        if(set_oppId.size() > 0){
            System.debug('Future call Invoice Send');
            QuickbookApiCrud.sendInvoice(set_oppId,null,0);
            System.debug('Future call ended');
        }
    }

}