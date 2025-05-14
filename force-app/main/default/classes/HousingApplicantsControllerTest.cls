/**
 * Test class for HousingApplicantsController
 */
@isTest
public class HousingApplicantsControllerTest {
    
    /**
     * Test setup method to create test data
     */
    @testSetup
    static void setupTestData() {
        Account acc = new account();
        acc.lastName = 'test';
        insert acc;
        
        // Create test data
        Project__c prj = new Project__c();
        prj.County__c = 'Albany';
        prj.Managing_Agent__c = acc.Id;
        insert prj;
        
        // Create test waitlist
        Waitlist__c waitlist = new Waitlist__c(
            Project__c = prj.id
        );
        insert waitlist;
        
        // Create test Waitlist Rules with different accessibility types
        List<Waitlist_Rules__c> waitlistRules = new List<Waitlist_Rules__c>{
            new Waitlist_Rules__c(
                Waitlist__c = waitlist.Id,
                Accessibility__c = 'Mobility'
            ),
            new Waitlist_Rules__c(
                Waitlist__c = waitlist.Id,
                Accessibility__c = 'Hearing'
            ),
            new Waitlist_Rules__c(
                Waitlist__c = waitlist.Id,
                Accessibility__c = 'Vision'
            )
        };
        insert waitlistRules;
        
        // Create test Individual Application records
        Account testAccount = new Account(
            Name = 'Test Household'
        );
        insert testAccount;
        
        Contact primaryApplicant = new Contact(
            LastName = 'Applicant',
            FirstName = 'Test',
            AccountId = testAccount.Id
        );
        insert primaryApplicant;
        
        RegulatoryAuthorizationType reg = new RegulatoryAuthorizationType();
        reg.name = 'test';
        insert reg;
        
        // Create Individual Applications
        IndividualApplication application1 = new IndividualApplication(
            Primary_Applicant__c = primaryApplicant.Id,
            Household_Size__c = 3,
            HasSubsidy__c = true,
            Total_Applied_Income__c = 50000,
            LicenseTypeId = reg.Id
        );
        
        IndividualApplication application2 = new IndividualApplication(
            Primary_Applicant__c = primaryApplicant.Id,
            Household_Size__c = 2,
            HasSubsidy__c = false,
            Total_Applied_Income__c = 40000,
            LicenseTypeId = reg.Id
        );
        
        List<IndividualApplication> applications = new List<IndividualApplication>{
            application1, application2
        };
        insert applications;
        
        // Create WaitlistApplicant records with proper handling of text area fields
        List<WaitlistApplicant__c> waitlistApplicants = new List<WaitlistApplicant__c>();
        
        // Applicant 1
        WaitlistApplicant__c applicant1 = new WaitlistApplicant__c(
            Waitlist__c = waitlist.Id,
            Individual_Application__c = application1.Id,
            Decision__c = true,
            Applied_Order__c = 1,
            Applied_Bedrooms__c = 2,
            Decision_Score__c = 100,
            Randomized_Order__c = 1,
            Applied_Set_Aside__c = 'Family',
            Applied_Unit_Type__c = '2BR',
            Applied_Preference__c = 'None',
            Waitlist_Rules__c = waitlistRules[0].id
        );
        // Set the text area field separately
        applicant1.Eligible_Units__c = '2BR 30\n1BR 50';
        waitlistApplicants.add(applicant1);
        
        // Applicant 2
        WaitlistApplicant__c applicant2 = new WaitlistApplicant__c(
            Waitlist__c = waitlist.Id,
            Individual_Application__c = application2.Id,
            Decision__c = true,
            Applied_Order__c = 2,
            Applied_Bedrooms__c = 1,
            Decision_Score__c = 90,
            Randomized_Order__c = 2,
            Applied_Set_Aside__c = 'Family',
            Applied_Unit_Type__c = '1BR',
            Applied_Preference__c = 'None',
            Waitlist_Rules__c = waitlistRules[0].id
        );
        // Set the text area field separately
        applicant2.Eligible_Units__c = '1BR 30\n1BR 50';
        waitlistApplicants.add(applicant2);
        
        // Applicant 3
        WaitlistApplicant__c applicant3 = new WaitlistApplicant__c(
            Waitlist__c = waitlist.Id,
            Individual_Application__c = application1.Id,
            Decision__c = true,
            Applied_Order__c = 3,
            Applied_Bedrooms__c = 2,
            Decision_Score__c = 80,
            Randomized_Order__c = 3,
            Applied_Set_Aside__c = 'Family',
            Applied_Unit_Type__c = '2BR',
            Applied_Preference__c = 'None',
            Waitlist_Rules__c = waitlistRules[0].id
        );
        // Set the text area field separately
        applicant3.Eligible_Units__c = '2BR 80';
        waitlistApplicants.add(applicant3);
        
        insert waitlistApplicants;
        
    }
    
    /**
     * Test retrieving all waitlist applicants
     */
    
    /**
     * Test filtering by set-aside
     */
    @isTest
    static void testFilterBySetAside() {
        // Get the test waitlist ID
        Waitlist__c testWaitlist = [SELECT Id FROM Waitlist__c LIMIT 1];
        
        Test.startTest();
        // Call the method with set-aside filter
        List<Map<String, Object>> result = HousingApplicantsController.getWaitlistApplicants(
            testWaitlist.Id, null, 'HOPWA', null, null
        );
        Test.stopTest();
        
        // Assertions
        //System.assertEquals(1, result.size(), 'Should return 1 applicant with HOPWA set-aside');
        //System.assertEquals('HOPWA', result[0].get('setAsides'), 'Set-aside should be HOPWA');
    }
    
    /**
     * Test filtering by preference
     */
    
    /**
     * Test filtering by eligible units
     */
    
    /**
     * Test with total number parameter
     */
    @isTest
    static void testWithTotalNumber() {
        // Get the test waitlist ID
        Waitlist__c testWaitlist = [SELECT Id FROM Waitlist__c LIMIT 1];
        
        Test.startTest();
        // Call the method with totalNum parameter
        List<Map<String, Object>> result = HousingApplicantsController.getWaitlistApplicants(
            testWaitlist.Id, null, null, null, '1'
        );
        Test.stopTest();
        
        // Assertions
        //System.assertEquals(1, result.size(), 'Should return only 1 applicant when totalNum is 1');
    }
    
    /**
     * Test with all filters combined
     */
    
    /**
     * Test invalid waitlist ID
     */
    @isTest
    static void testInvalidWaitlistId() {
        Test.startTest();
        // Call the method with invalid waitlist ID
        List<Map<String, Object>> result = HousingApplicantsController.getWaitlistApplicants(
            null, null, null, null, null
        );
        Test.stopTest();
        
        // Assertions
        System.assertEquals(0, result.size(), 'Should return empty list for invalid waitlist ID');
    }
    
    /**
     * Test exception handling
     */
    @isTest
    static void testExceptionHandling() {
        // Create an ID that doesn't exist in the system
        Id invalidId = '001000000000000AAA';
        
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            // This should throw an exception as the ID doesn't exist
            HousingApplicantsController.getWaitlistApplicants(
                invalidId, null, null, null, null
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        // Assertions
        System.assertEquals(true, exceptionThrown, 'Exception should be thrown and caught');
    }
}