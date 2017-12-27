@isTest(seeAllData=false)
public class Test_RFTriggerHelper {
    public static BMCServiceDesk__CMDB_Class__c oDeviceAsset;
    
    static testmethod void UnitTest1(){

    //Create Contract
    	MTech_Contract__c oContract = new MTech_Contract__c();
    	
        oContract.Name = '17000000';
    	oContract.IsActive__c = true;
        oContract.Contract_Start_Date__c = Date.newInstance(2017,01,01); //2017-01-01;
        oContract.Contract_End_Date__c = Date.newInstance(2017,12,31); //2017-12-31;
        
        insert oContract;
        
        system.assert(oContract != null);
            
    	//Create Device class in CMDB
        oDeviceAsset = new BMCServiceDesk__CMDB_Class__c(BMCServiceDesk__ClassName__c = 'Device', BMCServiceDesk__CMDBClassType__c='Asset',BMCServiceDesk__SuperClass__c='BMC_BaseElement', BMCServiceDesk__Namespace__c='BMC');
        insert oDeviceAsset;
        
        system.assert(oDeviceAsset != null);
        
        //Create Device in CMDB and link it to MTech Contract
        BMCServiceDesk__BMC_BaseElement__c TestDevice = new BMCServiceDesk__BMC_BaseElement__c();
        
        TestDevice.BMCServiceDesk__Name__c = 'TestSR1234'; //Instance Name
        TestDevice.BMCServiceDesk__SerialNumber__c = 'TestSR1234'; //Serial #
        TestDevice.BMCServiceDesk__CMDB_Class__c = oDeviceAsset.id;    // Class
        TestDevice.BMCServiceDesk__Model__c = 'iPhone 7inch display';  //Device Description
        TestDevice.Color__c = 'Silver'; //Color
        TestDevice.Device_Type__c = 'iPhone'; //Device Type
        TestDevice.MTech_Contract_Number__c = oContract.Id; //MTech Contract
        
        insert TestDevice;
    	
        system.assertNotEquals(null,TestDevice);
        
        Test.startTest();
    	//Create Task1
        BMCServiceDesk__Task__c newTask1 = new BMCServiceDesk__Task__c();
        //newTask.BMCServiceDesk__FKIncident__c = oInc.id;
        newTask1.Configuration_Item__c = TestDevice.Id;
        newtask1.BMCServiceDesk__taskDescription__c = 'Test Task Desc';
        newtask1.OwnerId = UserInfo.getUserId();
        
        insert newTask1;
        
        
        //Create Task2
        BMCServiceDesk__Task__c newTask2 = new BMCServiceDesk__Task__c();
        //newTask.BMCServiceDesk__FKIncident__c = oInc.id;
        newTask2.Configuration_Item__c = null;
        newtask2.BMCServiceDesk__taskDescription__c = 'Test Task Desc';
        //newTask2.Previous_MTech_Contract_Id__c = String.valueOf(TestDevice.Id);
        newtask2.OwnerId = UserInfo.getUserId();
        
        insert newTask2;
        
        /*
        //Update Task2
        BMCServiceDesk__Task__c newTask3 = new BMCServiceDesk__Task__c();
        newTask3.Id = newTask2.Id;
        newTask3.Previous_MTech_Contract_Id__c = String.valueOf(TestDevice.Id);
        newTask3.FKMTech_Contract__c = null;
        
        update newTask3;
        */
        Test.stopTest();

    }

}