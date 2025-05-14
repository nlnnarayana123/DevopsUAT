// eligibilityRuleSinglestep.js
import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getEligibilityRule from '@salesforce/apex/EligibilityRuleTempController.getEligibilityRule';
import saveEligibilityRule from '@salesforce/apex/EligibilityRuleTempController.saveEligibilityRule';
import updateEligibilityRule from '@salesforce/apex/EligibilityRuleTempController.updateEligibilityRule';
import getAccessibilityUnitsForWaitlist from '@salesforce/apex/EligibilityRuleTempController.getAccessibilityUnitForWaitlist';
import  getSetAsideUnitsForWaitlist from '@salesforce/apex/EligibilityRuleTempController.getSetAsideUnitsForWaitlist';
import  deleteEligibilityRule from '@salesforce/apex/EligibilityRuleTempController.deleteEligibilityRule';
import getPicklistValues from '@salesforce/apex/EligibilityRuleTempController.getPicklistValues';
import listingRules from '@salesforce/apex/ListingRuleCriteriacontroller.getlistingRules';
import updateRule from '@salesforce/apex/ListingRuleCriteriacontroller.updatelistingRules';
import deleteRule from '@salesforce/apex/ListingRuleCriteriacontroller.deletelistingRules';    
import addRule from '@salesforce/apex/ListingRuleCriteriacontroller.AddlistingRules';
import pubsub from 'omnistudio/pubsub';

export default class EligibilityRuleSinglestep extends LightningElement {
    errors = {};
    hasFormErrors = false;
    @api waitlistId;
    @api waitlistRule;
    @api waitlist;
    @track showSpinner = false;
    rulesAvailable = false;
    _isClosing = false;
    showSaveButton = false;
    @track newRule = {
        HouseholdSize: '',
        MinHouseholdIncome: '',
        MaxHouseholdIncome: ''
    };
    isSetAside = false;
    isStandardRule = false;
    disableRuleSelection = false;
    showDeleteRuleButton = false;
    showAccessbilityOptions = false;
    @track accessibilityUnitOptions = [];
    @track setAsideTypeOptions = [];
    @track AMICategory = [];
    @track AMIUnitType = [];
    @track rules = [];
    @track originalRules = []; // To store original values for cancel operation
    
    @track eligibilityRule = {};
    originalEligibilityRules = {};

    connectedCallback() {
        console.log(this.waitlistId,'waitlistId');
        console.log(this.waitlistRule?.WaitlistRuleId,'waitlist Rule ID....');
        this.waitlistRuleId = this.waitlistRule?.WaitlistRuleId
        // Fetch accessibility units based on waitlistRuleId
        if (this.waitlistId) {
            this.showSaveButton = true;
            
            this.loadAccessibilityUnits();
            this.loadSetAsideUnits();
            this.loadAMICategoryPicklistValues();
            this.loadNoOfBedRoomsPicklistValues();

            
        }
        console.log(this.SetAsideOptions,'set aside options');
        console.log(JSON.stringify(this.eligibilityRule),'eligibility rule');
    
    }

