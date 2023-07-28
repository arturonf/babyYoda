public with sharing class CaseController {
    @AuraEnabled(cacheable=true)
    public static List<Case> getOldestCasesAssignedToUser() {
        // Query the five oldest cases assigned to the current user
        return [SELECT Id, Subject, Status, Contact.Email, Contact.Name, Contact.Id
                FROM Case
                WHERE OwnerId = :UserInfo.getUserId() AND IsClosed = false
                ORDER BY CreatedDate DESC
                LIMIT 5];
    }
}
