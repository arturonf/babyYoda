public class ExternalSystemIntegration {
    public class Response {
        public Boolean found { get; set; }
    }

    public static Response makeCallout(String accessCode) {
        String endpoint = 'https://zx9ooznd34.execute-api.us-east-1.amazonaws.com/default/request-yoda-location/' + accessCode;
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');

        // Set the authentication credentials if required
        String username = 'mando';
        String password = '12345';
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        request.setHeader('Authorization', authorizationHeader);

        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            return (Response) JSON.deserialize(response.getBody(), Response.class);
        } else {
            return null;
        }
    }

    public static void findBabyYoda(Id caseId) {
        Case testCase = [SELECT Id, Subject, Planet__c, Successful_Scan__c FROM Case WHERE Id = :caseId];
        if (testCase != null && testCase.Planet__c != null) {
            // Retrieve the related planet's code
            Planet__c relatedPlanet = [SELECT Code__c FROM Planet__c WHERE Id = :testCase.Planet__c];
            if (relatedPlanet != null) {
                // Query the custom metadata for the access code based on the planet code
                String planetCode = relatedPlanet.Code__c;
                //Planet_Code__mdt customMetadata = Planet_Code__mdt.getInstance(planetCode);
                Planet_Code__mdt customMetadata = [SELECT Code__c, Access_Code__c FROM Planet_Code__mdt WHERE Code__c = :planetCode];
                if (customMetadata != null && !String.isBlank(customMetadata.Access_Code__c)) {
                    // Make the callout to the external system with the access code
                    Response response = makeCallout(customMetadata.Access_Code__c);
                    if (response != null) {
                        // Handle the response from the external system
                        if (response.found) {
                            // Baby Yoda found, close the case and mark it as successful
                            testCase.Status = 'Closed - Found';
                            testCase.Successful_Scan__c = true;
                        } else {
                            // Baby Yoda not found, close the case and mark it as not successful
                            testCase.Status = 'Closed - Not Found';
                            testCase.Successful_Scan__c = false;
                        }

                        // Update the case
                        update testCase;
                    }
                }
            }
        }
    }
}