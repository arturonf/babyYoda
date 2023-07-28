import { LightningElement, track, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import {  subscribe, unsubscribe, MessageContext } from 'lightning/empApi';
import { NavigationMixin } from 'lightning/navigation';
import getOldestCasesAssignedToUser from '@salesforce/apex/CaseController.getOldestCasesAssignedToUser';

const columns = [
    { label: 'Asunto', fieldName: 'Subject', type: 'text', sortable: true },
    { label: 'Estado', fieldName: 'Status', type: 'text', sortable: true },
    { label: 'Email de contacto', fieldName: 'ContactEmail', type: 'email', sortable: true },
    { label: 'Contacto relacionado', fieldName: 'ContactId', type: 'url', sortable: true , typeAttributes:{label: { fieldName: 'ContactName' }, target: '_blank'} },
    { label: 'Más Información', type: 'button', typeAttributes: { label: 'Ver', name: 'ver', title: 'Ver', variant: 'base', }, },
];

export default class CasosInterplanetarios extends NavigationMixin(LightningElement) {
    /*@api caseSubject;
    @api caseStatus;
    @api planetCode;
    @api successfulScan;
    @api NavigationMixin;*/
    
    @track caseData = [];
    @track error;
    @track selectedCase;
    @track viewDetails = false;

    wiredResult;

    @wire(getOldestCasesAssignedToUser)
    wiredCases( result ) {
        this.wiredResult = result;
        if (result.data) {
            this.caseData = result.data.map((caseRecord) => ({
                Id: caseRecord.Id,
                Subject: caseRecord.Subject,
                Status: caseRecord.Status,
                ContactEmail: caseRecord.Contact.Email,
                ContactName: caseRecord.Contact.Name,
                PlanetCode: caseRecord.Planet__r.PlanetCode__c,
                ContactId: 'theksquaregroup25-dev-ed.develop.lightning.force.com/lightning/r/Contact/' + caseRecord.Contact.Id + '/view',
            }));
            this.error = undefined;
            console.log('Data retrieved from query:', result.data); // Move the console.log() here
        } else if (result.error) {
            this.error = result.error;
            this.caseData = undefined;
            console.error('Error occurred during data retrieval:', result.error);
        }
    }

    columns = columns;

    subscription = {};
    @api channelName = '/event/New_Case__e';

    connectedCallback() {
        this.handleSubscribe();
    }

    handleSubscribe() {
        const self = this;
        const messageCallback = function (response) {

            refreshApex(self.wiredResult);

            console.log('New message received 1: ', JSON.stringify(response));
            console.log('New message received 2: ', response);

            var obj = JSON.parse(JSON.stringify(response));

            self.caseData = self.proxyToObj(self.data);
            self.caseData.push({Case_Id__c : obj.data.payload.Case_Id__c});
            console.log('this.data -> ' + JSON.stringify(self.caseData));
        };
 
        subscribe(this.channelName, -1, messageCallback).then(response => {
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            this.subscription = response;
        });
    }

    handleRowAction(event) {
        // Handle row action - navigate to the particular case viewer LWC component using the caseId
        const action = event.detail.action;
        const caseId = event.detail.row.Id;
        this.selectedCase = event.detail.row; // Store the selected case details

        if (action.name === 'ver') {
            // Show the case viewer component by setting viewDetails to true
            this.viewDetails = true;
        }
    }

    handleCaseClose() {
        // This method will be called from the child component when the scan is completed
        // Set viewDetails back to false to hide the case viewer component
        this.viewDetails = false;

        // Refresh the table data after the scan is completed
        this.refreshTable();
    }

    refreshTable() {
        // Call the Apex method to refresh the data and update the table
        return refreshApex(this.wiredCases);
    }
}