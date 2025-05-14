import { LightningElement, api, track } from 'lwc';
import fetchTiles from '@salesforce/apex/WaitlistRuleController.fetchTiles';    
 
export default class UnitTiles extends LightningElement {
    @track units = [];
    // waitlistId = 'a0Ycn000001W3LZEA0';
    // waitlistId = 'a0Ycn000001ZEHQEA4';
    @api waitlistId;
    connectedCallback(){
        console.log('unitTiles waitlistId', this.waitlistId);
        this.fetchRules();
    }


    fetchRules() {
        fetchTiles({recordId: this.waitlistId})
            .then((result) => {
                console.log(JSON.stringify(result),'unitTilesresult');
                // this.units = result;
                this.units = result.map((u) => ({
                    ...u,
                    selected: false,
                    cssClass: "unit-tile",
                    incomeRange: (u.minIncome != u.maxIncome) ? (this.formatCurrency(u.minIncome) + ' - ' + this.formatCurrency(u.maxIncome)) : this.formatCurrency(u.maxIncome),
                  }));
            })
            .catch((error) => {
                console.error('Error fetching tiles:', error);
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

    handleTileClick(event) {
        const clickedId = event.currentTarget.dataset.id;
        console.log('unitTiles clickedId', clickedId);
        
        // const combined = `${record?.unitType ?? ''} ${record?.ami ?? ''}`.trim();
        // const unitTypeString = combined.length > 0 ? combined.slice(0, -1) : '';
        this.units = this.units.map((u) => {
            if (u.id === clickedId) {
              const newSel = !u.selected;
              return {
                ...u,
                selected: newSel,
                cssClass: newSel ? "unit-tile selected" : "unit-tile"
              };
            }
              else  {
                return {
                  ...u,
                  selected: false,
                  cssClass: "unit-tile"
              };
            }
          });
          const record = this.units.find(u => u.id === clickedId);
          console.log(record.selected ? 'Yes' : 'No');
          let payload;
          if (record.selected){
            if (record.isSetAside || record.isPreference) {
              payload = {
                "unitType": '',
                "setAside": record?.setAside,
                "perference": record?.preferenceType
            }
            }
            else{
              payload = {
                "unitType": (record?.unitType + ' ' + record?.ami).slice(0, -1),
                "setAside": record?.setAside,
                "perference": record?.preferenceType
            }
              
            }
            
          }
          else {
            payload = {
                "unitType": '',
                "setAside": '',
                "perference": ''
            }
          }
         
        console.log('unitTiles payload', JSON.stringify(payload));
        this.dispatchEvent(
            new CustomEvent('done', {
              detail: payload,
              bubbles: true,       // allow parent outside shadow to hear it
              composed: true       // allow event to cross shadow boundary
            })
          );

    }
}