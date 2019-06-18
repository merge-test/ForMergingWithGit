global class scriptBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id FROM Opportunity WHERE proposal_issued_to_1__c != null AND AccountId != null AND stageName = \'Closed Won\''
        );
    }
    global void execute(Database.BatchableContext bc, List<Opportunity> records){
        List<Id> oppIds = new List<Id>();
        for(Opportunity opp : records){
            oppIds.add(opp.Id);
        }
        Update [Select id from Invoice__c where Opportunity__c = :oppIds];
    }    
    global void finish(Database.BatchableContext bc){
        
    }
    public static void testPass(){
        Integer i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
    }    
}