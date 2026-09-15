import { LightningElement, api } from 'lwc';
import enrichLead from '@salesforce/apex/EnrichmentController.enrichLead';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

const CHANNEL_NAME = '/event/Lead_Enrichment_Complete__e';

export default class ParentComp extends LightningElement {

    @api recordId;

    isLoading = false;
   // isCached = false;
    showCachedBanner = false;
    cachedData = null;
    loadingTimeout;

    subscription;

    connectedCallback() {
        this.subscribeToEnrichmentEvents();
    }

    disconnectedCallback() {
        // always clean up — otherwise the subscription leaks if the user
        // navigates away from the record while a job is still in flight
        if (this.subscription) {
            unsubscribe(this.subscription);
        }
        clearTimeout(this.loadingTimeout);
    }

    subscribeToEnrichmentEvents() {
        subscribe(CHANNEL_NAME, -1, (message) => {
            this.handlePlatformEvent(message);
        }).then((response) => {
            this.subscription = response;
        });

        onError((error) => {
            console.error('EMP API error:', error);
        });
    }

    handlePlatformEvent(message) {
        const payload = message.data.payload;

        // this component may be sitting on multiple Lead record pages'
        // worth of subscriptions in theory — always filter to THIS record
        if (payload.Lead_Id__c !== this.recordId) {
            return;
        }
        clearTimeout(this.loadingTimeout);
        this.isLoading = false;

        if (payload.Status__c === 'Enriched') {
          //  this.isCached = false;
            this.showCachedBanner = false;

            // the record changed via an async job — this is the moment
            // to tell the standard page (and the Enriched Details tab) to refresh
            notifyRecordUpdateAvailable([{ recordId: this.recordId }]);

            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Lead enriched successfully',
                variant: 'success'
            }));
        } else if (payload.Status__c === 'Failed') {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Enrichment Failed',
                message: payload.Error_Message__c || 'Unknown error occurred',
                variant: 'error'
            }));
        }
    }

    async handleLeadEnriched(event) {
        const forceEnrich = event.detail.forceEnrich;

        this.isLoading = true;
       // this.isCached = false;
        this.showCachedBanner = false;

        try {
            const result = await enrichLead({ leadId: this.recordId, forceEnrich });

            if (result.isCached) {
                // cache hit — this is the final answer, no async job was queued,
                // no event will ever arrive for this click
              //  this.isCached = true;
                this.showCachedBanner = true;
                this.cachedData = result;
                this.isLoading = false;

                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Showing cached enrichment data',
                    variant: 'success'
                }));
            }
            // else: result.status === 'In Progress' — job was queued.
            // isLoading stays true; we wait for handlePlatformEvent to fire.


            if (!result.isCached) {
                this.loadingTimeout = setTimeout(() => {
                    if (this.isLoading) {
                        this.isLoading = false;
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Timed Out',
                            message: 'Enrichment is taking longer than expected. Please refresh to check status.',
                            variant: 'warning'
                        }));
                    }
                }, 30000); // 30s — adjust to your typical API latency
            }

        } catch (error) {
            const message = error?.body?.message || 'Unknown error occurred';
            this.isLoading = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Enrichment Failed',
                message,
                variant: 'error'
            }));
        }
    }
}