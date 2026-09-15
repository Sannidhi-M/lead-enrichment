import { LightningElement, api, wire } from 'lwc';

import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'Lead.Enrichment_Status__c',
    'Lead.Enrichment_Notes__c',
    'Lead.Last_Enriched_Date__c',
    'Lead.Enrichment_Domain__c',
    'Lead.Company_Name__c',
    'Lead.Enriched_industry__c',
    'Lead.Employee_count__c',
    'Lead.Employee_range__c',
    'Lead.Enriched_country__c',
    'Lead.Eriched_logo__c',
    'Lead.Confidence_score__c'
];

export default class LeadEnrichmentPresenter extends LightningElement {

    @api recordId;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: FIELDS
    })
    lead;


    get status() {
        return this.lead?.data?.fields?.Enrichment_Status__c?.value;
    }

    get notes() {
        return this.lead?.data?.fields?.Enrichment_Notes__c?.value;
    }

    get lastEnrichedDate() {
        return this.lead?.data?.fields?.Last_Enriched_Date__c?.value;
    }

    get domain() {
        return this.lead?.data?.fields?.Enrichment_Domain__c?.value;
    }

    get companyName() {
        return this.lead?.data?.fields?.Company_Name__c?.value;
    }

    get industry() {
        return this.lead?.data?.fields?.Enriched_industry__c?.value;
    }

    get employeeCount() {
        return this.lead?.data?.fields?.Employee_count__c?.value;
    }

    get employeeRange() {
        return this.lead?.data?.fields?.Employee_range__c?.value;
    }

    get country() {
        return this.lead?.data?.fields?.Enriched_country__c?.value;
    }

    get logo() {
        return this.lead?.data?.fields?.Eriched_logo__c?.value;
    }

    get confidenceScore() {
        return this.lead?.data?.fields?.Confidence_score__c?.value;
    }
}