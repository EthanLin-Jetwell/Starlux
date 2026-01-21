public class CaseAttachmentHandler {

    // 新的 Files 支援
    public static void updateCaseHasAttachmentFromFiles(List<ContentDocumentLink> newList, List<ContentDocumentLink> oldList, Boolean isInsert, Boolean isDelete, Boolean isUndelete) {
        Set<Id> caseIds = new Set<Id>();

        List<ContentDocumentLink> targetList = new List<ContentDocumentLink>();
        if(isInsert || isUndelete) targetList = newList;
        if(isDelete && oldList != null) targetList = oldList;

        // 先查 File 的 CreatedBy
        Set<Id> contentVersionIds = new Set<Id>();
        for(ContentDocumentLink cdl : targetList){
            if(cdl.ContentDocumentId != null){
                ContentVersion cv = [
                    SELECT Id, CreatedBy.Username, ContentDocumentId
                    FROM ContentVersion
                    WHERE ContentDocumentId = :cdl.ContentDocumentId
                    LIMIT 1
                ];
                if(cdl.LinkedEntityId != null && String.valueOf(cdl.LinkedEntityId).startsWith('500')){
                    Case parentCase = [SELECT Id, RecordType.DeveloperName FROM Case WHERE Id = :cdl.LinkedEntityId LIMIT 1];
                    if(parentCase.RecordType.DeveloperName == 'Group_Booking'
                       && ((cv.CreatedBy.UserName == 'apiuser@starlux-airlines.com.starluxtrn') ||(cv.CreatedBy.UserName == 'apiuser@starlux-airlines.com')
                       )) {
                        caseIds.add(cdl.LinkedEntityId);
                    }
                }
            }
        }

        updateCaseHasAttachment(caseIds);
    }

    // 通用更新邏輯
    private static void updateCaseHasAttachment(Set<Id> caseIds){
        if(caseIds.isEmpty()) return;

        Map<Id, Case> casesToUpdate = new Map<Id, Case>(
            [SELECT Id, Has_Attachment__c,
                    (SELECT Id FROM ContentDocumentLinks LIMIT 1)
             FROM Case
             WHERE Id IN :caseIds]
        );

        List<Case> updates = new List<Case>();

        for(Case c : casesToUpdate.values()){
            Boolean hasAttachment = false;
            if((c.ContentDocumentLinks != null && !c.ContentDocumentLinks.isEmpty())){
                hasAttachment = true;
            }
            if(c.Has_Attachment__c != hasAttachment){
                c.Has_Attachment__c = hasAttachment;
                updates.add(c);
            }
        }

        if(!updates.isEmpty()){
            update updates;
        }
    }
}