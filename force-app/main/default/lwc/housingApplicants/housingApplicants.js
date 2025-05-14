// housingApplicants.js
import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getWaitlistApplicants from '@salesforce/apex/HousingApplicantsController.getWaitlistApplicants';
import pubsub from 'c/pubsub';


export default class HousingApplicants extends NavigationMixin(LightningElement) {
    @track applicants = [];
    @track isLoading = true;
    @track error;
    @track noRecordsFound = false;

    @api checkObj;
    @track isExtraColumn = false;
    
    currency = 20000;
    // Pagination variables
    @track totalRecords = [];
    @track visibleRecords = [];
    @track allData = [];
    @track currentPage = 1;
    @track totalPage = 1;
    @track recordSize = 100;
    @track isPagination = true;
    @track disablePrevious = true;
    @track disableNext = false;
    @track showRowValue = '100';

    // prefill = '\{"ContextId":"0iTcn000001xrULEAY","Status":"Decline Appeal","actionName":"Decline Appeal"}';


    @track isShowModal;

    // Private properties to store filter values
    _waitlistId = '';
    _unitsStr = '';
    _setAside = '';
    _preference = '';
    _filterStatus = [];

    @track appliedFiled;


    @api get totalNum() {
        return this._totalNum;
    }
    
    set totalNum(value) {
        if(value){    
            this._totalNum = value;
            this.refreshData();
        }
    }
    @api get waitlistId() {
        return this._waitlistId;
    }
    

    set waitlistId(value) {
        if(value){
            this._waitlistId = value;
        this.refreshData();
        }
        
    }

    // Getter and Setter for unitsStr
    @api get unitsStr() {
        return this._unitsStr;
    }
    
    set unitsStr(value) {
        this._unitsStr = value;
        this.refreshData();
    }


    
    // Getter and Setter for setAside
    @api get setAside() {
        return this._setAside;
    }
    
    set setAside(value) {
        this._setAside = value;
        this.refreshData();
    }
    
    // Getter and Setter for preference
    @api get preference() {
        return this._preference;
    }
    
    set preference(value) {
        this._preference = value;
        this.refreshData();
    }

    // Getter and Setter for unitsStr
    @api get filterStatus() {
        return this._filterStatus;
    }
    
    set filterStatus(value) {
        if(value) {
            this._filterStatus = value;
            
            console.log('Original this._filterStatus ==>' + JSON.stringify(this._filterStatus));

            
            // Store the filtered array to use when calling Apex
            
            this.refreshData();
        }
    }

    // Method to refresh data whenever a filter changes
    refreshData() {
        // Reset pagination to first page when filters change
        this.currentPage = 1;
        //this.loadHardcodedData();

        // Only fetch data if waitlistId is provided
        if (this._waitlistId) {
            this.fetchApplicants();
        }
    }
    
    @track isExtraColumn; 


    handleClose(){
        this.isShowModal = false;
    }

