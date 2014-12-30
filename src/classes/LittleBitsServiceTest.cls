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

@IsTest
private class LittleBitsServiceTest {

	@IsTest
	private static void callServiceMethodResultsInLittleBitsAPICallout()
	{
		// Create mocks
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		Mocks.LittleBitsTriggerSelector mockSelector = new Mocks.LittleBitsTriggerSelector(mocks);
		MockLittleBitsOutputCloudAPI mocksLittleBitsCloudAPI = new MockLittleBitsOutputCloudAPI();

		// Given
		mocks.startStubbing();
		LittleBitsTrigger__c lbsTrigger = new LittleBitsTrigger__c(Id = fflib_IDGenerator.generate(LittleBitsTrigger__c.SObjectType));
		lbsTrigger.Name = 'Track my Favourite Opportunity';
		lbsTrigger.RecordID__c = fflib_IDGenerator.generate(Opportunity.SObjectType);
		lbsTrigger.WhenFieldsModified__c = 'Probability';
		lbsTrigger.Active__c = true;
		lbsTrigger.DurationInMilliseconds__c = 10000;
		lbsTrigger.PercentField__c = 'Probability';		
		lbsTrigger.AccessToken__c = 'accesstoken';
		lbsTrigger.DeviceID__c = 'deviceid';
		List<LittleBitsTrigger__c> lbsTriggers = new List<LittleBitsTrigger__c> { lbsTrigger };
		Set<String> testRecordIds = new Set<String> { ((String)lbsTrigger.RecordID__c).substring(0,15) };
		mocks.when(mockSelector.sObjectType()).thenReturn(LittleBitsTrigger__c.SObjectType);
		mocks.when(mockSelector.selectActiveByRecordId(testRecordIds)).thenReturn(lbsTriggers);		
		mocks.stopStubbing();
		Test.setMock(HttpCalloutMock.class, mocksLittleBitsCloudAPI);
		Application.Selector.setMock(mockSelector);

		// When
		Opportunity oldOpp = new Opportunity(Id = lbsTrigger.RecordID__c);
		oldOpp.Probability = 20;
		Opportunity newOpp = new Opportunity(Id = lbsTrigger.RecordID__c);
		newOpp.Probability = 40;
		Map<Id, SObject> oldMap = new Map<Id, SObject> { oldOpp.Id => oldOpp };
		Map<Id, SObject> newMap = new Map<Id, SObject> { newOpp.Id => newOpp };
		Test.startTest();		
		LittleBitsService.triggerHandler(oldMap, newMap);
		Test.stopTest();

		// Then
		((ILittleBitsTriggerSelector) 
			mocks.verify(mockSelector)).selectActiveByRecordId(testRecordIds);		
		System.assertEquals(true, mocksLittleBitsCloudAPI.calloutMade);
	}

	@IsTest
	private static void callServiceMethodDoesNotResultInLittleBitsAPICallout()
	{
		// Create mocks
		fflib_ApexMocks mocks = new fflib_ApexMocks();
		Mocks.LittleBitsTriggerSelector mockSelector = new Mocks.LittleBitsTriggerSelector(mocks);
		MockLittleBitsOutputCloudAPI mocksLittleBitsCloudAPI = new MockLittleBitsOutputCloudAPI();

		// Given
		mocks.startStubbing();
		LittleBitsTrigger__c lbsTrigger = new LittleBitsTrigger__c(Id = fflib_IDGenerator.generate(LittleBitsTrigger__c.SObjectType));
		lbsTrigger.Name = 'Track my Favourite Opportunity';
		lbsTrigger.RecordID__c = fflib_IDGenerator.generate(Opportunity.SObjectType);
		lbsTrigger.WhenFieldsModified__c = 'Probability';
		lbsTrigger.Active__c = true;
		lbsTrigger.DurationInMilliseconds__c = 10000;
		lbsTrigger.PercentField__c = 'Probability';		
		lbsTrigger.AccessToken__c = 'accesstoken';
		lbsTrigger.DeviceID__c = 'deviceid';
		List<LittleBitsTrigger__c> lbsTriggers = new List<LittleBitsTrigger__c> { lbsTrigger };
		Set<String> testRecordIds = new Set<String> { ((String)lbsTrigger.RecordID__c).substring(0,15) };
		mocks.when(mockSelector.sObjectType()).thenReturn(LittleBitsTrigger__c.SObjectType);
		mocks.when(mockSelector.selectActiveByRecordId(testRecordIds)).thenReturn(lbsTriggers);		
		mocks.stopStubbing();
		Test.setMock(HttpCalloutMock.class, mocksLittleBitsCloudAPI);
		Application.Selector.setMock(mockSelector);

		// When
		Opportunity oldOpp = new Opportunity(Id = lbsTrigger.RecordID__c);
		oldOpp.Probability = 20;
		Opportunity newOpp = new Opportunity(Id = lbsTrigger.RecordID__c);
		newOpp.Probability = 20;
		Map<Id, SObject> oldMap = new Map<Id, SObject> { oldOpp.Id => oldOpp };
		Map<Id, SObject> newMap = new Map<Id, SObject> { newOpp.Id => newOpp };
		Test.startTest();		
		LittleBitsService.triggerHandler(oldMap, newMap);
		Test.stopTest();

		// Then
		((ILittleBitsTriggerSelector) 
			mocks.verify(mockSelector)).selectActiveByRecordId(testRecordIds);		
		System.assertEquals(false, mocksLittleBitsCloudAPI.calloutMade);
	}

	private class MockLittleBitsOutputCloudAPI implements HttpCalloutMock {
		public Boolean calloutMade = false;
		public HTTPResponse respond(HTTPRequest req) {
			calloutMade = true;
			HttpResponse res = new HttpResponse();
			res.setStatusCode(200);			
			return res;
		}		
	}
}