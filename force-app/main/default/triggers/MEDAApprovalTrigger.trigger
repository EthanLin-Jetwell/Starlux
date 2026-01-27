trigger MEDAApprovalTrigger on MEDA_Approval__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        MEDAApprovalFileCopyHandler.copyCaseFilesToMeda(Trigger.new);
    }
}