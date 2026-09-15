import { LightningElement, api } from 'lwc';

//import startEnrichment from '@salesforce/apex/LeadEnrichmentController.startEnrichment';

//import getEnrichmentStatus from '@salesforce/apex/LeadEnrichmentController.getEnrichmentStatus';

import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

export default class LeadEnrichment extends LightningElement {

    @api recordId;

    isLoading = false;

    pollingInterval;

    showCachedBanner = false;


    async handleEnrich() {

        this.isLoading = true;
        this.showCachedBanner = false;

        // try {

        //     const result = await startEnrichment({leadId: this.recordId});

        //     console.log('Enrichment result:', result);

        //     if (result === 'STARTED') {

        //         this.startPolling();

        //     } else if (result === 'CACHED') {

        //         await notifyRecordUpdateAvailable([
        //             { recordId: this.recordId }
        //         ]);

        //         this.isLoading = false;
        //     }

        // } catch (error) {

        //     console.error(
        //         'Enrichment failed:',
        //         error
        //     );

        //     this.isLoading = false;
        // }
    }


    startPolling() {

        this.checkStatus();

        this.pollingInterval = setInterval(() => {

            this.checkStatus();

        }, 1000);
    }


    // async checkStatus() {

    //     try {

    //         const status = await getEnrichmentStatus({
    //             leadId: this.recordId
    //         });

    //         console.log(
    //             'Current enrichment status:',
    //             status
    //         );


    //         if (status === 'Enriched') {

    //             this.stopPolling();

    //             await notifyRecordUpdateAvailable([
    //                 { recordId: this.recordId }
    //             ]);

    //             this.isLoading = false;

    //         } else if (status === 'Failed') {

    //             this.stopPolling();

    //             this.isLoading = false;

    //             console.error(
    //                 'Lead enrichment failed.'
    //             );
    //         }

    //     } catch (error) {

    //         console.error(
    //             'Unable to check enrichment status:',
    //             error
    //         );
    //     }
    // }


    stopPolling() {

        if (this.pollingInterval) {

            clearInterval(this.pollingInterval);

            this.pollingInterval = undefined;
        }
    }


    disconnectedCallback() {

        this.stopPolling();
    }
}