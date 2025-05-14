/**
 * @description Service class for performing CRUD operations on listingRuleCriteria object.
 * @author Hemanth Munagala
 * @date 04-13-2025
 */
public without sharing class ListingRuleCriteriacontroller {
    // Fetches all Listing Rule Criteria for a given Listing Rule ID
    @AuraEnabled
    public static List<Listing_Rule_Criteria__c> getlistingRules(String listingRuleId) {
        return [
            SELECT Id, HH_Max_Income__c, HH_Min_Income__c, Household_Size__c 
            FROM Listing_Rule_Criteria__c 
            WHERE Listing_Rule__c = :listingRuleId
        ];
    }

    // Deletes a Listing Rule Criteria record by ID
    @AuraEnabled
    public static String deletelistingRules(String listingRuleCriteriaId) {
        try {
            Listing_Rule_Criteria__c rule = [
                SELECT Id 
                FROM Listing_Rule_Criteria__c 
                WHERE Id = :listingRuleCriteriaId 
                LIMIT 1
            ];
            delete rule;
            return 'Listing Rule Criteria Deleted';
        } catch (Exception e) {
            return 'Error deleting Listing Rule Criteria: ' + e.getMessage();
        }
    }

    // Updates a Listing Rule Criteria record from a map input
    @AuraEnabled
    public static String updatelistingRules(Map<String, Object> RuleObject) {
        try {
            Listing_Rule_Criteria__c updateRule = new Listing_Rule_Criteria__c(
                Id = (Id) RuleObject.get('Id'),
                HH_Max_Income__c = (Decimal) RuleObject.get('HH_Max_Income__c'),
                HH_Min_Income__c = (Decimal) RuleObject.get('HH_Min_Income__c'),
                Household_Size__c = (Decimal) RuleObject.get('Household_Size__c')
            );

            update updateRule;
            return 'Listing Rule Criteria Updated';
        } catch (Exception e) {
            return 'Error updating Listing Rule Criteria: ' + e.getMessage();
        }
    }

    // Adds a new Listing Rule Criteria record from a map input
    @AuraEnabled
    public static String AddlistingRules(Map<String, Object> RuleObject) {
        try {
            Listing_Rule_Criteria__c addRule = new Listing_Rule_Criteria__c(
                Listing_Rule__c = (Id) RuleObject.get('Listing_Rule__c'),
                HH_Max_Income__c = (Decimal) RuleObject.get('HH_Max_Income__c'),
                HH_Min_Income__c = (Decimal) RuleObject.get('HH_Min_Income__c'),
                Household_Size__c = (Decimal) RuleObject.get('Household_Size__c')
            );

            insert addRule;
            return 'Listing Rule Criteria Added';
        } catch (Exception e) {
            return 'Error adding Listing Rule Criteria: ' + e.getMessage();
        }
    }
}