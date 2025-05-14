import { LightningElement,track,api } from 'lwc';

export default class WaitlistTitlesTab extends LightningElement {
    @api record = '';
    @track unitsStr = '';
    @track setAside = '';
    @track preference = '';
    @api waitlistId;

    // Track received data for debugging
    @track received = {}; 


    @track value = '100';

    get options() {
        return [
            { label: '100', value: '100' },
            { label: '500', value: '500' },
            { label: '1000', value: '1000' },
            { label: '3000', value: '3000' },
            { label: '5000', value: '5000' }
        ];
    }

    statuses = [
        'Submitted',
        'Select for review',
        'Accepted review',
        'Unit offered',
        'Closed',
        'Appeal filed'
    ];

    @track isLoaded;


    selectedStatuses = new Set();
    
    @track filterStatus;

    handleCheckboxChange(event) {
        // const fieldName = event.target.name;
        // this[fieldName] = event.target.checked;
        console.log('Checkbox changed:', event.target.name, event.target.checked);
        const status = event.target.name;
        const isChecked = event.target.checked;

        if (isChecked) {
            this.selectedStatuses.add(status);
        } else {
            this.selectedStatuses.delete(status);
        }

        const payload = {
            selected: Array.from(this.selectedStatuses)
        };

        this.filterStatus = Array.from(this.selectedStatuses);
        console.log('Checkbox payload:', JSON.stringify(this.filterStatus));
    }



    connectedCallback(){
            console.log('waitlistId ==>' + JSON.stringify(this.record));
            console.log('waitlistId ==>' + this.record?.WaitlistId);
            if(this.record){
                this.waitlistId = this.record?.WaitlistId
                this.isLoaded = true;
            }
    }

    handleChange(event) {
        this.value = event.detail.value;
    }

    
    // Handle event from child component
    handleChildDone(event) {
        // Store the complete data object for reference
        this.received = event.detail;
        console.log('Received from child:', JSON.stringify(this.received));
        
        // Extract individual values from the event detail
        if (event.detail) {
            // Check for unitType and update unitsStr
            if (event.detail.unitType) {
                this.unitsStr = event.detail.unitType;
                console.log('Updated unitsStr:', this.unitsStr);
            } else {
                this.unitsStr = '';
            }
            
            // Check for setAside
            if (event.detail.setAside) {
                this.setAside = event.detail.setAside;
                console.log('Updated setAside:', this.setAside);
            } else {
                this.setAside = '';
            }
            
            // Check for preference
            if (event.detail.preference) {
                this.preference = event.detail.preference;
                console.log('Updated preference:', this.preference);
            }
            else {
                this.preference = '';
            }
            
            // If any other properties need to be extracted, add them here
        }
        
        // Notify the housing applicants component if it exists
        this.notifyHousingApplicantsComponent();
    }
    
    // Method to notify the housing applicants component of filter changes
    notifyHousingApplicantsComponent() {
        const housingApplicantsComponent = this.template.querySelector('c-housing-applicants');
        if (housingApplicantsComponent) {
            // Update properties on the child component
            housingApplicantsComponent.waitlistId = this.waitlistId;
            housingApplicantsComponent.unitsStr = this.unitsStr;
            housingApplicantsComponent.setAside = this.setAside;
            housingApplicantsComponent.preference = this.preference;
            
            // Alternatively, you could call a public method on the child
            // if it has one, like refreshData()
            if (typeof housingApplicantsComponent.refreshData === 'function') {
                housingApplicantsComponent.refreshData();
            }
        }
    }
}