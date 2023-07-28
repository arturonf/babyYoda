@isTest
public class ExternalSystemIntegrationTest {
    @isTest
    static void testMakeCallout() {
        // Set up test data
        String accessCode = 'jPnR5625';

        // Mock the callout response
        Test.setMock(HttpCalloutMock.class, new ExternalSystemIntegrationMock());

        // Call the makeCallout method
        Test.startTest();
        ExternalSystemIntegration.Response response = ExternalSystemIntegration.makeCallout(accessCode);
        Test.stopTest();

        // Perform assertions on the response
        System.assertEquals(false, response.found, 'Expected Baby Yoda not found');
    }
    @isTest
    static void testFindBabyYoda() {
        // Create a test planet record
        Planet__c testPlanet = new Planet__c(Name = 'Alderaan', Code__c = 'A-00001');
        insert testPlanet;
        
        // Create a test case with the related planet
        Case testCase = new Case(
            Subject = 'Solicitud de escaneo - Alderaan',
            Description = 'Código de acceso al sistema de escaneo interplanetario: A-00001',
            Planet__c = testPlanet.Id
        );
        insert testCase;
        
        // Mock the callout response
        Test.setMock(HttpCalloutMock.class, new ExternalSystemIntegrationMock());
        
        // Call the method to find Baby Yoda
        Test.startTest();
        ExternalSystemIntegration.findBabyYoda(testCase.Id);
        Test.stopTest();
        
        // Verify that the case was updated with the correct status
        Case updatedCase = [SELECT Id, Status, Successful_Scan__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('Closed - Not Found', updatedCase.Status, 'Incorrect case status');
        System.assertEquals(false, updatedCase.Successful_Scan__c, 'Incorrect Successful Scan value');
    }
}