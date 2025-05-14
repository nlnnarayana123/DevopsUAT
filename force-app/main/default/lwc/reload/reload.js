import { LightningElement } from 'lwc';

export default class Reload extends LightningElement {

    connectedCallback() {
        console.log('Reload');
        // Reload the page when the component is inserted into the DOM
        setTimeout(() => { window.location.reload(); } , 1000); 
        
    }
}