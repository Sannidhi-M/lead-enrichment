import { LightningElement, api } from 'lwc';

export default class ChildComp extends LightningElement {

    @api isLoading = false;
    @api showCachedBanner = false;
    @api cachedData;

    get buttonLabel() {
        return this.showCachedBanner ? 'Re-enrich' : 'Enrich Lead';
    }

    handleEnrich() {
        this.dispatchEvent(new CustomEvent('enrichlead', {
            detail: {
                // only bypass the cache when this is an explicit re-enrich click
                forceEnrich: this.showCachedBanner
            }
        }));
    }
}