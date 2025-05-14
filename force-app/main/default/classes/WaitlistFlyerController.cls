/**
 * @description       : This apex class is used as Controller for VF page (wishlistFlyerPage (English version) 
 * 						2. wishlistFlyerPage_arabic 3. wishlistFlyerPage_french 4. wishlistFlyerPage_bengali 
 * 						5. wishlistFlyerPage_HaitainCreole 6. wishlistFlyerPage_italian 7. wishlistFlyerPage_korean 
 * 						8. wishlistFlyerPage_polish 9. wishlistFlyerPage_Russian 10. wishlistFlyerPage_chinese 
 * 						11. wishlistFlyerPage_urdu 12. wishlistFlyerPage_Yiddish 13. wishlistFlyerPage_spanish.)
 * @author            : Heena Karir, Mohammad Nagoor 
 * @Test Class Name   : WaitlistFlyerControllerTest
**/
public without sharing class WaitlistFlyerController {

    public Waitlist__c development { get; set; }   
    public List<Waitlist_Rules__c> waitlistRules { get; set; }
    public List<Waitlist_Attributes__c> amenitiesList { get; set; }   
    public String language { get; set; }
    public String concatAddress { get; set; }
    public String applicationDate {get; set;}
    public String lotteryDate {get; set;}    
    public Decimal availableUnits {get; set;}
    public String waitlistType {get; set;}    
    public Integer householdSize { get; set; }
    public Account waitlistAccount {get; set;}
    public String managingAgentAddress {get; set;}   
    public String lotteryTime {get; set;}
    public List<WaitlistRuleWrapper> waitlistRulesMap { get; set; }
    public Map<String, List<HouseholdWrapper>> householdMap { get; set; }
    public Boolean HasImage {get; set;}
    public Boolean hasVouchers {get; set;}
    public List<Waitlist_Attributes__c> preferenceList{get; set;}
    public Boolean HasApplicationDate {get; set;}
    public Boolean HasTransitDetails {get; set;} 
    public List<String> additionalInfoPoints { get; set; }
    public List<String> accessibilityInfoPoints { get; set; }
    public List<Integer> getSignatureList {get; set;}
    public List<Waitlist_Building__c> waitlistBuildings { get; set; }
    public List<Waitlist_Building__c> buildings { get; set; }
    public Boolean HasLottery {get; set;}
    
    public class WaitlistRuleWrapper {
        public String amiCategory { get; set; }
        public String unitType { get; set; }
        public Integer numberOfUnits { get; set; }
         public String accessibility {get; set;}
        public Decimal monthlyRent { get; set; }
        public String uniqueKey { get; set; }
        public List<Integer> firstHouseholdIcon { get; set; }
        public Decimal firstMinIncome { get; set; }
        public Decimal firstMaxIncome { get; set; }
        public List<HouseholdWrapper> additionalHouseholds { get; set; }
           public Integer totalRowSpan { get; set; }
        public Integer additionalRowSpan {get; set; }
    }
    
    public class HouseholdWrapper {
        public Integer householdSize { get; set; }
        public Integer numberOfUnits {get; set;}
         public String accessibility {get; set;}
        public Decimal minIncome { get; set; }
        public Decimal maxIncome { get; set; }
        public List<Integer> sizeIcon {get; set;}
    }
    
    public WaitlistFlyerController() {    
        
          // Initialize lists to prevent null pointer exceptions  
          
        development= new Waitlist__c();       
        waitlistRules = new List<Waitlist_Rules__c>();
        amenitiesList = new List<Waitlist_Attributes__c>();       
        waitlistAccount = new Account();
       waitlistRulesMap = new List<WaitlistRuleWrapper>();
        householdMap = new Map<String, List<HouseholdWrapper>>();        
        preferenceList = new List<Waitlist_Attributes__c>();
         getSignatureList= new List<Integer>{1,2,3,4,5,6,7};
         waitlistBuildings = new List<Waitlist_Building__c>();
           
        //Id developmentId = ApexPages.currentPage().getParameters().get('id');
        Id developmentId = ApexPages.currentPage().getParameters().get('id');
        if (String.isBlank(developmentId)) {
            developmentId = 'a0Ycq0000029V5JEAU'; // Default ID if none provided
        }
        
        /*language = ApexPages.currentPage().getParameters().get('language');          
        language = 'en_US';
        System.debug('Language: '+language);
        language = String.isBlank(language) ? 'en_US' : language;*/

        loadDevelopmentData(developmentId);
        loadAMIData(developmentId);
    }

    private void loadDevelopmentData(Id developmentId) {
       
        try {
    
            // Fetch Development Data
            List<Waitlist__c> devList = [
                SELECT Id, Account__c, Address__c, Address__r.Street, Address__r.City, Address__r.State, 
                       Address__r.PostalCode, Address__r.Country, Application_Due__c, Type__c,Waitlist_Image_URL__c, 
                       Total_1BR_Units__c, Total_2BR_Units__c, Total_3BR_Units__c, Total_4BR_Units__c, 
                       Total_5BR_Units__c, Total_Studio_Units__c, Lottery_Run_Date__c, Name, Project__c, Is_Accessible_Unit__c,
                       Amenities__c, Priority_Admission_For_Mobility_Impaired__c,Lottery_Run_Time__c,Lottery_Run_Location__c, 
                       Priority_Admission_For_Hearing_Vision__c, Project_Name__c, Waitlist_URL__c,More_Information__c, 
                Experience_Tile_Image_URL__c, Credit_Check__c,Criminal_Background_Check__c, Transit_Details__c, Additional_Information__c,
                External_Application_URL__c, Main_Contact_Email__c, Main_Contact_Phone__c, Application_Process__c, Accessibility_Information__c,
                Income_Restrictions__c,Total_No_Hearing_Vision_Impairment_Units__c,Total_Num_Mobility_Impairment_Units__c,Organization_URL__c
                FROM Waitlist__c 
                WHERE Id = :developmentId 
                LIMIT 1
            ];
            
            buildings = [
                SELECT Id, Building__r.Name, Total_Units__c, County__c, Building_Address__Street__s, Building_Address__City__s,
				Building_Address__StateCode__s, Building_Address__PostalCode__s, Building_Address__CountryCode__s                
                FROM Waitlist_Building__c
                WHERE Waitlist__c = :developmentId
            ];
            
			 
            system.debug('wb   '+ buildings);
            
         
            development = devList[0];
            
            if(development.Experience_Tile_Image_URL__c != '/resource/BlankDevelopment'){
                HasImage = true;
            }else{
                HasImage = false;
            }
            
            String additionalInfo = development.Additional_Information__c;
            if (String.isNotBlank(additionalInfo)) {
                // Split using "." and clean up empty values
                additionalInfoPoints = new List<String>();
                  List<String> addInfoPoints = getBulletItems(additionalInfo);
                for (String point : addInfoPoints) {                    
                        additionalInfoPoints.add(point.trim());                   
                }
            }
            
            String accessibilityInfo = development.Accessibility_Information__c;
            if (String.isNotBlank(accessibilityInfo)) {
                // Split using "." and clean up empty values
                accessibilityInfoPoints = new List<String>();
                List<String> accessPointsList = getBulletItems(accessibilityInfo);
                for (String point : accessPointsList) {                  
                        accessibilityInfoPoints.add(point);
                    }
                }
            
            
            //availableUnits = development.Total_1BR_Units__c + development.Total_2BR_Units__c + development.Total_3BR_Units__c 
                					//+ development.Total_4BR_Units__c + development.Total_5BR_Units__c + development.Total_Studio_Units__c ;
            
            waitlistType = development.Type__c;  
            
            concatAddress = 
                (development.Address__r.Street != null ? development.Address__r.Street : '') + ', ' +
                (development.Address__r.City != null ? development.Address__r.City : '') + ', ' +
                (development.Address__r.State != null ? development.Address__r.State : '') + ', ' +
                (development.Address__r.PostalCode != null ? development.Address__r.PostalCode : '') + ', ' +
                (development.Address__r.Country != null ? development.Address__r.Country : '');
            
            if (String.isBlank(concatAddress.replaceAll(',\\s*,', '').trim())) {
                concatAddress = '';
            }
            
            if(development.Transit_Details__c != null){
                HasTransitDetails = true;
            }else{
                HasTransitDetails = false;
            }
              
               // Format using format method with desired pattern
              //Datetime dt = Datetime.valueOf(development.Application_Due__c.toString());             
              //applicationDate = dt.format('MMMM dd, yyyy');
              //Datetime ltDate = Datetime.valueOf(development.Lottery_Run_Date__c.toString());
              //lotteryDate = ltDate.format('MMMM dd, yyyy');
            	//lotteryTime = development.Lottery_Run_Time__c.format('HH:mm:ss a');
            	
           	// Format using format method with desired pattern
            if (development.Application_Due__c != null) {
                Datetime dt = Datetime.valueOf(development.Application_Due__c.toString());
                applicationDate = dt.format('MMMM dd, yyyy');
                HasApplicationDate = true;
            } else {
                HasApplicationDate = false;
            }
            if (development.Lottery_Run_Date__c != null) {
                Datetime ltDate = Datetime.valueOf(development.Lottery_Run_Date__c.toString());
                lotteryDate = ltDate.format('MMMM dd, yyyy');
            } else {
                lotteryDate = '';
            }
            
            if (development.Lottery_Run_Time__c != null) {
                lotteryTime = development.Lottery_Run_Time__c.format('h:mm a');
            } else {
                lotteryTime = '';
            }
            
            if(development.Type__c != 'HCR Lottery'){
                HasLottery = true;
            }else{
                HasLottery = false;
            }
            
            if(development.Main_Contact_Phone__c !=null){
                development.Main_Contact_Phone__c = getFormattedPhone(development.Main_Contact_Phone__c );
            }
            if(development.External_Application_URL__c ==null){
                 development.External_Application_URL__c=System.Label.Housing_Search_URL;//'nyshousingsearch.gov';
            }
            
            /*if (language != 'en_US') {
                           
                development.Amenities__c = translateText('en',language,development.Amenities__c); 
                waitlistType = translateText('en',language,waitlistType); 
                concatAddress=  translateText('en',language,concatAddress);            
                applicationDate = translateText('en',language,formattedDate);             
                lotteryDate = translateText('en',language,LotteryformattedDate);
                
            }   */   
      
            
            // Fetch Amenities Data
            List<Waitlist_Attributes__c> amenitiesList = [
                SELECT Id, Waitlist__c, Name, Amenities__c, Record_Type_Name__c 
                FROM Waitlist_Attributes__c 
                WHERE Record_Type_Name__c = 'Amenities' AND Waitlist__c = :developmentId 
                ORDER BY Amenities__c ASC
            ];   
            
            String[] tmp1 = New String[]{};
                for(Waitlist_Attributes__c attr : amenitiesList){
                   tmp1.add(attr.Amenities__c);                   
                }
            development.Amenities__c = string.join(tmp1,', ');
            
            
              //Get the Data for Paper Application
            //Fetch preference          
            preferenceList = [
                SELECT Id, Preference_Types__c,Value__c, Waitlist__c FROM Waitlist_Attributes__c WHERE
                RecordType.Name = 'Preferences'AND Waitlist__c = :developmentId
            ]; 
            
              //Fetch Vouchers:          
           hasVouchers = [SELECT COUNT()                       
                                       FROM Waitlist_Attributes__c                        
                                       WHERE RecordType.Name = 'Vouchers'                       
                                        AND Waitlist__c = :developmentId] == 0;
           
                      
            //Fetch Account Data
            List<Account> waitlistAcc = [SELECT Id, Email__c, Website, Phone,BillingStreet, BillingCity,BillingPostalCode,
                               BillingState, BillingCountry FROM Account 
                WHERE Id = :development.Account__c LIMIT 1];
            waitlistAccount = waitlistAcc[0];
           
            managingAgentAddress = waitlistAccount.BillingStreet+', '+waitlistAccount.BillingCity+', '+
                waitlistAccount.BillingState+', '+ waitlistAccount.BillingPostalCode+', '+waitlistAccount.BillingCountry;
          
        } catch (Exception e) {
            System.debug('Error loading development data: ' + e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error loading development data: ' + e.getMessage()));
        }
    }

    
    private void loadAMIData(Id developmentId) {
        try {  
           
            Map<String, List<HouseholdWrapper>> tempHouseholdMap = new Map<String, List<HouseholdWrapper>>();
             availableUnits = 0;
           /* List<Waitlist_Rules__c> rules = [SELECT Id, Waitlist__c, AMI_Category__c, AMI_Unit_Type__c, 
                   Household_Size__c, Min_Household_Income__c, Max_Household_Income__c, AMI_Monthly_Rent__c,
                             AMI_Number_Of_Units_By_Type__c,Accessibility__c FROM Waitlist_Rules__c 
                             WHERE AMI_Category__c != NULL AND Waitlist__c = :developmentId 
                             ORDER BY AMI_Category__c, AMI_Unit_Type__c, AMI_Number_Of_Units_By_Type__c,Household_Size__c ASC];*/
            
			 List<Waitlist_Rules__c> rules = [SELECT Id, Waitlist__c, AMI_Category__c, AMI_Unit_Type__c, 
             AMI_Monthly_Rent__c, AMI_Number_Of_Units_By_Type__c,Accessibility__c FROM Waitlist_Rules__c 
            WHERE AMI_Category__c != NULL AND Waitlist__c = :developmentId 
            ORDER BY AMI_Category__c, AMI_Unit_Type__c, AMI_Number_Of_Units_By_Type__c ASC];
            
          System.debug('Rules: '+rules);
            if(!rules.isEmpty()){
                /*
                for (Waitlist_Rules__c rule : rules) {
                    System.debug('Processing Rule: ' + rule);
                
                    try {
                        String unitType = rule.AMI_Unit_Type__c;
                        Integer householdSize = rule.Household_Size__c != null ? Integer.valueOf(rule.Household_Size__c) : 0;
                        Integer numberOfUnits = rule.AMI_Number_Of_Units_By_Type__c != null ? Integer.valueOf(rule.AMI_Number_Of_Units_By_Type__c) : 0;
                        String accessibility = 'none';
                        if(rule.Accessibility__c != null || rule.Accessibility__c != '')
                        {
                            accessibility = rule.Accessibility__c;
                        }
                        String uniqueKey = rule.AMI_Category__c + '-' + unitType+ '-' +accessibility;
                
                        // Initialize HouseholdWrapper
                        HouseholdWrapper household = new HouseholdWrapper();
                        household.householdSize = householdSize;
                        household.numberOfUnits = numberOfUnits;
                        household.sizeIcon = new List<Integer>();
                        household.accessibility = accessibility;
                
                        // Generate size icons
                        for (Integer i = 1; i <= household.householdSize; i++) {
                            household.sizeIcon.add(i);
                        }
                
                        household.minIncome = rule.Min_Household_Income__c;
                        household.maxIncome = rule.Max_Household_Income__c;
                        
                
                        // Manage HouseholdWrapper in Map
                        if (!tempHouseholdMap.containsKey(uniqueKey)) {
                            tempHouseholdMap.put(uniqueKey, new List<HouseholdWrapper>());
                        }
                        tempHouseholdMap.get(uniqueKey).add(household);
                
                        availableUnits += household.numberOfUnits;
                        
                    } catch (Exception ex) {
                        System.debug('Error processing rule: ' + ex.getMessage());
                    }
                    
                }
               */
				
                Set<String> existingKeys = new Set<String>();
                for (Waitlist_Rules__c eachRule : rules) {
                    
                	String accessibility = 'none';
                    if (eachRule.AMI_Category__c == null || eachRule.AMI_Unit_Type__c == null) {
                        System.debug('Skipping rule due to missing AMI_Category__c or AMI_Unit_Type__c');
                        continue;
                    }
                	if(eachRule.Accessibility__c != null || eachRule.Accessibility__c != '')
                    {
                        accessibility = eachRule.Accessibility__c;
                    }
                    
                    String uniqueKey = eachRule.AMI_Category__c + '-' + eachRule.AMI_Unit_Type__c+
                    eachRule.AMI_Number_Of_Units_By_Type__c +'-' +accessibility;                    
                
                    // Check for duplicates using Set
                    if (existingKeys.contains(uniqueKey)) {
                        System.debug('Duplicate Found, Skipping');
                        continue;
                    }                
                    existingKeys.add(uniqueKey);
                    
                    // Initialize Wrapper
                    WaitlistRuleWrapper wrapper = new WaitlistRuleWrapper();
                    wrapper.amiCategory = eachRule.AMI_Category__c;                
                    // Handle unit type
                    if (eachRule.AMI_Unit_Type__c.equals('0')) {
                        wrapper.unitType = 'Studio';
                    } else {
                        wrapper.unitType = eachRule.AMI_Unit_Type__c + ' BR';
                    }                
                    wrapper.numberOfUnits = eachRule.AMI_Number_Of_Units_By_Type__c != null ? Integer.valueOf(eachRule.AMI_Number_Of_Units_By_Type__c) : 0;
                    wrapper.monthlyRent = eachRule.AMI_Monthly_Rent__c;
                    wrapper.uniqueKey = uniqueKey;
					wrapper.accessibility =  eachRule.Accessibility__c;
                    //wrapper.totalRowSpan =0;
                    // Fetch Household Data
                   List<Listing_Rule_Criteria__c> criteria = [Select Id, Household_Size__c, HH_Min_Income__c, HH_Max_Income__c
                                                             From Listing_Rule_Criteria__c Where Listing_Rule__c=:eachRule.Id
                                                              ORDER BY Household_Size__c ASC];
                     wrapper.additionalRowSpan=0;
                     System.debug('criteria: '+criteria);
                    if(!criteria.isEmpty())
                    {
                      wrapper.additionalRowSpan = criteria.size();
                        for(Listing_Rule_Criteria__c eachCriteria:criteria)
                        {
                              // Initialize HouseholdWrapper
                       		HouseholdWrapper household = new HouseholdWrapper();
                            household.householdSize = Integer.valueOf(eachCriteria.Household_Size__c);
                            household.minIncome = Integer.valueOf(eachCriteria.HH_Min_Income__c);
                        	household.maxIncome = Integer.valueOf(eachCriteria.HH_Max_Income__c);
                               household.sizeIcon = new List<Integer>();
                            // Generate size icons
                            for (Integer i = 1; i <= household.householdSize; i++) {
                                household.sizeIcon.add(i);
                            }
                            // Manage HouseholdWrapper in Map
                            if (!tempHouseholdMap.containsKey(uniqueKey)) {
                                tempHouseholdMap.put(uniqueKey, new List<HouseholdWrapper>());
                            }
                            tempHouseholdMap.get(uniqueKey).add(household);
                        }                  
                    
                        List<HouseholdWrapper> households = tempHouseholdMap.get(uniqueKey);
                        if (households != null && !households.isEmpty()) {                        
                    
                            // First Household Data
                            wrapper.firstHouseholdIcon = new List<Integer>();
                            for (Integer i = 1; i <= households[0].householdSize; i++) {
                                wrapper.firstHouseholdIcon.add(i);
                            }
                            wrapper.firstMinIncome = households[0].minIncome;
                            wrapper.firstMaxIncome = households[0].maxIncome;
                    
                            // Additional Household Data
                            wrapper.additionalHouseholds = new List<HouseholdWrapper>();
                            for (Integer i = 1; i < households.size(); i++) {
                                wrapper.additionalHouseholds.add(households[i]);
                            }
                        }
                    }     
                      
                    // Add Wrapper to Map
                    waitlistRulesMap.add(wrapper);
                    
                }
                   calculateRowSpans();
                 
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error loading AMI data: ' + e.getMessage()));
        }
        
        
    }
    
    
    private void calculateRowSpans() {
        try{
        Map<String, Integer> amiRowspans = new Map<String, Integer>();
        
        // First pass: count total rows for each AMI category
        for(WaitlistRuleWrapper rule : waitlistRulesMap) {
            String amiCategory = rule.amiCategory;
            Integer currentSpan = amiRowspans.containsKey(amiCategory) ? amiRowspans.get(amiCategory) : 0;
            
            // Add 1 for the main row
            currentSpan += 1;
            
            // Add rows for additional households
            if(rule.additionalHouseholds != null) {
                currentSpan += rule.additionalHouseholds.size();
            }
            
            amiRowspans.put(amiCategory, currentSpan);
        }
        
        // Second pass: set the rowspan for each rule
        String currentAmi = '';
        for(WaitlistRuleWrapper rule : waitlistRulesMap) {
            if(currentAmi != rule.amiCategory) {
                rule.totalRowSpan = amiRowspans.get(rule.amiCategory);
                currentAmi = rule.amiCategory;
            }else
            {
                rule.totalRowSpan = 0;
            }
            
             System.debug('totalRowSpan1: '+rule.totalRowSpan);
        }
        System.debug('totalRowSpan: '+amiRowspans);
        }
        catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error calculating row span: ' + e.getMessage()));
        }
    }

    private String getFormattedPhone(string phone) {   
    if (phone != null && phone.length() == 10) {
        return '(' + phone.substring(0, 3) + ')-' + 
               phone.substring(3, 7) + '-' + 
               phone.substring(7, 10);
    }
    return phone;
} 
    
    private List<String> getBulletItems(String text) {      
      
        System.debug('text :'+text);
        // Temporarily replace decimal numbers with a placeholder
        Pattern decimalPattern = Pattern.compile('\\d+\\.\\d+');
        Matcher decimalMatcher = decimalPattern.matcher(text);
        
        Map<String, String> replacements = new Map<String, String>();
        Integer counter = 0;
        
        while (decimalMatcher.find()) {
            String decimalVal = decimalMatcher.group();
            String placeholder = '##DECIMAL' + counter + '##';
            replacements.put(placeholder, decimalVal);
            text = text.replace(decimalVal, placeholder);
            counter++;
        }
         System.debug('text 2 :'+text);
        // Now split by periods
        List<String> sentences = text.split('\\.');
         System.debug('sentences :'+sentences);
        // Restore decimal numbers in each sentence
        List<String> processedSentences = new List<String>();
        for (String sentence : sentences) {
            String processedSentence = sentence.trim();
            System.debug('processedSentence :'+processedSentence);
            if (processedSentence!=''){            
                for (String placeholder : replacements.keySet()) {
                    if (processedSentence.contains(placeholder)) {
                        processedSentence = processedSentence.replace(placeholder, replacements.get(placeholder));
                    }
                }
            }
            System.debug('processedSentence :'+processedSentence);
            processedSentences.add(processedSentence);
        }
        System.debug('processedSentences :'+processedSentences);
        return processedSentences;
    }
       
      // Method to translate text using Google Translation API
  /*  public static String translateText(String sourceLanguage, String targetLanguage, String text){
        if (String.isBlank(text)) {
            return text;
        }
        
      List<Flyer_Translation__mdt> cmd = Flyer_Translation__mdt.getAll().values();
    	// RapidAPI Google Translate API Endpoint
  		String GOOGLE_TRANSLATE_URL = cmd[0].Google_Translate_URL__c;
    
        String GOOGLE_TRANSLATE_BATCH_URL = cmd[0].Google_Translate_Batch_URL__c;
     
        // Replace with your actual RapidAPI API Key
        String API_KEY = cmd[0].API_Key__c;
        
        System.debug(GOOGLE_TRANSLATE_URL);
        System.debug(GOOGLE_TRANSLATE_BATCH_URL);
        System.debug(API_KEY);
        
        string translationMessage; 
        system.debug('sourceLanguage ==>' + sourceLanguage);
        system.debug('targetLanguage ==>' + targetLanguage);
        system.debug('text ==>' + text);
        
        
        if (String.isEmpty(text) || String.isEmpty(targetLanguage)) {
            return 'Invalid input: Text and target language are required.';
        }
 
        try {
            // Construct the request body in JSON format
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('from', sourceLanguage);  // Source language (can be 'auto')
            requestBody.put('to', targetLanguage);    // Target language
            requestBody.put('text', text.toLowerCase()); 
            // The text to translate
 
            String jsonBody = JSON.serialize(requestBody);
 
            // Create HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(GOOGLE_TRANSLATE_URL);  // Correct endpoint without the API key in the URL
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('x-rapidapi-key', API_KEY);  // Correct header for RapidAPI key
            req.setHeader('x-rapidapi-host', 'google-translate113.p.rapidapi.com');
            req.setBody(jsonBody);  // Set the JSON body
 
            // Send HTTP request
            Http http = new Http();
            HTTPResponse res = http.send(req);
 
            // Parse JSON response
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                translationMessage = string.valueOf(responseMap.get('trans'));
                system.debug('data =>' + responseMap.get('trans'));
                return translationMessage;
 
                
            } else {
                String errorMessage = 'Error: ' + res.getStatusCode() + ' - ' + res.getBody();
                System.debug(errorMessage);
                return errorMessage;
            }
        } catch (Exception e) {
            String error = 'Translation failed: ' + e.getMessage();
            System.debug(error);
            return error;
        }
    }*/
}