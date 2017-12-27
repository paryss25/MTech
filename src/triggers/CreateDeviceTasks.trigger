trigger CreateDeviceTasks on BMCServiceDesk__Incident__c (before insert,after insert) {
	
	String DeviceId{get;set;}
	public static string sAccountName;
	public static string AccountId;
    public string TaskQueueId = '';
	

    if(trigger.isBefore)
    {
        BMCServiceDesk__Incident__c unsavedSR = trigger.new[0];
        if(unsavedSR.BMCServiceDesk__Service_Request_Title__c == 'Single Device Repair Request' || unsavedSR.BMCServiceDesk__Service_Request_Title__c == 'Multiple Device Repair Request'){
            System.debug('CreateDeviceTasks - Inside IsBefore');
            map<string,Id> mapAccounts = new map<string,Id>();
            List<Account> rfac = new List<Account>([Select Id,Name from Account where BMCServiceDesk__Remedyforce_Account__c=true]);
            for(Account ac : rfac)
                mapAccounts.put(ac.Name,ac.Id);
            
            User usr = [Select BMCServiceDesk__Account_Name__c from User where Id =: UserInfo.getUserId()];
            
            //BMCServiceDesk__Incident__c unsavedSR = trigger.new[0];
            //if(unsavedSR.BMCServiceDesk__Service_Request_Title__c == 'Single Device Repair Request' || unsavedSR.BMCServiceDesk__Service_Request_Title__c == 'Multiple Device Repair Request')
            unsavedSR.Account_Name__c = mapAccounts.get(usr.BMCServiceDesk__Account_Name__c);
            
            
            //unsavedSR.Account_Name__c = GetAccountId();
            
            //sAccountName = usr.BMCServiceDesk__Account_Name__c;
            //AccountId = mapAccounts.get(usr.BMCServiceDesk__Account_Name__c);
            
            //System.debug('***AccountName- '+usr.BMCServiceDesk__Account_Name__c);
            //System.debug('***AccountId- '+mapAccounts.get(usr.BMCServiceDesk__Account_Name__c));
        }
    }
	
    if(trigger.isAfter){
        BMCServiceDesk__Incident__c unsavedSR = trigger.new[0];
        if(unsavedSR.BMCServiceDesk__Service_Request_Title__c == 'Single Device Repair Request' || unsavedSR.BMCServiceDesk__Service_Request_Title__c == 'Multiple Device Repair Request'){
            System.debug('CreateDeviceTasks - Inside IsBefore');
            map<string,Id> mapAccounts = new map<string,Id>();
            List<Account> rfac = new List<Account>([Select Id,Name from Account where BMCServiceDesk__Remedyforce_Account__c=true]);
            for(Account ac : rfac)
                mapAccounts.put(ac.Name,ac.Id);
            
            User usr = [Select BMCServiceDesk__Account_Name__c from User where Id =: UserInfo.getUserId()];
            
            //Get Queue Id for Task
            List<QueueSobject> TaskQueues = new List<QueueSobject>([Select Id,QueueId,Queue.Name,SobjectType From QueueSobject Where SobjectType='BMCServiceDesk__Task__c']);
            if(TaskQueues.size() > 0)
            {
                for(QueueSobject TQ : TaskQueues){
                    if(TQ.Queue.Name == 'Warehouse'){
                        TaskQueueId = TQ.QueueId;
                        break;
                    }
                }
            }
            
            BMCServiceDesk__BMC_BaseElement__c newDevice = new BMCServiceDesk__BMC_BaseElement__c();
            
            //Get Class Id for 'Device'    
            BMCServiceDesk__CMDB_Class__c MTechClass = new BMCServiceDesk__CMDB_Class__c ();
            MTechClass = [SELECT Id, Name FROM BMCServiceDesk__CMDB_Class__c WHERE BMCServiceDesk__ClassName__c = 'Device' limit 1];
            
            BMCServiceDesk__Incident__c newSR = trigger.new[0];
            System.debug('***SFDC: Trigger.new is: ' + Trigger.new);
            
            if (newSR.BMCServiceDesk__isServiceRequest__c == true){
                if (newSR.BMCServiceDesk__Service_Request_Title__c == 'Single Device Repair Request'){
                    System.Debug('****Entering Trigger code for Single Device Repair Request');
                    
                    List<BMCServiceDesk__BMC_BaseElement__c> existingDevice = new List<BMCServiceDesk__BMC_BaseElement__c>();
                    
                    //existingDevice = [Select id, BMCServiceDesk__Name__c from BMCServiceDesk__BMC_BaseElement__c where BMCServiceDesk__SerialNumber__c=:newSR.SR_Serial__c];
                    existingDevice = [Select id,Name,BMCServiceDesk__Name__c from BMCServiceDesk__BMC_BaseElement__c where BMCServiceDesk__Name__c =: newSR.SR_Serial__c];
                    
                    if(existingDevice.isEmpty()){
                        System.Debug('****Creating New Device in CMDB');
                        //--Create new Device with Serial#
                        newDevice.BMCServiceDesk__Name__c = newSR.SR_Serial__c; //Instance Name
                        newDevice.BMCServiceDesk__SerialNumber__c = newSR.SR_Serial__c; //Serial #
                        newDevice.BMCServiceDesk__CMDB_Class__c = MTechClass.id;    // Class
                        newDevice.BMCServiceDesk__Model__c = newSR.SR_Model__c;  //Device Description
                        newDevice.Color__c = newSR.SR_Color__c; //Color
                        newDevice.Device_Type__c = newSR.SR_Device_Type__c; //Device Type
                        
                        insert newDevice;
                        System.Debug('****New Device created in CMDB');
                    }
                    
                    if(existingDevice.isEmpty()){
                        DeviceId = newDevice.id;
                        System.Debug('****New Device found. DeviceId - ' + DeviceId);
                    }
                    else{
                        DeviceId = existingDevice[0].id;
                        System.Debug('****Existing Device found. DeviceId - ' + DeviceId);
                    }
                    
                    //Create Task and assign Device Serial# to the Task
                    System.Debug('****Creating and linking Task with Service Request for Device');
                    BMCServiceDesk__Task__c newTask = new BMCServiceDesk__Task__c();
                    newTask.BMCServiceDesk__FKIncident__c = newSR.id;
                    newTask.Configuration_Item__c = DeviceId;
                    newtask.BMCServiceDesk__taskDescription__c = newSR.BMCServiceDesk__incidentDescription__c;
                    newtask.Device_Color__c = newSR.SR_Color__c;
                    newtask.Device_Type__c = newSR.SR_Device_Type__c;
                    newtask.Received_Date__c = newSR.CreatedDate;
                    newtask.Serial_Number_In__c = newSR.SR_Serial__c;
                    newtask.Service_Customer_Name__c = newSR.Repair_Customer_Name__c;
                    newtask.Warranty__c = newSR.SR_Warranty__c;
                    if(newSR.SR_Warranty__c==true)
                        newtask.Warranty_Status__c='Yes';
                    else
                        newtask.Warranty_Status__c='No';
                    
                    newtask.Account_Name__c = newSR.Account_Name__c;
                    newtask.Task_Status__c = 'Receiving'; 
                    newtask.OwnerId = TaskQueueId;
                    
                    insert newTask;
                    System.Debug('****Task created - ' + newTask.id);
                    
                    //Link Configuration Item (Device) to Task
                    BMCServiceDesk__BMC_CommonCILink__c CILink = new BMCServiceDesk__BMC_CommonCILink__c();
                    CILink.BMCServiceDesk__FKTask__c = newTask.id;
                    CILink.BMCServiceDesk__CIInstance__c = DeviceId;
                    CILink.BMCServiceDesk__ObjectName__c = 'Task__c';
                    CILink.BMCServiceDesk__ObjectRecordID__c = 'TSK-' + newTask.id;
                    
                    insert CILink;
                    System.Debug('****CI Link created');
                }
                System.Debug('****Exiting Trigger code');
            }
        }
	}
}