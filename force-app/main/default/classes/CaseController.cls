public with sharing class CaseController {
    @AuraEnabled(cacheable=true)
    public static List<Case> getOldestCasesAssignedToUser() {
        // Query the five oldest cases assigned to the current user
        //System.debug('QUERY RUNNING');
        //System.debug(UserInfo.getUserId());
        //String userId = String.valueOf(UserInfo.getUserId());
        return [SELECT Id, Subject, Status, Contact.Email, Contact.Name, Contact.Id
                FROM Case
                WHERE OwnerId = :UserInfo.getUserId() AND IsClosed = false
                /*WHERE OwnerId = :userId AND IsClosed = false*/
                ORDER BY CreatedDate ASC
                LIMIT 5];
    }
}