    // Method to fetch applicants from Apex
    fetchApplicants() {
        this.isLoading = true;

        let status = ["submitted","Selected For Review","acceptedReview","unitOffered","closed"];

        console.log('Fetching applicants with filters:', 
                    'waitlistId =', this._waitlistId, 
                    'unitsStr =', this._unitsStr,
                    'setAside =', this._setAside,
                    'preference =', this._preference,
                '_tota_filterStatuslNum =', JSON.stringify(this._filterStatus) );

        getWaitlistApplicants({
            waitlistId: this._waitlistId,
            unitsStr: this._unitsStr,
            setAside: this._setAside,
            preference: this._preference,
            status: this._filterStatus
            
        })
        .then(data => {
            // Process the data to add the list versions of eligibility and preferredUnitSize
            const processedData = data.map(app => {
                if(app.individualApplication != null && app.individualApplication != undefined){
                    this.isExtraColumn = app.individualApplication;
                }

                return {
                    ...app,
                    setAsidesList: this.splitSemicolonString(app.setAsides),
                    preferencesList: this.splitSemicolonString(app.preferences),
                    eligibilityList: this.splitSemicolonString(app.eligibility),
                    preferredUnitSizeList: this.splitSemicolonString(app.preferredUnitSize)
                };
            });
            console.log('this.totalRecords ==> ' + JSON.stringify(this.totalRecords));
            this.totalRecords = processedData;
            
            this.noRecordsFound = this.totalRecords.length === 0;
            
            // Set up pagination
            this.setupPagination();
            
            this.error = undefined;
        })
        .catch(error => {
            this.error = 'Error loading applicants: ' + 
                (error.body && error.body.message ? error.body.message : error.message);
            this.totalRecords = [];
            this.applicants = [];
            this.noRecordsFound = true;
            console.error('Error fetching applicants', error);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    
    // Method to load hardcoded data (3000 records)
    loadHardcodedData() {
        this.isLoading = true;
        
        try {
            // Create array to hold 3000 records
            const hardcodedData = [];
            
            // Generate 3000 records
            for (let i = 1; i <= 3000; i++) {
                // Determine values based on position
                const hhSize = (i % 4) + 1; // 1, 2, 3, 4
                const income = '$' + (20000 + (i * 500)).toLocaleString();
                const setAside = i % 5 === 0 ? 'HOPWA' : i % 7 === 0 ? 'NPLH' : i % 11 === 0 ? 'Section 8' : '';
                const preference = i % 6 === 0 ? 'Displaced' : i % 8 === 0 ? 'Live/Work' : i % 10 === 0 ? 'Neighborhood' : '';
                const eligibility = i % 3 === 0 ? '1BR 50;3BR 60;5BR 80' : i % 4 === 0 ? '1BR 50;3BR 60' : '5BR 80;1BR 50;3BR 60';
                const preferredUnitSize = i % 5 === 0 ? '1BR' : i % 4 === 0 ? '5BR' : i % 3 === 0 ? '3BR' : '1BR;3BR';
                
                // Create the record
                hardcodedData.push({
                    id: 'rec-' + i,
                    position: i.toString(),
                    name: 'Applicant ' + i,
                    hhSize: hhSize.toString(),
                    income: income,
                    setAsides: setAside,
                    preferences: preference,
                    rentalSubsidy: i % 7 === 0 ? 'Yes' : 'No',
                    eligibility: eligibility,
                    preferredUnitSize: preferredUnitSize,
                    status: 'Not Eligible',
                    mobilePhone: '555-' + Math.floor(100 + Math.random() * 900) + '-' + Math.floor(1000 + Math.random() * 9000),
                    phone: '555-' + Math.floor(100 + Math.random() * 900) + '-' + Math.floor(1000 + Math.random() * 9000),
                    appliedIncome: income,
                    occupants: hhSize.toString(),
                    waitlistDays: Math.floor(Math.random() * 365).toString(),
                    appliedOrder: (i % 10 + 1).toString(),
                    randomizedOrder: (i % 100 + 1).toString(),
                    expanded: false,
                    expandIcon: 'utility:chevrondown',
                    detailClass: 'slds-hide',
                    eligibilityList: eligibility.split(';').map(item => item.trim()),
                    preferredUnitSizeList: preferredUnitSize.split(';').map(item => item.trim())
                });
            }
            
            // Filter based on provided filters
            let filteredData = hardcodedData;
            
            // Apply unitsStr filter if provided
            if (this._unitsStr) {
                filteredData = filteredData.filter(rec => 
                    rec.eligibility && rec.eligibility.includes(this._unitsStr)
                );
            }
            
            // Apply setAside filter if provided
            if (this._setAside) {
                filteredData = filteredData.filter(rec => 
                    rec.setAsides && rec.setAsides.includes(this._setAside)
                );
            }
            
            // Apply preference filter if provided
            if (this._preference) {
                filteredData = filteredData.filter(rec => 
                    rec.preferences && rec.preferences.includes(this._preference)
                );
            }
            
            // Store the filtered data
            this.totalRecords = filteredData;
            this.noRecordsFound = this.totalRecords.length === 0;
            
            // Set up pagination
            this.setupPagination();
            
            this.error = undefined;
        } catch (error) {
            this.error = 'Error loading data: ' + error.message;
            this.totalRecords = [];
            this.applicants = [];
            this.noRecordsFound = true;
            console.error('Error generating data', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    // Connected callback to fetch data when component initializes
    connectedCallback() {
        if (this._waitlistId) {
            this.fetchApplicants();
        }
        //pubsub.register('FormSubmitted', this.handleMessage.bind(this));
        //pubsub.register('TestEvent', this.handleTest);
        pubsub.register('omniscript_action', {
            data: this.handleOmniAction.bind(this),
        });
        

       // this.loadHardcodedData();

    }

    handleOmniAction(data) {
        // perform logic to handle the Action's response data
    }

    prefillObject;

    waitlistApplicant(event){

        let actionName = event.target.dataset.action;
        let status = event.target.dataset.status;
        let contextId = event.target.dataset.id;
        let subStatus = event.target.dataset.substatus;
         let appealStatus = event.target.dataset.appealstatus;

        let prefillObject = {
            ContextId: contextId,
            Id: contextId,
            Status: status,
            actionName: actionName,
            subStatus: subStatus,
            appealStatus:appealStatus
        };


        this.prefillObject = JSON.stringify(prefillObject);

        console.log('prefillObject: ' + this.prefillObject);
        this.isShowModal = true;


    }
    
    // Setup pagination based on current data
    setupPagination() {
        if (this.totalRecords) {
            // Set total pages based on record size
            this.totalPage = this.totalRecords.length === 0 ? 1 : Math.ceil(this.totalRecords.length / this.recordSize);
            
            // Update records for current page
            this.updateRecords();
            
            // Update button states
            this.updateButtonStates();
        }
    }

    // Update records for the current page
    updateRecords() {
        const start = (this.currentPage - 1) * this.recordSize;
        const end = this.recordSize * this.currentPage;
        this.visibleRecords = this.totalRecords.slice(start, end);
        this.applicants = this.visibleRecords;
    }
    
    // Update next/previous button states
    updateButtonStates() {
        this.disablePrevious = this.currentPage <= 1;
        this.disableNext = this.currentPage >= this.totalPage;
    }
    
    // Handle next page button click
    nextHandler() {
        if (this.currentPage < this.totalPage) {
            this.currentPage = this.currentPage + 1;
            this.updateRecords();
            this.updateButtonStates();
        }
    }
    
    // Handle previous page button click
    previousHandler() {
        if (this.currentPage > 1) {
            this.currentPage = this.currentPage - 1;
            this.updateRecords();
            this.updateButtonStates();
        }
    }

    // Helper method to split strings by semicolon
    splitSemicolonString(str) {
        if (!str) return [];
        return str.split(';').map(item => item.trim());
    }
    
    get applicantsWithoutFirst() {
        return this.applicants.length > 1 ? this.applicants.slice(1) : [];
    }
    
    get hasApplicants() {
        return this.applicants.length > 0;
    }
    
    toggleDetailSection(event) {
        const applicantId = event.currentTarget.dataset.id;

        console.log('applicantId ==>' + applicantId);
        
        // First close any open detail section
        this.applicants.forEach(app => {
            // If this is not the current applicant and it's expanded, close it
            if (app.id !== applicantId && app.expanded) {
                console.log('applicantId In' );
                app.expanded = false;
                app.expandIcon = 'utility:chevrondown';
                app.detailClass = 'slds-hide';
            }
        });
        
        // Now toggle the current applicant's detail section
        const applicantIndex = this.applicants.findIndex(app => app.id === applicantId);

        console.log('applicantIndex ==>' + applicantIndex);

        
        if (applicantIndex !== -1) {
            // Toggle the expanded state
            this.applicants[applicantIndex].expanded = !this.applicants[applicantIndex].expanded;



            console.log('applicantId expanded ==>' + this.applicants[applicantIndex].expanded);
            
            // Update icon and detail section visibility based on expanded state
            if (this.applicants[applicantIndex].expanded) {
                this.applicants[applicantIndex].expandIcon = 'utility:chevronup';
                this.applicants[applicantIndex].detailClass = '';
            } else {
                this.applicants[applicantIndex].expandIcon = 'utility:chevrondown';
                this.applicants[applicantIndex].detailClass = 'slds-hide';
                console.log('applicantIndex hide ==>' );

            }
        }
        
        console.log('applicants ==>' + JSON.stringify(this.applicants));
        // Create a new array reference to trigger reactivity
        this.applicants = [...this.applicants];
    }

    @track expandTi;

    handleDropdown() {
        this.expandTi = !this.expandTi;
    }
    
    viewApplication(event) {
        const applicantId = event.currentTarget.dataset.id;
        // Find the applicant
        const applicant = this.applicants.find(app => app.id === applicantId);
        
        const individualApplicationId = applicant.individualApplication || 'null'; // Fallback ID for demo
        
        // Navigate to the Experience Site page using a relative URL pattern
        // This is more maintainable as it will work across different sandboxes/orgs
        const url = `/housing/s/individualapplication/${individualApplicationId}`;
        
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
        
        // Log for debugging
        console.log('Navigating to Individual Application: ' + individualApplicationId);
        
    }
}