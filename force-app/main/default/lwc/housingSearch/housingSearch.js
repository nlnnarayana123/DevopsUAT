import { LightningElement, api, track, wire } from 'lwc';
import filterListings from '@salesforce/apex/HousingSearchV3.getWaitListRecords';
import getAttributes from '@salesforce/apex/HousingSearchV3.getWaitlistAttributes';
import getlocations from '@salesforce/apex/HousingSearchV3.fetchWaitlistLocations';
import getPicklistValues from '@salesforce/apex/HousingSearchV3.getPicklistValues';
// import getProjects from '@salesforce/apex/HousingSearchV3.getProjects';
import getAccessebilities from '@salesforce/apex/HousingSearchV3.getAccessebilities';
import bedrooms from '@salesforce/resourceUrl/FlexCard_Bedroom';
import money from '@salesforce/resourceUrl/FlexCard_Money';
import location from '@salesforce/resourceUrl/FlexCard_Location';
import handicapLogo from '@salesforce/resourceUrl/Flexcard_Wheelchair';
import development from '@salesforce/resourceUrl/Flexcard_Development';


import demoImage from '@salesforce/resourceUrl/BlankDevelopment'
import { NavigationMixin } from 'lightning/navigation';
import accessibleUnits from '@salesforce/label/c.AccessibleUnits'; 

//Added for pubsub communication
// import { fireEvent } from 'c/pubsub';
/**
 * Handle the user clicking on a language option
 * @param {Event} event - The click event
*/   

export default class HousingSearch extends NavigationMixin(LightningElement) {
    // Configurable properties from Experience Builder
    accesibleUnitsHelpText = "Developments that are currently accepting applications for Accessible Units that are set aside for households that require mobility, visual and/or hearing accessible features only.";
    @api title = 'Housing Search Results';
    @api showTitle = false;
    @api showMitchellLamaFilter = false;
    @api defaultLocation = 'Rochester, NY';
    @api defaultPageSize = 6;
    demoImage = demoImage;
    bedroomOptions = [];
    bedroomsIcon = bedrooms;
    handicapLogo = handicapLogo;
    moneyIcon = money;
    locationIcon = location;
    development = development;
    accessibleUnits = accessibleUnits;
    @wire(getPicklistValues, { objectName: 'Waitlist_Rules__c', fieldName: 'AMI_Unit_Type__c' })
    wiredUnitTypeValues({ error, data }) {
        //this.isLoading = true;
        if (data) {
            this.bedroomOptions = [{ label: 'Any', value: 'Any' },...data];
            this.error = undefined;
        } else if (error) {
            this.error = 'Error loading picklist values: ' + error.body.message;
            this.bedroomOptions = [];
            //this.isLoading = false;
            console.error('Error fetching picklist values', error);
        }
    }
    @track amenitiesTags = [];
    @track preferencesTags = [ ];
    @track vouchersTags = [];
    allAmenities = [];
    allPreferences = [];
    allVouchers = [];
    selectedMaxRent = null;
    selectedMinRent = null;
    selectedBedrooms = null;
    income = null;
    @track selectedCity = null;
    @track selectedCounty = null;
    @track selectedZip =null;
    selectedProject = null;
    @track selectedLocationType = 'City';
    @track selectedAccessibleUnit= '';
    listings = [];
    allListings  = [];
    waitlistListings = [];
    lotteryListings = [];
    filterInput={};
    showCitiesDd = true;
    showCountyDd = false;
    showZipdd = false;


    cityOptions = []
    countyOptions = [];
    zipOptions = [];
    locationTypeOptions = [
        { label: 'City', value: 'City' },
        { label: 'County', value: 'County' },
        { label: 'ZIP', value: 'ZIP' }

    ];

    AccessbileUnitOptions  = [
        { label: 'All', value: 'All' },
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' },
        
    ];

