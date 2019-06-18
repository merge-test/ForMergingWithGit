public class InvoiceTriggerHandler {
    public class PreviousDelays{
        public Decimal retainerDelays {get;set;}
        public Decimal schematicDelays {get;set;}
        public Decimal dobFilDelays {get;set;}
        public Decimal dobAppDelays {get;set;}
        public Decimal bidDocsDelays {get;set;}
        public Decimal constrAdminDelays {get;set;}
        public Decimal punchDelays {get;set;}
        
        public PreviousDelays(){
            retainerDelays = 0;
            schematicDelays = 0;
            dobFilDelays = 0;
            dobAppDelays = 0;
            bidDocsDelays = 0;
            constrAdminDelays = 0;
            punchDelays = 0;
        }
    }
    
    public static void handleDefaultCheck(List<Invoice__c> newInvoices,Map<Id,Invoice__c> oldInvoices){
        List<String> defaultStages = new List<String>();
        defaultStages.add(System.label.Default_Stage_1);
        defaultStages.add(System.label.Default_Stage_2);
        defaultStages.add(System.label.Default_Stage_3);
        defaultStages.add(System.label.Default_Stage_4);
        defaultStages.add(System.label.Default_Stage_5);
        defaultStages.add(System.label.Default_Stage_6);
        defaultStages.add(System.label.Default_Stage_7);
        
        if(oldInvoices == null){
            for(Invoice__c inv : newInvoices){
                if(defaultStages.contains(inv.Name)){
                    inv.Default__c = true;
                }
            }
        }
        else{
            for(Invoice__c inv : newInvoices){
                if(inv.Name != oldInvoices.get(inv.Id).Name){
                    if(inv.Default__c == true && defaultStages.contains(inv.Name) == false){
                        inv.Default__c = false;
                    }
                    else if(inv.Default__c == false && defaultStages.contains(inv.Name) == true){
                        inv.Default__c = true;
                    }
                }
            }
        }
    }
    
    public static void preventNullValues(List<Invoice__c> newInvoices){
        for(Invoice__c invoice : newInvoices){
            invoice.Fee__c = ((invoice.Fee__c == null)?0:invoice.Fee__c);
        }
    }
    
    public static void populateTimeAndDelays(List<Invoice__c> newInvoices){
        for(Invoice__c invoice : newInvoices){
            if(invoice.Delays_Month__c == null){
                invoice.Delays_Month__c = 0;
            }
            if(invoice.Time_Frame__c == null ){
                invoice.Time_Frame__c = '0';
            }
            
            if(invoice.Name.equals('Retainer')){
                invoice.Time_Frame__c = '0';
            }                
        }
    }
    
    public static void preventDuplicateNames(List<Invoice__c> newInvoices){
        Map<String,Boolean> duplicateCheckNew = new Map<String,Boolean>();
        List<Id> oppIds = new List<Id>();
        List<Id> invIds = new List<Id>();
        for(Invoice__c inv : newInvoices){
            oppIds.add(inv.Opportunity__c);
            invIds.add(inv.Id);
            if(duplicateCheckNew.get(inv.Opportunity__c+''+inv.Name) != null && duplicateCheckNew.get(inv.Opportunity__c+''+inv.Name) == false){
                duplicateCheckNew.put(inv.Opportunity__c+''+inv.Name,true);
            }
            else{
                duplicateCheckNew.put(inv.Opportunity__c+''+inv.Name,false);
            }
        }
        
        Map<String,Boolean> duplicateCheckExisting = new Map<String,Boolean>();
        for(Invoice__c inv : [SELECT Id,Name,Opportunity__c FROM Invoice__c where Opportunity__c = :oppIds and Id != :invIds]){    
            duplicateCheckExisting.put(inv.Opportunity__c+''+inv.Name,true);
        }
        
        for(Invoice__c inv : newInvoices){
            if((duplicateCheckExisting != null && duplicateCheckExisting.get(inv.Opportunity__c+''+inv.Name) == true) || 
               (duplicateCheckNew != null && duplicateCheckNew.get(inv.Opportunity__c+''+inv.Name) == true)){
                   inv.addError('Stage with same name already exists.');
               }
        }
    }
    
    public static void calculateDates(List<Invoice__c> newInvoices){
        List<Id> oppIds = new List<Id>();
        List<Id> oppsOfNotDefaultInvoices = new List<Id>();
        Map<Id,Map<String,Invoice__c>> defaultInvoices = new Map<Id,Map<String,Invoice__c>>();
        Map<Id,Map<String,Invoice__c>> othersDefaultInvoices = new Map<Id,Map<String,Invoice__c>>();
        for(Invoice__c inv : newInvoices){
            oppIds.add(inv.Opportunity__c);
            if(inv.Default__c){
                if(defaultInvoices.get(inv.Opportunity__c) != null){
                    defaultInvoices.get(inv.Opportunity__c).put(inv.Name,inv);
                }
                else{
                    defaultInvoices.put(inv.Opportunity__c,new Map<String,Invoice__c>());
                    defaultInvoices.get(inv.Opportunity__c).put(inv.Name,inv);
                }
            }
            else{
                oppsOfNotDefaultInvoices.add(inv.Opportunity__c);
            }
        }
        
        for(Invoice__c inv : [SELECT Excpected_Billing_Date__c,Default__c, Id, Name, Delays__c,Delays_Month__c,Time_Frame__c, Opportunity__c FROM Invoice__c where Opportunity__c = :oppsOfNotDefaultInvoices]){
            if(inv.Default__c){
                if(othersDefaultInvoices.get(inv.Opportunity__c) != null){
                    othersDefaultInvoices.get(inv.Opportunity__c).put(inv.Name,inv);
                }
                else{
                    othersDefaultInvoices.put(inv.Opportunity__c,new Map<String,Invoice__c>());
                    othersDefaultInvoices.get(inv.Opportunity__c).put(inv.Name,inv);
                }
            }
        }
        
        Map<Id,Opportunity> relatedOpportunities = new Map<Id,Opportunity>([Select Id,CloseDate,TF_SD__c, TF_DOB_Filing__c, TF_DOB_App__c, TF_DD_CD__c,
                                                                            TF_CA__c, TF_Punch__c from Opportunity where Id = :oppIds]);
        for(Invoice__c inv : newInvoices){
            inv.Excpected_Billing_Date__c = getBillingDate(inv,relatedOpportunities.get(inv.Opportunity__c),defaultInvoices,othersDefaultInvoices,true);
        }
        
    }
    
    public static PreviousDelays getPreviousDelays(Boolean defaultInv,Map<String,Invoice__c> defaultInvoices, Map<String,Invoice__c> othersDefaultInvoices){
        PreviousDelays delays = new PreviousDelays();
        
        if(defaultInv){
            if(defaultInvoices == null){
                return delays;
            }
            delays.retainerDelays = defaultInvoices.get('Retainer') != null ? (defaultInvoices.get('Retainer').Delays_Month__c):0;
            
            delays.schematicDelays = defaultInvoices.get('Schematic Design') != null ? ((defaultInvoices.get('Schematic Design').Delays_Month__c) + 
                                                                                        (defaultInvoices.get('Schematic Design').Time_Frame__c == null?0: Integer.valueOf(defaultInvoices.get('Schematic Design').Time_Frame__c))):0;
            
            delays.dobFilDelays = defaultInvoices.get('DOB Filing') != null ? ((defaultInvoices.get('DOB Filing').Delays_Month__c) + 
                                                                               (defaultInvoices.get('DOB Filing').Time_Frame__c == null?0: Integer.valueOf(defaultInvoices.get('DOB Filing').Time_Frame__c))):0;
            
            delays.dobAppDelays = defaultInvoices.get('DOB Approval') != null ? ((defaultInvoices.get('DOB Approval').Delays_Month__c) + 
                                                                                 (defaultInvoices.get('DOB Approval').Time_Frame__c == null?0: Integer.valueOf(defaultInvoices.get('DOB Approval').Time_Frame__c))):0;
            
            delays.bidDocsDelays = defaultInvoices.get('Bid Documents') != null ? ((defaultInvoices.get('Bid Documents').Delays_Month__c) + 
                                                                                   (defaultInvoices.get('Bid Documents').Time_Frame__c == null?0: Integer.valueOf(defaultInvoices.get('Bid Documents').Time_Frame__c))):0;
            
            delays.constrAdminDelays = defaultInvoices.get('Construction Admin') != null ? ((defaultInvoices.get('Construction Admin').Delays_Month__c) + 
                                                                                            (defaultInvoices.get('Construction Admin').Time_Frame__c == null?0: Integer.valueOf(defaultInvoices.get('Construction Admin').Time_Frame__c))):0;
            
            delays.punchDelays = defaultInvoices.get('Punchlist') != null ? ((defaultInvoices.get('Punchlist').Delays_Month__c) + 
                                                                             (defaultInvoices.get('Punchlist').Time_Frame__c == null?0: Integer.valueOf(defaultInvoices.get('Punchlist').Time_Frame__c))):0;
        }
        else{
            if(othersDefaultInvoices == null){
                return delays;
            }
            delays.retainerDelays = othersDefaultInvoices.get('Retainer') != null ? (othersDefaultInvoices.get('Retainer').Delays_Month__c):0;
            
            delays.schematicDelays = othersDefaultInvoices.get('Schematic Design') != null ? ((othersDefaultInvoices.get('Schematic Design').Delays_Month__c) + 
                                                                                              (othersDefaultInvoices.get('Schematic Design').Time_Frame__c == null?0: Integer.valueOf(othersDefaultInvoices.get('Schematic Design').Time_Frame__c))):0;
            
            delays.dobFilDelays = othersDefaultInvoices.get('DOB Filing') != null ? ((othersDefaultInvoices.get('DOB Filing').Delays_Month__c) + 
                                                                                     (othersDefaultInvoices.get('DOB Filing').Time_Frame__c == null?0: Integer.valueOf(othersDefaultInvoices.get('DOB Filing').Time_Frame__c))):0;
            
            delays.dobAppDelays = othersDefaultInvoices.get('DOB Approval') != null ? ((othersDefaultInvoices.get('DOB Approval').Delays_Month__c) + 
                                                                                       (othersDefaultInvoices.get('DOB Approval').Time_Frame__c == null?0: Integer.valueOf(othersDefaultInvoices.get('DOB Approval').Time_Frame__c))):0;
            
            delays.bidDocsDelays = othersDefaultInvoices.get('Bid Documents') != null ? ((othersDefaultInvoices.get('Bid Documents').Delays_Month__c) + 
                                                                                         (othersDefaultInvoices.get('Bid Documents').Time_Frame__c == null?0: Integer.valueOf(othersDefaultInvoices.get('Bid Documents').Time_Frame__c))):0;
            
            delays.constrAdminDelays = othersDefaultInvoices.get('Construction Admin') != null ? ((othersDefaultInvoices.get('Construction Admin').Delays_Month__c) + 
                                                                                                  (othersDefaultInvoices.get('Construction Admin').Time_Frame__c == null?0: Integer.valueOf(othersDefaultInvoices.get('Construction Admin').Time_Frame__c))):0;
            
            delays.punchDelays = othersDefaultInvoices.get('Punchlist') != null ? ((othersDefaultInvoices.get('Punchlist').Delays_Month__c) + 
                                                                                   (othersDefaultInvoices.get('Punchlist').Time_Frame__c == null?0: Integer.valueOf(othersDefaultInvoices.get('Punchlist').Time_Frame__c))):0;
        }
        return delays;
    }
    
    public static PreviousDelays getPreviousDelays(Map<String,Invoice__c> defaultInvoices){
        PreviousDelays delays = new PreviousDelays();
        if(defaultInvoices == null){
            return delays;
        }
        
        delays.retainerDelays = defaultInvoices.get('RetainerDefault') != null ? (defaultInvoices.get('RetainerDefault').Delays_Month__c):0;
        
        delays.schematicDelays = defaultInvoices.get('Schematic DesignDefault') != null ? ((defaultInvoices.get('Schematic DesignDefault').Delays_Month__c) + 
                                                                                           (defaultInvoices.get('Schematic DesignDefault').Time_Frame__c == null?0: Integer.valueOf(defaultInvoices.get('Schematic DesignDefault').Time_Frame__c))):0;
        
        delays.dobFilDelays = defaultInvoices.get('DOB FilingDefault') != null ? ((defaultInvoices.get('DOB FilingDefault').Delays_Month__c) + 
                                                                                  (defaultInvoices.get('DOB FilingDefault').Time_Frame__c == null?0: Integer.valueOf(defaultInvoices.get('DOB FilingDefault').Time_Frame__c))):0;
        
        delays.dobAppDelays = defaultInvoices.get('DOB ApprovalDefault') != null ? ((defaultInvoices.get('DOB ApprovalDefault').Delays_Month__c) + 
                                                                                    (defaultInvoices.get('DOB ApprovalDefault').Time_Frame__c == null?0: Integer.valueOf(defaultInvoices.get('DOB ApprovalDefault').Time_Frame__c))):0;
        
        delays.bidDocsDelays = defaultInvoices.get('Bid DocumentsDefault') != null ? ((defaultInvoices.get('Bid DocumentsDefault').Delays_Month__c) + 
                                                                                      (defaultInvoices.get('Bid DocumentsDefault').Time_Frame__c == null?0: Integer.valueOf(defaultInvoices.get('Bid DocumentsDefault').Time_Frame__c))):0;
        
        delays.constrAdminDelays = defaultInvoices.get('Construction AdminDefault') != null ? ((defaultInvoices.get('Construction AdminDefault').Delays_Month__c) + 
                                                                                               (defaultInvoices.get('Construction AdminDefault').Time_Frame__c == null?0: Integer.valueOf(defaultInvoices.get('Construction AdminDefault').Time_Frame__c))):0;
        
        delays.punchDelays = defaultInvoices.get('PunchlistDefault') != null ? ((defaultInvoices.get('PunchlistDefault').Delays_Month__c) + 
                                                                                (defaultInvoices.get('PunchlistDefault').Time_Frame__c == null?0: Integer.valueOf(defaultInvoices.get('PunchlistDefault').Time_Frame__c))):0;
        return delays;
    }
    
    public static Date getBillingDate(Invoice__c inv, Opportunity opp, Map<Id,Map<String,Invoice__c>> defaultInvoices, Map<Id,Map<String,Invoice__c>> othersDefaultInvoices,Boolean onInsert){
        Date closeDate = opp.CloseDate;
        if(closeDate == null || inv == null){
            return null;
        }
        
        PreviousDelays preDelays;
        if(onInsert){
            preDelays = getPreviousDelays(inv.Default__c,defaultInvoices.get(opp.Id),othersDefaultInvoices.get(opp.Id));
        }
        else{
            preDelays = getPreviousDelays(othersDefaultInvoices.get(opp.Id));
        }
        Decimal delays = 0;
        Decimal previousStages = 0;
        Decimal totalDays = 0;
        Integer timeFrame = 0;
        if(inv.Default__c){
            if(inv.Name == 'Retainer'){
                delays = inv.Delays_Month__c;
                totalDays = delays;
            }
            else if(inv.Name == 'Schematic Design'){
                delays = inv.Delays_Month__c;
                timeFrame = inv.Time_Frame__c == null?0: Integer.valueOf(inv.Time_Frame__c);
                
                previousStages = preDelays.retainerDelays;
                
                totalDays = delays + previousStages + timeFrame;
            }
            else if(inv.Name == 'DOB Filing'){
                delays = inv.Delays_Month__c;
                timeFrame = inv.Time_Frame__c == null?0: Integer.valueOf(inv.Time_Frame__c);
                
                previousStages = preDelays.retainerDelays + preDelays.schematicDelays;
                
                totalDays = delays + previousStages + timeFrame;
            }
            else if(inv.Name == 'DOB Approval'){
                delays = inv.Delays_Month__c;
                timeFrame = inv.Time_Frame__c == null?0: Integer.valueOf(inv.Time_Frame__c);
                
                previousStages = preDelays.retainerDelays + preDelays.schematicDelays + preDelays.dobFilDelays;
                
                totalDays = delays + previousStages + timeFrame;
            }
            else if(inv.Name == 'Bid Documents'){
                delays = inv.Delays_Month__c;
                timeFrame = inv.Time_Frame__c == null?0: Integer.valueOf(inv.Time_Frame__c);
                
                previousStages = preDelays.retainerDelays + preDelays.schematicDelays + preDelays.dobFilDelays + preDelays.dobAppDelays;
                
                totalDays = delays + previousStages + timeFrame;
            }
            else if(inv.Name == 'Construction Admin'){
                delays = inv.Delays_Month__c;
                timeFrame = inv.Time_Frame__c == null?0: Integer.valueOf(inv.Time_Frame__c);
                
                previousStages = preDelays.retainerDelays + preDelays.schematicDelays + preDelays.dobFilDelays + preDelays.dobAppDelays + preDelays.bidDocsDelays;
                
                totalDays = delays + previousStages + timeFrame;
            }
            else if(inv.Name == 'Punchlist'){
                delays = inv.Delays_Month__c;
                timeFrame = inv.Time_Frame__c == null?0: Integer.valueOf(inv.Time_Frame__c);
                
                previousStages = preDelays.retainerDelays + preDelays.schematicDelays + preDelays.dobFilDelays + preDelays.dobAppDelays + preDelays.bidDocsDelays + preDelays.constrAdminDelays;
                
                totalDays = delays + previousStages + timeFrame;
            }
        }
        else{
            delays = inv.Delays_Month__c;
            timeFrame = inv.Time_Frame__c == null?0: Integer.valueOf(inv.Time_Frame__c);
            
            previousStages = preDelays.retainerDelays + preDelays.schematicDelays + preDelays.dobFilDelays + preDelays.dobAppDelays + preDelays.bidDocsDelays + preDelays.constrAdminDelays + preDelays.punchDelays;
            
            totalDays = delays + previousStages + timeFrame;
        }
        return closeDate.addDays((Integer)totalDays * 7);
    }
    
    public static void calculateDatesOnUpdate(List<Invoice__c> newInvoices,Map<Id,Invoice__c> oldInvoices,Boolean isDelete){
        if(isDelete == true){
            newInvoices = new List<Invoice__c>(oldInvoices.values());
        }
        List<Id> oppIds = new List<Id>();
        List<Invoice__c> impactedInvoices = new List<Invoice__c>();
        List<Invoice__c> toUpdateInvoices = new List<Invoice__c>();
        List<Id> impactedInvoiceIds = new List<Id>();
        Map<Id,Map<String,Invoice__c>> allInvoices = new Map<Id,Map<String,Invoice__c>>();
        
        for(Invoice__c inv : newInvoices){
            if((inv.Opp_Close_Date_Change_Track__c != oldInvoices.get(inv.Id).Opp_Close_Date_Change_Track__c) ||
               (inv.Time_Frame__c != oldInvoices.get(inv.Id).Time_Frame__c) ||
               (inv.Delays_Month__c != oldInvoices.get(inv.Id).Delays_Month__c) || 
               (inv.Default__c != oldInvoices.get(inv.Id).Default__c)){
                   impactedInvoices.add(inv);
                   impactedInvoiceIds.add(inv.Id);
                   oppIds.add(inv.Opportunity__c);
               }
            else if(isDelete){
                impactedInvoices.add(inv);
                impactedInvoiceIds.add(inv.Id);
                oppIds.add(inv.Opportunity__c);
            }
        }
        
        for(Invoice__c inv : [SELECT Excpected_Billing_Date__c,Default__c , Id, Name, Delays__c,Delays_Month__c,Time_Frame__c,Opportunity__c FROM Invoice__c where Opportunity__c = :oppIds]){    
            if(allInvoices.get(inv.Opportunity__c) != null){
                if(inv.Default__c == true){
                    allInvoices.get(inv.Opportunity__c).put(inv.Name+'Default',inv);
                }
                else{
                    allInvoices.get(inv.Opportunity__c).put(inv.Name+'Not Default',inv);
                }
            }
            else{
                if(inv.Default__c == true){
                    allInvoices.put(inv.Opportunity__c,new Map<String,Invoice__c>());
                    allInvoices.get(inv.Opportunity__c).put(inv.Name+'Default',inv);
                }
                else{
                    allInvoices.put(inv.Opportunity__c,new Map<String,Invoice__c>());
                    allInvoices.get(inv.Opportunity__c).put(inv.Name+'Not Default',inv);
                }
            }
        }
        
        if(isDelete == false){
            for(Invoice__c inv : impactedInvoices){
                if(allInvoices.get(inv.Opportunity__c) != null){
                    if(inv.Default__c == true){
                        allInvoices.get(inv.Opportunity__c).put(inv.Name+'Default',inv);
                    }
                    else{
                        allInvoices.get(inv.Opportunity__c).put(inv.Name+'Not Default',inv);
                    }
                }
                else{
                    if(inv.Default__c == true){
                        allInvoices.put(inv.Opportunity__c,new Map<String,Invoice__c>());
                        allInvoices.get(inv.Opportunity__c).put(inv.Name+'Default',inv);
                    }
                    else{
                        allInvoices.put(inv.Opportunity__c,new Map<String,Invoice__c>());
                        allInvoices.get(inv.Opportunity__c).put(inv.Name+'Not Default',inv);
                    }
                }
            }
        }
        
        Map<Id,Opportunity> relatedOpportunities = new Map<Id,Opportunity>([Select Id,CloseDate,TF_SD__c, TF_DOB_Filing__c, TF_DOB_App__c, TF_DD_CD__c,
                                                                            TF_CA__c, TF_Punch__c from Opportunity where Id = :oppIds]);
        
        setBillingDateOnUpdate(impactedInvoiceIds, toUpdateInvoices, relatedOpportunities, allInvoices);
        if(toUpdateInvoices.size() > 0){
            Map<Id,Date> schedulerData = new Map<Id,Date>();
            for(Invoice__c inv : toUpdateInvoices){
                schedulerData.put(inv.Id, Inv.Excpected_Billing_Date__c);
            }
            InvoiceDateUpdateScheduler s = new InvoiceDateUpdateScheduler(schedulerData); 
            System.enqueueJob(s);
        }
    }
    
    public static void setBillingDateOnUpdate(List<Id> impactedInvoices,List<Invoice__c> toUpdate,Map<Id,Opportunity> relatedOpportunities, Map<Id,Map<String,Invoice__c>> allInvoices){
        for(Id key : allInvoices.keySet()){
            Map<String,Invoice__c> relatedInvoices =  allInvoices.get(key);
            Date currentDate;
            Date newDate;
            currentDate = relatedInvoices.get('RetainerDefault') != null ? relatedInvoices.get('RetainerDefault').Excpected_Billing_Date__c : null;
            newDate = getBillingDate(relatedInvoices.get('RetainerDefault'), relatedOpportunities.get(key), null, allInvoices,false);
            if(newDate != currentDate){
                relatedInvoices.get('RetainerDefault').Excpected_Billing_Date__c = newDate;
                if(impactedInvoices.contains(relatedInvoices.get('RetainerDefault').Id) == false){
                    toUpdate.add(relatedInvoices.get('RetainerDefault'));
                }
            }
            
            
            currentDate = relatedInvoices.get('Schematic DesignDefault') != null ? relatedInvoices.get('Schematic DesignDefault').Excpected_Billing_Date__c : null;
            newDate = getBillingDate(relatedInvoices.get('Schematic DesignDefault'), relatedOpportunities.get(key), null, allInvoices,false);
            if(newDate != currentDate){
                relatedInvoices.get('Schematic DesignDefault').Excpected_Billing_Date__c = newDate;
                if(impactedInvoices.contains(relatedInvoices.get('Schematic DesignDefault').Id) == false){
                    toUpdate.add(relatedInvoices.get('Schematic DesignDefault'));
                }                
            }
            
            currentDate = relatedInvoices.get('DOB FilingDefault') != null ? relatedInvoices.get('DOB FilingDefault').Excpected_Billing_Date__c : null;
            newDate = getBillingDate(relatedInvoices.get('DOB FilingDefault'), relatedOpportunities.get(key), null, allInvoices,false);
            if(newDate != currentDate){
                relatedInvoices.get('DOB FilingDefault').Excpected_Billing_Date__c = newDate;
                if(impactedInvoices.contains(relatedInvoices.get('DOB FilingDefault').Id) == false){
                    toUpdate.add(relatedInvoices.get('DOB FilingDefault'));
                } 
            }
            
            
            currentDate = relatedInvoices.get('DOB ApprovalDefault') != null ? relatedInvoices.get('DOB ApprovalDefault').Excpected_Billing_Date__c : null;
            newDate = getBillingDate(relatedInvoices.get('DOB ApprovalDefault'), relatedOpportunities.get(key), null, allInvoices,false);
            if(newDate != currentDate){
                relatedInvoices.get('DOB ApprovalDefault').Excpected_Billing_Date__c = newDate;
                if(impactedInvoices.contains(relatedInvoices.get('DOB ApprovalDefault').Id) == false){
                    toUpdate.add(relatedInvoices.get('DOB ApprovalDefault'));
                } 
            }
            
            currentDate = relatedInvoices.get('Bid DocumentsDefault') != null ? relatedInvoices.get('Bid DocumentsDefault').Excpected_Billing_Date__c : null;
            newDate = getBillingDate(relatedInvoices.get('Bid DocumentsDefault'), relatedOpportunities.get(key), null, allInvoices,false);
            if(newDate != currentDate){
                relatedInvoices.get('Bid DocumentsDefault').Excpected_Billing_Date__c = newDate;
                if(impactedInvoices.contains(relatedInvoices.get('Bid DocumentsDefault').Id) == false){
                    toUpdate.add(relatedInvoices.get('Bid DocumentsDefault'));
                } 
            }
            
            currentDate = relatedInvoices.get('Construction AdminDefault') != null ? relatedInvoices.get('Construction AdminDefault').Excpected_Billing_Date__c : null;
            newDate = getBillingDate(relatedInvoices.get('Construction AdminDefault'), relatedOpportunities.get(key), null, allInvoices,false);
            if(newDate != currentDate){
                relatedInvoices.get('Construction AdminDefault').Excpected_Billing_Date__c = newDate;
                if(impactedInvoices.contains(relatedInvoices.get('Construction AdminDefault').Id) == false){
                    toUpdate.add(relatedInvoices.get('Construction AdminDefault'));
                } 
            }
            
            currentDate = relatedInvoices.get('PunchlistDefault') != null ? relatedInvoices.get('PunchlistDefault').Excpected_Billing_Date__c : null;
            newDate = getBillingDate(relatedInvoices.get('PunchlistDefault'), relatedOpportunities.get(key), null, allInvoices,false);
            if(newDate != currentDate){
                relatedInvoices.get('PunchlistDefault').Excpected_Billing_Date__c = newDate;
                if(impactedInvoices.contains(relatedInvoices.get('PunchlistDefault').Id) == false){
                    toUpdate.add(relatedInvoices.get('PunchlistDefault'));
                } 
            }
            
            for(String nameOfTheInvoice : relatedInvoices.keySet()){
                if(relatedInvoices.get(nameOfTheInvoice).Default__c != true){
                    currentDate = relatedInvoices.get(nameOfTheInvoice) != null ? relatedInvoices.get(nameOfTheInvoice).Excpected_Billing_Date__c : null;
                    newDate = getBillingDate(relatedInvoices.get(nameOfTheInvoice), relatedOpportunities.get(key), null, allInvoices,false);
                    if(newDate != currentDate){
                        relatedInvoices.get(nameOfTheInvoice).Excpected_Billing_Date__c = newDate;
                        if(impactedInvoices.contains(relatedInvoices.get(nameOfTheInvoice).Id) == false){
                            toUpdate.add(relatedInvoices.get(nameOfTheInvoice));
                        } 
                    }
                }
            }
        }
    }
    
    public static void adjustBilledPercentages(List<Invoice__c> newInvoices,Map<Id,Invoice__c> oldInvoices){
        for(Invoice__c inv : newInvoices){
            if(inv.Fee__c != oldInvoices.get(inv.Id).Fee__c){
                if(inv.Fee__c!=0){
                    Decimal oldBilledAmount = (inv.Billed__c / 100) * oldInvoices.get(inv.Id).Fee__c;
                    inv.Billed__c = (oldBilledAmount / inv.Fee__c) * 100;
                    if(inv.Billed__c > 100){
                        inv.addError('InvoiceTriggerHandler billed percentage Error ='+inv.Name + ' : Billed percentage exceeded from 100%. Please adjust the Opportunity Amout accordingly.');
                    }
                }
                else{
                    if(inv.Billed__c > 0){
                        inv.addError('InvoiceTriggerHandler billed percentage Error ='+inv.Name + ' : Fee of a Billed Stage cannot be 0.');            
                    }
                    else{
                        inv.Billed__c = 0;                        
                    }
                }
            }
        }
    }
}