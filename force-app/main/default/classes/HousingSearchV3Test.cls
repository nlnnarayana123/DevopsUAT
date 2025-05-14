@isTest
private class HousingSearchV3Test {
    
    @TestSetup 
    static void setupMethod() {
        // Create a contact linked to the test user
        Contact testContact = new Contact( FirstName = 'Test', LastName = 'Contact' );
        insert testContact;
       
        Account managingAgent = new Account( Name = 'Test Managing Agent');
        insert managingAgent;
        
        Project__c testProject1 = new Project__c( Name = 'Test Project1', County__c='Albany', Managing_Agent__c = managingAgent.Id);
        Project__c testProject2 = new Project__c( Name = 'Test Project2', County__c='Albany', Managing_Agent__c = managingAgent.Id);
        insert testProject1;
        insert testProject2;
        
        //waitlists with different statuses
        list<Waitlist__c> waitlistList = new list<Waitlist__c>{
            new Waitlist__c(Status__c='Open', Project__c=testProject1.Id,Application_Due__c=Date.today(),City__c='New York',Is_Accessible_Unit__c=true),
            new Waitlist__c(Status__c='Open', Project__c=testProject1.Id,Application_Due__c=null,Is_Accessible_Unit__c=false),
            new Waitlist__c(Status__c='Open', Project__c=testProject2.Id,Application_Due__c=Date.today(),Is_Accessible_Unit__c=false),
            new Waitlist__c(Status__c='Pending Lottery', Project__c=testProject2.Id,Application_Due__c=null,Is_Accessible_Unit__c=true)
        };
        insert waitlistList;
        
        //testdata for waitlist buildings
        list<Waitlist_Building__c> buildingList = new list<Waitlist_Building__c>{
            new Waitlist_Building__c(Waitlist__c=waitlistList[0].Id, County__c='Albany',  Building_Address__City__s='New York', Building_Address__PostalCode__s='10001'),
            new Waitlist_Building__c(Waitlist__c=waitlistList[0].Id, County__c='Albany', Building_Address__City__s='Binghamton', Building_Address__PostalCode__s='90001'),
            new Waitlist_Building__c(Waitlist__c=waitlistList[2].Id, County__c='Bronx', Building_Address__City__s='Lake Placid', Building_Address__PostalCode__s='11201'),
            new Waitlist_Building__c(Waitlist__c=waitlistList[3].Id, County__c='Essex', Building_Address__City__s='Hudson', Building_Address__PostalCode__s='11102')
        };
        insert buildingList;
        
        //testdata for waitlist attributes
        list<Waitlist_Attributes__c> attrList = new list<Waitlist_Attributes__c>{
            new Waitlist_Attributes__c(Waitlist__c=waitlistList[0].Id, Category__c='Preferences', Preference_Types__c='Artist', Voucher_Types__c='PBCA'),
            new Waitlist_Attributes__c(Waitlist__c=waitlistList[1].Id, Category__c='Set Aside', Preference_Types__c='Homeless', Voucher_Types__c='PBCA'),
            new Waitlist_Attributes__c(Waitlist__c=waitlistList[2].Id, Category__c='Preferences', Preference_Types__c='Left Handed', Voucher_Types__c='Tenant Based Section 8'),
            new Waitlist_Attributes__c(Waitlist__c=waitlistList[3].Id, Category__c='Set Aside', Preference_Types__c='Veteran', Voucher_Types__c='RAD')
        };
        insert attrList;
        
        //Testdata for waitlist rules
        list<Waitlist_Rules__c> rulesList = new list<Waitlist_Rules__c>{
            new Waitlist_Rules__c(Waitlist__c = waitlistList[0].Id, AMI_Unit_Type__c = '2BR', AMI_Monthly_Rent__c = 1500,HasHearingVision__c=true),
            new Waitlist_Rules__c(Waitlist__c = waitlistList[1].Id, AMI_Unit_Type__c = '1BR', AMI_Monthly_Rent__c = 1200,HasMobilityAccessible__c=true),
            new Waitlist_Rules__c(Waitlist__c = waitlistList[2].Id, AMI_Unit_Type__c = '3BR', AMI_Monthly_Rent__c = 1800,HasMobilityAccessible__c=true)
        };
        insert rulesList;
        
        //Testdata for waitlist rules
        list<Listing_Rule_Criteria__c> listingRules = new list<Listing_Rule_Criteria__c>{
            new Listing_Rule_Criteria__c(Listing_Rule__c = rulesList[0].Id, HH_Max_Income__c = 200000, HH_Min_Income__c = 20000, Household_Size__c=5),
            new Listing_Rule_Criteria__c(Listing_Rule__c = rulesList[1].Id, HH_Max_Income__c = 300000, HH_Min_Income__c = 30000, Household_Size__c=5),
            new Listing_Rule_Criteria__c(Listing_Rule__c = rulesList[2].Id, HH_Max_Income__c = 400000, HH_Min_Income__c = 40000, Household_Size__c=5)
        };
        insert listingRules;
    }
    
    
    @IsTest
    static void testGetPicklistValuesSuccessful() {
        Test.startTest();
        
        // Use Case object and Status field as an example
        List<Map<String, String>> results = HousingSearchV3.getPicklistValues('Case', 'Status');
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results.size() > 0, 'Should return at least one active picklist value');
        