    // Search parameters
    @track location;
    @track selectedPriceRange;
    @track selectedAmenities;
    projects;
    
    // UI Control properties
    @track advancedSearchVisible = false;
    @track isLoading = false;
    @track activeTab = 'all';
    @track showOnlyMitchellLama = false;
    accessiblities;
    selectedAccessibility = '';

    
    // Computed properties for UI
    get advancedSearchClass() {
        return this.advancedSearchVisible ? 'advanced-search-section visible' : 'advanced-search-section hidden';
    }

    get advancedSearchLabel() {
        return this.advancedSearchVisible ? 'Hide Advanced Filters' : 'Show Advanced Filters';
    }
    
    get allTabClass() {
        return this.activeTab === 'all' ? 'tab active' : 'tab';
    }
    
    get lotteryTabClass() {
        return this.activeTab === 'lottery' ? 'tab active' : 'tab';
    }
    
    get waitlistTabClass() {
        return this.activeTab === 'waitlist' ? 'tab active' : 'tab';
    }
    
    get hasResults() {
        return this.propertyResults && this.propertyResults.length > 0;
    }
    

// Add these methods to your component

handleAccessibleChange(event) {
    this.selectedAccessibleUnit = event.target.checked;
    let accessible = {'isAccessibleUnit':event.target.checked};
    Object.assign(this.filterInput, accessible);
    this.filterProperties(this.filterInput);
    console.log('accessible',JSON.stringify(this.filterInput));
    console.log('accessible',this.selectedAccessibleUnit);
    // this.filterListings();
}

fetchAttributes(attributeType){
    // console.log('Fetching attributes for '+ attributeType + '... ');
    getAttributes({fieldName:attributeType}).then(result => {
        // console.log('attr results',result);
        if (attributeType === 'Amenities__c') {
            this.amenitiesTags = result;
            this.allAmenities = JSON.parse(JSON.stringify(result));
        } else if (attributeType === 'Preference_Types__c') {
            this.preferencesTags = result;
            this.allPreferences = JSON.parse(JSON.stringify(result));
        } else if (attributeType === 'Voucher_Types__c') {
            this.vouchersTags = result;
            this.allVouchers = JSON.parse(JSON.stringify(result));
        }
    }).catch(error => {
        // console.log('attr error',error);
        this.attributes = [];
    });
}

fetchAccessebilities(){
    getAccessebilities().then(result => {
        console.log('Accessebilities',result);
        this.accessiblities = result;
    }).catch(error => {
        console.log('Accessebilities error',error);
        // this.accessiblities = [];
    });
}

fetchLocationsInfo(){
    getlocations().then(result => {
        // console.log('locations',result);
        this.cityOptions = result.Cities;
        this.countyOptions = result.Counties;
        this.zipOptions = result.ZipCodes;
    }).catch(error => {
        // console.log('locations error',error);
        this.locations = [];
    });
}

// fetchProjects(){
//     getProjects().then(result => {
//         console.log('projects',JSON.stringify(result));
//         this.projects = result;
//     }).catch(error => {
//         // console.log('projects error',error);
//         this.projects = [];
//     });
// }

getFilterInput() {
    this.filterInput = {
        "Amenities": this.getSelectedTagValues(this.amenitiesTags),
        "RentLow": this.selectedMinRent,
        "RentHigh": this.selectedMaxRent,
        "Preferences": this.getSelectedTagValues(this.preferencesTags),
        "Vouchers": this.getSelectedTagValues(this.vouchersTags),
        "UnitType": this.selectedBedrooms=='' ? null: this.selectedBedrooms,
        "Income": this.income=='' ? null: this.income,
        "SelectedCity": this.selectedCity,
        "SelectedCounty": this.selectedCounty,
        "SelectedZip": this.selectedZip,
        "LocationType": this.selectedLocationType,
        "Project": this.selectedProject,
        "isAccessibleUnit": this.selectedAccessibleUnit,
        "Accessibility": this.selectedAccessibility
    };
}

handleLocationTypeChange(event) {
    this.selectedLocationType = event.detail.value;
    if (this.selectedLocationType === 'City') {
        this.showCitiesDd = true;
        this.showCountyDd = false;
        this.showZipdd = false;
    } else if (this.selectedLocationType === 'County') {
        this.showCitiesDd = false;
        this.showCountyDd = true;
        this.showZipdd = false;
    } else if (this.selectedLocationType === 'ZIP') {
        this.showCitiesDd = false;
        this.showCountyDd = false;
        this.showZipdd = true;
    }
    //firing pubsub event
    // const eventData = {
    //     click: 'filter property result',
    //     result: this.listings
    // }
    // // Fire the event to notify other components
    // fireEvent('filterPropertyResults', eventData);
}

handleCityChange(event) {
    //let city = {'SelectedCity':event.detail.value,'LocationType':this.selectedLocationType};
    //this.selectedCity = event.detail.value;
    /* This change from detail to target is done to accomodate language trnaslation, above is the original code*/
    let city = {'SelectedCity':event.target.value,'LocationType':this.selectedLocationType};
    this.selectedCity = event.target.value;
    this.selectedLocationType = 'City';
    Object.assign(this.filterInput, city);
    this.filterProperties(this.filterInput);
}

handleProjectChange(event) {
    console.log('entered project change');
    console.log(JSON.stringify(event));
    console.log(event.target.value);
    this.selectedProject = event.target.value;
    let project = {'Project':event.target.value};
    Object.assign(this.filterInput, project);
    console.log('project',JSON.stringify(this.filterInput));
    this.filterProperties(this.filterInput);
}

handleAccessiblityChange(event){
    this.selectedAccessibility = event.target.value;
    let accessibility = {'Accessibility':event.target.value};
    Object.assign(this.filterInput, accessibility);
    this.filterProperties(this.filterInput);
}

handleCountyChange(event) {
    //let county = {'SelectedCounty':event.detail.value,'LocationType':this.selectedLocationType};
    //this.selectedCounty = event.detail.value;
    /* This change from detail to target is done to accomodate language trnaslation, above is the original code*/
    let county = {'SelectedCounty':event.target.value,'LocationType':this.selectedLocationType};
    this.selectedCounty = event.target.value;
    this.selectedLocationType = 'County';
    Object.assign(this.filterInput, county);
    this.filterProperties(this.filterInput);
}

handleZipChange(event) { 
    //let zip = {'SelectedZip':event.detail.value,'LocationType':this.selectedLocationType};
    //this.selectedZip = event.detail.value;
    /* This change from detail to target is done to accomodate language trnaslation, above is the original code*/
    let zip = {'SelectedZip':event.target.value,'LocationType':this.selectedLocationType};
    this.selectedZip = event.target.value;
    this.selectedLocationType = 'ZIP';
    Object.assign(this.filterInput, zip);
    this.filterProperties(this.filterInput);
}

handleMinRentChange(event) {
    // this.selectedMinRent = Number(event.target.value);
    let value = event.target.value.trim();
    this.selectedMinRent = value === "" ? null : Number(value);
    this.validateRentRange();
}

handleMaxRentChange(event) {
    let value = event.target.value.trim();
    this.selectedMaxRent = value === "" ? null : Number(value);
    // this.selectedMaxRent = Number(event.target.value);
    this.validateRentRange();
}

validateRentRange() {
    // console.log('this.selectedMaxRent',this.selectedMaxRent);
    // console.log('this.selectedMinRent',this.selectedMinRent);
    if ((this.selectedMaxRent > 0 && this.selectedMaxRent < this.selectedMinRent) || (this.selectedMaxRent == 0 && this.selectedMinRent==0)) {
        this.showValidationError = true;
    } else {
        let rentFields = {};
        this.showValidationError = false;
        if (this.selectedMinRent == null && this.selectedMinRent == null){
            rentFields.RentLow = null;
            rentFields.RentHigh = null;
        }
        else if (this.selectedMinRent == null){
            rentFields.RentLow = 0;
            rentFields.RentHigh =   this.selectedMaxRent;
        }
        else if (this.selectedMaxRent == null){
            rentFields.RentHigh = 1000000000;
            rentFields.RentLow = this.selectedMinRent;
        }
        else{
            rentFields.RentHigh =   this.selectedMaxRent;
            rentFields.RentLow = this.selectedMinRent;
        }
        Object.assign(this.filterInput, rentFields);
        this.filterProperties(this.filterInput);
    }
    }

handleBedroomsChange(event) {
    //let bedroom = {'UnitType':event.detail.value};
    //this.selectedBedrooms = event.detail.value;
    /* This change from detail to target is done to accomodate language trnaslation, above is the original code*/
    let bedroom = {'UnitType':event.target.value};
    this.selectedBedrooms = event.target.value;
    Object.assign(this.filterInput, bedroom);
    this.filterProperties(this.filterInput);
}

handleIncomeChange(event) {
    
    let income = event.detail.value;
    if (income==''|| income==null){
        income = null;
    }
    this.income = income;
    // console.log(this.income,'yes');
    Object.assign(this.filterInput, {'Income':income});
    this.filterProperties(this.filterInput);
}
formatCurrency(amount) {
    if (isNaN(amount)) return '';
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
        minimumFractionDigits: 0
    }).format(amount);
}

