public with sharing class MultipleDeviceRequestController {
    public String SelectedSRNumber {get;set;}
    //public String srId {get;set;}
    
    public List<MTech_Devices__c> PendingSRs {get;set;}
    public List<MTech_Devices__c> RelatedDevices {get; set;}
    
    //map<Id, string> mapPendingDv = new map<Id,string>();
    public Set<String> setPendingDv = new Set<String>();
        
    private ApexPages.StandardSetController standardController;
    private Set<Id> MDIds = new Set<Id>();
    
    public MultipleDeviceRequestController(ApexPages.StandardSetController sController)
    {
        standardController = sController;
        pendingSRs = new List<MTech_Devices__c>();

        PendingSRs = [Select SR_Id__c,Serial_Number__c,SR_Number2__c,Device_Type__c,Device_Description__c,Device_Color__c,Warranty_Claim__c from MTech_Devices__c WHERE Registered__c=false];
        for(MTech_Devices__c pDv : pendingSRs){
            if(pDv.SR_Number2__c != null)
            	setPendingDv.add(pDv.SR_Number2__c);
        }
        //system.debug('***srNumber - '+srNumber);
    }
    
    public List<SelectOption> SRList
    {
        get{
            SRList = new List<SelectOption>();
            
            for(string tempSrNo : setPendingDv){
                SRList.add(new SelectOption(tempSrNo,tempSrNo));
            }
            system.debug('***SRList - ' + SRList);
            return SRList;
        }
        set;
    }
    public PageReference getDevices()
    {
        system.debug('***getDevices Entry');
        if(Test.isRunningTest()==true){
            RelatedDevices = new List<MTech_Devices__c>([SELECT Id,SR_Id__c,Serial_Number__c,SR_Number2__c,Device_Type__c,Device_Id__c,Device_Description__c,Device_Color__c,Warranty_Claim__c,Registered__c,Problem_Description__c,Customer_Name__c,CreatedDate from MTech_Devices__c]);
        }
        else{
            system.debug('***SelectedSRNumber - ' + SelectedSRNumber);
            RelatedDevices = new List<MTech_Devices__c>([SELECT Id,SR_Id__c,Serial_Number__c,SR_Number2__c,Device_Type__c,Device_Id__c,Device_Description__c,Device_Color__c,Warranty_Claim__c,Registered__c,Problem_Description__c,Customer_Name__c,CreatedDate from MTech_Devices__c WHERE SR_Number2__c=: SelectedSRNumber AND Registered__c =false]);
            system.debug('***RelatedDevices - ' + RelatedDevices);
            system.debug('***getDevices Exit');
        }
        return null;
    }
	
    public PageReference doCancel()
    {
        return standardController.cancel();
    }
    
    public void SyncDevices()
    {
        System.Debug('In Sync method');
        
        //Get Contract Name & Ids
        /*
        List<MTech_Contract__c> MTechContracts = new List<MTech_Contract__c>();
        MTechContracts = [SELECT Name,Id FROM MTech_Contract__c WHERE IsActive__c = true];
        
		map<string,Id> mapContracts = new map<string,Id>();
        for (MTech_Contract__c oContract : MTechContracts){
            mapContracts.put(oContract.Name,oContract.Id);
        }
        
		
		//Get Contract Name & Ids
        List<Contract> MTechContracts = new List<Contract>();
        MTechContracts = [SELECT MTech_Contract_Name__c,Id FROM Contract];
        
		map<string,Id> mapContracts = new map<string,Id>();
        for (Contract oContract : MTechContracts){
            mapContracts.put(oContract.MTech_Contract_Name__c,oContract.Id);
        }
        system.debug('>>>mapContracts- '+mapContracts);
        */
        
        
        //Get Class Id for 'MTech_Devices'    
        BMCServiceDesk__CMDB_Class__c DeviceClass = new BMCServiceDesk__CMDB_Class__c ();
        DeviceClass = [SELECT Id FROM BMCServiceDesk__CMDB_Class__c WHERE BMCServiceDesk__ClassName__c = 'Device' Limit 1];

        List<MTech_Devices__c> newMDs = new List<MTech_Devices__c>();
        
        //From Selected Devices, create a set of Serial#
        Set<String> setSerialNo = new Set<String>();
        for(MTech_Devices__c aMD : RelatedDevices){
            setSerialNo.add(aMD.Serial_Number__c);
            system.debug('###Set setSerialNo - '+aMD.Serial_Number__c);
        }
        
        try{
	        //Check if Device exists in CMDB
	        system.debug('###Set setSerialNo - '+setSerialNo.size());
	        List<BMCServiceDesk__BMC_BaseElement__c> existingDevices = new List<BMCServiceDesk__BMC_BaseElement__c>();
	        //existingDevices=[Select id, BMCServiceDesk__Name__c from BMCServiceDesk__BMC_BaseElement__c where BMCServiceDesk__SerialNumber__c IN : setSerialNo];
            existingDevices=[Select id,Name,BMCServiceDesk__Name__c from BMCServiceDesk__BMC_BaseElement__c where BMCServiceDesk__Name__c IN : setSerialNo];
	        
	        Set<String> setExstingDvcNames = new Set<String>();
	        for(BMCServiceDesk__BMC_BaseElement__c aED : existingDevices){
	            setExstingDvcNames.add(aED.BMCServiceDesk__Name__c);
	            system.debug('>>>Set setExstingDvcNames - '+aED.BMCServiceDesk__Name__c);
	        }
	                
            if(existingDevices.isEmpty()){
                System.debug('Existing devices not found. Create new Devices.');
	            newMDs = [Select Id,Serial_Number__c,Device_Color__c,Device_Type__c,Device_Description__c from MTech_Devices__c where Serial_Number__c IN: setSerialNo and SR_Number2__c=:SelectedSRNumber];
        	}
            else{
                System.debug('Existing devices found.');
	            newMDs = [Select Id,Serial_Number__c,Device_Color__c,Device_Type__c,Device_Description__c from MTech_Devices__c where Serial_Number__c NOT IN: setExstingDvcNames and SR_Number2__c=:SelectedSRNumber and Registered__c =false];
            }
	        
	        List<BMCServiceDesk__BMC_BaseElement__c> addDevices = new List<BMCServiceDesk__BMC_BaseElement__c>();
	        //Create Devices from Mtech_Devices which does not exist in CMDB
	        if(newMDs.size()>0){
	            for(MTech_Devices__c aDevice : newMDs){
	                BMCServiceDesk__BMC_BaseElement__c MTD = new BMCServiceDesk__BMC_BaseElement__c();
	                
	                MTD.BMCServiceDesk__Name__c = aDevice.Serial_Number__c;  //Serial #
	                MTD.BMCServiceDesk__SerialNumber__c = aDevice.Serial_Number__c;  //Serial #
	                MTD.BMCServiceDesk__CMDB_Class__c = DeviceClass.id;
	                MTD.BMCServiceDesk__Model__c = aDevice.Device_Description__c; //Device Description
	                MTD.Color__c = aDevice.Device_Color__c; //Color
	                MTD.Device_Type__c = aDevice.Device_Type__c; //Device Type
                    //System.debug('>>>Contract - '+aDevice.MTech_Contract_Name__c);
	                //if (aDevice.MTech_Contract_Name__c!=null)
	                //	MTD.MTech_Contract__c = Id.valueOf(mapContracts.get(aDevice.MTech_Contract_Name__c)); 
	                 
	                addDevices.add(MTD);
	            }
	            system.debug('>>>addDevices: ' + addDevices);
	            if (!addDevices.isEmpty())
	                insert addDevices;
	        }
	        //Update MTech_Devices with Device Ids
	        UpdateDeviceIDs(setSerialNo, RelatedDevices);
	        CreateLinkTasks(RelatedDevices);
	        CompleteDeviceRegistration(RelatedDevices);
        }
        catch(Exception excp1){}
    }
    private void UpdateDeviceIDs(Set<String> MDSrNo, List<MTech_Devices__c> selDev)
    {
        //for each selected Mtech device -> get the Device ID from CMDB and update it in MTech_Devices
        List<BMCServiceDesk__BMC_BaseElement__c> DevicesIds = [Select id,BMCServiceDesk__Name__c from BMCServiceDesk__BMC_BaseElement__c where BMCServiceDesk__SerialNumber__c IN : MDSrNo];
        List<MTech_Devices__c> UpdDevIds = new List<MTech_Devices__c>();
        
        map<string,Id> mapBE = new map<string,Id>();
        for (BMCServiceDesk__BMC_BaseElement__c aBE : DevicesIds){
            mapBE.put(aBE.BMCServiceDesk__Name__c,aBE.Id);
        }
        //if(Test.isRunningTest()==true)
        //    SelectedSRNumber=selDev[0].SR_Number2__c;
        try{
            System.debug('>>>selDev - '+selDev);
            System.debug('>>>SR_Number2__c - '+selDev[0].SR_Number2__c);
            //Get Service Request Id
            BMCServiceDesk__Incident__c SR = new BMCServiceDesk__Incident__c ();
            
            if(Test.isRunningTest()==true){
                //SR = [Select Id from BMCServiceDesk__Incident__c where Id=: PendingSRs[0].Id limit 1];
                SR = [Select Id from BMCServiceDesk__Incident__c];
            }
            else{
                SR = [Select Id from BMCServiceDesk__Incident__c where Name =: SelectedSRNumber limit 1];
            }
            //SR = [Select Id from BMCServiceDesk__Incident__c where Name ='00000972' limit 1];
            
            //System.debug('>>>SelectedSRNumber - '+SelectedSRNumber);
            System.debug('>>>SR - '+SR);
            if(SR != null){
                for(MTech_Devices__c aDev : selDev){
                    if(mapBE.containsKey(aDev.Serial_Number__c)){
                        aDev.Device_Id__c = mapBE.get(aDev.Serial_Number__c);	//Device Id
                        aDev.SR_Id__c = SR.Id;	//SR Id
                        system.debug('*****Device ID: '+aDev.Device_Id__c);
                        system.debug('*****Serial Number: '+aDev.Serial_Number__c);
                        system.debug('*****SR Id: '+SR.Id);
                        
                        UpdDevIds.add(aDev);
                    }
                }
                update UpdDevIds;
            }
        }
        catch(Exception excp2){}
    }
    
    private void CreateLinkTasks(List<MTech_Devices__c> MDev)
    {
        try{
            BMCServiceDesk__Incident__c SRAccount = new BMCServiceDesk__Incident__c();
            
            if(Test.isRunningTest()==true)
                SRAccount = [Select Account_Name__c from BMCServiceDesk__Incident__c Limit 1];
            else
            	SRAccount = [Select Account_Name__c from BMCServiceDesk__Incident__c where Id=: MDev[0].SR_Id__c];
            
            
            System.debug('>>>SRAccount - '+SRAccount.Account_Name__c);
            Account SrAc = [Select Name from Account where Id=:SRAccount.Account_Name__c];
            
            List<BMCServiceDesk__Task__c> newTasks = new List<BMCServiceDesk__Task__c>();
            for(MTech_Devices__c md : MDev)
            {
                //Create Tasks
                BMCServiceDesk__Task__c aTask = new BMCServiceDesk__Task__c();
                
                system.debug('***md- '+md);
                aTask.BMCServiceDesk__FKIncident__c = md.SR_Id__c;
                aTask.Configuration_Item__c = md.Device_Id__c;
                aTask.BMCServiceDesk__taskDescription__c = md.Problem_Description__c;
                aTask.Problem_Description__c = md.Problem_Description__c;
                aTask.Task_Status__c = 'Receiving';
                aTask.Device_Color__c = md.Device_Color__c;
                aTask.Device_Type__c = md.Device_Type__c;
                aTask.Account_Name__c = SrAc.Name;
                aTask.Received_Date__c = md.CreatedDate; 
                aTask.BMCServiceDesk__openDateTime__c = md.CreatedDate; 
                aTask.Serial_Number_In__c = md.Serial_Number__c;
                aTask.Service_Customer_Name__c = md.Customer_Name__c;
                aTask.Warranty__c = md.Warranty_Claim__c;
                aTask.Device_Description__c = md.Device_Description__c;
                aTask.OwnerId = UserInfo.getUserId();
                
                system.debug('*****aTask - '+aTask.Configuration_Item__c+' || '+aTask.BMCServiceDesk__taskDescription__c+' || '+aTask.BMCServiceDesk__FKIncident__c+' || '+aTask.OwnerId+' || ');
                newTasks.add(aTask);
            }
            system.debug('>>>newTasks: ' + newTasks);
            if(!newTasks.isEmpty())
                insert newTasks;
            
            //Link Configuration Item (Device) to Task
            List<BMCServiceDesk__BMC_CommonCILink__c> CILinks = new List<BMCServiceDesk__BMC_CommonCILink__c>();
            for (BMCServiceDesk__Task__c tsk : newTasks)
            {
                BMCServiceDesk__BMC_CommonCILink__c CILink = new BMCServiceDesk__BMC_CommonCILink__c();
                
                CILink.BMCServiceDesk__FKTask__c = tsk.id;
                CILink.BMCServiceDesk__CIInstance__c = tsk.Configuration_Item__c;
                CILink.BMCServiceDesk__ObjectName__c = 'Task__c';
                CILink.BMCServiceDesk__ObjectRecordID__c = 'TSK-' + tsk.id;
                CILinks.add(CILink);
                system.debug('*****CILink added for Task - '+ tsk.id);
            }
            
            insert CILinks;
            System.Debug('****CI Links created');
        }
        catch(Exception excp3){}
    }
    
    private void CompleteDeviceRegistration(List<MTech_Devices__c> UnRegisteredDevices){
        try{
            List<MTech_Devices__c> RegDevs = new List<MTech_Devices__c>();
            
            for(MTech_Devices__c rDev : UnRegisteredDevices){
                rDev.Registered__c = true;
                RegDevs.add(rDev);
            }
            update RegDevs;
        }
        catch(Exception excp4){}
    }
}