@IsTest
private class CustomEmailHandlerTest {
    @IsTest
    static void testHandleInboundEmail_Success() {
        // Test a successful case creation with a valid access code in the email body
        Test.startTest();

        // Create a test inbound email
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Solicitud de escaneo - Planet A';
        email.plainTextBody = 'Código de acceso al sistema de escaneo interplanetario: A-00001';

        // Create and insert a test planet
        Planet__c testPlanet = new Planet__c(Code__c = 'A-00001', Name = 'Planet A');
        insert testPlanet;

        // Call the handleInboundEmail method
        Messaging.InboundEmailResult result = new CustomEmailHandler().handleInboundEmail(email, null);

        // Verify the case creation and email response
        List<Case> cases = [SELECT Subject, Description, Planet__c FROM Case];
        System.assertEquals(1, cases.size());
        System.assertEquals('Solicitud de escaneo - Planet A', cases[0].Subject);
        System.assertEquals('Código de acceso al sistema de escaneo interplanetario: A-00001', cases[0].Description);
        System.assertEquals(testPlanet.Id, cases[0].Planet__c);
        //System.assertTrue(result.success);
        System.assertEquals('Case created successfully with External ID: A-00001', result.message);

        Test.stopTest();
    }

    @IsTest
    static void testHandleInboundEmail_PlanetNotFound() {
        // Test case creation with a valid access code in the email body, but the related planet is not found
        Test.startTest();

        // Create a test inbound email
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Solicitud de escaneo - Planet B';
        email.plainTextBody = 'Código de acceso al sistema de escaneo interplanetario: B-00099';

        // Call the handleInboundEmail method
        Messaging.InboundEmailResult result = new CustomEmailHandler().handleInboundEmail(email, null);

        // Verify the planet not found error response
        List<Case> cases = [SELECT Subject, Description, Planet__c FROM Case];
        System.assertEquals(0, cases.size());
        //System.assertFalse(result.success);
        System.assertEquals('Planet with the specified access code not found.', result.message);

        Test.stopTest();
    }

    @IsTest
    static void testHandleInboundEmail_AccessCodeNotFound() {
        // Test case creation with no valid access code in the email body
        Test.startTest();

        // Create a test inbound email with no access code
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Solicitud de escaneo - Planet C';
        email.plainTextBody = 'This is a test email without an access code.';

        // Call the handleInboundEmail method
        Messaging.InboundEmailResult result = new CustomEmailHandler().handleInboundEmail(email, null);

        // Verify the access code not found error response
        List<Case> cases = [SELECT Subject, Description, Planet__c FROM Case];
        System.assertEquals(0, cases.size());
        //System.assertFalse(result.success);
        System.assertEquals('Access code not found in the email body.', result.message);

        Test.stopTest();
    }

    // Add more test methods as needed to cover additional scenarios.
}