    loadAccessibilityUnits() {
        this.showSpinner = true;

        getAccessibilityUnitsForWaitlist({ waitlistId: this.waitlistId })
            .then(result => {
                console.log(JSON.stringify(result),'hemanth first');
                this.accessibilityOptions = result;
                if (this.accessibilityOptions.length > 0) {
                    this.showAccessbilityOptions = true;
                }
                // if (this.accessibilityOptions.length) {
                //     this.eligibilityRule.accessibilityUnit = this.accessibilityOptions[0].value;
                // }
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading Accessibility Units',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }


    loadSetAsideUnits() {
        this.showSpinner = true;

        getSetAsideUnitsForWaitlist({ waitlistId: this.waitlistId })   
            .then(result => {
                console.log(JSON.stringify(result),'hemanth second');
                this.SetAsideOptions = result;
                if (this.SetAsideOptions.length) {
                    this.eligibilityRule.SetAsideUnit = this.SetAsideOptions[0].value;
                }
                if (this.waitlistRuleId) {
                    this.loadExistingRule();
                    this.getListingRules();
                    
                    this.disableRuleSelection = true;
                } else {
                    this.eligibilityRule.ruleType = 'set-aside';
                }
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading SetAside Units',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }


    

    loadExistingRule() {
        this.showSpinner = true;
        getEligibilityRule({ recordId: this.waitlistRuleId })
            .then(result => {
                console.log(JSON.stringify(result),'eligibility rules');
                this.eligibilityRule = result;
                this.originalEligibilityRules = {...result};
                // console.log(JSON.stringify(this.eligibilityRule),'this.eligibilityRule');
                // console.log(JSON.stringify(this.SetAsideOptions),'SetAsideOptions');
                this.isStandardRule = this.eligibilityRule.ruleType == 'Standard Eligibility Rule' ? true : false;
                // console.log(this.isStandardRule,this.eligibilityRule,'isStandardRule',this.eligibilityRule.ruleType);
                this.isSetAside = this.eligibilityRule.ruleType == 'This is for Set Aside' ? true : false;
                this.rulesAvailable = this.eligibilityRule.ruleType == 'Standard Eligibility Rule' ? true : false;
                this.showSaveButton = this.eligibilityRule.ruleType == 'Standard Eligibility Rule' ? true : false;
                this.showDeleteRuleButton = true;
                this.disableRuleSelection = true;
                this.showSpinner = false;

            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            })
    }

    get isStandardRule() {
        return this.eligibilityRule.ruleType === 'standard';
    }

    get isSetAside() {
        return this.eligibilityRule.ruleType === 'set-aside';
    }
    
    // Initialize with appropriate defaults
    
    
    getListingRules() {
        this.showSpinner = true;
        listingRules({listingRuleId: this.waitlistRuleId})
        .then(result => {
            // console.log('Apex Success: get listing rules', JSON.stringify(result),this.waitlistRuleId);
            this.rules = result;
            this.rules = this.rules.map(rule => ({
                ...rule,
                isEditing: false,
                rowClass: ''
            }))
            this.originalRules = this.rules;
            // console.log(this.rules);
        })
        .catch(error => {
            console.error('Apex Error:', error);
        })
        .finally(() => {
            this.showSpinner = false;
        });
    }

    loadAMICategoryPicklistValues() {
        this.showSpinner = true;
        getPicklistValues({ objectName: 'Waitlist_Rules__c', fieldName: 'AMI_Category__c' })
            .then(result => {
                console.log(JSON.stringify(result),'hemanth third');
                this.AMICategory = result;

            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading picklist values',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    loadNoOfBedRoomsPicklistValues() {
        this.showSpinner = true;
        getPicklistValues({ objectName: 'Waitlist_Rules__c', fieldName: 'AMI_Unit_Type__c' })
            .then(result => {
                console.log(JSON.stringify(result),'bedrooms fourth');
                this.AMIUnitType = result;
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading picklist values',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    get numberOfUnits() {
        return this.eligibilityRule.numberOfUnits;
    }

    get amiNetRent() {
        return this.eligibilityRule.amiNetRent;
    }

    handleRuleTypeChange(event) {
        this.eligibilityRule.ruleType = event.target.value;
        if (event.target.value == 'Standard Eligibility Rule'){
            this.isStandardRule = true;
            this.isSetAside = false;
        }
        else{
            this.isStandardRule = false;
            this.isSetAside = true;
        }
    }

    handleAccessibilityChange(event) {
        this.eligibilityRule.accessibilityUnit = event.target.value;
        if (this.eligibilityRule.accessibilityUnit){
            this.errors.accessibilityUnit = '';
        }
    }

    handleAmiCategoryChange(event) {
        this.eligibilityRule.amiCategory = event.target.value;
        if (this.eligibilityRule.amiCategory){
            this.errors.amiCategory = '';
        }
        // console.log(JSON.stringify(this.errors));
    }

    handleBedroomsChange(event) {
        this.eligibilityRule.numberOfBedrooms = event.target.value;
        if (this.eligibilityRule.numberOfBedrooms){
            this.errors.numberOfBedrooms = '';
        }
    }

    handleUnitsChange(event) {
        this.eligibilityRule.numberOfUnits = event.target.value;
        if (this.eligibilityRule.numberOfUnits){
            this.errors.numberOfUnits = '';
        }
    }

    handleRentChange(event) {
        this.eligibilityRule.amiNetRent = event.detail.value;
        if (this.eligibilityRule.amiNetRent){
            this.errors.amiNetRent = '';
        }
    }
    
    handleSetAsideTypeChange(event) {
        this.eligibilityRule.setAsideType = event.target.value;
        if (this.eligibilityRule.setAsideType){
            this.errors.setAsideType = '';
        }
    }

    
    handleSave(){
        if (!this.validateFields()) {
            return;
        }
        // console.log(JSON.stringify(this.eligibilityRule),'HEan');
        if (this.waitlistRuleId){
            let payload = {...this.eligibilityRule, recordId : this.waitlistRuleId};
            updateEligibilityRule({ruleData:payload}).then(result => {
                if (result == 'Success'){
                    this.loadExistingRule();
                }
            });
            this.showSaveButton = this.eligibilityRule.ruleType == 'Standard Eligibility Rule' ? true : false;
        }
        else {
            let payload = {
                        Waitlist__c : this.waitlistId,
                        Type_of_Eligibility_Rule__c :this.eligibilityRule.ruleType,
                        Accessibility__c : this.eligibilityRule.ruleType == 'Standard Eligibility Rule' ? this.eligibilityRule.accessibilityUnit : '',
                        AMI_Category__c: this.eligibilityRule.ruleType == 'Standard Eligibility Rule' ? this.eligibilityRule.amiCategory : '',
                        AMI_Unit_Type__c: this.eligibilityRule.ruleType == 'Standard Eligibility Rule' ? this.eligibilityRule.numberOfBedrooms : '', // No of Bedrooms
                        Size_of_Waitlist__c : this.eligibilityRule.ruleType == 'Standard Eligibility Rule' ? this.eligibilityRule.numberOfUnits : '', // No of Units
                        AMI_Number_of_Units_by_Type__c : this.eligibilityRule.ruleType == 'Standard Eligibility Rule' ? this.eligibilityRule.numberOfUnits : '', // no of units
                        AMI_Monthly_Rent__c: this.eligibilityRule.ruleType == 'Standard Eligibility Rule' ? this.eligibilityRule.amiNetRent :null,
                        SetAside__c : this.eligibilityRule.ruleType != 'Standard Eligibility Rule' ? this.eligibilityRule.setAsideType : ''
                    };
                    // console.log('Payload being sent:', JSON.stringify(payload));

                    saveEligibilityRule({ eligibilityRule: payload })
        .then(result => {
            // console.log('Save result:', result);

            let message = 'Eligibility Rule saved successfully';
            let variant = 'success';

            if (result.includes('already exists')) {
                message = 'An Eligibility Rule already exists for this Waitlist';
                variant = 'info';
                
            }
            else{

                this.waitlistRuleId = result;
                this.getListingRules();
                this.disableRuleSelection = true;
                this.rulesAvailable = this.eligibilityRule.ruleType == 'Standard Eligibility Rule' ? true : false;
                this.showSaveButton = this.eligibilityRule.ruleType == 'Standard Eligibility Rule' ? true : false;
            }

            

            this.dispatchEvent(
                new ShowToastEvent({
                    title: variant === 'success' ? 'Success' : 'Info',
                    message: message,
                    variant: variant
                })
            );

            // Fire success event only if it's a successful insert
            if (variant === 'success') {
                const match = result.match(/Id: (\w+)/);
                if (match && match[1]) {
                    this.dispatchEvent(new CustomEvent('success', {
                        detail: { id: match[1] }
                    }));
                }
            }
        })
        .catch(error => {
            console.error('Error saving record:', error);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'An unexpected error occurred',
                    variant: 'error'
                })
            );
        });
        }
        
    }
    handleCancel() {
        // console.log(JSON.stringify(this.originalEligibilityRules),'original');
        // console.log(JSON.stringify(this.eligibilityRule),'before change');
        // Fire cancel event to be handled by the parent component
        this.eligibilityRule = {...this.originalEligibilityRules};
        // console.log(JSON.stringify(this.eligibilityRule),'after change');
        // this.dispatchEvent(new CustomEvent('cancel'));
    }



    handleNewMinIncomeChange(event) {
        let value = event.target.value;
        this.newRule.MinHouseholdIncome = value === '' || value === null || value === undefined
            ? 0
            : parseFloat(value);
        this.showCompletionMessage = false;
    }
    handleNewMaxIncomeChange(event) {
        this.newRule.MaxHouseholdIncome = parseFloat(event.target.value) || 0;
        this.showCompletionMessage = false;
    }
    
    // Handle adding a new rule
    handleAddClick() {
        if (!this.validateNewRule()) {
            return;
        }
    
        // Abort if still not available
        if (!this.waitlistRuleId) {
            // console.log('Waitlist Rule ID still not found after refresh. Aborting add.');
            return;
        }
        const payload = {
            HH_Min_Income__c: this.newRule.MinHouseholdIncome,
            HH_Max_Income__c: this.newRule.MaxHouseholdIncome,
            Household_Size__c: this.newRule.HouseholdSize,
            Listing_Rule__c: this.waitlistRuleId
        };
        addRule({ RuleObject: payload })
        .then(() => {
            // Exit edit mode after success
            this.getListingRules();
            this.newRule = {
                HouseholdSize: '',
                MinHouseholdIncome: '',
                MaxHouseholdIncome: ''
            };

            // Show success toast
            this.showToast('Success', 'Rule Added successfully', 'success');
        })
        .catch(error => {
            console.error('Error updating rule:', error);
            this.showToast('Error', 'Failed to Add rule', 'error');
        });

    }
    
    // Validate new rule
    validateNewRule() {
        // console.log(JSON.stringify(this.newRule),'this.newRule');
        // Check max household income specifically - to show the completion message
        if (!this.newRule.MaxHouseholdIncome) {
            this.showCompletionMessage = true;
            return false;
        }
        
        // Check for other empty values
        if (!this.newRule.HouseholdSize || 
            isNaN(this.newRule.HouseholdSize)) { 
            this.showToast('Error', 'Please fill in all fields with valid numbers', 'error');
            return false;
        }
        
        return this.validateRuleData(
            this.newRule.HouseholdSize,
            this.newRule.MinHouseholdIncome,
            this.newRule.MaxHouseholdIncome
        );
    }
    
    // Validate an existing rule
    validateRule(rule) {
        // console.log(rule,'rule');
        return this.validateRuleData(
            rule.Household_Size__c,
            rule.HH_Min_Income__c,
            rule.HH_Max_Income__c
        );
    }
    
    // Common validation logic
    validateRuleData(householdSize, minIncome, maxIncome) {
        // Check for valid household size
        if (householdSize < 1) {
            this.showToast('Error', 'Household size must be at least 1', 'error');
            return false;
        }
        if (householdSize > 9) {
            this.showToast('Error', 'Household size must be less than  or equal to 9', 'error');
            return false;
        }
        // Check min/max relationship
        if (minIncome >= maxIncome) {
            this.showToast('Error', 'Minimum income must be less than maximum income', 'error');
            return false;
        }
        
        return true;
    }


    handleEditClick(event) {
        // console.log('Edit Clicked');
        const ruleId = event.target.dataset.id;
        // console.log(JSON.stringify(this.rules));
        // console.log(ruleId,'ruleId');
        // Set edit mode for this row
        this.rules = this.rules.map(rule => {
            if (rule.Id === ruleId) {
                return { 
                    ...rule, 
                    isEditing: true,
                    rowClass: 'edit-mode-row'
                };
            }
            return { 
                ...rule, 
                isEditing: false,
                rowClass: ''
            }; // Ensure only one row is in edit mode
        });
        
        // Save the original state in case of cancel
        this.originalRules = JSON.parse(JSON.stringify(this.rules));
        // console.log(JSON.stringify(this.originalRules));
    }
 
handleSaveClick(event) {
    // console.log('entered',JSON.stringify(event));
    const ruleId = event.target.dataset.id;
    const ruleIndex = this.rules.findIndex(rule => rule.Id === ruleId);
    // console.log(ruleIndex,'ruleIndex');
    if (ruleIndex !== -1) {
        const updatedRule = this.rules[ruleIndex];

        // Validate before saving
        if (!this.validateRule(updatedRule)) {
            return;
        }
        // console.log(updatedRule.Id,
        //     updatedRule.HH_Min_Income__c,
        //     updatedRule.HH_Max_Income__c,
        //     updatedRule.Household_Size__c,'updatedRule');

        // Call Apex method to update the record
        updateRule({
            RuleObject: {
                Id: updatedRule.Id,
                HH_Min_Income__c: updatedRule.HH_Min_Income__c,
                HH_Max_Income__c: updatedRule.HH_Max_Income__c,
                Household_Size__c: updatedRule.Household_Size__c
            }
        })
        .then((result) => {
            // Exit edit mode after success
            // console.log(result,'result');
            this.getListingRules();

            // Show success toast
            this.showToast('Success', 'Rule updated successfully', 'success');
        })
        .catch(error => {
            console.error('Error updating rule:', error);
            this.showToast('Error', 'Failed to update rule', 'error');
        });
    }
}

    
    // Handle cancel edit
    handleCancelClick(event) {

        const ruleId = event.target.dataset.id;
        
        // Find the original rule
        const originalRule = this.originalRules.find(rule => rule.Id === ruleId);
        
        if (originalRule) {
            // Restore original values and exit edit mode
            this.rules = this.rules.map(rule => {
                if (rule.Id === ruleId) {
                    return { 
                        ...originalRule, 
                        isEditing: false,
                        rowClass: ''
                    };
                }
                return rule;
            });
        }
    }
    
    // Handle field changes during edit
    handleFieldChange(event) {
        const ruleId = event.target.dataset.id;
        const field = event.target.dataset.field;
        let value = event.target.value;
        // console.log(value,field,ruleId, 'new data');
        // Convert to appropriate type
        if (field === 'Household_Size__c') {
            value = parseInt(value, 10) || 0;
        } else {
            value = parseFloat(value) || 0;
        }
        
        // Update the rule in edit mode
        this.rules = this.rules.map(rule => {
            if (rule.Id === ruleId) {
                // console.log(rule,'fetched rule');
                return { ...rule, [field]: value };
            }
            return rule;
        });
        // console.log(JSON.stringify(this.rules),'after field change');
    }
    
    // Handle delete
    handleDeleteClick(event) {
        const ruleId = event.target.dataset.id;
        
        // Confirm deletion
        if (!confirm('Are you sure you want to delete this rule?')) {
            return;
        }
        deleteRule({ listingRuleCriteriaId: ruleId })
        .then(() => {
            // Exit edit mode after success
            this.getListingRules();
            // Show success toast
            this.showToast('Success', 'Rule Deleted successfully', 'success');
            
        })
        .catch(error => {
            console.error('Error updating rule:', error);
            this.showToast('Error', 'Failed to Delete rule', 'error');
        });

    }
    
    // Handle new row changes
    handleNewHouseholdSizeChange(event) {
        // console.log(event.target.value,'house');
        // console.log(this.newRule.HouseholdSize,'beofre');
        this.newRule.HouseholdSize = parseInt(event.target.value, 10) || '';
        // console.log(this.newRule.HouseholdSize,'after');
        this.showCompletionMessage = false;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }


    handleDeleteRule(){
        // console.log('entered delete rule',  this.waitlistRuleId);
        deleteEligibilityRule({recordId:this.waitlistRuleId}).then(
            result => {
                pubsub.fire('closemodelpubs','close',{});
                // pubsub.fire('refreshmodelpubs','refresh',{});
                /*this.showToast('Success', 'Rule Deleted successfully', 'success');
                this.dispatchEvent(new CustomEvent('closemodal', {
                    bubbles: true,
                    composed: true
                }));
                this.dispatchEvent(new CustomEvent('refreshmodal', {
                    bubbles: true,
                    composed: true
                }));*/
            }
        ).catch(error => {
            console.error('Error updating rule:', error);
            this.showToast('Error', 'Failed to Remove rule', 'error');
        });
    }

    
    handleClose() {
        pubsub.fire('closemodelpubs','close',{});
        // pubsub.fire('refreshmodelpubs','refresh',{});

        // this.dispatchEvent(new CustomEvent('closemodal', {
        //     bubbles: true,
        //     composed: true
        // }));
        // this.dispatchEvent(new CustomEvent('refreshmodal', {
        //     bubbles: true,
        //     composed: true
        // }));
    }

    validateFields() {
        // Reset errors
        this.errors = {};
        let isValid = true;
        
        if (this.isSetAside) {
            // Validate set-aside fields
            if (!this.eligibilityRule.setAsideType) {
                this.errors.setAsideType = 'Please select a Set-Aside type';
                isValid = false;
            }
        } else if (this.isStandardRule) {
            // Validate standard rule fields
            // console.log(JSON.stringify(this.eligibilityRule));
            // if (!this.eligibilityRule.accessibilityUnit && this.showAccessbilityOptions) {
            //     this.errors.accessibilityUnit = 'Please select an Accessibility Unit';
            //     isValid = false;
            // }
            
            if (!this.eligibilityRule.amiCategory) {
                this.errors.amiCategory = 'Please select an AMI Category';
                isValid = false;
            }
            
            if (!this.eligibilityRule.numberOfBedrooms) {
                this.errors.numberOfBedrooms = 'Please select the Number of Bedrooms';
                isValid = false;
            }
            
            if (!this.eligibilityRule.numberOfUnits) {
                this.errors.numberOfUnits = 'Please enter the Number of Units Available';
                isValid = false;
            }
            
            if (!this.eligibilityRule.amiNetRent) {
                this.errors.amiNetRent = 'Please enter the AMI Net Rent';
                isValid = false;
            }
        }
        // console.log(JSON.stringify(this.errors));
        this.hasFormErrors = !isValid;
        return isValid;
    }
}