public class CustomEmailHandler implements Messaging.InboundEmailHandler {
    public Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        try {
            // Get the email subject and body
            String emailSubject = email.subject;
            String emailBody = email.plainTextBody;

            // Define the regex pattern to extract the access code
            String regexPattern = '(?i)Código de acceso al sistema de escaneo interplanetario:\\s*([A-Za-z0-9@-]+)';

            // Find the access code using the regex pattern
            Pattern pattern = Pattern.compile(regexPattern);
            Matcher matcher = pattern.matcher(emailBody);
            String accessCode = null;
            if (matcher.find()) {
                accessCode = matcher.group(1);
            }

            // If the access code is found, query the related planet
            if (accessCode != null) {
                List<Planet__c> planets = [SELECT Id, Name FROM Planet__c WHERE Code__c = :accessCode LIMIT 1];
                if (!planets.isEmpty()) {
                    Planet__c planet = planets[0];

                    // Check if there is a contact with the email address from the inbound email
                    List<Contact> relatedContacts = [SELECT Id FROM Contact WHERE Email = :email.fromAddress LIMIT 1];
                    Contact relatedContact = null;
                    if(relatedContacts.size() == 1){
                        relatedContact = relatedContacts[0];
                    }

                    // Create a new contact if one does not exist
                    if (relatedContact == null) {
                        relatedContact = new Contact(
                            LastName = 'Unknown', // Set a default last name for the contact
                            Email = email.fromAddress
                        );
                        insert relatedContact;
                    }

                    // Create the case with the related planet and contact information
                    Case newCase = new Case(
                        Subject = emailSubject,
                        Description = emailBody,
                        Planet__c = planet.Id,
                        ContactId = relatedContact.Id, // Link the case to the related contact
                        SuppliedEmail = email.fromAddress,
                        Origin = 'Email',
                        Status = 'New' // Set the appropriate initial status for the case
                    );

                    insert newCase;

                    
                    // Publish a message
                    New_Case__e nce = New New_Case__e(Case_Id__c = newCase.Id);
                    Database.SaveResult sr = EventBus.publish(nce);
                    if (sr.isSuccess()) {
                        System.debug('Successfully published event.');
                    } else {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('Error returned: ' +
                                        err.getStatusCode() +
                                        ' - ' +
                                        err.getMessage());
                        }
                    }

                    // Return the success message to the sender
                    result.success = true;
                    result.message = 'Case created successfully with External ID: ' + accessCode;
                } else {
                    // Planet with the access code not found, return an error message
                    result.success = false;
                    result.message = 'Planet with the specified access code not found.';
                }
            } else {
                // Access code not found in the email body, return an error message
                result.success = false;
                result.message = 'Access code not found in the email body.';
            }
        } catch (Exception ex) {
            // Error occurred during processing, return an error message
            result.success = false;
            result.message = 'An error occurred during email processing: ' + ex.getMessage();
        }

        return result;
    }
}