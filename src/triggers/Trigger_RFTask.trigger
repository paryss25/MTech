trigger Trigger_RFTask on BMCServiceDesk__Task__c (before insert, after insert, before update, after update, after delete) {
	/*
    if(Trigger.isAfter){
    	if (trigger.isInsert || trigger.isUpdate)
   			RFTaskTriggerHelper.UpdateLinkedTasks(Trigger.new);	//Update the count of Number Of Linked Tasks in MTech Contract
        
        if(trigger.isDelete)
            RFTaskTriggerHelper.UpdateLinkedTasks(Trigger.old);	//When Linked Task gets deleted
    }
    
    
    if(Trigger.isBefore){
        if (trigger.isInsert || trigger.isUpdate)
            RFTaskTriggerHelper.LinkUnlinkTaskContract(Trigger.new);	//When Device# gets linked or unlinked
    }
	*/
}