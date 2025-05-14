public with sharing class EligibilityRuleTempController {
    @AuraEnabled
    public static String deleteEligibilityRule(String recordId){
        try{
            List<Waitlist_Rules__c> rule = [ SELECT Id FROM Waitlist_Rules__c WHERE Id = :recordId];
            if (rule.size()==1){
                delete rule;
                return 'Rule Deleted Successfully';
            }
            return 'Error in Deleting Rule';
                
        }
        catch(Exception e){throw new AuraHandledException('Error retrieving eligibility rule: ' + e.getMessage());}
    }
    
    @AuraEnabled
    public static String updateEligibilityRule(Map<String,Object> ruleData){
        try{
            List<Waitlist_Rules__c> rule = [
            SELECT Id, Type_of_Eligibility_Rule__c, AMI_Monthly_Rent__c, Available_Units__c, AMI_Unit_Type__c, AMI_Category__c, HasHearingVision__c,HasMobilityAccessible__c FROM Waitlist_Rules__c
                 WHERE Id = :(Id)ruleData.get('recordId')
                 LIMIT 1
            ];
            if (rule.size() == 1){
                // Convert from String to Decimal safely
    Object netRent = ruleData.get('amiNetRent');
    if (netRent != null) {
        rule[0].AMI_Monthly_Rent__c = (netRent instanceof Decimal) 
            ? (Decimal)netRent 
            : Decimal.valueOf(String.valueOf(netRent));
    }

    Object availableUnits = ruleData.get('numberOfUnits');
    if (availableUnits != null) {
        rule[0].Available_Units__c = (availableUnits instanceof Decimal) 
            ? (Decimal)availableUnits 
            : Decimal.valueOf(String.valueOf(availableUnits));
    }
            }
            update rule;
            return 'Success';
        }
        catch(Exception e){throw new AuraHandledException('Error retrieving eligibility rule: ' + e.getMessage());}
    }
    
    /**
     * Retrieves an existing eligibility rule by ID
     * @param recordId - The Id of the eligibility rule to retrieve
     * @return Map<String, Object> - The eligibility rule data
     */
    
    @AuraEnabled
    public static Map<String, Object> getEligibilityRule(String recordId) {
        try {
            Map<String, Object> ruleData = new Map<String, Object>();
            // This is a sample implementation - replace with your actual object and field names
            List<Waitlist_Rules__c> rule = [
            SELECT Id, Type_of_Eligibility_Rule__c,SetAside__c, AMI_Monthly_Rent__c, Size_of_Waitlist__c, AMI_Unit_Type__c, AMI_Category__c, HasHearingVision__c,HasMobilityAccessible__c FROM Waitlist_Rules__c
                 WHERE Id = :recordId
                 LIMIT 1
            ];
            //Hearing/Vision Adapted
            //Mobility Adapted
            
            if (rule.size() == 1){
                String accessibilityUnit;
            if (rule[0].HasHearingVision__c) {
                accessibilityUnit = 'Hearing/Vision Adapted';
            } else if (rule[0].HasMobilityAccessible__c) {
                accessibilityUnit = 'Mobility Adapted';
            } 
                ruleData.put('ruleType', rule[0].Type_of_Eligibility_Rule__c);
                ruleData.put('setAsideType', rule[0].SetAside__c);
                ruleData.put('accessibilityUnit', accessibilityUnit);
                ruleData.put('amiCategory', rule[0].AMI_Category__c);
                ruleData.put('numberOfBedrooms', rule[0].AMI_Unit_Type__c);
                ruleData.put('numberOfUnits', rule[0].Size_of_Waitlist__c);
                ruleData.put('amiNetRent', rule[0].AMI_Monthly_Rent__c);
            }
           return ruleData;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving eligibility rule: ' + e.getMessage());
        }
    }
    
    /**
     * Saves an eligibility rule
     * @param ruleData - Map containing the eligibility rule data
     * @return String - Id of the saved record
     */
    @AuraEnabled
    public static String saveEligibilityRule(Map<String, Object> eligibilityRule) {
        try {
            Id waitlistId     = (Id) eligibilityRule.get('Waitlist__c');
            String setAside   = (String) eligibilityRule.get('SetAside__c');
            String ruleType   = (String) eligibilityRule.get('Type_of_Eligibility_Rule__c');
            
            // Check if a rule already exists for this Waitlist and SetAside
            if(ruleType == 'This is for Set Aside') {             
                List<Waitlist_Rules__c> existing = [
                    SELECT Id
                    FROM Waitlist_Rules__c
                    WHERE Waitlist__c = :waitlistId
                    AND SetAside__c = :setAside
                    LIMIT 1
                ];
                
                if (!existing.isEmpty()) {
                    return 'An Eligibility Rule already exists for this Waitlist and SetAside.';
                }
                Waitlist_Rules__c rule = new Waitlist_Rules__c(
                Waitlist__c                       = waitlistId,
                SetAside__c                       = setAside,
                  Type_of_Eligibility_Rule__c  = ruleType
            );
            insert rule;
            return rule.Id;
                
            }
            if (ruleType == 'Standard Eligibility Rule') {
                String accessibility   = (String) eligibilityRule.get('Accessibility__c');
                String amiCategory     = (String) eligibilityRule.get('AMI_Category__c');
                String amiUnitType     = (String) eligibilityRule.get('AMI_Unit_Type__c');
                
                List<Waitlist_Rules__c> existingStandard = [
                    SELECT Id
                    FROM Waitlist_Rules__c
                    WHERE Waitlist__c = :waitlistId
                    AND Accessibility__c = :accessibility
                    AND AMI_Category__c = :amiCategory
                    AND AMI_Unit_Type__c = :amiUnitType
                    LIMIT 1
                ];
                if (!existingStandard.isEmpty()) {
                    return 'An Eligibility Rule with the same Accessibility, AMI Category, and Bedrooms already exists';
                }
            }
            Object waitlistSize = eligibilityRule.get('Size_of_Waitlist__c');
            Decimal size  = (waitlistSize instanceof Decimal) ? (Decimal)waitlistSize : Decimal.valueOf(String.valueOf(waitlistSize));
            
            Object noOfUnits = eligibilityRule.get('AMI_Number_of_Units_by_Type__c');
            Decimal numberOfUnits  = (noOfUnits instanceof Decimal) ? (Decimal)noOfUnits : Decimal.valueOf(String.valueOf(noOfUnits));
            
            Object monthlyRent = eligibilityRule.get('AMI_Monthly_Rent__c');
            Decimal rent  = (monthlyRent instanceof Decimal) ? (Decimal)monthlyRent : Decimal.valueOf(String.valueOf(monthlyRent));
            
            Boolean hasHearingVision = false;
            Boolean hasMobilityAccess = false;
            if ((String) eligibilityRule.get('Accessibility__c') == 'Hearing/Vision Adapted') {
                hasHearingVision = true;
            } else if ((String) eligibilityRule.get('Accessibility__c') == 'Mobility Adapted') {
                hasMobilityAccess = true;
            } 
            system.debug('entereed');
            Waitlist_Rules__c rule = new Waitlist_Rules__c(
                Waitlist__c                       = waitlistId,
                Type_of_Eligibility_Rule__c       = (String) eligibilityRule.get('Type_of_Eligibility_Rule__c'),
                Accessibility__c                  = (String) eligibilityRule.get('Accessibility__c'),
                HasHearingVision__c               = hasHearingVision,
                HasMobilityAccessible__c          = hasMobilityAccess,
                AMI_Category__c                   = (String) eligibilityRule.get('AMI_Category__c'),
                AMI_Unit_Type__c                  = (String) eligibilityRule.get('AMI_Unit_Type__c'),
                Size_of_Waitlist__c               = size,
                AMI_Number_of_Units_by_Type__c    = numberOfUnits,
                AMI_Monthly_Rent__c               = rent,
                SetAside__c                       = setAside
            );
            
            insert rule;
            return rule.Id;
            
        } catch (Exception e) {
            return 'Error saving Eligibility Rule: ' + e.getMessage();
        }
    }


    
    @AuraEnabled
    public static List<Map<String, String>> getAccessibilityUnitForWaitlist(String waitlistId) {
        List<Map<String, String>> unitList = new List<Map<String, String>>();
        
        // Get Project Id from Waitlist
        Id projectId;
        try {
            projectId = [SELECT Project__c FROM Waitlist__c WHERE Id = :waitlistId LIMIT 1].Project__c;
        } catch (Exception e) {
            return unitList; // Return empty list if project or waitlist is invalid
        }
		/*
        // Query Project Attributes for Preference_Types__c
        List<AggregateResult> results = [
            SELECT Preference_Types__c pref, TOLABEL(Preference_Types__c) label 
            FROM Project_Attributes__c 
            WHERE Preference_Types__c != null AND Project__c = :projectId AND IsSetAside__c = TRUE
            GROUP BY Preference_Types__c ORDER BY Preference_Types__c
        ];

        for (AggregateResult ar : results) {
            Map<String, String> entry = new Map<String, String>();
            entry.put('key', (String)ar.get('label'));
            entry.put('value', (String)ar.get('pref'));
            unitList.add(entry);
        } */
	
        // Optional: Check for special accessibility cases in Project
        Project__c proj = [SELECT Number_of_Hearing_and_Vision_Impaired_Un__c,Number_of_Mobility_Accessible_Units__c FROM Project__c WHERE Id = :projectId LIMIT 1];
        if (proj.Number_of_Hearing_and_Vision_Impaired_Un__c > 0) {
            unitList.add(new Map<String, String>{ 'label' => 'Hearing/Vision Adapted', 'value' => 'Hearing/Vision Adapted' });
        } 
        if (proj.Number_of_Mobility_Accessible_Units__c > 0) {
            unitList.add(new Map<String, String>{ 'label' => 'Mobility Adapted', 'value' => 'Mobility Adapted' });
        } 

        return unitList;
    }
    
    @AuraEnabled
    public static List<Map<String, String>> getSetAsideUnitsForWaitlist(String waitlistId) {
        List<Map<String, String>> unitList = new List<Map<String, String>>();

        // Get Project Id from Waitlist
        Id projectId;
        try {
            projectId = [SELECT Project__c FROM Waitlist__c WHERE Id = :waitlistId LIMIT 1].Project__c;
        } catch (Exception e) {
            return unitList; // Return empty list if project or waitlist is invalid
        }

        // Query Project Attributes for Preference_Types__c
        List<AggregateResult> results = [
            SELECT Preference_Types__c pref, TOLABEL(Preference_Types__c) label 
            FROM Project_Attributes__c 
            WHERE Preference_Types__c != null AND Project__c = :projectId AND IsSetAside__c = TRUE
            GROUP BY Preference_Types__c ORDER BY Preference_Types__c
        ];

        for (AggregateResult ar : results) {
            Map<String, String> entry = new Map<String, String>();
            entry.put('label', (String)ar.get('label'));
            entry.put('value', (String)ar.get('pref'));
            unitList.add(entry);
        }
		/*
        // Optional: Check for special accessibility cases in Project
        Project__c proj = [SELECT Number_of_Hearing_and_Vision_Impaired_Un__c FROM Project__c WHERE Id = :projectId LIMIT 1];
        if (proj.Number_of_Hearing_and_Vision_Impaired_Un__c > 0) {
            unitList.add(new Map<String, String>{ 'key' => 'Hearing/Vision Adapted', 'value' => 'Hearing/Vision Adapted' });
        } */

        return unitList;
    }
    
    @AuraEnabled
    public static List<Map<String, String>> getAmiCategoriesForWaitlist(String waitlistId) {
        List<Map<String, String>> amiList = new List<Map<String, String>>();
        
        try {
            // Query distinct AMI Category values from Waitlist_Rules__c
            List<AggregateResult> results = [
                SELECT AMI_Category__c cat, TOLABEL(AMI_Category__c) label
                FROM Waitlist_Rules__c
                WHERE Waitlist__c = :waitlistId AND AMI_Category__c != null
                GROUP BY AMI_Category__c ORDER BY AMI_Category__c
            ];
            
            for (AggregateResult ar : results) {
                Map<String, String> entry = new Map<String, String>();
                entry.put('key', (String)ar.get('label'));
                entry.put('value', (String)ar.get('cat'));
                amiList.add(entry);
            }
            
        } catch (Exception e) {
            // Log or handle error
            System.debug('Error in getAmiCategoriesForWaitlist: ' + e.getMessage());
        }
        
        return amiList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPicklistValues(String objectName, String fieldName) {
        List<Map<String, String>> options = new List<Map<String, String>>();
       
        try {
            // Get the describe result for the object
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
            if (objectType == null) {
                throw new AuraHandledException('Object not found: ' + objectName);
            }
           
            // Get the describe result for the field
            Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
            Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get(fieldName).getDescribe();
           
            // Verify this is a picklist field
            if (fieldDescribe.getType() != Schema.DisplayType.PICKLIST &&
                fieldDescribe.getType() != Schema.DisplayType.MULTIPICKLIST) {
                throw new AuraHandledException(fieldName + ' is not a picklist field');
            }
           
            // Get picklist values
            List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
           
            // Construct return value
            for (Schema.PicklistEntry entry : picklistValues) {
                if (entry.isActive()) {
                    Map<String, String> option = new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    };
                    options.add(option);
                }
            }
           
            return options;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching picklist values: ' + e.getMessage());
        }
    }



}