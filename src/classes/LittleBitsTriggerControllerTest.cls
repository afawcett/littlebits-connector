/**
 * Copyright (c) 2013, Andrew Fawcett
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, 
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, 
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, 
 *      this list of conditions and the following disclaimer in the documentation 
 *      and/or other materials provided with the distribution.
 * - Neither the name of the Andrew Fawcett, nor the names of its contributors 
 *      may be used to endorse or promote products derived from this software without 
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

@IsTest
private with sharing class LittleBitsTriggerControllerTest 
{
	private testmethod static void testDeployedStatus()
	{
		// Test supported?
		if(!TestContext.isSupported())
			return;
		
    	// Metadata API web Service mock implementation for tests
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
		
		// Test data
		LittleBitsTrigger__c lbsTrigger = new LittleBitsTrigger__c();
		lbsTrigger.Name = 'Track my Favourite Opportunity';
		lbsTrigger.RecordID__c = fflib_IDGenerator.generate(Opportunity.SObjectType);
		lbsTrigger.WhenFieldsModified__c = 'Probability';
		lbsTrigger.Active__c = true;
		lbsTrigger.DurationInMilliseconds__c = 10000;
		lbsTrigger.PercentField__c = 'Probability';
		insert lbsTrigger;
								
		// Open test context, permits callouts following DML
		Test.startTest();
					
		// Assert initial state of controller when the trigger for the child object is deployed
		LittleBitsTriggerController controller = new LittleBitsTriggerController(new ApexPages.StandardController( lbsTrigger ));
		System.assertEquals(true, controller.Deployed);
		System.assertEquals('LittleBitsOpportunityTrigger', controller.TriggerName);
		System.assertEquals('LittleBitsOpportunityTriggerTest', controller.TriggerTestName);
		System.assertEquals('LittleBitsOpportunityTrigger', controller.TriggerX.Name);
		System.assertEquals('LittleBitsOpportunityTriggerTest', controller.TriggerTest.Name);
		System.assertEquals(controller.TriggerX.Body, controller.getTriggerCode());
		System.assertEquals(controller.TriggerTest.Body, controller.getTriggerTestCode());
		System.assertEquals(
			    '<?xml version="1.0" encoding="UTF-8"?>' + 
				'<Package xmlns="http://soap.sforce.com/2006/04/metadata">' + 
	    			'<version>32.0</version>' + 
				'</Package>',	
			controller.getPackageXml());
		System.assertEquals(
			    '<?xml version="1.0" encoding="UTF-8"?>' + 
				'<Package xmlns="http://soap.sforce.com/2006/04/metadata">' + 
	    			'<types>' + 
	        			'<members>'+controller.TriggerName+'</members>' +
	        			'<name>ApexTrigger</name>' + 
	    			'</types>' + 
	    			'<types>' + 
	        			'<members>'+controller.TriggerTestName+'</members>' +
	        			'<name>ApexClass</name>' + 
	    			'</types>' + 
	    			'<version>32.0</version>' + 
				'</Package>',				
				controller.getDestructiveChangesXml());
		System.assertEquals(
		    '<?xml version="1.0" encoding="UTF-8"?>' +
			'<ApexTrigger xmlns="http://soap.sforce.com/2006/04/metadata">' +
			    '<apiVersion>32.0</apiVersion>' + 
			    '<status>Active</status>' +
			'</ApexTrigger>',		
			controller.getTriggerCodeMetadata());
		System.assertEquals(
		    '<?xml version="1.0" encoding="UTF-8"?>' +
			'<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">' +
			    '<apiVersion>32.0</apiVersion>' + 
			    '<status>Active</status>' +
			'</ApexClass>',		
			controller.getTriggerTestCodeMetadata());
			
		// Undeploy (no need to emulate the zip contents prepared by the client as mock service does not bother with this)
		controller.deployZip();
		
		Test.stopTest();
	}

	private testmethod static void testNotDeployedStatus()
	{
		// Test supported?
		if(!TestContext.isSupported())
			return;

		// Namespace		
		Schema.DescribeSObjectResult describe = LittleBitsAPI__c.sObjectType.getDescribe();
		String name = describe.getName();
		String localName = describe.getLocalName();
		String namespace = name.removeEnd(localName).removeEnd('__');		

    	// Metadata API web Service mock implementation for tests
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl());

		// Test data		
		LittleBitsTrigger__c lbsTrigger = new LittleBitsTrigger__c();
		lbsTrigger.Name = 'Track my Favourite Opportunity';
		lbsTrigger.RecordID__c = fflib_IDGenerator.generate(Contact.SObjectType);
		lbsTrigger.WhenFieldsModified__c = 'Probability';
		lbsTrigger.Active__c = true;
		lbsTrigger.DurationInMilliseconds__c = 10000;
		lbsTrigger.PercentField__c = 'Probability';
		insert lbsTrigger;
			
		// Open test context, permits callouts following DML
		Test.startTest();
		
		// Assert initial state of controller when the trigger for the child object is deployed
		LittleBitsTriggerController controller = new LittleBitsTriggerController(new ApexPages.StandardController( lbsTrigger ));
		System.assertEquals(false, controller.Deployed);
		System.assertEquals('lbc_ContactTrigger', controller.TriggerName);
		System.assertEquals('lbc_ContactTest', controller.TriggerTestName);
		System.assertEquals(null, controller.TriggerX);
		System.assertEquals(null, controller.TriggerTest);
		System.assertEquals(
				'/**\n' +
				' * Auto Generated and Deployed by the LittleBits Connector package (lbc)\n' +
				' **/\n' +
				'trigger ' + controller.TriggerName + ' on ' + controller.SObjectName + '\n' + 
				'    (before delete, before insert, before update, after delete, after insert, after undelete, after update)\n'+ 
				'{\n'+
				'    ' + (namespace.length()>0 ? namespace + '.' : '') + 'LittleBitsService.triggerHandler();\n'+
				'}\n', controller.getTriggerCode());
		System.assertEquals(
			 	'/**\n' +
				' * Auto Generated and Deployed by the LittleBits Connector package (lbc)\n' +
				' **/\n' +	
				'@IsTest\n' +	 
			    'private class ' + controller.TriggerTestName + '\n' +  
				'{\n' + 
				'    private static testmethod void testTrigger()\n' +
				'    {\n' + 
				'        // Code to cover the one line trigger, the method called has been tested separately by the packaged tests.\n' +
				'        try { insert new ' + controller.SObjectName + '(); } catch(Exception e) { }\n' +
				'    }\n' +
				'}', controller.getTriggerTestCode());
		System.assertEquals(
			    '<?xml version="1.0" encoding="UTF-8"?>' + 
				'<Package xmlns="http://soap.sforce.com/2006/04/metadata">' + 
	    			'<types>' + 
	        			'<members>'+controller.TriggerName+'</members>' +
	        			'<name>ApexTrigger</name>' + 
	    			'</types>' + 
	    			'<types>' + 
	        			'<members>'+controller.TriggerTestName+'</members>' +
	        			'<name>ApexClass</name>' + 
	    			'</types>' + 
	    			'<version>32.0</version>' + 
				'</Package>',
			controller.getPackageXml());
		System.assertEquals(
		    '<?xml version="1.0" encoding="UTF-8"?>' +
			'<ApexTrigger xmlns="http://soap.sforce.com/2006/04/metadata">' +
			    '<apiVersion>32.0</apiVersion>' + 
			    '<status>Active</status>' +
			'</ApexTrigger>',
			controller.getTriggerCodeMetadata());
		System.assertEquals(
		    '<?xml version="1.0" encoding="UTF-8"?>' +
			'<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">' +
			    '<apiVersion>32.0</apiVersion>' + 
			    '<status>Active</status>' +
			'</ApexClass>',		
			controller.getTriggerTestCodeMetadata());
											
		Test.stopTest();
	}
	
    /**
     * Metadata API web service mock class for tests above
     **/
	private class WebServiceMockImpl implements WebServiceMock 
	{
		public void doInvoke(
			Object stub, Object request, Map<String, Object> response,
			String endpoint, String soapAction, String requestName,
			String responseNS, String responseName, String responseType) 
		{
			if(request instanceof MetadataService.deploy_element)
			{				
				MetadataService.deployResponse_element response_x = new MetadataService.deployResponse_element();
				response_x.result = new MetadataService.AsyncResult();
				response_x.result.id = 'someid';
				response_x.result.done = true;				
				response_x.result.state = 'Complete';
				response.put('response_x', response_x);
			}			
			else if(request instanceof MetadataService.checkDeployStatus_element)
			{
				System.assertEquals('someid', ((MetadataService.checkDeployStatus_element) request).asyncProcessId);
				MetadataService.checkDeployStatusResponse_element response_x = new MetadataService.checkDeployStatusResponse_element();
				response_x.result = new MetadataService.DeployResult(); 
				response_x.result.details = new MetadataService.DeployDetails();
				response_x.result.details.runTestResult = new MetadataService.RunTestsResult();
				response_x.result.details.runTestResult.numFailures = 0;
				response_x.result.details.componentFailures = new List<MetadataService.DeployMessage>();
				response.put('response_x', response_x);
			}
			else if(request instanceof MetadataService.listMetadata_element)
			{
				MetadataService.listMetadataResponse_element response_x = new MetadataService.listMetadataResponse_element();
				response_x.result = new List<MetadataService.FileProperties>();
				response.put('response_x', response_x);
			}
			return;
		}
	}    		
}