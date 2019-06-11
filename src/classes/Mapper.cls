public class Mapper
{        
    public string typeOfObj {get;set;}
    public List<Mapper__c> listOfObjs {get;set;}
    public List<SelectOption> allLabels {get;set;}
    public List<SelectOption> allQBLabels {get;set;}
    public Mapper()
    {}
    public Mapper(string obj)
    {
        typeOfObj = obj;      
        listOfObjs = [SELECT id, Field_Name__c,  Quickbooks_Field_Name__c, Object__c  
                      FROM Mapper__c 
                      WHERE Object__c =: obj];
        allLabels = new List<SelectOption>();
        allQBLabels = new List<SelectOption>();
        
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        
        Schema.SObjectType leadSchema;
		if(obj=='Account' || obj=='Opportunity')
        {
            leadSchema   = schemaMap.get(obj);
        }
        else if(obj=='Invoice')
        {
            leadSchema   = schemaMap.get('Opportunity');
        }
        
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        allLabels.add(new SelectOption ('None','----'));
        for (String fieldName: fieldMap.keySet()) 
        {
            allLabels.add(new SelectOption (fieldName,fieldMap.get(fieldName).getDescribe().getLabel()));//It provides to get the object fields label.
        }
        
        if(obj=='Account' || obj=='Opportunity')
        {
            allQBLabels.add(new SelectOption ('None','----'));
            allQBLabels.add(new SelectOption ('Title','Title'));
            allQBLabels.add(new SelectOption ('GivenName','Given Name'));
            allQBLabels.add(new SelectOption ('MiddleName','Middle Name'));
            allQBLabels.add(new SelectOption ('FamilyName','Family Name'));
            allQBLabels.add(new SelectOption ('Suffix','Suffix'));
            allQBLabels.add(new SelectOption ('DisplayName','Display Name'));
            allQBLabels.add(new SelectOption ('FullyQualifiedName','Fully Qualified Name'));
            allQBLabels.add(new SelectOption ('CompanyName','Company Name'));
            allQBLabels.add(new SelectOption ('Active','Active'));
            allQBLabels.add(new SelectOption ('PrimaryPhone','Primary Phone'));
            allQBLabels.add(new SelectOption ('AlternatePhone','Alternate Phone'));
            allQBLabels.add(new SelectOption ('Mobile','Mobile'));
            allQBLabels.add(new SelectOption ('Fax','Fax'));
            allQBLabels.add(new SelectOption ('PrimaryEmailAddr','Primary Email Address'));
            allQBLabels.add(new SelectOption ('WebAddr','Web Address'));
            allQBLabels.add(new SelectOption ('Taxable','Taxable'));
            
            allQBLabels.add(new SelectOption ('BillLine1','Billing Street'));
            allQBLabels.add(new SelectOption ('BillCity','Billing City'));
            allQBLabels.add(new SelectOption ('BillCountry','Billing Country'));
            allQBLabels.add(new SelectOption ('BillPostalCode','Billing PostalCode'));
            allQBLabels.add(new SelectOption ('BillCountrySubDivisionCode','Billing State'));
            
            allQBLabels.add(new SelectOption ('ShipLine1','Ship Street'));
            allQBLabels.add(new SelectOption ('ShipCity','Ship City'));
            allQBLabels.add(new SelectOption ('ShipCountry','Ship Country'));
            allQBLabels.add(new SelectOption ('ShipPostalCode','Ship PostalCode'));
            allQBLabels.add(new SelectOption ('ShipCountrySubDivisionCode','Ship State'));
            
            allQBLabels.add(new SelectOption ('Notes','Notes'));
            allQBLabels.add(new SelectOption ('Balance','Balance'));
            
            allQBLabels.add(new SelectOption ('ContactDetails','Contact Details'));
        }
        else if(obj=='Invoice')
        {
            allQBLabels.add(new SelectOption ('None','----'));
            allQBLabels.add(new SelectOption ('BillEmailCc','CC Address'));
            allQBLabels.add(new SelectOption ('BillEmailBcc','BCC Address'));
        }
       

    }
}