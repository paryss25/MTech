global class IncomingDevice_Safeware implements Messaging.InboundEmailHandler{

    //List to store all lines of the email body
    public static list<String> AllLines;	

    public string AccountName;
    public string AccountId;
    public static string SerialNumber;
    public static string CustomerName;
    public static string CustomerEmail;
    public static string ReturnAddress;
    public static string DeviceType;
    public static string DeviceDesc;
    public static string DeviceColor;
    public static string ProbDesc;
    public static boolean WarrantyClaim;
    public static string ContractNumber;
    public static string ServiceContractNumber;
    public static boolean ShipLableNeeded;
    public static boolean ShipBox;
    
    public string SRId = '';
    public string sFromEmail;
    public string UserId;
    
    public string REQDEFNAME = 'Incoming Single Device Request';
    //public string SAFEWAREUSERNAME = 'claims@safeware.com';
    public string sLogs = '';
    public string TaskQueueId;
    public string tempLine;
    
        
	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope env){
	    //Create an inboundEmailResult object for returning the result of email service.
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

	    // Add the email plain text into the local variable
	    String sBody = email.plainTextBody != null ? email.plainTextBody : email.htmlBody;
	        
	    // Add the email from Address text into the local variable
	    sFromEmail = email.fromAddress;
        System.debug('sFromEmail - '+sFromEmail);
	
	    // Add the email subject into the local variable
	    String sSubject = email.subject;

		//Set the User Id
		//User[] usr = [Select Id,BMCServiceDesk__Account_ID__c,BMCServiceDesk__Account_Name__c from User where username =: SAFEWAREUSERNAME];
		
        User[] usr = [Select Id,BMCServiceDesk__Account_ID__c,BMCServiceDesk__Account_Name__c from User where username =: sFromEmail];
		if(usr.size() > 0){
			AccountName = usr[0].BMCServiceDesk__Account_Name__c;
			UserId = usr[0].Id;
			sLogs = sLogs + 'AccountName='+AccountName+',UserId='+UserId;
			System.debug('sLogs1='+sLogs);
		}
        else{
           	sLogs = sLogs + 'ERROR: User ' + sFromEmail + 'does not exist in Remedyforce';
			System.debug('sLogs1='+sLogs);

            result.success = false;
            return result;
        }
		
		
        /*
		//Get the Account ID
		
		map<string,Id> mapAccounts = new map<string,Id>();
		List<Account> rfac = new List<Account>([Select Id,Name from Account where BMCServiceDesk__Remedyforce_Account__c=true]);
		for(Account ac : rfac)
			mapAccounts.put(ac.Name,ac.Id);
			
		AccountId = mapAccounts.get(usr[0].BMCServiceDesk__Account_Name__c);
        System.debug('AccountId111='+AccountId);
		*/
		
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
		
        AllLines = new list<String>();
        //Incoming email will be in text format. Email Body lines are separated by '<br>'
        AllLines = sBody.split('<br>');
        System.debug('>>>AllLines - '+AllLines);
        
        for(String line : AllLines){
 
            if( line.contains('Account Name:'))
            	AccountName =  usr[0].BMCServiceDesk__Account_Name__c;
            //if( line.contains('Account Name:'))
            //	AccountName =  line.SubStringAfter(':').trim();
        	
            if( line.contains('Serial Number:')){
                SerialNumber = line.SubStringAfter(':').trim();
                
                if(SerialNumber.length()>24)
                	SerialNumber=SerialNumber.mid(0,24);
            }

            if( line.contains('Customer Name:')){
                CustomerName = line.SubStringAfter(':').trim();
                
                if(CustomerName.length()>254)
                	CustomerName=CustomerName.mid(0,254);
            }
        	
            if( line.contains('Customer Email Address:'))
                CustomerEmail = line.SubStringAfter(':').trim();
        	
            if( line.contains('Return Address:')){
                ReturnAddress = line.SubStringAfter(':').trim();

                if(ReturnAddress.length()>254)
                    ReturnAddress = ReturnAddress.mid(0,254);
            }
        	
            if( line.contains('Device Type:'))
                DeviceType = line.SubStringAfter(':').trim();
        	
            if( line.contains('Device Description:')){
                DeviceDesc = line.SubStringAfter(':').trim();
                
                if(DeviceDesc.length()>49)
                    DeviceDesc = DeviceDesc.mid(0,49);
        	}
        	
            if( line.contains('Device Color:'))
                DeviceColor = line.SubStringAfter(':').trim();
        	
            if( line.contains('Problem Description:'))
                ProbDesc = line.SubStringAfter(':').trim();
        	
            if( line.contains('Warranty Claim:')) {
                tempLine = line.SubStringAfter(':').trim();
                if(tempLine.trim()=='Y')
                	WarrantyClaim = true;
                else
                	WarrantyClaim = false;
        	}
            
            if( line.contains('Service Contract Number:')){
                ServiceContractNumber = line.SubStringAfter(':').trim();
            
                if (ServiceContractNumber.length()>19)
                	ServiceContractNumber = ServiceContractNumber.mid(0,19);
            }
            
            if( line.contains('Shipping Label Needed:')){
                tempLine = line.SubStringAfter(':').trim();
            
                if(tempLine.trim()=='Y')
                	ShipLableNeeded = true;
                else
                	ShipLableNeeded = false;
            }

            if( line.contains('Ship Box:')){
                tempLine = line.SubStringAfter(':').trim();
                
                if(tempLine.trim()=='Y')
                    ShipBox = true;
                else
                	ShipBox = false;
            }

		}
        
		sLogs = sLogs + ',SerialNumber='+SerialNumber+',CustomerName='+CustomerName+',CustomerEmail='+CustomerEmail+',DeviceType='+DeviceType+',DeviceColor='+DeviceColor+',WarrantyClaim='+tempLine.trim()+' ,ServiceContractNumber='+ServiceContractNumber;
		System.debug('sLogs2='+sLogs);
		
		//Create SR
        BMCServiceDesk__SRM_RequestDefinition__c reqDef = [Select Id,BMCServiceDesk__FKCategory__c,BMCServiceDesk__FKBusinessService__c,BMCServiceDesk__FKServiceOffering__c from BMCServiceDesk__SRM_RequestDefinition__c where Name =: REQDEFNAME];
		System.debug('>>>reqDef - '+reqDef.Id);
        System.debug('>>>userId - '+userId);
        //Create Request Detail
        BMCServiceDesk__SRM_RequestDetail__c oRD = new BMCServiceDesk__SRM_RequestDetail__c(
            BMCServiceDesk__FKClient__c = Id.valueOf(UserId),	//userinfo.getUserId(),
            BMCServiceDesk__FKRequestDefinition__c = reqDef.Id,
            BMCServiceDesk__ServiceRequest__c = REQDEFNAME,
            BMCServiceDesk__ApprovalRequired__c = false
        );
        insert oRD;
        
        System.debug('AccountId='+AccountId+','+'AccountName='+usr[0].BMCServiceDesk__Account_Name__c+','+'SerialNumber='+SerialNumber+','+'CustomerName='+CustomerName);
        //System.debug('AccountId='+AccountId+','+'AccountName='+AccountName+','+'SerialNumber='+SerialNumber+','+'CustomerName='+CustomerName);
        System.debug('ReturnAddress='+ReturnAddress+','+'DeviceType='+DeviceType+','+'DeviceDesc='+DeviceDesc+','+'DeviceColor='+DeviceColor+','+'ProbDesc='+ProbDesc);
        System.debug('WarrantyClaim='+WarrantyClaim+','+' ,ServiceContractNumber='+ServiceContractNumber+'reqDef.BMCServiceDesk__FKCategory__c='+reqDef.BMCServiceDesk__FKCategory__c+','+'reqDef.BMCServiceDesk__FKBusinessService__c='+reqDef.BMCServiceDesk__FKBusinessService__c);
        System.debug('reqDef.Id='+reqDef.Id+','+'reqDef.BMCServiceDesk__FKServiceOffering__c='+reqDef.BMCServiceDesk__FKServiceOffering__c+','+'oRD.Id='+oRD.Id);
        System.debug('REQDEFNAME='+REQDEFNAME+','+'CustomerEmail='+CustomerEmail+','+'TaskQueueId='+TaskQueueId);
        
		//Create Incident
        BMCServiceDesk__Incident__c oInc = new BMCServiceDesk__Incident__c(
        	Account_Name__c = Id.valueOf( usr[0].BMCServiceDesk__Account_ID__c),
        	//Account_Name__c = AccountName,
        	SR_Serial__c = SerialNumber,
        	Repair_Customer_Name__c = CustomerName,
        	Shipping_Address__c = ReturnAddress,
        	SR_Device_Type__c = DeviceType,
        	SR_Model__c = DeviceDesc,
        	SR_Color__c = DeviceColor,
        	BMCServiceDesk__incidentDescription__c = ProbDesc,
        	SR_Warranty__c = WarrantyClaim,
            Need_a_Shipping_Label__c = ShipLableNeeded,
            Need_a_Shipping_Label_Box__c = ShipBox,
            BMCServiceDesk__FKCategory__c = reqDef.BMCServiceDesk__FKCategory__c,
            BMCServiceDesk__FKClient__c = Id.valueOf(UserId),	//userinfo.getUserId(),
            BMCServiceDesk__FKBusinessService__c = reqDef.BMCServiceDesk__FKBusinessService__c,
            BMCServiceDesk__FKRequestDefinition__c = reqDef.Id,
            BMCServiceDesk__FKServiceOffering__c = reqDef.BMCServiceDesk__FKServiceOffering__c,
            BMCServiceDesk__FKRequestDetail__c = oRD.Id,
            BMCServiceDesk__Service_Request_Title__c = REQDEFNAME,
            BMCServiceDesk__IncidentType__c = 'Service Request',
            Repair_Customer_Email__c = CustomerEmail,
            OwnerId = TaskQueueId,
            Purchase_Order__c = ServiceContractNumber
        );
        insert oInc;
        System.debug('Incident created='+oInc.Name);
        
        //Update Request Detail with Incident number
        BMCServiceDesk__SRM_RequestDetail__c updateRD = [Select BMCServiceDesk__FKIncident__c from BMCServiceDesk__SRM_RequestDetail__c where id =: oRD.id];
        updateRD.BMCServiceDesk__FKIncident__c = oInc.id;
        update updateRD;

		//Get Class Id for 'Device'    
        BMCServiceDesk__CMDB_Class__c DeviceClass = [SELECT Id FROM BMCServiceDesk__CMDB_Class__c WHERE BMCServiceDesk__ClassName__c = 'Device'];
		
		//BMCServiceDesk__BMC_BaseElement__c[] DeviceCIs = [Select id,Name,BMCServiceDesk__Name__c from BMCServiceDesk__BMC_BaseElement__c where BMCServiceDesk__SerialNumber__c =: SerialNumber];
		BMCServiceDesk__BMC_BaseElement__c[] DeviceCIs = [Select id,Name,BMCServiceDesk__Name__c from BMCServiceDesk__BMC_BaseElement__c where BMCServiceDesk__Name__c =: SerialNumber];
		
		BMCServiceDesk__Task__c aTask = new BMCServiceDesk__Task__c();
		
        
		if(DeviceCIs.size() == 0)
		{
			//Create new Device in CMDB
            BMCServiceDesk__BMC_BaseElement__c BE = new BMCServiceDesk__BMC_BaseElement__c();
            
            BE.BMCServiceDesk__Name__c = SerialNumber;  //Serial #
            BE.BMCServiceDesk__SerialNumber__c = SerialNumber;  //Serial #
            BE.BMCServiceDesk__CMDB_Class__c = DeviceClass.id;
            BE.BMCServiceDesk__Model__c = DeviceDesc; //Device Description
            BE.Color__c = DeviceColor; //Color
            BE.Device_Type__c = DeviceType; //Device Type
            
            //upsert BE;
            insert BE;
            System.debug('New Device Registered='+BE.Name);
            
            //Link newly created Configuration Item to Task
            aTask.Configuration_Item__c = BE.Id;
		}
		else{
			System.debug('Existing Device found='+DeviceCIs[0].Name);
            //Link existing Configuration Item to Task
			aTask.Configuration_Item__c = DeviceCIs[0].Id;
		}
			
        aTask.BMCServiceDesk__FKIncident__c = oInc.Id;
        aTask.BMCServiceDesk__taskDescription__c = ProbDesc;
        aTask.Problem_Description__c = ProbDesc;
        aTask.Task_Status__c = 'Receiving';
        aTask.Device_Color__c = DeviceColor;
        aTask.Device_Type__c = DeviceType;
        aTask.Account_Name__c = AccountName;
        aTask.Received_Date__c = system.today(); 
        aTask.BMCServiceDesk__openDateTime__c = system.today(); 
        aTask.Serial_Number_In__c = SerialNumber;
        aTask.Service_Customer_Name__c = CustomerName;
        aTask.Warranty__c = WarrantyClaim;
        aTask.Device_Description__c = DeviceDesc;
        aTask.OwnerId = Id.valueOf(TaskQueueId);
        aTask.Purchase_Order_Number__c = ServiceContractNumber;

		insert aTask;
		System.debug('Task created='+aTask.Name);
		
        //Link Configuration Item (Device) to Task
        BMCServiceDesk__BMC_CommonCILink__c CILink = new BMCServiceDesk__BMC_CommonCILink__c();
            
            CILink.BMCServiceDesk__FKTask__c = aTask.id;
            CILink.BMCServiceDesk__CIInstance__c = aTask.Configuration_Item__c;
            CILink.BMCServiceDesk__ObjectName__c = 'Task__c';
            CILink.BMCServiceDesk__ObjectRecordID__c = 'TSK-' + aTask.id;
        
        insert CILink;
        System.debug('Task CI link created='+CILink.Name);

        //if (UserId!='' && UserId!=null)
        //	SendEmail(UserId);
        
        // Set the result to true.
        result.success = true;

        // Return the result for the  Email Service
        return result;
	}
	
    /*
    public static void SendEmail(string toUserId)
	{
        try{
            IncomingEmail__c IMCc = IncomingEmail__c.getInstance('Safeware_Cc_Address');
            IncomingEmail__c IMTemplate = IncomingEmail__c.getInstance('Template_Name');
            
            string CcAddr = '';
            EmailTemplate ET;
            
            if(IMCc!=null)
                CcAddr = IMCc.Value__c;
            
            System.debug('CcAddr - '+CcAddr);
            
            //Get Template Id
            if(IMTemplate!=null){
                ET = [SELECT Id,Name FROM EmailTemplate WHERE Name =: IMTemplate.Value__c];
                System.debug('ET Id/Name - '+ ET.Id + '/' + ET.Name);
            }
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            //Check for size and set to address of the mail
            if(toUserId!='' && toUserId!=null)
                mail.setTargetObjectId(Id.valueOf(toUserId));
           
            //Set the cc address of the mail
            if(CcAddr!='' && CcAddr!=null){
                List<String> lstCCAddresses = CcAddr.split('@@@');
                mail.setCcAddresses(lstCCAddresses);
            }
            mail.saveAsActivity = false;
            if(IMTemplate!=null)
                mail.setTemplateId(Id.valueOf(ET.Id));
            else{
                mail.setSubject('Service Request Created:');
            	mail.setPlainTextBody('New Service Request Created:');
            }
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            system.debug('Email Sent to: '+toUserId);
        }
        catch(Exception ex){}
    }
	*/
	/*
	public static void CreateSR()
	{
		string RDName = 'Single Device Repair Request';
        BMCServiceDesk__SRM_RequestDefinition__c reqDef = Database.query('Select Id,BMCServiceDesk__FKCategory__c,BMCServiceDesk__FKBusinessService__c,BMCServiceDesk__FKServiceOffering__c from BMCServiceDesk__SRM_RequestDefinition__c where Name =: RDName');
		
        //Create Request Detail
        BMCServiceDesk__SRM_RequestDetail__c oRD = new BMCServiceDesk__SRM_RequestDetail__c(
            BMCServiceDesk__FKClient__c = UserId,
            BMCServiceDesk__FKRequestDefinition__c = reqDef.Id,
            BMCServiceDesk__ServiceRequest__c = 'Safeware',
            BMCServiceDesk__ApprovalRequired__c = false
        );
        insert oRD;
            
		System.debug(AccountName);
		//Create Incident
        BMCServiceDesk__Incident__c oInc = new BMCServiceDesk__Incident__c(
        	Account_Name__c = Id.valueOf(AccountId),
        	SR_Serial__c = SerialNumber,
        	Repair_Customer_Name__c = CustomerName,
        	Shipping_Address__c = ReturnAddress,
        	SR_Device_Type__c = DeviceType,
        	SR_Model__c = DeviceDesc,
        	SR_Color__c = DeviceColor,
        	BMCServiceDesk__incidentDescription__c = ProbDesc,
        	SR_Warranty__c = WarrantyClaim,
            BMCServiceDesk__FKCategory__c = reqDef.BMCServiceDesk__FKCategory__c,
            BMCServiceDesk__FKClient__c = userId,
            BMCServiceDesk__FKBusinessService__c = reqDef.BMCServiceDesk__FKBusinessService__c,
            BMCServiceDesk__FKRequestDefinition__c = reqDef.Id,
            BMCServiceDesk__FKServiceOffering__c = reqDef.BMCServiceDesk__FKServiceOffering__c,
            BMCServiceDesk__FKRequestDetail__c = oRD.Id,
            BMCServiceDesk__Service_Request_Title__c = 'Single Device Repair Request',
            BMCServiceDesk__TemplateAlreadyApplied__c = false,
            BMCServiceDesk__TemplateName__c = '',
            BMCServiceDesk__IncidentType__c = 'Service Request',
            OwnerId = userId
            //BMCServiceDesk__contactType__c = 'Self Service'
            //Name='Inc1234'
        );
        insert oInc;
        
        SRId = oInc.Id;
        
        //Update Request Detail with Incident number
        BMCServiceDesk__SRM_RequestDetail__c updateRD = [Select BMCServiceDesk__FKIncident__c from BMCServiceDesk__SRM_RequestDetail__c where id =: oRD.id];
        updateRD.BMCServiceDesk__FKIncident__c = oInc.id;
        update updateRD;
        
        
	}
	
	
	public static BMCServiceDesk__BMC_BaseElement__c CreateDevice()
	{
		//Get Class Id for 'MTech_Devices'    
        BMCServiceDesk__CMDB_Class__c DeviceClass = new BMCServiceDesk__CMDB_Class__c ();
        DeviceClass = [SELECT Id FROM BMCServiceDesk__CMDB_Class__c WHERE BMCServiceDesk__ClassName__c = 'Device' Limit 1];
		
		//BMCServiceDesk__BMC_BaseElement__c DeviceCI = [Select id,BMCServiceDesk__Name__c from BMCServiceDesk__BMC_BaseElement__c where BMCServiceDesk__SerialNumber__c =: SerialNumber];
		BMCServiceDesk__BMC_BaseElement__c DeviceCI = [Select id,BMCServiceDesk__Name__c from BMCServiceDesk__BMC_BaseElement__c where BMCServiceDesk__SerialNumber__c =1];
		
		//if(DeviceCI.id == null)
		//{
			//Create new Device in CMDB
            BMCServiceDesk__BMC_BaseElement__c BE = new BMCServiceDesk__BMC_BaseElement__c();
            
            BE.BMCServiceDesk__Name__c = SerialNumber;  //Serial #
            BE.BMCServiceDesk__SerialNumber__c = SerialNumber;  //Serial #
            BE.BMCServiceDesk__CMDB_Class__c = DeviceClass.id;
            BE.BMCServiceDesk__Model__c = DeviceDesc; //Device Description
            BE.Color__c = DeviceColor; //Color
            BE.Device_Type__c = DeviceType; //Device Type
            
            insert BE;
            
            //CreateTask(BE);
            return BE;
		//}
		//else
		//	return DeviceCI;
		
			//CreateTask(DeviceCI);
	}

	
	public static void CreateTask(BMCServiceDesk__BMC_BaseElement__c Device)
	{
        //Create Tasks
        BMCServiceDesk__Task__c aTask = new BMCServiceDesk__Task__c();
        
	        aTask.BMCServiceDesk__FKIncident__c = SRId;
	        aTask.Configuration_Item__c = Device.Id;
	        aTask.BMCServiceDesk__taskDescription__c = ProbDesc;
	        aTask.Problem_Description__c = ProbDesc;
	        aTask.Task_Status__c = 'Receiving';
	        aTask.Device_Color__c = DeviceColor;
	        aTask.Device_Type__c = DeviceType;
	        aTask.Account_Name__c = AccountName;
	        aTask.Received_Date__c = Today(); 
	        aTask.BMCServiceDesk__openDateTime__c = Today(); 
	        aTask.Serial_Number_In__c = SerialNumber;
	        aTask.Service_Customer_Name__c = CustomerName;
	        aTask.Warranty__c = WarrantyClaim;
	        aTask.Device_Description__c = DeviceDesc;
	        aTask.OwnerId = UserId;

		insert aTask;
		
		
        //Link Configuration Item (Device) to Task
        BMCServiceDesk__BMC_CommonCILink__c CILink = new BMCServiceDesk__BMC_CommonCILink__c();
            
            CILink.BMCServiceDesk__FKTask__c = aTask.id;
            CILink.BMCServiceDesk__CIInstance__c = aTask.Configuration_Item__c;
            CILink.BMCServiceDesk__ObjectName__c = 'Task__c';
            CILink.BMCServiceDesk__ObjectRecordID__c = 'TSK-' + aTask.id;
        
        insert CILink;
	}
		*/
	/*
	public static string GetAccountId()
	{
		map<string,Id> mapAccounts = new map<string,Id>();
		List<Account> rfac = new List<Account>([Select Id,Name from Account where BMCServiceDesk__Remedyforce_Account__c=true]);
		for(Account ac : rfac)
			mapAccounts.put(ac.Name,ac.Id);
			
		User usr = [Select BMCServiceDesk__Account_Name__c from User where username =: sFromEmail];
		
		return mapAccounts.get(usr.BMCServiceDesk__Account_Name__c);
	}
	*/
}