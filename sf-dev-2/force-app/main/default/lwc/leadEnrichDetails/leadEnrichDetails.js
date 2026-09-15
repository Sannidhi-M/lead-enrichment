import { LightningElement, wire, api } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import COMPANY_NAME from '@salesforce/schema/Lead.Company_Name__c';
import INDUSTRY from '@salesforce/schema/Lead.Enriched_industry__c';
import EMPLOYEE_COUNT from '@salesforce/schema/Lead.Employee_count__c';
import EMPLOYEE_RANGE from '@salesforce/schema/Lead.Employee_range__c';
import COUNTRY from '@salesforce/schema/Lead.Enriched_country__c';
import DOMAIN from '@salesforce/schema/Lead.Enrichment_Domain__c';
import CONFIDENCE_SCORE from '@salesforce/schema/Lead.Confidence_score__c';
import LAST_ENRICHED_DATE from '@salesforce/schema/Lead.Last_Enriched_Date__c';
import ENRICHMENT_NOTES from '@salesforce/schema/Lead.Enrichment_Notes__c';
import COMPANY_LOGO from '@salesforce/schema/Lead.Eriched_logo__c';


export default class LeadEnrichDetails extends LightningElement {

    @api recordId;
    fields = [COMPANY_NAME, INDUSTRY, EMPLOYEE_COUNT, EMPLOYEE_RANGE, COUNTRY, DOMAIN, CONFIDENCE_SCORE, LAST_ENRICHED_DATE, ENRICHMENT_NOTES, COMPANY_LOGO];

    @wire(getRecord, {recordId : '$recordId', fields : '$fields'})
    records;

    get companyName(){
        return getFieldValue(this.records.data, COMPANY_NAME);
    }

    get industry(){
        return getFieldValue(this.records.data, INDUSTRY);
    }
    get employeeCount(){
        return getFieldValue(this.records.data, EMPLOYEE_COUNT);
    }
    get employeeRange(){
        return getFieldValue(this.records.data, EMPLOYEE_RANGE);
    }
    get country(){
        return getFieldValue(this.records.data, COUNTRY);
    }
    get domain(){
        return getFieldValue(this.records.data, DOMAIN);
    }
    get confidenceScore(){
        return getFieldValue(this.records.data, CONFIDENCE_SCORE);
    }
    get lastEnrichedDate(){
        return getFieldValue(this.records.data, LAST_ENRICHED_DATE);
    }

    get enrichmentNotes(){
        return getFieldValue(this.records.data, ENRICHMENT_NOTES);
    }

    get logo(){
        console.log('logo', getFieldValue(this.records.data, COMPANY_LOGO));
        return getFieldValue(this.records.data, COMPANY_LOGO);
    }

   
}