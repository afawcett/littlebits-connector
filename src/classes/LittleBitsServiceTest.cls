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

	@IsTest(SeeAllData=true)
	// Why SeeAllData? https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_test_reports.htm
	private static void callRunReportTriggersEnsureACalloutOccurs() {

		// Create Mocks
		MockLittleBitsOutputCloudAPI mocksLittleBitsCloudAPI = new MockLittleBitsOutputCloudAPI();
		Test.setMock(HttpCalloutMock.class, mocksLittleBitsCloudAPI);

		// Given
		LittleBitsReportTrigger__c reportTrigger = new LittleBitsReportTrigger__c();
		reportTrigger.Name = 'Test';
		reportTrigger.ReportDeveloperName__c = 'ClosedWonOpportunities';
		reportTrigger.Active__c = true;
		reportTrigger.DeviceID__c = 'deviceId';
		reportTrigger.AccessToken__c = 'accessToken';
		reportTrigger.GroupingIndex__c = 0;
		reportTrigger.AggregateIndexForPercent__c = 1;
		reportTrigger.AggregateIndexForDuration__c = null;
		reportTrigger.UniqueName__c = 'Test';		
		insert reportTrigger;
		Opportunity opp = new Opportunity();
		opp.Name = 'Test';
		opp.StageName = 'Open';
		opp.CloseDate = System.today();
		opp.Amount = 10000;
		insert opp;

		// When
		Test.startTest();
		LittleBitsService.runReportTriggers(new Set<Id> { reportTrigger.Id });
		Test.stopTest();

		// Then
		System.assertEquals(true, mocksLittleBitsCloudAPI.calloutMade);
	}

	@IsTest(SeeAllData=true)
	// Why SeeAllData? https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_test_reports.htm
	private static void callRunReportTriggersEnsureACalloutOccursByUniqueName() {

		// Create Mocks
		MockLittleBitsOutputCloudAPI mocksLittleBitsCloudAPI = new MockLittleBitsOutputCloudAPI();
		Test.setMock(HttpCalloutMock.class, mocksLittleBitsCloudAPI);

		// Given
		LittleBitsReportTrigger__c reportTrigger = new LittleBitsReportTrigger__c();
		reportTrigger.Name = 'Test';
		reportTrigger.ReportDeveloperName__c = 'ClosedWonOpportunities';
		reportTrigger.Active__c = true;
		reportTrigger.DeviceID__c = 'deviceId';
		reportTrigger.AccessToken__c = 'accessToken';
		reportTrigger.GroupingIndex__c = 0;
		reportTrigger.AggregateIndexForPercent__c = 1;
		reportTrigger.AggregateIndexForDuration__c = null;
		reportTrigger.UniqueName__c = 'Test';
		insert reportTrigger;
		Opportunity opp = new Opportunity();
		opp.Name = 'Test';
		opp.StageName = 'Open';
		opp.CloseDate = System.today();
		opp.Amount = 10000;
		insert opp;

		// When
		Test.startTest();
		LittleBitsService.runReportTriggers(new Set<String> { reportTrigger.UniqueName__c });
		Test.stopTest();

		// Then
		System.assertEquals(true, mocksLittleBitsCloudAPI.calloutMade);
	}

	@IsTest(SeeAllData=true)
	// Why SeeAllData? https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_test_reports.htm
	private static void callRunReportTriggersEnsureAExceptionOccurs() {

		// Given
		LittleBitsReportTrigger__c reportTrigger = new LittleBitsReportTrigger__c();
		reportTrigger.Name = 'Test';
		reportTrigger.ReportDeveloperName__c = 'Bad';
		reportTrigger.Active__c = true;
		reportTrigger.DeviceID__c = 'deviceId';
		reportTrigger.AccessToken__c = 'accessToken';
		reportTrigger.GroupingIndex__c = 0;
		reportTrigger.AggregateIndexForPercent__c = 1;
		reportTrigger.AggregateIndexForDuration__c = null;
		reportTrigger.UniqueName__c = 'Test';		
		insert reportTrigger;

		// When ... Then
		try {
			LittleBitsService.runReportTriggers(new Set<Id> { reportTrigger.Id });
			System.assert(false, 'Expected exception');
		} catch (Exception e) {
			System.assertEquals('Report Bad was not found.', e.getMessage());
		}
	}

	@IsTest
	private static void testProcessEvents() {

		// Given
		String testEvent = '{"type":"amplitude","timestamp":1438506243653,"user_id":43303,"bit_id":"00e04c035309","payload":{"percent":100,"delta":"ignite"}}';
		LittleBitsService.FlowFactoryClass = 'LittleBitsServiceTest.TestFlowFactory';
		LittleBitsDeviceSubscription__c deviceSub = new LittleBitsDeviceSubscription__c();
		deviceSub.DeviceID__c = '00e04c035309';
		deviceSub.FlowName__c = 'TestFlow';
		deviceSub.Active__c = true;
		insert deviceSub;

		// When
		LittleBitsService.processSubscriptionEvent((Map<String, Object>) JSON.deserializeUntyped(testEvent));
	}

	@IsTest
	private static void testSubscribe() {

		// Given
		Schema.DescribeSObjectResult describe = LittleBitsAPI__c.sObjectType.getDescribe();
		String name = describe.getName();
		String localName = describe.getLocalName();
		String namespace = name.removeEnd(localName).removeEnd('__');				
		String expectedAccessToken = 'testaccesstoken';
		String expectedBody = 'publisher_id=00e04c035309&subscriber_id=https://littlebitsconnectdev-developer-edition.eu5.force.com/services/apexrest' + (namespace.length()>0 ? '/'+namespace : '') + '/subscriber&publisher_events=amplitude:delta:ignite';
		Integer mockResponseStatusCode = 201;
		String mockResponseBody = '';
		Test.setMock(HttpCalloutMock.class, 
			new MockLittleBitsSubscriptionCloudAPI(
				expectedAccessToken, 
				expectedBody, 
				mockResponseStatusCode,
				mockResponseBody));
		LittleBitsAPI__c config = new LittleBitsAPI__c();
		config.SubscriptionSiteURL__c = 'https://littlebitsconnectdev-developer-edition.eu5.force.com';
		insert config;
		LittleBitsDeviceSubscription__c deviceSub = new LittleBitsDeviceSubscription__c();
		deviceSub.DeviceID__c = '00e04c035309';
		deviceSub.AccessToken__c = 'testaccesstoken';		
		deviceSub.FlowName__c = 'TestFlow';
		deviceSub.Event__c = 'amplitude:delta:ignite';
		deviceSub.Active__c = true;
		insert deviceSub;

		// When
		Test.startTest();				
		LittleBitsService.updateDeviceSubscriptions(new Set<Id> { deviceSub.Id });
		Test.stopTest();
	}

	@IsTest
	private static void testUnsubscribe() {

		// Given
		Schema.DescribeSObjectResult describe = LittleBitsAPI__c.sObjectType.getDescribe();
		String name = describe.getName();
		String localName = describe.getLocalName();
		String namespace = name.removeEnd(localName).removeEnd('__');		
		String expectedAccessToken = 'testaccesstoken';
		String expectedBody = 'publisher_id=00e04c035309&subscriber_id=https://littlebitsconnectdev-developer-edition.eu5.force.com/services/apexrest' + (namespace.length()>0 ? '/'+namespace : '') + '/subscriber';
		Integer mockResponseStatusCode = 200;
		String mockResponseBody = '';
		Test.setMock(HttpCalloutMock.class, 
			new MockLittleBitsSubscriptionCloudAPI(
				expectedAccessToken, 
				expectedBody, 
				mockResponseStatusCode,
				mockResponseBody));
		LittleBitsAPI__c config = new LittleBitsAPI__c();
		config.SubscriptionSiteURL__c = 'https://littlebitsconnectdev-developer-edition.eu5.force.com';
		insert config;
		LittleBitsDeviceSubscription__c deviceSub = new LittleBitsDeviceSubscription__c();
		deviceSub.DeviceID__c = '00e04c035309';
		deviceSub.AccessToken__c = 'testaccesstoken';
		deviceSub.FlowName__c = 'TestFlow';
		deviceSub.Event__c = 'amplitude:delta:ignite';
		deviceSub.Active__c = true;
		insert deviceSub;

		// When
		Test.startTest();		
		LittleBitsService.deleteDeviceSubscriptions(new Set<Id> { deviceSub.Id });
		Test.stopTest();		
	}

	public class TestFlowFactory implements ILittleBitsFlowFactory {
		public Flow.Interview newInstance(String flowName, Map<String, Object> params) {
			System.assertEquals('TestFlow', flowName);
			System.assertEquals('amplitude', params.get('lbc_type'));
			System.assertEquals('1438506243653', params.get('lbc_timestamp') + '');
			System.assertEquals('43303', params.get('lbc_user_id') + '');
			System.assertEquals('00e04c035309', params.get('lbc_bit_id'));
			System.assertEquals('100', params.get('lbc_payload_percent') + '');
			System.assertEquals('ignite', params.get('lbc_payload_delta'));
			return null;
		}
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

	/**
	 * Mocks the LittleBits Cloud API for /devices/subscriptions HTTP POST, GET and DELETE
	 **/
	private class MockLittleBitsSubscriptionCloudAPI implements HttpCalloutMock {

		private String expectedAccessToken;
		private String expectedBody;
		private Integer mockResponseStatusCode;
		private String mockResponseBody;

		public MockLittleBitsSubscriptionCloudAPI(
			String expectedAccessToken,
			String expectedBody,
			Integer mockResponseStatusCode,
			String mockResponseBody) {
			this.expectedAccessToken = expectedAccessToken;
			this.expectedBody = expectedBody;
			this.mockResponseStatusCode = mockResponseStatusCode;
			this.mockResponseBody = mockResponseBody;
		}

		public HTTPResponse respond(HTTPRequest req) {

			// Assert header
			System.assertEquals(req.getHeader('Authorization'), 'Bearer ' + expectedAccessToken);

			// Assert body
			System.assertEquals(expectedBody, req.getBody());
			
			// Mock response
			HttpResponse res = new HttpResponse();
			res.setStatusCode(mockResponseStatusCode);
			if(mockResponseBody!=null)
				res.setBody(mockResponseBody);
			return res;
		}
	}	
}