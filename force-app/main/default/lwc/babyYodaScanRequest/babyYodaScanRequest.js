import { LightningElement, track, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import {  subscribe, unsubscribe, MessageContext } from 'lightning/empApi';
import getOldestCasesAssignedToUser from '@salesforce/apex/CaseController.getOldestCasesAssignedToUser';

const columns = [
    { label: 'Asunto', fieldName: 'Subject', type: 'text', sortable: true },
    { label: 'Estado', fieldName: 'Status', type: 'text', sortable: true },
    { label: 'Email de contacto', fieldName: 'ContactEmail', type: 'email', sortable: true },
    { label: 'Contacto relacionado', fieldName: 'ContactId', type: 'url', sortable: true , typeAttributes:{label: { fieldName: 'ContactName' }, target: '_blank'} },
    { label: 'View Case', type: 'button', typeAttributes: { label: 'View Case', name: 'view_case', title: 'View Case', variant: 'base', }, },
];

export default class CasosInterplanetarios extends LightningElement {
    @track caseData = [];
    @track error;

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

            self.data = self.proxyToObj(self.data);
            self.data.push({Case_Id__c : obj.data.payload.Case_Id__c});
            console.log('this.data -> ' + JSON.stringify(self.data));
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
        if (action.name === 'view_case') {
            // Navigate to the case viewer LWC passing the caseId as a parameter
            this.navigateToCaseViewer(caseId);
        }
        
    }

    navigateToCaseViewer(caseId) {
        // Use navigation service to navigate to the case viewer LWC
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__CaseViewer', // Replace 'CaseViewer' with the actual name of your case viewer LWC
            },
            state: {
                c__caseId: caseId,
            },
        });
    }

    /*refreshTable() {
        // Call the Apex method to refresh the data and update the table
        //console.log('im here');
        return refreshApex(this.wiredCases);
    }*/
}