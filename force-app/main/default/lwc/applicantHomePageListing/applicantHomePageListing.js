import { LightningElement, api, track } from 'lwc';
import getListings from '@salesforce/apex/HousingSearchV3.getListingsOnProfile';
import { NavigationMixin } from 'lightning/navigation';
import demoImage from '@salesforce/resourceUrl/BlankDevelopment';
import accessibleUnits from '@salesforce/label/c.AccessibleUnits'; 


export default class HousingSearchForLoggedInUser extends NavigationMixin(LightningElement) {
    // Configurable properties from Experience Builder
    listings = [];
    showListings;
    isLoading = false;
    AdvancedSearchUrl = '/find-housing';
    demoImage = demoImage;
    accessibleUnits = accessibleUnits;

// Add these methods to your component

navigateToAdvancedSearch(){
    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            url: this.AdvancedSearchUrl
        }
    });
}

    filterProperties(input){
        // console.log('filter input',JSON.stringify(input));
        this.isLoading = true;
        getListings().then(result => {
            this.listings =  result.map(item => {
                return {
                    ...item,
                    MaximumIncome: this.formatCurrency(item.MaximumIncome),
                    MinimumIncome: this.formatCurrency(item.MinimumIncome)
                };});
            if (this.listings.length > 0){
                this.showListings = true;
            }
            else{
                this.showListings = false;
            }
            // console.log('filter results',this.listings);
        }).catch(error => {
            this.showListings = false;
            // console.log('filter error',error);
        }).finally(() => {
            this.isLoading = false; // Hide spinner after API call completes
        });
    }

    formatCurrency(amount) {
        if (isNaN(amount)) return '';
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0
        }).format(amount);
    }
    
    // Lifecycle methods
    connectedCallback() {
        this.showListings = true;
        // Initialize location from the configurable property
        this.filterProperties(this.filterInput);
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
}