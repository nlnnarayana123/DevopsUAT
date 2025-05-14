import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createCase from '@salesforce/apex/CaseCreationController.createCase';
import getCurrentUserInfo from '@salesforce/apex/CaseCreationController.getCurrentUserInfo';
import getCaseTypePicklistValues from '@salesforce/apex/CaseCreationController.getCaseTypePicklistValues';

export default class CaseCreationForm extends LightningElement {
    @track firstName = '';
    @track lastName = '';
    @track email = '';
    @track phone = '';
    @track username = '';
    @track subject = '';
    @track description = '';
    @track errors  = {};
    @track loading = false;
    @track isGuest = true;
    
    // File upload related properties
    @track fileName = '';
    @track fileType = '';
    @track fileData = '';
    @track showFileUpload = true;
    
    // Type picklist
    @track typeOptions = [];
    @track selectedType = '';
    
    connectedCallback() {
        // Get current user info
        this.getUserInfo();
        
        // Get Case Type picklist values
        this.getCaseTypes();
    }

    validateFields() {
        let valid = true;
        let tempErrors = {};
    
        if (!this.firstName) {
            tempErrors.firstName = 'First Name is required.';
            valid = false;
        }
        if (!this.lastName) {
            tempErrors.lastName = 'Last Name is required.';
            valid = false;
        }
        if (!this.email) {
            tempErrors.email = 'Email is required.';
            valid = false;
        }

        if (!this.selectedType) {
            tempErrors.selectedType = 'Type is required.';
            valid = false;
        }
        if (!this.subject) {
            tempErrors.subject = 'Subject is required.';
            valid = false;
        }
        if (!this.description) {
            tempErrors.description = 'Description is required.';
            valid = false;
        }

    
        this.errors = tempErrors;
        return valid;
    }
    
    
    // Get current user info
    getUserInfo() {
        this.loading = true;
        getCurrentUserInfo()
            .then(result => {
                // Set initial values but don't restrict editing
                this.firstName = result.firstName;
                this.lastName = result.lastName;
                this.email = result.email;
                this.username = result.username;
                this.isGuest = result.isGuest;
                this.loading = false;
            })
            .catch(error => {
                this.loading = false;
                console.error('Error getting user info:', error);
            });
    }
    
    // Get Case Type picklist values
    getCaseTypes() {
        getCaseTypePicklistValues()
            .then(result => {
                this.typeOptions = result;
            })
            .catch(error => {
                console.error('Error getting case types:', error);
            });
    }
    
    // Handle input changes
    handleInputChange(event) {
        const field = event.target.name;
        this[field] = event.target.value;
        this.errors[field] = ''; // Clear error message for the field
    }
    
    // Handle file upload
    handleFileUpload(event) {
        const file = event.target.files[0];
        if (file) {
            this.fileName = file.name;
            this.fileType = file.type;
            
            // Read file as base64
            const reader = new FileReader();
            reader.onload = () => {
                this.fileData = reader.result;
            };
            reader.readAsDataURL(file);
            
            this.showFileUpload = false;
        }
    }
    
    // Remove selected file
    handleRemoveFile() {
        this.fileName = '';
        this.fileType = '';
        this.fileData = '';
        this.showFileUpload = true;
    }
    
    // Validate the form
    validateForm() {
        let isValid = true;
        const inputFields = this.template.querySelectorAll('lightning-input[firstName], lightning-textarea[data-id]');
        console.log('inputFields', JSON.stringify(inputFields),inputFields);
        inputFields.forEach(field => {
            if (!field.checkValidity()) {
                field.reportValidity();
                isValid = false;
            }
        });
        
        return isValid;
    }
    
    // Submit the form
    handleSubmit() {
        this.validateForm();
        this.errors = {}; // clear previous errors

    if (!this.validateFields()) {
        return;
    }
            
            createCase({
                firstName: this.firstName,
                lastName: this.lastName,
                email: this.email,
                phone: this.phone,
                username: this.username,
                type: this.selectedType,
                subject: this.subject,
                description: this.description,
                fileData: this.fileData,
                fileName: this.fileName,
                fileType: this.fileType
            })
            .then(result => {
                this.loading = false;
                this.showSuccessToast();
                this.resetForm();
            })
            .catch(error => {
                this.loading = false;
                this.showErrorToast(error.body?.message || 'An error occurred');
            });
        
    }
    
    // Reset form after submission
    resetForm() {
        // Clear all fields after submission
        this.firstName = '';
        this.lastName = '';
        this.email = '';
        this.phone = '';
        this.username = '';
        this.subject = '';
        this.description = '';
        this.selectedType = '';
        this.fileName = '';
        this.fileType = '';
        this.fileData = '';
        this.showFileUpload = true;
        
        // Reset all form field values
        const inputFields = this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox');
        if (inputFields) {
            inputFields.forEach(field => {
                field.value = '';
            });
        }
    }
    
    // Show success toast notification
    showSuccessToast() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Your inquiry has been submitted successfully!',
                variant: 'success'
            })
        );
    }
    
    // Show error toast notification
    showErrorToast(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: message || 'An error occurred while submitting your inquiry.',
                variant: 'error'
            })
        );
    }
}