import { LightningElement, api, track, wire } from 'lwc';
import savePDFEmployee from '@salesforce/apex/CreateEVCQUotePDFController.savePDFToQuote';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// import { getDataConnectorSourceFields } from 'lightning/analyticsWaveApi';

export default class EvcQuotePdf extends LightningElement {
    @api recordId;
    
    @track pdfview =true;
    @track disabledButton = false;
    url;

    connectedCallback(){
        this.url='/apex/EVCQuoteTemplatePdf?core.apexpages.request.devconsole=1&id='+this.recordId;
        console.log('this.recordId  ' +this.recordId);
    }
    handleSave(event){
        this.disabledButton = true;
        this.pdfview = event.target.value; 
        
        savePDFEmployee({recordId:this.recordId})

        // .then(result => {
        //     console.log('success      ' +result);
        // }).catch(err => {
        //     console.log('error' +JSON.stringify(err));
        // })
        

        .then(result=>{
            this. handleDismiss();
            console.log('Inside Result')
            console.log(result);
            
            this.dispatchEvent(new ShowToastEvent({
                title: '',
                message: 'PDF was saved successfully to quote.',
                variant: 'success'
            }));
            
        })

       .catch(error=>{
            console.log('Inside Error');
            console.log('Error message: ', error.message);
            console.log('Error body: ', JSON.stringify(error.body));  // Full error object
            console.log('Error status: ', error.status);  // HTTP status code if available

            // You can also display the error to the user using toast messages or other UI elements
            this.showToast('Error', error.message, 'error');
       })
      }

      handleDismiss(){

        const closeQA = new CustomEvent('close');
    
        // Dispatches the event.
    
        this.dispatchEvent(closeQA);
    
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

}