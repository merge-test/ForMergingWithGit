public class ContactTriggerHandler {
    public static void triggerAddressChange(List<Contact> newContacts,Map<Id,Contact> oldContacts){
        Set<Id> contactsWithChangedAddress = new Set<Id>();
        for(Contact con : newContacts){
            if(con.MailingCity != oldContacts.get(con.Id).MailingCity ||
               con.MailingCountry != oldContacts.get(con.Id).MailingCountry ||
               con.MailingPostalCode != oldContacts.get(con.Id).MailingPostalCode ||
               con.MailingState != oldContacts.get(con.Id).MailingState ||
               con.MailingStreet != oldContacts.get(con.Id).MailingStreet ||
               con.OtherCity != oldContacts.get(con.Id).OtherCity ||
               con.OtherCountry != oldContacts.get(con.Id).OtherCountry ||
               con.OtherPostalCode != oldContacts.get(con.Id).OtherPostalCode ||
               con.OtherState != oldContacts.get(con.Id).OtherState ||
               con.OtherStreet != oldContacts.get(con.Id).OtherStreet){
                   contactsWithChangedAddress.add(con.Id);
               }
        }
        
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for(Opportunity opp : [Select Id,AddressChangesCount__c from Opportunity 
                               where proposal_issued_to_1__c = :contactsWithChangedAddress 
                               or proposal_issued_to_2__c = :contactsWithChangedAddress]){
            opp.AddressChangesCount__c = opp.AddressChangesCount__c == null ? 1 : opp.AddressChangesCount__c + 1;
            oppsToUpdate.add(opp);
        }
        
        update oppsToUpdate;
    }
}