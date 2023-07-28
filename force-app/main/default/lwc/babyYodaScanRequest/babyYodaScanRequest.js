import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getOldestCasesAssignedToUser from '@salesforce/apex/CaseController.getOldestCasesAssignedToUser';

/*const columns = [
    { label: 'Asunto', fieldName: 'Subject', type: 'text', sortable: true },
    { label: 'Estado', fieldName: 'Status', type: 'text', sortable: true },
    { label: 'Email de contacto', fieldName: 'ContactEmail', type: 'email', sortable: true },
    {
        label: 'Contacto relacionado',
        type: 'url',
        typeAttributes: { label: { fieldName: 'ContactName' }, target: '_blank' },
    },
];*/

const columns = [
    { label: 'Asunto', fieldName: 'Subject', type: 'text', sortable: true },
    { label: 'Estado', fieldName: 'Status', type: 'text', sortable: true },
    { label: 'Email de contacto', fieldName: 'ContactEmail', type: 'email', sortable: true },
    { label: 'Contacto relacionado', fieldName: 'ContactId', type: 'url', sortable: true , typeAttributes:{label: { fieldName: 'ContactName' }, target: '_blank'}},
];

export default class CasosInterplanetarios extends LightningElement {
    @track caseData = [];
    @track error;

    @wire(getOldestCasesAssignedToUser)
    wiredCases({ error, data }) {
        if (data) {
            this.caseData = data.map((caseRecord) => ({
                Id: caseRecord.Id,
                Subject: caseRecord.Subject,
                Status: caseRecord.Status,
                ContactEmail: caseRecord.Contact.Email,
                ContactName: caseRecord.Contact.Name,
                ContactId: 'theksquaregroup25-dev-ed.develop.lightning.force.com/lightning/r/Contact/' + caseRecord.Contact.Id + '/view',
            }));
            this.error = undefined;
            console.log('Data retrieved from query:', data); // Move the console.log() here
        } else if (error) {
            this.error = error;
            this.caseData = undefined;
            console.error('Error occurred during data retrieval:', error);
        }
    }

    

    columns = columns;

    handleRowAction(event) {
        const caseId = event.detail.row.Id;
        // Handle row action - navigate to the particular case viewer LWC component using the caseId
    }

    refreshTable() {
        // Call the Apex method to refresh the data and update the table
        return refreshApex(this.wiredCases);
    }
}
