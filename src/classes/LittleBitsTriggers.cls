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
 * Encapsulates all behaviour logic relating to the LittleBitsTrigger__c object
 * 
 * For more guidelines and details see 
 *   https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Domain_Layer
 *
 **/
public class LittleBitsTriggers extends fflib_SObjectDomain
{
	private static final Integer APEXTRIGGER_NAME_LENGTH = 40; // ApexTrigger.Name.getDescribe().getLength(); gives 255?
	
	private static final Integer APEXCLASS_NAME_LENGTH = 40; // ApexClass.Name.getDescribe().getLength(); gives 255?

	public LittleBitsTriggers(List<LittleBitsTrigger__c> records) 
	{
		super(records);	
	}

	public override void onValidate()
	{
		for(LittleBitsTrigger__c record : (List<LittleBitsTrigger__c>) Records)
		{
		}
	}

	public override void onValidate(Map<Id,SObject> existingRecords)
	{
		for(LittleBitsTrigger__c record : (List<LittleBitsTrigger__c>) Records)
		{
		}
	}

	/**
	 * Trigger name for given lookup rollup summary
	 **/
	public static String makeTriggerName(LittleBitsTrigger__c lbsTrigger)
	{
		String sObjectName = 
			fflib_SObjectDescribe.getDescribe(((Id)lbsTrigger.RecordID__c).
					getSObjectType()).getDescribe().getName();
		if(Test.isRunningTest() && sObjectName == 'Opportunity')
			return 'LittleBitsOpportunityTrigger';
		return calculateComponentName(sObjectName, 'Trigger', APEXTRIGGER_NAME_LENGTH);
	}
	
	/**
	 * Apex test name for given lookup rollup summary
	 **/
	public static String makeTriggerTestName(LittleBitsTrigger__c lbsTrigger)
	{
		String sObjectName = 
			fflib_SObjectDescribe.getDescribe(((Id)lbsTrigger.RecordID__c).
					getSObjectType()).getDescribe().getName();
		if(Test.isRunningTest() && sObjectName == 'Opportunity')
			return 'LittleBitsOpportunityTriggerTest';		
		return calculateComponentName(sObjectName, 'Test', APEXCLASS_NAME_LENGTH);
	}
	
	/**
	 * Ensures the component name never exceeds the given maximum length but yet still remains unique
	 **/
	private static String calculateComponentName(String childObjectName, String suffix, Integer maxComponentNameLength)
	{
		String trimmedObjectName = childObjectName.replace('__c', '').replace('__', '_');
		String componentName = 'lbc_' + trimmedObjectName + suffix;
		Integer componentNameLength = componentName.length();
		if(componentNameLength > maxComponentNameLength) // Do we need to trim the trigger name?
		{
			Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
			SObjectType childObjectType = gd.get(childObjectName);		
			String childObjectPrefix = childObjectType.getDescribe().getKeyPrefix(); // Key prefix will be used to make the trimmed name unique again
			Integer overflowChars = componentNameLength - maxComponentNameLength; // How much do we need to trim the name by?
			trimmedObjectName = trimmedObjectName.substring(0, trimmedObjectName.length() - overflowChars); // Trim the overflow characters from the name
			trimmedObjectName = trimmedObjectName.substring(0, trimmedObjectName.length() - childObjectPrefix.length()); // Trim space for the prefix on the end
			trimmedObjectName+= childObjectPrefix; // Add on the end the unique object prefix (to ensure the trimmed name is still unique)
			componentName = 'lbc_' + trimmedObjectName + suffix; 
		}
		return componentName;
	}

	public class Constructor implements fflib_SObjectDomain.IConstructable
	{
		public fflib_SObjectDomain construct(List<SObject> sObjectList)
		{
			return new LittleBitsTriggers(sObjectList);
		}
	}	
}