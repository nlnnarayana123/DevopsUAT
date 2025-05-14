public with sharing class HousingSearchV3 {
    // Constants for object API names
    private static final String WAITLIST_OBJECT = 'Waitlist__c';
    private static final String WAITLIST_ATTRIBUTES_OBJECT = 'Waitlist_Attributes__c';
    private static final String WAITLIST_RULES_OBJECT = 'Waitlist_Rules__c';
    private static final String WAITLIST_BUILDINGS_OBJECT = 'Waitlist_Building__c';
    private static final String LISTING_RULE_CRITERIA_OBJECT = 'Listing_Rule_Criteria__c';
    // private static final String ORDER_BY = ' order by Type__c, Application_Due__c desc,CreatedDate desc, Project_Name__c';
    private static final String ORDER_BY = ' order by Type__c, CreatedDate desc, Project_Name__c';
    private static final String HAS_HEARING_VISION = 'Hearing/Vision Adapted';
    private static final String HAS_MOBILITY_ADAPTED = 'Mobility Adapted';
    
    // Status values for filtering open waitlists
    private static final List<String> VALID_WAITLIST_STATUSES = new List<String>{'Open'};
    
    /**
     * Retrieves waitlist records based on input filters
     * @param input Map of filter parameters
     * @return List of housing records matching the criteria
     */
    @AuraEnabled
    public static List<Map<String, Object>> getWaitListRecords(Map<String, Object> input) {
        try {
            // Build queries for different filtering aspects
            Map<String, String> queryMap = buildQueries(input);
            // Execute filtered queries
            List<SObject> filteredResults = executeFilterQueries(queryMap);
            
            // Retrieve final waitlist records
            return mapResultsToHousingRecords(filteredResults);
        } catch (Exception e) {
            // Log error and return empty list
            return new List<Map<String, Object>>();
        }
    }
    
    /**
     * Builds queries for different filtering aspects
     * @param input Map of filter parameters
     * @return Map of query strings
     */
    private static Map<String, String> buildQueries(Map<String, Object> input) {
        return new Map<String, String> {
            'buildingQuery' => buildBuildingsQuery(input),
            'rulesQuery' => buildRulesQuery(input),
            'attributesQuery' => buildAttributesQuery(input),
            'listingRulesQuery' => buildListingRuleQuery(input),
            'listingsQuery' => buildListingsQuery(input)
        };
    }

    private static string buildBuildingsQuery(Map<String, Object> input){
        boolean allFiltersEmpty = 
        (input.get('SelectedCity') == null || input.get('SelectedCity') == '' || input.get('SelectedCity') == 'All Cities') &&
        (input.get('SelectedZip') == null || input.get('SelectedZip') == '' || input.get('SelectedZip') == 'All Zip Codes') &&
        (input.get('SelectedCounty') == null || input.get('SelectedCounty') == '' || input.get('SelectedCounty') == 'All Counties');
    
        if (allFiltersEmpty) {
            return '';
        }
        String buildingQuery = 'SELECT Waitlist__c  FROM ' + WAITLIST_BUILDINGS_OBJECT + ' WHERE Waitlist__c != null ';
        if (input.get('SelectedCity') != 'All Cities' && input.get('SelectedCity') != null && input.get('SelectedCity') != '' && input.get('LocationType') == 'City') {
            buildingQuery += ' AND  Building_Address__City__s = \'' + input.get('SelectedCity') + '\'';
        }
        if (input.get('SelectedZip') != 'All Zip Codes' && input.get('SelectedZip') != null && input.get('LocationType') == 'ZIP') {
            buildingQuery += ' AND Building_Address__PostalCode__s = \'' + input.get('SelectedZip') + '\'';
        }
        if (input.get('SelectedCounty') != 'All Counties' && input.get('SelectedCounty') != null && input.get('LocationType') == 'County') {
            buildingQuery += ' AND County__c = \'' + input.get('SelectedCounty') + '\'';
        }
        buildingQuery += ' AND Waitlist__r.Status__c IN :VALID_WAITLIST_STATUSES GROUP BY Waitlist__c';
        
        return buildingQuery;
    }

    private static String buildRulesQuery(Map<String, Object> input) {
        String rulesQuery = '';
        if (input.get('RentHigh') != null || input.get('RentLow') != null || (input.get('UnitType') != 'Any' && (String)input.get('UnitType')!='' && input.get('UnitType') != null) || (input.get('Accessibility') != 'Any' && (String)input.get('Accessibility')!='' && input.get('Accessibility') != null)) {
            rulesQuery = 'SELECT Waitlist__c  FROM ' + WAITLIST_RULES_OBJECT + ' WHERE Waitlist__c != null';
            if (input.get('UnitType') != 'Any' && (String)input.get('UnitType')!='' && input.get('UnitType') != null) {
                rulesQuery += ' AND AMI_Unit_Type__c = ' + '\'' + input.get('UnitType') + '\'';
            }
            if (input.get('RentHigh') != null && input.get('RentLow') != null) {
                rulesQuery += ' AND AMI_Monthly_Rent__c <= ' + input.get('RentHigh') + ' AND AMI_Monthly_Rent__c >= ' + input.get('RentLow');
            }
            if (input.get('Accessibility') != 'Any' && (String)input.get('Accessibility')!='' && input.get('Accessibility') != null) {
                if (input.get('Accessibility') == HAS_HEARING_VISION) {
                    rulesQuery += ' AND HasHearingVision__c = true';
                } else if (input.get('Accessibility') == HAS_MOBILITY_ADAPTED) {
                    rulesQuery += ' AND HasMobilityAccessible__c = true';
                }
            }
            rulesQuery += ' AND Waitlist__r.Status__c IN :VALID_WAITLIST_STATUSES GROUP BY Waitlist__c';
        }
        return rulesQuery;
    }
    
    
    private static String buildAttributesQuery(Map<String, Object> input) {
        if (input.get('Amenities')== new List<Object>() && input.get('Preferences')== new List<Object>()  && input.get('Vouchers')== new List<Object>()) {
            return '';
        }
        String attrQuery = 'SELECT Waitlist__c FROM ' + WAITLIST_ATTRIBUTES_OBJECT + ' WHERE Waitlist__c != null';
        String attributesClause = buildAttributesClause(input);
        attrQuery += attributesClause;
        attrQuery += ' AND Waitlist__r.Status__c IN :VALID_WAITLIST_STATUSES Group By Waitlist__c' ;
        return attrQuery;
    }


    private static String buildListingRuleQuery(Map<String, Object> input) {
        String listingRulesQuery = '';
        if (input.get('Income') != null) {
            listingRulesQuery = 'SELECT Listing_Rule__r.Waitlist__c  FROM ' + LISTING_RULE_CRITERIA_OBJECT + ' WHERE Listing_Rule__r.Waitlist__c != null';
            listingRulesQuery += ' AND HH_Max_Income__c >= ' + input.get('Income') + ' AND HH_Min_Income__c <= ' + input.get('Income');
            listingRulesQuery += ' GROUP BY Listing_Rule__r.Waitlist__c';
        }
        return listingRulesQuery;
    }


    private static String buildListingsQuery(Map<String, Object> input) {
        system.debug(input.get('Project'));
        system.debug(input.get('Project') != '');
        system.debug(input.get('Project') != null);
        String listingsQuery ='';
        if ((input.get('Project') != null && input.get('Project') != '') || (input.get('isAccessibleUnit') != null && input.get('isAccessibleUnit') != '' && input.get('isAccessibleUnit') != false)) {
            System.debug('Inside Listings Query');
            listingsQuery = 'SELECT Id FROM ' + WAITLIST_OBJECT + ' WHERE Id != null';
            system.debug(listingsQuery+'listingsquery');
            if (input.get('Project') != null && input.get('Project') != '') {
                System.debug('Inside Project');
                String pattern = '%' + input.get('Project') + '%';
                listingsQuery += ' AND Project__r.Name Like \'' + pattern + '\'';
                system.debug(listingsQuery+'listingsquery');
            }
            if (input.get('isAccessibleUnit') != null && input.get('isAccessibleUnit') != '' && input.get('isAccessibleUnit') != false) {
                listingsQuery += ' AND Is_Accessible_Unit__c  = ' + input.get('isAccessibleUnit');
                
            }
            listingsQuery += ' AND Status__c IN :VALID_WAITLIST_STATUSES';
            system.debug(listingsQuery+'listingsquery');
            
        }
        
        return listingsQuery;
    }

    /**
     * Executes filter queries and aggregates matching waitlist IDs
     * @param queryMap Map of query strings
     * @return List of filtered SObjects
     */
    private static List<SObject> executeFilterQueries(Map<String, String> queryMap) {
        // Execute individual queries
        List<SObject> rulesResults = executeQuery(queryMap.get('rulesQuery'));
        List<SObject> attrResults = executeQuery(queryMap.get('attributesQuery'));
        List<SObject> buildingResults = executeQuery(queryMap.get('buildingQuery'));
        List<SObject> listingRulesQueryResults = executeQuery(queryMap.get('listingRulesQuery'));
        List<SObject> listingsQueryResults = executeQuery(queryMap.get('listingsQuery'));
        List<SObject> allResults = executeQuery('SELECT Project_Name__c,Application_Due__c, is_mitchell_lama__c, id, county__c,  HH_Max_Income__c,HH_Min_Income__c,  Type__c, Is_Accessible_Unit__c ,   experience_tile_image_url__c FROM ' + WAITLIST_OBJECT + ' WHERE Id !=null AND Status__c IN :VALID_WAITLIST_STATUSES' + ORDER_BY);

            Set<Id> waitlistIds = aggregateWaitlistIds(
                rulesResults, 
                attrResults, 
                buildingResults, 
                allResults,
                listingRulesQueryResults,
                listingsQueryResults,
                queryMap
            );
    
            // Build and execute final detailed query
            String detailedQuery = buildDetailedQuery(waitlistIds);
            return Database.query(detailedQuery);
        
    }

    /**
     * Safely executes a SOQL query
     * @param queryString SOQL query to execute
     * @return List of query results
     */
    private static List<SObject> executeQuery(String queryString) {
        return String.isBlank(queryString) 
            ? new List<SObject>() 
            : Database.query(queryString);
    }


    /**
     * Aggregates waitlist IDs based on different filter results
     * @param rulesResults Results from rules query
     * @param attrResults Results from attributes query
     * @param buildingResults Results from buildings query
     * @param queryMap Map of original queries
     * @return Set of filtered waitlist IDs
     */
    private static Set<Id> aggregateWaitlistIds(
        List<SObject> rulesResults, 
        List<SObject> attrResults, 
        List<SObject> buildingResults, 
        List<SObject> allResults,
        List<SObject> listingRulesQueryResults,
        List<SObject> listingsQueryResults,
        Map<String, String> queryMap
    ) {
        Set<Id> waitlistIds = new Set<Id>();
        Boolean hasBuildings = String.isNotBlank(queryMap.get('buildingQuery'));
        Boolean hasRules = String.isNotBlank(queryMap.get('rulesQuery'));
        Boolean hasAttributes = String.isNotBlank(queryMap.get('attributesQuery'));
        Boolean hasListingRules = String.isNotBlank(queryMap.get('listingRulesQuery'));
        Boolean hasListings = String.isNotBlank(queryMap.get('listingsQuery'));

        if (hasBuildings || hasRules || hasAttributes || hasListingRules || hasListings){
            Set<Id> rulesIds = collectIds(rulesResults, 'Waitlist__c');
            Set<Id> attributeIds = collectIds(attrResults, 'Waitlist__c');
            Set<Id> buildingIds = collectIds(buildingResults, 'Waitlist__c');
            Set<Id> listingRulesIds = collectIds(listingRulesQueryResults, 'Waitlist__c');
            Set<Id> listingsIds = collectIds(listingsQueryResults, 'Id');

        // Determine which filter to prioritize
        

        // Intersect IDs based on applied filters
        if (hasBuildings) waitlistIds.addAll(buildingIds);
        else if (hasRules) waitlistIds.addAll(rulesIds);
        else if (hasAttributes) waitlistIds.addAll(attributeIds);
        else if (hasListingRules) waitlistIds.addAll(listingRulesIds);
        else if (hasListings) waitlistIds.addAll(listingsIds);

        // Further filter IDs if multiple filters applied
        if (!waitlistIds.isEmpty()) {
            if (hasRules) waitlistIds.retainAll(rulesIds);
            if (hasAttributes) waitlistIds.retainAll(attributeIds);
            if (hasBuildings) waitlistIds.retainAll(buildingIds);   
            if (hasListingRules) waitlistIds.retainAll(listingRulesIds);
            if (hasListings) waitlistIds.retainAll(listingsIds);
        }
        }
        else{
            waitlistIds = collectIds(allResults, 'Id');

        }
        return waitlistIds;
    }

    /**
     * Collects IDs from a list of SObjects for a specific field
     * @param records List of SObjects
     * @param fieldName Field to extract IDs from
     * @return Set of collected IDs
     */
    private static Set<Id> collectIds(List<SObject> records, String fieldName) {
        Set<Id> ids = new Set<Id>();
        for (SObject record : records) {
            Id recordId = (Id)record.get(fieldName);
            if (recordId != null) {
                ids.add(recordId);
            }
        }
        return ids;
    }


    private static String buildAttributesClause(Map<String, Object> input) {
        
        List<Object> amenitiesObject = (List<Object>)input.get('Amenities');
        List<Object> preferencesObject = (List<Object>)input.get('Preferences');
        List<Object> vouchersObject = (List<Object>)input.get('Vouchers');
        List<String> amenities = new List<String>();
        if (amenitiesObject != null) {
            for (Object obj : amenitiesObject) {
                amenities.add(String.valueOf(obj));
            }
        } 
        
        List<String> preferences = new List<String>();
        if (preferencesObject != null) {
            for (Object obj : preferencesObject) {
                preferences.add(String.valueOf(obj));
            }
        }
        
        List<String> vouchers = new List<String>();
        if (vouchersObject != null) {
            for (Object obj : vouchersObject) {
                vouchers.add(String.valueOf(obj));
            }
        }
        
        
        String attributesClause = '';
        if (!amenities.isEmpty() || !preferences.isEmpty() || !vouchers.isEmpty()) {
            List<String> attributesConditions = new List<String>();
            if (!amenities.isEmpty()) {                
                attributesConditions.add(' Amenities__c IN (' + formatIncludesClause(amenities) + ')');
            }
            if (!preferences.isEmpty()) {
                attributesConditions.add('Preference_Types__c IN (' + formatIncludesClause(preferences) + ')');
            }
            if (!vouchers.isEmpty()) {
                attributesConditions.add('Voucher_Types__c IN (' + formatIncludesClause(vouchers)+ ')');
            }
            attributesClause = ' AND (' + String.join(attributesConditions, ' OR ') + ')';
        }
        return attributesClause;
    }
    
    private static String formatIncludesClause(List<String> values) {
        List<String> quotedValues = new List<String>();
        for (String value : values) {
            quotedValues.add('\'' + value + '\'');
        }
        return String.join(quotedValues, ',');
    }
    
    private static String buildDetailedQuery(Set<Id> waitlistIds) {
        return 'SELECT Is_Accessible_Unit__c ,Project_Name__c,Application_Due__c, is_mitchell_lama__c, id, county__c,  HH_Max_Income__c,HH_Min_Income__c,  Type__c, experience_tile_image_url__c FROM ' + WAITLIST_OBJECT + ' WHERE Id IN :waitlistIds AND Status__c IN :VALID_WAITLIST_STATUSES' + ORDER_BY;
    }
    
   
    private static List<Map<String, Object>> mapResultsToHousingRecords(List<SObject> results) {
        List<Map<String, Object>> responseResults = new List<Map<String, Object>>();
        
        for (SObject record : results) {
            Map<String, Object> housingRecord = new Map<String, Object>();
            
            try {
                housingRecord.put('Id', (String)record.get('Id'));
                housingRecord.put('IsMitchellLama', 'Yes'.equals(record.get('Is_Mitchell_Lama__c')));
                housingRecord.put('MinimumIncome', record.get('HH_Min_Income__c') != null ? record.get('HH_Min_Income__c'):0);
                String type = (String)record.get('Type__c');
                if (type != null && type.startsWith('HCR ')) {
                    type = type.replaceFirst('HCR ', '');
                }
                
                housingRecord.put('showApplicationDueDate', (String)record.get('Type__c') == 'HCR Lottery'? true: false);
                housingRecord.put('Type', type);
                housingRecord.put('County', (String)record.get('County__c'));
                housingRecord.put('Image', (String)record.get('experience_tile_image_url__c'));
                housingRecord.put('MaximumIncome', record.get('HH_Max_Income__c') != null ? record.get('HH_Max_Income__c'):0);
                housingRecord.put('HasImage', record.get('experience_tile_image_url__c') != '/resource/BlankDevelopment');
                housingRecord.put('ProjectName', (String)record.get('Project_Name__c'));
                housingRecord.put('isAccessibleUnit', record.get('Is_Accessible_Unit__c'));
                if (record.get('Application_Due__c') != null) {
                    housingRecord.put('ApplicationEndDate', ((Date)record.get('Application_Due__c')).format() // Formats to MM/DD/YYYY
                    );
                }       
                else{
                    housingRecord.put('ApplicationEndDate', record.get('Application_Due__c'));
                }        
                responseResults.add(housingRecord);
            } catch(Exception e) {
                System.debug('Error Building Map for HousingRecord: ' + e.getMessage() + ' ln: ' + e.getLineNumber());
            }
        }
        return responseResults;
    }
    
    
    /**
     * Retrieves distinct values for a specific attribute field
     * @param fieldName Field to retrieve distinct values for
     * @return List of distinct field values
     */
    @AuraEnabled
    public static List<Map<String,Object>> getWaitlistAttributes(String fieldName) {
        try {
            String safeFieldName = String.escapeSingleQuotes(fieldName);
            String query = 'SELECT ' + safeFieldName + 
                           ' FROM ' + WAITLIST_ATTRIBUTES_OBJECT + 
                           ' WHERE ' + safeFieldName + ' != null ' +
                           ' AND Waitlist__r.Status__c IN :VALID_WAITLIST_STATUSES ' +
                           ' GROUP BY ' + safeFieldName + 
                           ' ORDER BY ' + safeFieldName + ' ASC';
            
            List<Map<String,Object>> output = new List<Map<String,Object>>();
            for (AggregateResult ar : Database.query(query)) {
                String fieldValue = (String) ar.get(safeFieldName);
                output.add(new Map<String,Object>{
                    'value' => fieldValue,
                    'label' => fieldValue,
                    'selected' => false
                });
            }
            return output;
        } catch (Exception e) {
            // Use proper Salesforce exception handling
            throw new AuraHandledException('Error retrieving waitlist attributes: ' + e.getMessage());
        }
    }
    
    
    @AuraEnabled
    public static Map<String, List<Map<String,Object>>> fetchWaitlistLocations() {
        Map<String, List<Map<String,Object>>> locationData = new Map<String, List<Map<String,Object>>>();
        
        // Fetch Cities
        List<AggregateResult> cityResults = [
            SELECT Building_Address__City__s FROM Waitlist_Building__c 
            WHERE Building_Address__City__s != NULL 
            AND Waitlist__r.Status__c IN :VALID_WAITLIST_STATUSES
            GROUP BY Building_Address__City__s ORDER BY Building_Address__City__s ASC
        ];
        List<Map<String,Object>> cities = new List<Map<String,Object>>();
        cities.add(new Map<String,Object>{'value' =>'All Cities','label' => 'All Cities'});
        for (AggregateResult ar : cityResults) {
            cities.add(new Map<String,Object>{'value' => (String) ar.get('Building_Address__City__s'),'label' => (String) ar.get('Building_Address__City__s')});
        }
        locationData.put('Cities', cities);
        
        // Fetch Counties
        List<AggregateResult> countyResults = [
            SELECT County__c FROM Waitlist_Building__c 
            WHERE County__c != NULL 
            AND Waitlist__r.Status__c IN :VALID_WAITLIST_STATUSES
            GROUP BY County__c ORDER BY County__c ASC
        ];
        List<Map<String,Object>> counties = new List<Map<String,Object>>();
        counties.add(new Map<String,Object>{'value' =>'All Counties','label' => 'All Counties'});
        for (AggregateResult ar : countyResults) {
            counties.add(new Map<String,Object>{'value' => (String) ar.get('County__c'),'label' => (String) ar.get('County__c')});
        }
        locationData.put('Counties', counties);
        
        // Fetch Zip Codes
        List<AggregateResult> zipResults = [
            SELECT Building_Address__PostalCode__s FROM Waitlist_Building__c 
            WHERE Building_Address__PostalCode__s != NULL 
            AND Waitlist__r.Status__c IN :VALID_WAITLIST_STATUSES
            GROUP BY Building_Address__PostalCode__s ORDER BY Building_Address__PostalCode__s ASC
        ];
        List<Map<String,Object>> zipCodes = new List<Map<String,Object>>();
        zipCodes.add(new Map<String,Object>{'value' =>'All ZIP Codes','label' => 'All ZIP Codes'});
        for (AggregateResult ar : zipResults) {
            zipCodes.add(new Map<String,Object>{'value' => (String) ar.get('Building_Address__PostalCode__s'),'label' => (String) ar.get('Building_Address__PostalCode__s')});
        }
        locationData.put('ZipCodes', zipCodes);
        return locationData;
    }

     @AuraEnabled
    public static List<Map<String, Object>> getListingsOnProfile(){
        try {
            List<Map<String, Object>> responseResults = new List<Map<String, Object>>();
            List<user> currentUser = [SELECT Id, contactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
           if (currentUser.isEmpty() || currentUser[0].ContactId == null) {
                // No user with contact found, return empty list
                return responseResults;
            }
            
            if (!currentUser.isEmpty()){
                List<Contact> currentContact = [SELECT Id, Household_Account__c,Number_of_Persons_Count__c FROM Contact WHERE Id = :currentUser[0].contactId LIMIT 1];
                //system.debug(currentContact);
                Account householdAccount;
                if(currentContact[0].Household_Account__c!=null||currentContact[0].Household_Account__c !=''){
                    List<Account> householdAccounts = [SELECT Id, HouseholdIncomeRollup__c,Household_Size__c
                                                       FROM Account 
                                                       WHERE Id = :currentContact[0].Household_Account__c 
                                                       LIMIT 1];
                    
                    if (!householdAccounts.isEmpty()) {
                        householdAccount = householdAccounts[0];
                    }     
                }
                
                if(!currentContact.isEmpty()){
                    String query = 'SELECT Listing_Rule__r.Waitlist__c FROM Listing_Rule_Criteria__c';
                    List<String> conditions = new List<String>();
                    
                    if (householdAccount.Household_Size__c != null) {
                        conditions.add(' Household_Size__c = ' + householdAccount.Household_Size__c);
                    }
                    
                    if (householdAccount.HouseholdIncomeRollup__c != null) {
                        conditions.add(' HH_Min_Income__c <=' +householdAccount.HouseholdIncomeRollup__c+ ' AND HH_Max_Income__c >= ' + householdAccount.HouseholdIncomeRollup__c);
                    }
                    // Append conditions if any exist
                    if (!conditions.isEmpty()) {
                        query += ' WHERE ' + String.join(conditions, ' AND ');
                        query += 'AND Listing_Rule__r.Waitlist__r.Status__c IN :VALID_WAITLIST_STATUSES GROUP BY Listing_Rule__r.Waitlist__c';
                        List<SObject> results = Database.query(query);
                        Set<Id> waitlistIds = new Set<Id>();
                        for (SObject record : results) {
                            waitlistIds.add((Id)record.get('Waitlist__c'));
                        }
                        
                        if (!waitlistIds.isEmpty()) {
                            String detailedQuery = buildDetailedQuery(waitlistIds);
                            results = Database.query(detailedQuery);
                        responseResults = mapResultsToHousingRecords(results);
                        }
                        
                        return responseResults;
                        
                    }
                }
            }
            return responseResults;
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    } 

    /**
     * Gets picklist values for a specific object field
     * @param objectName - API name of the Salesforce object
     * @param fieldName - API name of the picklist field
     * @return List<Map<String, String>> - List of picklist values with label and value
     */
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

    @AuraEnabled(cacheable=true)
    public static List<AggregateResult> getProjects() {
    try {
        return [ SELECT  Project__r.Name value,  Project__r.Name label FROM Waitlist__c WHERE Status__c IN : VALID_WAITLIST_STATUSES
                 GROUP BY  Project__r.Name ];
    } catch (Exception ex) {
        // Log the exception for debugging purposes
        System.debug('Error in getProjects: ' + ex.getMessage());
        
        // Optionally, throw a generic error message to LWC/Aura
        throw new AuraHandledException('Unable to retrieve project data. Please try again later.');
    }
    } 


    @AuraEnabled
    public static List<Map<String, String>> getAccessebilities(){
        try {
            List<Map<String, String>> valuesList = new List<Map<String, String>>();
            // Add default option
            valuesList.add(new Map<String, String>{'label' => 'Any', 'value' => 'Any'});
            list<Waitlist_Rules__c> hearingVisionRecord=[Select Waitlist__c from Waitlist_Rules__c where HasHearingVision__c=true];
            list<Waitlist_Rules__c> MobilityAccessibleRecord=[Select Waitlist__c from Waitlist_Rules__c where HasMobilityAccessible__c=true];

            if(hearingVisionRecord.size()>0){
                Map<String, String> entry = new Map<String, String>();
                    entry.put('label', HAS_HEARING_VISION);    
                    entry.put('value', HAS_HEARING_VISION);
                    valuesList.add(entry);
            }
            if(MobilityAccessibleRecord.size()>0){
                Map<String, String> entry = new Map<String, String>();
                    entry.put('label', HAS_MOBILITY_ADAPTED);
                    entry.put('value', HAS_MOBILITY_ADAPTED);
                    valuesList.add(entry);     
                }
            return valuesList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}