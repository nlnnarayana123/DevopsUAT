/**
 * @description Service class for waitlist rule object to fetch ids based on setadises or unit types provided and to get unit type and set asides list
 * @author Hemanth Munagala
 * @date 04-08-2025
 */
public with sharing class WaitlistRuleController {
    /**
     * Fetches AMI Unit Types and SetAside values as separate categorized lists.
     */
    @AuraEnabled
    public static Map<String, List<Map<String, String>>> getPreferenceValues(String recordId) {
        Map<String, List<Map<String, String>>> response = new Map<String, List<Map<String, String>>>();

        response.put('unitTypes', fetchPicklistValues(recordId, 'AMI'));
        response.put('setAsides', fetchPicklistValues(recordId, 'SetAside'));

        return response;
    }

    /**
     * Given a list of AMI Unit Types or SetAside values, returns matching Waitlist_Rules__c record Ids as a semicolon-separated string.
     */
    @AuraEnabled
    public static String getMatchingWaitlistRuleIds(String recordId, List<String> inputValues) {
        List<Waitlist_Rules__c> rules = [
            SELECT Id FROM Waitlist_Rules__c 
            WHERE Waitlist__c = :recordId AND (AMI_Unit_Type__c IN :inputValues OR SetAside__c IN :inputValues)
        ];

        List<String> idList = new List<String>();
        for (Waitlist_Rules__c rule : rules) {
            idList.add(rule.Id);
        }

        return String.join(idList, ';');
    }

    /**
     * Private helper to fetch picklist values of either AMI Unit Types or SetAside from Waitlist Rules.
     * @param recordId - ID of the Waitlist record
     * @param type - 'AMI' or 'SetAside'
     */
    private static List<Map<String, String>> fetchPicklistValues(String recordId, String type) {
        List<Map<String, String>> valuesList = new List<Map<String, String>>();
        List<AggregateResult> results;

        if (type == 'AMI') {
            results = [
                SELECT AMI_Unit_Type__c Value, TOLABEL(AMI_Unit_Type__c) Key 
                FROM Waitlist_Rules__c 
                WHERE Waitlist__c = :recordId AND AMI_Unit_Type__c != null 
                GROUP BY AMI_Unit_Type__c 
                ORDER BY AMI_Unit_Type__c ASC
            ];
            for (AggregateResult ar : results) {
            Map<String, String> entry = new Map<String, String>();
            entry.put('key', (String) ar.get('Key'));
            entry.put('value', (String) ar.get('Value'));
            valuesList.add(entry);
        }
           return valuesList;
        } else if (type == 'SetAside') {
            results = [
                SELECT SetAside__c Value, SetAside__c Key 
                FROM Waitlist_Rules__c 
                WHERE Waitlist__c = :recordId AND SetAside__c != null 
                GROUP BY SetAside__c 
                ORDER BY SetAside__c ASC
            ];
            list<Waitlist_Rules__c> hearingVisionRecord=[Select Waitlist__c from Waitlist_Rules__c where HasHearingVision__c=true AND Waitlist__r.Id = :recordId];
            list<Waitlist_Rules__c> MobilityAccessibleRecord=[Select Waitlist__c from Waitlist_Rules__c where HasMobilityAccessible__c=true AND Waitlist__r.Id = :recordId];
            for (AggregateResult ar : results) {
                    Map<String, String> entry = new Map<String, String>();
                    entry.put('key', (String) ar.get('Key'));
                    entry.put('value', (String) ar.get('Value'));
                    valuesList.add(entry);
                 }
            if(hearingVisionRecord.size()>0){
                Map<String, String> entry = new Map<String, String>();
                    entry.put('key', 'Hearing/Vision Adapted');
                    entry.put('value', 'Hearing/Vision Adapted');
                    valuesList.add(entry);
            }
            if(MobilityAccessibleRecord.size()>0){
                Map<String, String> entry = new Map<String, String>();
                    entry.put('key', 'Mobility Adapted');
                    entry.put('value', 'Mobility Adapted');
                    valuesList.add(entry);     
                }
            return valuesList;   
        } else {
            return valuesList; // Return empty if invalid type
        }        
    }

    @AuraEnabled
    public static List<Map<String, Object>> fetchTiles(String recordId) {
        List<Map<String, Object>> response = new List<Map<String, Object>>();
        // This method is not implemented in the original code.
        Map<String,String> unitTypes = new Map<String,String>{'SRO'=>'SRO', '0' => 'Studio', '1' => '1BR', '2' => '2BR', '3' => '3BR', '4' => '4BR', '5' => '5BR'};
        try {
            List<Waitlist_Attributes__c> wlAttributes = [SELECT Id,Preference_Types__c, Name FROM Waitlist_Attributes__c WHERE Waitlist__c = :recordId];
            Id projectId = [SELECT Id, Project__c FROM Waitlist__c WHERE Id = :recordId LIMIT 1].Project__c;
            List<Project_Attributes__c> proAttributes = [SELECT Preference_Types__c FROM Project_Attributes__c WHERE Preference_Types__c != null AND Project__c = :projectId AND IsSetAside__c = TRUE];
           
            Set<String> proPrefTypes = new Set<String>();
            for (Project_Attributes__c pa : proAttributes) {
                proPrefTypes.add(pa.Preference_Types__c);
            }
            system.debug(wlAttributes);
            system.debug(proAttributes);

            // 3a) If you want just the Strings (the “diff” of pref-types):
            List<Waitlist_Attributes__c> filteredWL = new List<Waitlist_Attributes__c>();
            for (Waitlist_Attributes__c wa : wlAttributes) {
                if (wa.Preference_Types__c != null && !proPrefTypes.contains(wa.Preference_Types__c)) {
                    filteredWL.add(wa);
                }
            }
            system.debug(filteredWL);
            LIST<Waitlist_Rules__c> rules = [SELECT Id,AMICategoryType__c,Name,AMI_Unit_Type__c,AMI_Monthly_Rent__c,Accessibility__c,Waitlist__r.RecordType.Name,SetAside__c,AMI_Category__c,HH_Max_Income__c, HH_Min_Income__c,HH_Max_Household_Size__c,HH_Min_Household_Size__c	 FROM Waitlist_Rules__c WHERE Waitlist__c = :recordId Order BY SetAside__c, Bedrooms__c ASC, AMI_Category__c ASC];
            List<Map<String, Object>> tiles = new List<Map<String, Object>>();

            for (Waitlist_Rules__c rule : rules) {
                Map<String, Object> tile = new Map<String, Object>();
                String occupantRange = (rule.HH_Min_Household_Size__c == rule.HH_Max_Household_Size__c ) ? String.valueOf(rule.HH_Max_Household_Size__c) : String.valueOf(rule.HH_Min_Household_Size__c) + '-' + String.valueOf(rule.HH_Max_Household_Size__c);
                // String incomeRange;
                // if ( rule.HH_Min_Income__c == null && rule.HH_Max_Income__c == null ) {
                //     incomeRange = '';
                // }
                // else if ( rule.HH_Min_Income__c == rule.HH_Max_Income__c ) {
                //     incomeRange = '$' + String.valueOf(rule.HH_Max_Income__c);
                // }
                // else {
                //     incomeRange = '$' 
                //                 + String.valueOf(rule.HH_Min_Income__c) 
                //                 + ' - $' 
                //                 + String.valueOf(rule.HH_Max_Income__c);
                // }

                tile.put('id', rule.Id);
                tile.put('accessibility', rule.Accessibility__c);
                tile.put('ami', rule.AMI_Category__c);
                tile.put('unitType', unitTypes.get(rule.AMI_Unit_Type__c));
                // tile.put('incomeRange', incomeRange);
                tile.put('occupants', occupantRange);
                tile.put('isSetAside', rule.SetAside__c != null);
                tile.put('setAside',rule.SetAside__c);
                tile.put('isPreference',false);
                tile.put('isRule', rule.SetAside__c == null);
                tile.put('maxIncome', rule.HH_Max_Income__c);
                tile.put('minIncome', rule.HH_Min_Income__c); 
                tiles.add(tile);
            }
            
        for (Waitlist_Attributes__c wa: filteredWL) {
            Map<String, Object> tile = new Map<String, Object>();
            tile.put('id', wa.Id);
            tile.put('preferenceType', wa.Preference_Types__c);
            tile.put('isPreference',true);
            tile.put('isSetAside', false);
            tile.put('isRule', false);

            tiles.add(tile);
        }
        return tiles;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}