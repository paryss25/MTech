@isTest (SeeAllData=false)
private class TestMTechSingleDevice {
    public static BMCServiceDesk__CMDB_Class__c oCls;
    public static BMCServiceDesk__CMDB_Class__c oDeviceAsset;
    public static String userId;
    public static string DeviceId;
    
    public static void CreateTestData(){
        //Test.startTest();
        //String userName = UserInfo.getUserName();
        //User activeUser = [Select Id, Name, Email From User where Username=: userName limit 1];
        //String userNm = activeUser.Name;
        //String userEmail = activeUser.Email;
        userId = UserInfo.getUserId();
        DeviceId='';
        
        //BMCServiceDesk__CMDB_Class__c oCls;
        //oCls = [Select Id from BMCServiceDesk__CMDB_Class__c where BMCServiceDesk__ClassName__c = 'BMC_BusinessService'];
        oCls = new BMCServiceDesk__CMDB_Class__c(BMCServiceDesk__ClassName__c = 'BMC_BusinessService', BMCServiceDesk__CMDBClassType__c='CI',BMCServiceDesk__SuperClass__c='BMC_BaseElement', BMCServiceDesk__Namespace__c='BMC');
        insert oCls;
        system.assert(oCls != null);
        
        //BMCServiceDesk__CMDB_Class__c oDeviceAsset;
        oDeviceAsset = new BMCServiceDesk__CMDB_Class__c(BMCServiceDesk__ClassName__c = 'Device', BMCServiceDesk__CMDBClassType__c='Asset',BMCServiceDesk__SuperClass__c='BMC_BaseElement', BMCServiceDesk__Namespace__c='BMC');
        insert oDeviceAsset;
        system.assert(oDeviceAsset != null);
    }
    
