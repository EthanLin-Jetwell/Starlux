trigger CaseFileTrigger on ContentDocumentLink (after insert, after delete, after undelete) {
    CaseAttachmentHandler.updateCaseHasAttachmentFromFiles(Trigger.new, Trigger.old, Trigger.isInsert, Trigger.isDelete, Trigger.isUndelete);
}