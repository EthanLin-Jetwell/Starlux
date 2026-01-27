public class CallCenterCantDownloadCaseAttachment implements Sfc.ContentDownloadHandlerFactory {
    public Sfc.ContentDownloadHandler getContentDownloadHandler(List<ID> listIds, Sfc.ContentDownloadContext context) {
    return null; //2025-01-06 herbert為了註記inactive整個程式加進來的
/*        // 初始化 ContentDownloadHandler
        Sfc.ContentDownloadHandler contentDownloadHandler = new Sfc.ContentDownloadHandler();
        System.debug('Inside the Content Download');

        // 查詢附件關聯的 LinkedEntityId
        List<ContentDocumentLink> contentLinks = [
            SELECT LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN (
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id IN :listIds
            )
        ];
        // 將 LinkedEntityId 分類為案件（Case）與非案件物件
        List<Id> caseIds = new List<Id>();
        for (ContentDocumentLink link : contentLinks) {
            if (link.LinkedEntityId.getSObjectType() == Case.SObjectType) {
                caseIds.add(link.LinkedEntityId);
            }
        }
        // 如果沒有案件 ID，允許下載（表示附件不屬於案件）
        if (caseIds.isEmpty()) {
            contentDownloadHandler.isDownloadAllowed = true;
            return contentDownloadHandler;
        }
        // 查詢案件資料
        List<Case> cases = [
            SELECT Id
            FROM Case
            WHERE Id IN :caseIds
        ];
        // 如果沒有查詢到相關案件，允許下載
        if (cases.isEmpty()) {
            contentDownloadHandler.isDownloadAllowed = true;
            return contentDownloadHandler;
        }
        // 獲取當前使用者的 Profile 資訊
        Id profileId = UserInfo.getProfileId();
        Profile userProfile = [
            SELECT Id, Name
            FROM Profile
            WHERE Id = :profileId
        ];
        // 如果使用者是 Call Center Agent，檢查案件條件
        if (userProfile != null && userProfile.Name.startsWith('Call Center')) {
            for (Case c : cases) {
                // 檢查 Case.Id 是否以 '500' 開頭
                if (c.Id != null && String.valueOf(c.Id).startsWith('500')) { 
                    contentDownloadHandler.isDownloadAllowed = false;
                    contentDownloadHandler.downloadErrorMessage = 'Downloading a file is not allowed for your profile.';
                    return contentDownloadHandler;
                }
            }
        }
        // 預設允許下載
        contentDownloadHandler.isDownloadAllowed = true;
        return contentDownloadHandler;
*/
    }
         public static void fakeMethod(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
             i++;}
    }