    static testMethod void testSingleDevice(){

        CreateTestData();
        system.assert(oDeviceAsset != null);

        /*Create Queue
        //Select Id,QueueId,Queue.Name,SobjectType From QueueSobject Where SobjectType='BMCServiceDesk__Task__c'
        Group qo = new Group(Type='Queue', Name='Warehouse1');
		insert qo;

        QueueSobject qoInc = new QueueSobject(QueueId=qo.Id,SobjectType='BMCServiceDesk__Incident__c');
        insert qoInc;
        
        QueueSobject qoTask = new QueueSobject(QueueId=qo.Id,SobjectType='BMCServiceDesk__Task__c');
        insert qoTask;
        */
            
        //Create Service
        BMCServiceDesk__BMC_BaseElement__c oService = new BMCServiceDesk__BMC_BaseElement__c(
            BMCServiceDesk__CMDB_Class__c = oCls.Id,
            BMCServiceDesk__InstanceID__c = 'Inst-Test Device Repair Service',
            BMCServiceDesk__Name__c = 'Name-Test Device Repair Service',
            BMCServiceDesk__ServiceType__c = 'BusinessService'
        );
        insert oService;
        
        //Create Service Offering
        BMCServiceDesk__BMC_BaseElement__c oOffering = new BMCServiceDesk__BMC_BaseElement__c(
            BMCServiceDesk__CMDB_Class__c = oCls.Id,
            BMCServiceDesk__FKBusinessService__c = oService.Id,
            BMCServiceDesk__InstanceID__c = 'Inst-Test Repair Service',
            BMCServiceDesk__Name__c = 'Name-TestRepair Service',
            BMCServiceDesk__ServiceType__c = 'Offering'
        );
        insert oOffering;
        
        //Create Category
        BMCServiceDesk__Category__c oCat = new BMCServiceDesk__Category__c(Name = 'Test Category_iPhone6', BMCServiceDesk__AvailableForIncidents__c=true, BMCServiceDesk__AvailableForServiceCatalog__c=true);
        insert oCat;
        
        //Create Request detail Template
        BMCServiceDesk__SYSTemplate__c oSRTemplate = new BMCServiceDesk__SYSTemplate__c(Name='test SR Template',BMCServiceDesk__templateFor__c='Request Detail');
        insert oSRTemplate;

        //Create Incident Template        
        BMCServiceDesk__SYSTemplate__c oIncTemplate = new BMCServiceDesk__SYSTemplate__c(Name='Test Inc Template',BMCServiceDesk__templateFor__c='Incident');
        insert oIncTemplate;
        
        //Create Request Definition
        string SRName = 'Single Device Repair Request';
        BMCServiceDesk__SRM_RequestDefinition__c reqDef = new BMCServiceDesk__SRM_RequestDefinition__c(BMCServiceDesk__FKCategory__c=oCat.Id,BMCServiceDesk__FKBusinessService__c=oService.Id,BMCServiceDesk__FKServiceOffering__c=oOffering.Id,Name=SRName,BMCServiceDesk__serviceRequestTitle__c=SRName);
        insert reqDef;
        //BMCServiceDesk__SRM_RequestDefinition__c reqDef = Database.query('Select Id,BMCServiceDesk__FKCategory__c,BMCServiceDesk__FKBusinessService__c,BMCServiceDesk__FKServiceOffering__c from BMCServiceDesk__SRM_RequestDefinition__c where Name =: SRName');
        
        system.assert(reqDef.Id != null);
        //Create Request Detail
        BMCServiceDesk__SRM_RequestDetail__c oRD = new BMCServiceDesk__SRM_RequestDetail__c(
            BMCServiceDesk__FKClient__c = userId,
            //BMCServiceDesk__FKIncident__c = '',
            BMCServiceDesk__FKRequestDefinition__c = reqDef.Id,
            BMCServiceDesk__ServiceRequest__c = 'Test Service Request for iPhone 6',
            BMCServiceDesk__ApprovalRequired__c = false
        );
        insert oRD;
        Test.startTest();
        //Create Incident
        BMCServiceDesk__Incident__c oInc = new BMCServiceDesk__Incident__c(
            BMCServiceDesk__FKCategory__c = reqDef.BMCServiceDesk__FKCategory__c,
            BMCServiceDesk__FKClient__c = userId,
            BMCServiceDesk__FKBusinessService__c = reqDef.BMCServiceDesk__FKBusinessService__c,
            BMCServiceDesk__FKRequestDefinition__c = reqDef.Id,
            BMCServiceDesk__FKRequestDetail__c = oRD.Id,
            BMCServiceDesk__FKServiceOffering__c = reqDef.BMCServiceDesk__FKServiceOffering__c,
            BMCServiceDesk__Service_Request_Title__c = 'Single Device Repair Request',
            BMCServiceDesk__TemplateAlreadyApplied__c = false,
            BMCServiceDesk__TemplateName__c = '',
            BMCServiceDesk__IncidentType__c = 'Service Request',
            SR_Serial__c='Test00011b',
            SR_Model__c='iPhone',
            SR_Color__c='Gold',
            SR_Device_Type__c='iPhone',
            OwnerId = userId,
            BMCServiceDesk__contactType__c = 'Self Service'
        );
        insert oInc;

        System.assertEquals(oInc.BMCServiceDesk__Service_Request_Title__c,'Single Device Repair Request');
        Test.stopTest();
        //Update Request Detail
        BMCServiceDesk__SRM_RequestDetail__c updateoRD = [Select BMCServiceDesk__FKIncident__c from BMCServiceDesk__SRM_RequestDetail__c where id =: oRD.id];
        updateoRD.BMCServiceDesk__FKIncident__c = oInc.id;
        update updateoRD;

        List<BMCServiceDesk__BMC_BaseElement__c> LinkedDevice = new List<BMCServiceDesk__BMC_BaseElement__c>([Select Id, BMCServiceDesk__Name__c from BMCServiceDesk__BMC_BaseElement__c where BMCServiceDesk__Name__c =: oInc.SR_Serial__c]);
        //System.assertEquals(LinkedDevice.size(),1);
        //Test.startTest();
        
        //Create Device
        BMCServiceDesk__BMC_BaseElement__c TestDevice = new BMCServiceDesk__BMC_BaseElement__c();
        if(LinkedDevice.size()== 0){
            TestDevice.BMCServiceDesk__Name__c = oInc.SR_Serial__c; //Instance Name
            TestDevice.BMCServiceDesk__SerialNumber__c = oInc.SR_Serial__c; //Serial #
            TestDevice.BMCServiceDesk__CMDB_Class__c = oDeviceAsset.id;    // Class
            TestDevice.BMCServiceDesk__Model__c = oInc.SR_Model__c;  //Device Description
            TestDevice.Color__c = oInc.SR_Color__c; //Color
            TestDevice.Device_Type__c = oInc.SR_Device_Type__c; //Device Type
            
            insert TestDevice;
        }
        
        if(LinkedDevice.isEmpty()){
            DeviceId = TestDevice.id;
            System.Debug('****New Device found. DeviceId - ' + DeviceId);
        }
        else{
            DeviceId = LinkedDevice[0].id;
            System.Debug('****Existing Device found. DeviceId - ' + DeviceId);
        }

        //Create Task
        BMCServiceDesk__Task__c newTask = new BMCServiceDesk__Task__c();
        newTask.BMCServiceDesk__FKIncident__c = oInc.id;
        newTask.Configuration_Item__c = DeviceId;
        newtask.BMCServiceDesk__taskDescription__c = 'Test Task Desc';
        newtask.OwnerId = UserInfo.getUserId();
        
        insert newtask;
        
        //Test.stopTest();
    }    
}