public class CustomEmailHandler implements Messaging.InboundEmailHandler {
    public Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        try {
            // Get the email subject and body
            String emailSubject = email.subject;
            String emailBody = email.plainTextBody;

            // Define the regex pattern to extract the access code
            String regexPattern = '(?i)Código de acceso al sistema de escaneo interplanetario:\\s*([A-Za-z0-9-]+)';

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

                    // Create the case with the related planet information
                    Case newCase = new Case(
                        Subject = emailSubject,
                        Description = emailBody,
                        Planet__c = planet.Id,
                        Status = 'New' // Set the appropriate initial status for the case
                    );

                    insert newCase;

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