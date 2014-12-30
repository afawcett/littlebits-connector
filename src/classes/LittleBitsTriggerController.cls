/**
 * Copyright (c), Andrew Fawcett, inc
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
 * - Neither the name of the Andrew Fawcett, inc nor the names of its contributors 
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

/**
 * Handles the Manage Trigger Custom Button
 **/
public with sharing class LittleBitsTriggerController 
{
	public String ZipData { get; set; }	
	
	public MetadataService.AsyncResult AsyncResult {get; private set;}
	
	public LittleBitsTrigger__c LittleBitsTrigger  { get; set; }

	public String SObjectName { get; set; }

	public String TriggerName { get; set; }
	
	public String TriggerTestName { get; set; }
	
	public Boolean Deployed { get; set; }
	
	public ApexTrigger TriggerX { get; private set; }
	
	public ApexClass TriggerTest { get; private set; }
	
	public Integer deployCount;
	
	public Boolean MetadataConnectionError {get;set;}	
	
	public LittleBitsTriggerController(ApexPages.StandardController standardController)
	{
		// Query Lookup Rollup Summary record
		ILittleBitsTriggerSelector selector = 
			(ILittleBitsTriggerSelector) Application.Selector.newInstance(LittleBitsTrigger__c.SObjectType);
		LittleBitsTrigger = selector.selectById(new Set<Id> { standardController.getId() })[0];
		SObjectName	= 
			fflib_SObjectDescribe.getDescribe(((Id)LittleBitsTrigger.RecordID__c).
					getSObjectType()).getDescribe().getName();
		
		// Generate names for test and triggers to deploy / undeploy
		TriggerName = LittleBitsTriggers.makeTriggerName(LittleBitsTrigger);
		TriggerTestName = LittleBitsTriggers.makeTriggerTestName(LittleBitsTrigger);
				
		// Initialise view state
		init();
	}
	
	public String getPackageXml()
	{
		if(Deployed)
			// package.xml for undeploy
			return 
			    '<?xml version="1.0" encoding="UTF-8"?>' + 
				'<Package xmlns="http://soap.sforce.com/2006/04/metadata">' + 
	    			'<version>32.0</version>' + 
				'</Package>';		
		else
			// package.xml for deploy
			return 
			    '<?xml version="1.0" encoding="UTF-8"?>' + 
				'<Package xmlns="http://soap.sforce.com/2006/04/metadata">' + 
	    			'<types>' + 
	        			'<members>'+TriggerName+'</members>' +
	        			'<name>ApexTrigger</name>' + 
	    			'</types>' + 
	    			'<types>' + 
	        			'<members>'+TriggerTestName+'</members>' +
	        			'<name>ApexClass</name>' + 
	    			'</types>' + 
	    			'<version>32.0</version>' + 
				'</Package>';		
	}
	
	public String getDestructiveChangesXml()
	{
		return 
		    '<?xml version="1.0" encoding="UTF-8"?>' + 
			'<Package xmlns="http://soap.sforce.com/2006/04/metadata">' + 
    			'<types>' + 
        			'<members>'+TriggerName+'</members>' +
        			'<name>ApexTrigger</name>' + 
    			'</types>' + 
    			'<types>' + 
        			'<members>'+TriggerTestName+'</members>' +
        			'<name>ApexClass</name>' + 
    			'</types>' + 
    			'<version>32.0</version>' + 
			'</Package>';				
	}
	
	public String getTriggerTestCodeMetadata()
	{
		return 
		    '<?xml version="1.0" encoding="UTF-8"?>' +
			'<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">' +
			    '<apiVersion>32.0</apiVersion>' + 
			    '<status>Active</status>' +
			'</ApexClass>';		
	}
		
	public String getTriggerTestCode()	
	{
		if(Deployed && TriggerTest!=null)
			// Display currently deployed code for confirmation
			return TriggerTest.Body; 
		else
			// Deploy generated code
			return
			 	'/**\n' +
				' * Auto Generated and Deployed by the LittleBits Connector package (lbc)\n' +
				' **/\n' +	
				'@IsTest\n' +	 
			    'private class ' + TriggerTestName + '\n' +  
				'{\n' + 
				'    private static testmethod void testTrigger()\n' +
				'    {\n' + 
				'        // Code to cover the one line trigger, the method called has been tested separately by the packaged tests.\n' +
				'        try { insert new ' + SObjectName + '(); } catch(Exception e) { }\n' +
				'    }\n' +
				'}';
	}
	
	public String getTriggerCodeMetadata()
	{
		return 
		    '<?xml version="1.0" encoding="UTF-8"?>' +
			'<ApexTrigger xmlns="http://soap.sforce.com/2006/04/metadata">' +
			    '<apiVersion>32.0</apiVersion>' + 
			    '<status>Active</status>' +
			'</ApexTrigger>';		
	}
	
	public String getTriggerCode()
	{
		if(Deployed && TriggerX!=null)
		{
			// Display currently deployed code for confirmation
			return TriggerX.Body;
		} 
		else
		{
			// Namespace?
			Schema.DescribeSObjectResult describe = LittleBitsTrigger__c.sObjectType.getDescribe();
			String name = describe.getName();
			String localName = describe.getLocalName();
			String namespace = name.removeEnd(localName).removeEnd('__');					
			// Deploy generated code		
			return 
				'/**\n' +
				' * Auto Generated and Deployed by the LittleBits Connector package (lbc)\n' +
				' **/\n' +
				'trigger ' + TriggerName + ' on ' + SObjectName + '\n' + 
				'    (before delete, before insert, before update, after delete, after insert, after undelete, after update)\n'+ 
				'{\n'+
				'    '+ (namespace.length() > 0 ? namespace + '.' : '') + 'LittleBitsService.triggerHandler();\n'+
				'}\n';
		}		
	}
	
	public PageReference deployZip()
	{
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, Deployed ? 'Removing...' : 'Deploying...'));

		// Deploy zip file posted back from the page action function				
		MetadataService.MetadataPort service = createService();
		MetadataService.DeployOptions deployOptions = new MetadataService.DeployOptions();
        deployOptions.allowMissingFiles = false;
        deployOptions.autoUpdatePackage = false;
        deployOptions.checkOnly = false;
        deployOptions.ignoreWarnings = false;
        deployOptions.performRetrieve = false;
        deployOptions.purgeOnDelete = false;
        deployOptions.rollbackOnError = true;
        deployOptions.runAllTests = false;
        deployOptions.runTests = null;
        deployOptions.singlePackage = true;		
		AsyncResult = service.deploy(ZipData, DeployOptions);		
		return null;
	}	
	
	public PageReference checkAsyncRequest()
	{	
		// Check the status of the retrieve request
		MetadataService.MetadataPort service = createService();
		MetadataService.DeployResult deployResult = service.checkDeployStatus(AsyncResult.Id, true);
		if(deployResult.done)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, Deployed ? 'Remove complete.' : 'Deployment complete.'));

			// Deployment errors?
			if(deployResult.details!=null && deployResult.details.componentFailures!=null)
				for(MetadataService.DeployMessage deployMessage : deployResult.details.componentFailures)
					if(deployMessage.problem!=null)
						ApexPages.addMessage(
							new ApexPages.Message(ApexPages.Severity.Error, 
								deployMessage.fileName + 
									' (Line: ' + deployMessage.lineNumber + ': Column:' + deployMessage.columnNumber + ') : ' + 
										deployMessage.problem));
			// Test errors?
			MetadataService.RunTestsResult runTestResult = deployResult.details.runTestResult;
			if(runTestResult.numFailures > 0)
				for(MetadataService.RunTestFailure testFailure : runTestResult.failures)
					ApexPages.addMessage(
						new ApexPages.Message(ApexPages.Severity.Error, 
							testFailure.name + '.' + testFailure.methodName + ' ' + testFailure.message + ' ' + testFailure.stackTrace));
			// Code coverage warnings?
			if(runTestResult.codeCoverageWarnings!=null)
				for(MetadataService.CodeCoverageWarning codeCoverageWarning : runTestResult.codeCoverageWarnings)
					ApexPages.addMessage(
						new ApexPages.Message(ApexPages.Severity.Warning, 
							(codeCoverageWarning.namespace!=null ? codeCoverageWarning.namespace+'.' : '') +
							codeCoverageWarning.name + ':' +
							codeCoverageWarning.message));
			
			AsyncResult = null;
			
			// Initialise view state to try again
			init();
		}
		else
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, (Deployed ? 'Removing...' : 'Deploying...') + '.'.repeat(deployCount++)));
		}	
		return null;
	}
	
	private void init()
	{
		// Metadata API connection?
		MetadataConnectionError = !LittleBitsService.checkMetadataAPIConnection();
		if(MetadataConnectionError)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Salesforce Metadata API connection failure, click the link below to configure.'));
			return;			
		}
		
		// Already deployed?
		Map<String, ApexTrigger> apexTriggers = new ApexTriggersSelector().selectByName(new Set<String> { TriggerName });
		Map<String, ApexClass> apexClasses = new ApexClassesSelector().selectByName(new Set<String> { TriggerTestName });
		Deployed = apexTriggers.size()==1 && apexClasses.size()==1;
		TriggerX = Deployed ? apexTriggers.values()[0] : null;
		TriggerTest = Deployed ? apexClasses.values()[0] : null;
		deployCount = 0;
		
		// Message to confirm current status
		if(Deployed)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Apex Trigger <b>' + TriggerName + '</b> is installed.'));  		
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Apex Class <b>' + TriggerTestName + '</b> is installed.'));  		
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Click <b>Remove</b> to uninstall the Apex Trigger and Apex Class for this object.'));  					
		}
		else
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Click <b>Deploy</b> to install the Apex Trigger and Apex Class for this object.'));  					
		}
	}
	
	private static MetadataService.MetadataPort createService()
	{ 
		MetadataService.MetadataPort service = new MetadataService.MetadataPort();
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = UserInfo.getSessionId();
		return service;		
	}		
}