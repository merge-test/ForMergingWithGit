public class MapperClass {
    
    public List<Mapper> allObjects {get;set;}
    public List<string> objects {get;set;}
    public MapperClass()
    {
        initializeObjs();
    }
    
    public void initializeObjs(){
        allObjects = new List<Mapper>();
        allObjects.add(new Mapper('Account'));
        allObjects.add(new Mapper('Opportunity'));
        allObjects.add(new Mapper('Invoice'));
    }
    
    public void updateInvList()
    {
        allObjects[2].listOfObjs.add(new Mapper__c(Object__c = 'Invoice'));
    }
    
    public void updateOppList()
    {
        allObjects[1].listOfObjs.add(new Mapper__c(Object__c = 'Opportunity'));
    }
    
    public void updateAccList()
    {
        allObjects[0].listOfObjs.add(new Mapper__c(Object__c = 'Account'));
    }
    
    public void saveMapping()
    {
        Database.DMLOptions db = new Database.DMLOptions();
        
        Database.upsert(allObjects[0].listOfObjs, false);
        Database.upsert(allObjects[1].listOfObjs, false);
        Database.upsert(allObjects[2].listOfObjs, false);

        ApexPages.Message msg =  new ApexPages.message(ApexPages.severity.INFO,'Mapping Saved Successfully');
        ApexPages.addMessage(msg);
    }
    public void deleteRecord()
    {
        String toDelete = ApexPages.currentPage().getParameters().get('idd');
        
        List<Mapper__c> mapper=[SELECT id, Quickbooks_Field_Name__c
                                FROM Mapper__c
                                WHERE id =: toDelete];
        
        if(mapper.size()>0)
        {
            if(mapper[0].Quickbooks_Field_Name__c!='DisplayName')
            {
                delete mapper[0];
            }
        }
        
    }
    
}