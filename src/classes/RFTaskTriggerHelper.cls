public class RFTaskTriggerHelper {
    public static datetime StDate;
    public static datetime EndDate;
    public static Integer TotalLinkedTasks;
    
    public static void UpdateLinkedTasks(List<BMCServiceDesk__Task__c> newTasks){
        
        System.debug('UpdateLinkedTasks-'+newTasks.size());
        //Get MTech Contract Name from Tasks

        //try{
            Set<string> setMContracts = new Set<string>();
        	for(BMCServiceDesk__Task__c aTask : newTasks){
                system.debug('aTask.MTech_Contract_Number__c - '+aTask.MTech_Contract_Number__c);
                if(aTask.MTech_Contract_Number__c != null){
                    setMContracts.add(aTask.FKMTech_Contract__c);	//Link Task
                }
                else if (aTask.Previous_MTech_Contract_Id__c != null){
                    setMContracts.add(aTask.Previous_MTech_Contract_Id__c);	//Unlink Task
                }
        	}
        
        	RefreshLinkedTasks(setMContracts);
        //}
        //catch(DMLException e){
        //    newTasks.get(0).addError(e.getDMLMessage(0));
        //}

    }
    
    /*
    public static void RemoveLinkedTasks(List<BMCServiceDesk__Task__c> newTasks){
        System.debug('RemoveLinkedTasks-'+newTasks.size());
        //Get MTech Contract Name from Tasks
        Set<string> setMContracts = new Set<string>();
        for(BMCServiceDesk__Task__c aTask : newTasks){
            system.debug('aTask.MTech_Contract_Name__c - '+aTask.MTech_Contract_Name__c);
			setMContracts.add(aTask.MTech_Contract_Name__c);
        }
        RefreshLinkedTasks(setMContracts);
    }
	*/
    
    public static void RefreshLinkedTasks(Set<String> setMContracts){
        
        List <MTech_Contract__c> UpdMContracts = new List<MTech_Contract__c>();
        for (string sMContract : setMContracts){
            System.debug('MTech_Contract_Name__c - '+ sMContract);
            //Get the MTech Contract Details from Contract Name in Task
			MTech_Contract__c MContract = [SELECT Id,Name,Contract_End_Date__c,Contract_Start_Date__c,IsActive__c FROM MTech_Contract__c WHERE Id=: Id.valueOf(sMContract)];
           	StDate =  MContract.Contract_Start_Date__c;
            EndDate = MContract.Contract_End_Date__c;
            //system.debug('Start & End Dates = ' + StDate +' - '+EndDate);
            system.debug('MContract Id = ' + MContract.Id);
            
            //Get the total Tasks based on Contract Start/End Date
            TotalLinkedTasks = [SELECT Count() FROM BMCServiceDesk__Task__c WHERE MTech_Contract_Number__c =: MContract.Name AND CreatedDate >: StDate AND CreatedDate <: EndDate AND FKMTech_Contract__c!=null];
            system.debug('TotalLinkedTasks for Contract ('+ sMContract + ') = ' + TotalLinkedTasks);
            
			//Update Total Linked Tasks in MTech Contract            
            MTech_Contract__c aMContract = new MTech_Contract__c();
            aMContract.Id = MContract.Id;
            //aMContract.Number_Of_Linked_Tasks__c = TotalLinkedTasks;
            aMContract.Contract_Incidents_Used__c = TotalLinkedTasks;
            
            UpdMContracts.add(aMContract);
    	}
        update UpdMContracts;

    }
    
    public static void LinkUnlinkTaskContract(List<BMCServiceDesk__Task__c> newTasks){
        
        for (BMCServiceDesk__Task__c tsk : newTasks){
            System.debug('MTech_Contract_Number__c = ' + tsk.MTech_Contract_Number__c);
            System.debug('Configuration_Item__c = ' + tsk.Configuration_Item__c);
            System.debug('FKMTech_Contract__c = ' + tsk.FKMTech_Contract__c);
            
            if(tsk.Configuration_Item__c != null){
            	BMCServiceDesk__BMC_BaseElement__c BE = [Select Id, Name, MTech_Contract_Number__c from BMCServiceDesk__BMC_BaseElement__c where Id =: tsk.Configuration_Item__c];
            	System.debug('BE.Name = ' + BE.MTech_Contract_Number__c);
                if(BE.MTech_Contract_Number__c!=null){
                    MTech_Contract__c aMContract = [SELECT Id,Contract_End_Date__c,Contract_Start_Date__c,IsActive__c FROM MTech_Contract__c WHERE Id =: BE.MTech_Contract_Number__c];
    
                    tsk.FKMTech_Contract__c = aMContract.Id;
                    tsk.Previous_MTech_Contract_Id__c = null;
                }
            }
            else{
                tsk.Previous_MTech_Contract_Id__c = tsk.FKMTech_Contract__c;
                tsk.FKMTech_Contract__c=null;
            }
    	}

	}
}