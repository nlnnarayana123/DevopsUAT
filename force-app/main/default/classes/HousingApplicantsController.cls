/**
 * Controller to retrieve housing applicants for the housing applicant table component
 */
public without sharing class HousingApplicantsController {
    
    /**
     * Retrieves waitlist applicants formatted for display in the Housing Applicants LWC
     * @param waitlistId - The ID of the waitlist to retrieve applicants for
     * @param unitsStr - The eligible units string to filter applicants by
     * @param setAside - The set-aside value to filter by
     * @param preference - The preference value to filter by
     * @param appliedFiled - String indicator for appeal filed status
     * @param status - List of status values to filter by   
     * @return List<Map<String, Object>> - Formatted applicant data for the component
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getWaitlistApplicants(
        String waitlistId, 
        String unitsStr, 
        String setAside, 
        String preference, 
        List<String> status
    ) {
        List<Map<String, Object>> formattedApplicants = new List<Map<String, Object>>();
        List<WaitlistApplicant__c> matchingRecords = new List<WaitlistApplicant__c>();
        String totalNum;
        
        try {
            // Input validation
            if (String.isBlank(waitlistId)) {
                return formattedApplicants;
            }
            
            // Default to 10000 records if totalNum is not specified
            if (String.isBlank(totalNum)) {
                totalNum = '10000';
            }
            
            // Query for waitlist record to check if lottery has been run
            Waitlist__c waitListRecord = [SELECT Id, Type__c, Actual_Lottery_Run_DateTime__c 
                                         FROM Waitlist__c 
                                         WHERE Id = :waitlistId LIMIT 1];
            
            // Build dynamic query - FIXED: Added missing comma after Applicant_Tiles_Filter_Status__c
            String baseQuery = 'SELECT Id, Eligible_Units__c, Decision__c, Name, Applied_Order__c, ' +
                          'Applied_Bedrooms__c, Decision_Score__c, Randomized_Order__c, Applied_Set_Aside__c, ' +
                          'Individual_Application__c, Applied_Unit_Type__c, Applied_Preference__c, CreatedDate, ' +
                          'Waitlist__r.RecordType.Name, ' + 
                          'Individual_Application__r.Applicant_Tiles_Filter_Status__c, ' + // FIXED: Added comma here
                          'Individual_Application__r.Primary_Applicant__r.Name, ' +
                          'Individual_Application__r.Primary_Applicant__r.MobilePhone, Individual_Application__r.Reject_Reason__c, Individual_Application__r.Reject_Reason_Other__c, ' +
                          'Individual_Application__r.Primary_Applicant__r.Phone, Individual_Application__r.Appeal_Reject_Other__c,  Individual_Application__r.Appeal_Rejection_Reason__c, ' +
                          'Individual_Application__r.CreatedDate, Individual_Application__r.Name,' +
                          'Individual_Application__r.Household_Size__c, Application_Status__c, ' +
                          'Individual_Application__r.HasSubsidy__c, Individual_Application__r.Status, ' +
                          'Individual_Application__r.Total_Applied_Income__c, Individual_Application__r.Appeal_Filed__c ' +
                          'FROM WaitlistApplicant__c ' +
                          'WHERE Waitlist__c = :waitlistId ' +
                          'AND Individual_Application__r.WaitlistEligible__c = true ' +
                          'AND Status__c != \'Rejected\' ';
            
            // Add status filter if provided
            if (status != null && !status.isEmpty()) {
                baseQuery += ' AND Individual_Application__r.Applicant_Tiles_Filter_Status__c IN :status';
            }
            
            // Safely add set-aside filter if provided
            if (String.isNotBlank(setAside)) {
                baseQuery += ' AND Applied_Set_Aside__c LIKE \'%' + String.escapeSingleQuotes(setAside) + '%\'';
            }
            
            // Safely add preference filter if provided
            if (String.isNotBlank(preference)) {
                baseQuery += ' AND Applied_Preference__c LIKE \'%' + String.escapeSingleQuotes(preference) + '%\'';
            }
            
            // Add appeal filed filter if specified
            /*if(String.isNotBlank(appliedFiled) && appliedFiled.equalsIgnoreCase('true')){
                baseQuery += ' AND Individual_Application__r.Appeal_Filed__c = true';
            }*/
            
            // Add order by and limit
            Integer limitValue = Integer.valueOf(totalNum);
            Boolean lottery = false;
            
            if(waitListRecord.Type__c == 'HCR Lottery' ){
                if(waitListRecord.Type__c == 'HCR Lottery' && waitListRecord.Actual_Lottery_Run_DateTime__c == null ){
                    baseQuery += ' ORDER BY Applied_Order__c ASC NULLS LAST LIMIT :limitValue';   
                    lottery = true;   
                } else {
                    baseQuery += ' ORDER BY Randomized_Order__c ASC NULLS LAST LIMIT :limitValue';   
                    lottery = true;
                }
            } else {
                baseQuery += ' ORDER BY CreatedDate ASC NULLS LAST LIMIT :limitValue';
            }
            
            System.debug('baseQuery ==>' + baseQuery);
            
            // Execute dynamic query
            List<WaitlistApplicant__c> applicants = Database.query(baseQuery);
            System.debug('Query returned ' + applicants.size() + ' records');
            
            // Apply unitsStr filter if provided, otherwise use all records
            if (String.isNotBlank(unitsStr)) {
                for (WaitlistApplicant__c record : applicants) {
                    if (record.Eligible_Units__c != null && record.Eligible_Units__c.contains(unitsStr)) {
                        matchingRecords.add(record);
                    }
                }
            } else {
                // If unitsStr is blank, include all records
                matchingRecords = applicants;
            }
            
            System.debug('After filtering, matchingRecords has ' + matchingRecords.size() + ' records');
            
            // Return early if no matching records
            if (matchingRecords.isEmpty()) {
                return formattedApplicants;
            }
            
            // Format each applicant for the component
            Integer position = 1;
            
            for (WaitlistApplicant__c record : matchingRecords) {
                // Get income value if available
                Decimal income = (record.Individual_Application__r != null) ? 
                    record.Individual_Application__r.Total_Applied_Income__c : null;
                
                // Calculate days in waitlist if created date is available
                String waitlistDays = '0';
                if (record.Individual_Application__r != null && record.Individual_Application__r.CreatedDate != null) {
                    Integer days = Math.abs(System.today().daysBetween(record.Individual_Application__r.CreatedDate.date()));
                    waitlistDays = String.valueOf(days);
                }

                // if (record.Reject_Reason__c){

                // }
                
                
                
                // Format the applicant record for the component
                Map<String, Object> applicantMap = new Map<String, Object>{
                    'id' => record.Id,
                    'position' => position,
                    'individualApplicationNumber' => (record.Individual_Application__r.Name != null) ? String.valueOf(record.Individual_Application__r.Name) : '',
                    'name' => (record.Individual_Application__r != null) ? record.Individual_Application__r.Primary_Applicant__r.Name : '',
                    'hhSize' => (record.Individual_Application__r != null) ? String.valueOf(record.Individual_Application__r.Household_Size__c) : '',
                    'income' => income,
                    'preferences' => 
                        (record.Applied_Preference__c != null && record.Applied_Preference__c.toLowerCase() != 'null') 
                        ? record.Applied_Preference__c 
                        : '',
                    'setAsides' => 
                        (record.Applied_Set_Aside__c != null && record.Applied_Set_Aside__c.toLowerCase() != 'null') 
                        ? record.Applied_Set_Aside__c 
                        : '',
                    'rentalSubsidy' => (record.Individual_Application__r != null) ? 
                                      ((record.Individual_Application__r.HasSubsidy__c == true) ? 'Yes' : 'No') : 'No',
                    'eligibility' => record.Eligible_Units__c,
                    'preferredUnitSize' =>  (record.Applied_Unit_Type__c != null && record.Applied_Unit_Type__c.toLowerCase() != 'null') 
                        ? record.Applied_Unit_Type__c 
                        : '',
                    'status' => record.Application_Status__c,
                    'isApplicantRejected' => record.Individual_Application__r.Reject_Reason__c != null ? true : false,
                    'isAppealRejected' => record.Individual_Application__r.Appeal_Rejection_Reason__c != null ? true : false,
                    'applicantRejectReason' =>  (record.Individual_Application__r.Reject_Reason__c == 'Other') ? record.Individual_Application__r.Reject_Reason_Other__c : record.Individual_Application__r.Reject_Reason__c,
                    'appealRejectReason' =>  (record.Individual_Application__r.Appeal_Rejection_Reason__c == 'Other') ? record.Individual_Application__r.Appeal_Reject_Other__c : record.Individual_Application__r.Appeal_Rejection_Reason__c,
                    'mobilePhone' => (record.Individual_Application__r != null) ? record.Individual_Application__r.Primary_Applicant__r.MobilePhone : '',
                    'phone' => (record.Individual_Application__r != null) ? record.Individual_Application__r.Primary_Applicant__r.Phone : '',
                    'appliedIncome' => income,
                    'occupants' => (record.Individual_Application__r != null) ? String.valueOf(record.Individual_Application__r.Household_Size__c) : '',
                    'waitlistDays' => waitlistDays,
                    'appliedOrder' => record.Applied_Order__c != null ? String.valueOf(record.Applied_Order__c) : '0',
                    'randomizedOrder' => (lottery == true) ? String.valueOf(record.Randomized_Order__c) : String.valueOf(record.Applied_Order__c),
                    'expanded' => false,
                    'expandIcon' => 'utility:chevrondown',
                    'detailClass' => 'slds-hide',
                    'individualApplication' => (record.Individual_Application__r != null) ? String.valueOf(record.Individual_Application__r.Id) : '',
                    'sumbittedStatus' => (record.Individual_Application__r.Applicant_Tiles_Filter_Status__c == 'Submitted') ?  true: false,
                    'selectedForReview' => (record.Individual_Application__r.Applicant_Tiles_Filter_Status__c == 'Selected For Review') ?  true: false,
                    'acceptReview' => (record.Individual_Application__r.Applicant_Tiles_Filter_Status__c == 'Unit Ready to be Offered') ?  true: false,
                    'unitOffered' => (record.Individual_Application__r.Applicant_Tiles_Filter_Status__c == 'Unit Offered') ?  true: false,
                    'appealFiled' => (record.Individual_Application__r.Applicant_Tiles_Filter_Status__c == 'Appeal Filed') ?  true: false
                };
                
                formattedApplicants.add(applicantMap);
                position++;
            }
            
            System.debug('formattedApplicants ==>' + formattedApplicants);
            
        } catch (Exception e) {
            System.debug('Error retrieving waitlist applicants: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            throw new AuraHandledException('Error retrieving applicants: ' + e.getMessage());
        }
        
        return formattedApplicants;
    }
}