        // Verify each result has label and value
        for (Map<String, String> option : results) {
            System.assertNotEquals(null, option.get('label'), 'Label should not be null');
            System.assertNotEquals(null, option.get('value'), 'Value should not be null');
        }
    }
    
   @IsTest
    static void testGetPicklistValuesNonPicklistField() {
        Test.startTest();
        
        // Use a non-picklist field (e.g., Id field) to test error handling
        try {
            HousingSearchV3.getPicklistValues('Case', 'Id');
            System.assert(false, 'Should have thrown an AuraHandledException');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('is not a picklist field'), 'Incorrect error message');
        }
        
        Test.stopTest();
    }
    
    
    @IsTest
    static void testGetPicklistValuesWithTestObjectName() {
        Test.startTest();
        try {
            HousingSearchV3.getPicklistValues('Test Object', 'Id');
            System.assert(false, 'Should have thrown an AuraHandledException');
        } catch (AuraHandledException e) {
            
        }
        
        Test.stopTest();
    } 
    
    
    @IsTest
    public static void testGetListingsOnProfile_positive(){
        // Create test data
        User adminUser = [Select Id from User Where Id = :UserInfo.getUserId()];
        
        
        // Create an account (required for community users)
        Account objAccount = new Account(Name = 'Test Account',Household_Size__c=5);
        insert objAccount;
        
        // Create a contact associated with the account
        Contact objContact = new Contact(
            FirstName = 'Salesforce3', 
            LastName = 'GentryTeststffs',
            AccountId = objAccount.Id,
            Household_Account__c = objAccount.Id
        );
        insert objContact;
        Member_Income__c mi = new Member_Income__c(Contact__c=objContact.Id, Net_Income__c=50000,Household_Account__c=objAccount.Id);
        insert mi;
        
    
        // Create community user
        System.runAs(adminUser){
            Profile objProfile = [Select Id from Profile Where Name = 'HCR Applicant Community Login'];
            UserRole testRole = new UserRole(DeveloperName = 'TestRole', Name = 'Test Role');
        insert testRole;
        
        adminUser.UserRoleId = testRole.Id;
        update adminUser;
            User userObject = new User(
                alias = 'adb89',
                email = 'salesforce.gentry@gmail.com',
                emailencodingkey = 'UTF-8',
                lastname = 'gentryTest',
                languagelocalekey = 'en_US',
                localesidkey = 'en_US',
                profileid = objProfile.Id,
                timezonesidkey = 'America/Los_Angeles',
                username = 'salesforce.test3455@abc.com',
                contactId = objContact.Id
            );
            insert userObject;
        }

        // Verify the user was created
        System.assertEquals(1, [SELECT COUNT() FROM User WHERE username = 'salesforce.test3455@abc.com']);
        User loggedInUser = [SELECT Id FROM User WHERE username = 'salesforce.test3455@abc.com']; 
        System.runAs(loggedInUser){
            Test.startTest();
        List<Map<String, Object>> results = HousingSearchV3.getListingsOnProfile();
        Test.stopTest();
            system.assertEquals(3,results.size(),'Three listings should be suggested');
        }
        
    }
   
    @IsTest
    public static void testGetListingsOnProfile_negative(){
        // Create test data
        User adminUser = [Select Id from User Where Id = :UserInfo.getUserId()];
        
        
        // Create an account (required for community users)
        Account objAccount = new Account(Name = 'Test Account',Household_Size__c=1);
        insert objAccount;
        
        // Create a contact associated with the account
        Contact objContact = new Contact(
            FirstName = 'Salesforce3', 
            LastName = 'GentryTeststffs',
            AccountId = objAccount.Id,
            Household_Account__c = objAccount.Id
        );
        insert objContact;
        Member_Income__c mi = new Member_Income__c(Contact__c=objContact.Id, Net_Income__c=50000,Household_Account__c=objAccount.Id);
        insert mi;
        
    
        // Create community user
        System.runAs(adminUser){
            Profile objProfile = [Select Id from Profile Where Name = 'HCR Applicant Community Login'];
            UserRole testRole = new UserRole(DeveloperName = 'TestRole', Name = 'Test Role');
        insert testRole;
        
        adminUser.UserRoleId = testRole.Id;
        update adminUser;
            User userObject = new User(
                alias = 'adb89',
                email = 'salesforce.gentry@gmail.com',
                emailencodingkey = 'UTF-8',
                lastname = 'gentryTest',
                languagelocalekey = 'en_US',
                localesidkey = 'en_US',
                profileid = objProfile.Id,
                timezonesidkey = 'America/Los_Angeles',
                username = 'salesforce.test3455@abc.com',
                contactId = objContact.Id
            );
            insert userObject;
        }
        
        // Verify the user was created
        System.assertEquals(1, [SELECT COUNT() FROM User WHERE username = 'salesforce.test3455@abc.com']);
        User loggedInUser = [SELECT Id FROM User WHERE username = 'salesforce.test3455@abc.com']; 
        System.runAs(loggedInUser){
            Test.startTest();
        List<Map<String, Object>> results = HousingSearchV3.getListingsOnProfile();
        Test.stopTest();
            System.assertEquals(0,results.size(),'No records should be returned');
        }
        
    }
    
    
    @isTest
    static void testGetWaitlistAttributes() {
        Test.startTest();
  
        List<Map<String, Object>> categoryResult = HousingSearchV3.getWaitlistAttributes('Category__c');
        List<Map<String, Object>> preferenceResult = HousingSearchV3.getWaitlistAttributes('Preference_Types__c');
        List<Map<String, Object>> voucherResult = HousingSearchV3.getWaitlistAttributes('Voucher_Types__c');
        
        Test.stopTest();
        
        
        System.assertEquals(2, categoryResult.size(), 'Category field should return 2 unique values');
        System.assertEquals(3, preferenceResult.size(), 'Preference field should return 3 unique values');
        System.assertEquals(2, voucherResult.size(), 'Voucher field should return 2 unique values');
        
        for(Map<String, Object> result : categoryResult) {
        System.assertEquals(result.get('value'), result.get('label'), 'Label should match value for category');
        System.assertEquals(false, result.get('selected'), 'Selected should be false by default for category');
    }
    
    for(Map<String, Object> result : preferenceResult) {
        System.assertEquals(result.get('value'), result.get('label'), 'Label should match value for preference');
        System.assertEquals(false, result.get('selected'), 'Selected should be false by default for preference');
    }
    
    for(Map<String, Object> result : voucherResult) {
        System.assertEquals(result.get('value'), result.get('label'), 'Label should match value for voucher');
        System.assertEquals(false, result.get('selected'), 'Selected should be false by default for voucher');
    }
        
    Set<String> categoryValues = new Set<String>();
    for(Map<String, Object> result : categoryResult) {
        categoryValues.add((String)result.get('value'));
    }
        system.debug(categoryValues);
    System.assert(categoryValues.contains('Preferences'), 'Result should contain "Preferences"');
    System.assert(categoryValues.contains('Set Aside'), 'Result should contain "Set Aside"');
    
    Set<String> preferenceValues = new Set<String>();
    for(Map<String, Object> result : preferenceResult) {
        preferenceValues.add((String)result.get('value'));
    }
    System.assert(preferenceValues.contains('Artist'), 'Result should contain "Artist"');
    System.assert(preferenceValues.contains('Homeless'), 'Result should contain "Homeless"');
    
    Set<String> voucherValues = new Set<String>();
    for(Map<String, Object> result : voucherResult) {
        voucherValues.add((String)result.get('value'));
    }
        System.debug(voucherValues);
    System.assert(voucherValues.contains('PBCA'), 'Result should contain "PBCA"');
    System.assert(voucherValues.contains('Tenant Based Section 8'), 'Result should contain "Project Based Vouchers"');
}
        
    @isTest
	static void testGetWaitlistAttributesInvalidField() {
    Test.startTest();
    
    // Call method with a field name that doesn't exist on Waitlist_Attributes__c
    Exception caughtException;
    try {
        List<Map<String, Object>> result = HousingSearchV3.getWaitlistAttributes('NonExistent_Field__c');
    } catch (Exception e) {
        caughtException = e;
    }
    
    // Verify exception was thrown and is of the correct type
    System.assertNotEquals(null, caughtException, 'An exception should be thrown for invalid field name');
    System.assert(caughtException instanceof AuraHandledException, 
                 'Exception should be of type AuraHandledException');
    
    Test.stopTest();
}
  
    @isTest
    static void testFetchWaitlistLocations() {
        Test.startTest();
        
        Map<String, List<Map<String, Object>>> result = HousingSearchV3.fetchWaitlistLocations();
        
        Test.stopTest();
        
        System.assert(result.containsKey('Cities'), 'Cities key should exist');
        System.assert(result.containsKey('Counties'), 'Counties key should exist');
        System.assert(result.containsKey('ZipCodes'), 'ZipCodes key should exist');
        
        System.assert(result.get('Cities').size() > 1, 'Cities list should contain more than one entry');
        System.assert(result.get('Counties').size() > 1, 'Counties list should contain more than one entry');
        System.assert(result.get('ZipCodes').size() > 1, 'ZipCodes list should contain more than one entry');
        
        System.assertEquals('All Cities', result.get('Cities')[0].get('value'), 'First city should be "All Cities"');
        System.assertEquals('All Counties', result.get('Counties')[0].get('value'), 'First county should be "All Counties"');
        System.assertEquals('All Zip Codes', result.get('ZipCodes')[0].get('value'), 'First zip code should be "All Zip Codes"');
    }
    
    
 @isTest
    static void testGetWaitListRecords_withHearingAid() {
        Test.startTest();        
        //search with amenities, preferences, and vouchers
        Map<String, Object> advancedInput = new Map<String, Object>{
            'UnitType' => '2BR',
            'Income' => '50000',
            'RentLow' => '1000',
            'RentHigh' => '2000',
            'LocationType' => 'City',
            'SelectedCity' => 'New York',
            'SelectedZip' => '10001',
            'Amenities' => new List<String>{'Artist'},
            'Preferences' => new List<String>{'Homeless'},
            'Vouchers' => new List<String>{'PBCA'},
            'Accessibility' => 'Hearing/Vision Adapted',
            'Project' => 'Test Project1',
            'isAccessibleUnit'=> true
        };
        
        List<Map<String, Object>> advancedResults = HousingSearchV3.getWaitListRecords(advancedInput);
        system.debug(advancedResults);         
        Test.stopTest();
        System.assertEquals(1, advancedResults.size(), 'Advanced search should return one listing');
    }
    
    
    @isTest
    static void testGetWaitListRecords_withMobilityAdapted() {
        Test.startTest();        
        //search with amenities, preferences, and vouchers
        Map<String, Object> advancedInput = new Map<String, Object>{
            'UnitType' => '2BR',
            'Income' => '50000',
            'RentLow' => '1000',
            'RentHigh' => '2000',
            'LocationType' => 'City',
            'SelectedCity' => 'New York',
            'SelectedZip' => '10001',
            'Amenities' => new List<String>{'Artist'},
            'Preferences' => new List<String>{'Homeless'},
            'Vouchers' => new List<String>{'PBCA'},
            'Accessibility' => 'Mobility Adapted',
            'Project' => 'Test Project1',
            'isAccessibleUnit'=> false
        };
        
        List<Map<String, Object>> advancedResults = HousingSearchV3.getWaitListRecords(advancedInput);
        system.debug(advancedResults);         
        Test.stopTest();
        System.assertEquals(0, advancedResults.size(), 'Advanced search should return zero listings');
    }
    
    @isTest
    static void testGetWaitListRecords_withEmptyInput() {
        Test.startTest();        
        //search with amenities, preferences, and vouchers
        Map<String, Object> advancedInput = new Map<String, Object>();
        
        List<Map<String, Object>> advancedResults = HousingSearchV3.getWaitListRecords(advancedInput);
        system.debug('hemanth');
        Test.stopTest();
        system.debug(advancedResults);
        System.assertEquals(3, advancedResults.size(), 'Advanced search should return 3 listings');
    }
    
    @isTest
    static void testGetWaitListRecords_withCountySelected() {
        Test.startTest();        
        //search with amenities, preferences, and vouchers
        Map<String, Object> advancedInput = new Map<String, Object>{
            'UnitType' => '2BR',
            'Income' => '50000',
            'RentLow' => '1000',
            'RentHigh' => '2000',
            'LocationType' => 'County',
            'SelectedCounty' => 'Albany',
            'SelectedZip' => '10001',
            'Amenities' => new List<String>(),
            'Preferences' => new List<String>(),
            'Vouchers' => new List<String>(),
            'Accessibility' => 'Hearing/Vision Adapted',
            'Project' => 'Test Project1',
            'isAccessibleUnit'=> true
        };
        
        List<Map<String, Object>> advancedResults = HousingSearchV3.getWaitListRecords(advancedInput);
        system.debug(advancedResults);         
        Test.stopTest();
        System.assertEquals(1, advancedResults.size(), 'Advanced search should return one listing');
    }
    
    @isTest
    static void testGetWaitListRecords_withZipSelected() {
        Test.startTest();        
        //search with amenities, preferences, and vouchers
        Map<String, Object> advancedInput = new Map<String, Object>{
            'UnitType' => '2BR',
            'Income' => '50000',
            'RentLow' => '1000',
            'RentHigh' => '2000',
            'LocationType' => 'Zip',
            'SelectedZip' => '10001',
            'Amenities' => new List<String>{'Artist'},
            'Preferences' => new List<String>{'Homeless'},
            'Vouchers' => new List<String>{'PBCA'},
            'Accessibility' => 'Hearing/Vision Adapted',
            'Project' => 'Test Project1',
            'isAccessibleUnit'=> true
        };
        
        List<Map<String, Object>> advancedResults = HousingSearchV3.getWaitListRecords(advancedInput);
        system.debug(advancedResults);         
        Test.stopTest();
        System.assertEquals(1, advancedResults.size(), 'Advanced search should return one listing');
    }
    
    @IsTest
    public static void testGetAccessebilities(){
        Test.startTest();
        List<Map<String, String>> results = HousingSearchV3.getAccessebilities();
        Test.stopTest();
        system.assertEquals(3,results.size(),'3 Accessibilities should be retrieved');
    }

     
}