@track tooltipVisible = false;

    showTooltip() {
        this.tooltipVisible = true;
    }

    hideTooltip() {
        this.tooltipVisible = false;
    }
    
    filterProperties(input){
        console.log('filter input',JSON.stringify(input));
        filterListings({input:input}).then(result => {
            this.listings =  result.map(item => {
                return {
                    ...item,
                    MaximumIncome: this.formatCurrency(item.MaximumIncome),
                    MinimumIncome: this.formatCurrency(item.MinimumIncome)
                };});
            // console.log('filter results',JSON.stringify(this.listings[0]));
            this.allListings = this.listings; // Holds all records
            this.waitlistListings = this.listings.filter(listing => listing.Type === 'HCR Waitlist');
            this.lotteryListings = this.listings.filter(listing => listing.Type === 'HCR Lottery'); 

            console.log('filter results',JSON.stringify(this.listings));

            //firing pubsub event
            // const eventData = {
            //     click: 'filter property result',
            //     result: this.listings
            // }

            // // Fire the event to notify other components
            // fireEvent('filterPropertyResults', eventData);
                        
        });
    }

    
    // Lifecycle methods
    connectedCallback() {
        // Initialize location from the configurable property
        // this.fetchProjects();
        this.fetchAccessebilities();
        this.getFilterInput();
        this.filterProperties(this.filterInput);
        this.fetchAttributes('Amenities__c');
        this.fetchAttributes('Preference_Types__c');    
        this.fetchAttributes('Voucher_Types__c');
        this.fetchLocationsInfo();

    }
    
    handleListingClick(event) {
        const listingId = event.currentTarget.dataset.id; // Get the clicked listing ID
        // console.log('listingId',listingId);
        if (listingId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    recordId: listingId,
                    url: '/waitlist/'+listingId // Change to your actual object API name
                }
            });
        }
    }
    // UI Event handlers
    toggleAdvancedSearch() {
        this.advancedSearchVisible = !this.advancedSearchVisible;
    }
    
    showAllResults() {
        this.activeTab = 'all';
        this.listings = this.allListings;
    }
    
    showLotteryResults() {
        this.activeTab = 'lottery';
        this.listings = this.lotteryListings;
    }
    
    showWaitlistResults() {
        this.activeTab = 'waitlist';
        this.listings = this.waitlistListings;
    }
    
    // Handle tag selection
    handleTagClick(event) {
        const tagId = event.currentTarget.dataset.id;
        // Find and toggle the tag in all tag collections
        this.toggleTagInCollection(this.amenitiesTags, tagId);
        this.toggleTagInCollection(this.preferencesTags, tagId);
        this.toggleTagInCollection(this.vouchersTags, tagId);
        // Add or remove the 'selected' class directly for immediate visual feedback
        if (event.currentTarget.classList.contains('selected')) {
            event.currentTarget.classList.remove('selected');
            const iconElement = event.currentTarget.querySelector('.tag-icon');
            if (iconElement) {
                iconElement.textContent = '+';
            }
        } else {
            event.currentTarget.classList.add('selected');
            const iconElement = event.currentTarget.querySelector('.tag-icon');
            if (iconElement) {
                iconElement.textContent = '✓';
            }
        }
        const selectedAmenities = this.getSelectedTagValues(this.amenitiesTags);
        const selectedPreferences = this.getSelectedTagValues(this.preferencesTags);
        const selectedVouchers = this.getSelectedTagValues(this.vouchersTags);

        this.filterInput = {
            ...this.filterInput,
            Amenities: selectedAmenities,
            Preferences: selectedPreferences,
            Vouchers: selectedVouchers,
        };
        
        this.filterProperties(this.filterInput);

    }
    
    // Toggle selected state in tag collections
    toggleTagInCollection(collection, tagId) {
        collection.forEach(tag => {
            if (tag.value === tagId) {
                tag.selected = !tag.selected;
            }
        });
    }
    
    // Method to programmatically add the 'selected' class based on tag state
    renderedCallback() {
        // Apply selected class to tags based on their state
        this.applySelectedClassAndIcon(this.amenitiesTags);
        this.applySelectedClassAndIcon(this.preferencesTags);
        this.applySelectedClassAndIcon(this.vouchersTags);
    }
    
    // Helper method to apply the selected class and change icon
    applySelectedClassAndIcon(tagCollection) {
        const tagElements = this.template.querySelectorAll('.tag');
        
        tagElements.forEach(element => {
            const tagId = element.dataset.id;
            const tag = tagCollection.find(t => t.value === tagId);
            
            if (tag && tag.selected) {
                element.classList.add('selected');
                const iconElement = element.querySelector('.tag-icon');
                if (iconElement) {
                    iconElement.textContent = '✓';
                }
            } else if (tag && !tag.selected) {
                element.classList.remove('selected');
                const iconElement = element.querySelector('.tag-icon');
                if (iconElement) {
                    iconElement.textContent = '+';
                }
            }
        });
    }
    
    clearAllFilters() {     
        //Reset filter properties
        this.selectedMinRent = null;
        this.selectedMaxRent = null;
        this.selectedLocationType = 'City';
        this.income = '';
        this.selectedCity = '';
        this.showCitiesDd = true;
        this.showCountyDd = false;
        this.showZipdd = false;
        this.selectedCounty = '';
        this.selectedZip = '';
        this.selectedBedrooms = '';
        this.selectedProject = '';
        this.selectedAccessibleUnit = '';
        this.selectedAccessibility = '';
        this.resetTagCollection(this.amenitiesTags);
        this.resetTagCollection(this.preferencesTags);
        this.resetTagCollection(this.vouchersTags);
        // console.log('entered clear filter');
        this.getFilterInput();
        // console.log('filter inputt',this.income);
        // console.log('bedrooms before',this.selectedBedrooms);
        this.filterProperties(this.filterInput);
        // console.log('bedrooms after',this.income);
    }
    
    resetTagCollection(collection) {
        collection.forEach(tag => {
            tag.selected = false;
        });
    }
    
    // Helper method to get values from selected tags
    getSelectedTagValues(collection) {
        return collection
            .filter(tag => tag.selected)
            .map(tag => tag.value);
    }
    
}