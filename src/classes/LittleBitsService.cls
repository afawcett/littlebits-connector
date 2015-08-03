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

global class LittleBitsService {

	/**
	 * Information describing device and data to send
	 **/
	global class DeviceOutput {
		global String AccessToken {get;set;}
        global String DeviceId {get;set;}
        global Integer Percent {get;set;}
        global Integer DurationMs {get;set;}
	}

	/** 
	 * Response from the runReportTriggers method
	 **/
	global class ReportTriggersResult {
		global Integer Percent {get; private set;}
		global Integer DurationMs {get; private set;}		
	}

	/**
	 * Check this service can connect to the Metadata API when needed
	 **/
	global static Boolean checkMetadataAPIConnection()
	{
		try {
			MetadataService.MetadataPort service = new MetadataService.MetadataPort();
			service.SessionHeader = new MetadataService.SessionHeader_element();
			service.SessionHeader.sessionId = UserInfo.getSessionId();
			List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();		
			MetadataService.ListMetadataQuery remoteSites = new MetadataService.ListMetadataQuery();
			remoteSites.type_x = 'RemoteSiteSetting';
			queries.add(remoteSites);					
			service.listMetadata(queries, 28);			
		} catch (Exception e) {
			return false;
		}
		return true;
	}

	/**
	 * Send parcent for the given duration to the given device
	 **/
	global static void send(List<DeviceOutput> deviceOutputs) {
		// NOTE: LittleBits Cloud API is not bulkified, maybe one day it will be!
		for(DeviceOutput deviceOutput : deviceOutputs) {
			getDevice(deviceOutput.AccessToken, deviceOutput.DeviceId).
				output(deviceOutput.Percent, deviceOutput.DurationMs);			
		}
	}

	/**
	 * Determine if the given records should result in a LittleBit trigger executing (requires LittleBitsTrigger__c setup)
	 **/
	global static void triggerHandler(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {

		// Any of these records relate to a little bit trigger?
		Set<Id> updatedRecordIds = newMap.keySet();
		Set<String> updatedRecordIdsTruncated = new Set<String>();
		for(Id updatedRecord : updatedRecordIds)
			updatedRecordIdsTruncated.add(((String)updatedRecord).substring(0,15));
		ILittleBitsTriggerSelector lbtSelector = 
			(ILittleBitsTriggerSelector) 
				Application.Selector.newInstance(LittleBitsTrigger__c.SObjectType);
		List<LittleBitsTrigger__c> lbTriggers = lbtSelector.selectActiveByRecordId(updatedRecordIdsTruncated);
		if(lbTriggers.size()>0) {
			List<LittleBitsTrigger__c> triggersToFire = new List<LittleBitsTrigger__c>();
			for(LittleBitsTrigger__c lbTrigger : lbTriggers) {
				// Only fire the trigger if the specified fields have been modified
				List<String> fields = lbTrigger.WhenFieldsModified__c.split(',');
				SObject oldRecord = oldMap.get(lbTrigger.RecordID__c);
				SObject newRecord = newMap.get(lbTrigger.RecordID__c);
				Boolean modified = false;
				for(String field : fields)
				{
					field = field.trim();
					Object oldValue = oldRecord.get(field);
					Object newValue = newRecord.get(field);
					if(!oldValue.equals(newValue))
					{
						modified = true;
						break;
					}
				}
				if(modified)
					triggersToFire.add(lbTrigger);
			}
			// Enqueue a job to output to the device/s?
			if(triggersToFire.size()>0)
			{
				OutputToDevicesJob lbtJob = new OutputToDevicesJob();
				for(LittleBitsTrigger__c lbTrigger : triggersToFire) {
					SObject record = newMap.get(lbTrigger.RecordID__c);
					// Literal percent and/or duration?
					Integer percent = lbTrigger.Percent__c != null ? 
						lbTrigger.Percent__c.intValue() : null;
					Integer durationMs = lbTrigger.DurationInMilliseconds__c != null ? 
						lbTrigger.DurationInMilliseconds__c.intValue() : null;
					// Retrieve percent and/or duration from associated record?
					if(percent==null)
					{
						Decimal recordDecimal = (Decimal) record.get(lbTrigger.PercentField__c);
						if(recordDecimal!=null)
							percent = recordDecimal.intValue();
					}
					if(durationMs==null)
					{
						Decimal recordDecimal = (Decimal) record.get(lbTrigger.DurationInMillisecondsField__c);
						if(recordDecimal!=null)
							durationMs = recordDecimal.intValue();
					}
					// Access token and Device Id can be null, if so the LittleBits Apex client API will retrieve from a custom setting
					String accessToken = lbTrigger.AccessToken__c;
					String deviceId = lbTrigger.DeviceID__c;
					lbtJob.addOutput(accessToken, deviceId, percent, durationMs);
				}
				// http://salesforce.stackexchange.com/questions/66947/callout-loop-not-allowed-in-unit-test-for-queueable-that-implements-httpcallou
				if(Test.isRunningTest())
					lbtJob.execute(null);
				else
					System.enqueueJob((lbtJob));
			}
		}		
	}

	/**
	 * Main entry point for LittleBits triggers (currently only updates handled) (requires LittleBitsTrigger__c setup)
	 **/
	global static void triggerHandler() {
		if(Trigger.isUpdate && Trigger.isAfter)
			triggerHandler(Trigger.oldMap, Trigger.newMap);
	}

	/**
	 * Processes the given LittleBits Report Trigger records, runs the reports outputs to the devices
	 *    Based on the great work by Cory Cowgil: http://corycowgill.blogspot.co.uk/2014/12/create-real-life-dashboard-with.html
	 **/
	global static List<ReportTriggersResult> runReportTriggers(Set<Id> reportTriggerIds) {

		// Query Report Triggers and determine Reports to Run
		List<LittleBitsReportTrigger__c> reportTriggers = 
			new LittleBitsReportTriggersSelector().selectById(reportTriggerIds);
		Set<String> reportNames = new Set<String>();
		for(LittleBitsReportTrigger__c reportTrigger : reportTriggers) {
			reportNames.add(reportTrigger.ReportDeveloperName__c);
		}

 		// Query Platform Reports 		
        List <Report> reportList = 
        	new ReportsSelector().selectByDeveloperName(reportNames);
        Map<String, Report> reportsByName = 
        	new Map<String, Report>();
        for(Report report : reportList) {
        	reportsByName.put(report.DeveloperName, report);
        }

        // TODO: Group report triggers on the same report to run the report once

        // Run Reports and output to the Devices
        List<ReportTriggersResult> runReportTriggersResults = new List<ReportTriggersResult>();
        for(LittleBitsReportTrigger__c reportTrigger : reportTriggers) {
        	// Report associated with this Trigger?
        	Report report = reportsByName.get(reportTrigger.ReportDeveloperName__c);
        	if(report==null)
        		throw new LittleBitsServiceException('Report ' + reportTrigger.ReportDeveloperName__c + ' was not found.');
	        String reportId = report.Id;	        
	        // Run the report
	        Reports.ReportResults results = Reports.ReportManager.runReport(reportId, true);	        
	        // Parse results of the report to obtain the percent and duration from the given co-ordinates
	        Reports.Dimension dim = results.getGroupingsDown();
	        Reports.GroupingValue groupingVal = dim.getGroupings()[Integer.valueOf(reportTrigger.GroupingIndex__c)];	        
	        Reports.ReportFactWithDetails factDetails =
	            (Reports.ReportFactWithDetails)results.getFactMap().get(groupingVal.getKey() + '!T');	        
	        Reports.SummaryValue sumValForDuration = 
	        	reportTrigger.AggregateIndexForDuration__c!=null ? 
	        		factDetails.getAggregates()[Integer.valueOf(reportTrigger.AggregateIndexForDuration__c)] : null;
	        Reports.SummaryValue sumValForPercent = 
	        	reportTrigger.AggregateIndexForPercent__c!=null ? 
	        		factDetails.getAggregates()[Integer.valueOf(reportTrigger.AggregateIndexForPercent__c)] : null;
	        // Send to Device
			DeviceOutput deviceOutput = new DeviceOutput();
			deviceOutput.AccessToken = reportTrigger.AccessToken__c;
			deviceOutput.DeviceId = reportTrigger.DeviceId__c;			
			deviceOutput.Percent = sumValForPercent !=null ? Integer.valueOf(sumValForPercent.getValue()) : 0;
			deviceOutput.DurationMs = sumValForDuration !=null ? Integer.valueOf(sumValForDuration.getValue()) : -1;
			send(new List<DeviceOutput> { deviceOutput });	        
			// Pass back to caller
			ReportTriggersResult result = new ReportTriggersResult();
			result.Percent = deviceOutput.Percent;
			result.DurationMs = deviceOutput.DurationMs;
			runReportTriggersResults.add(result);
        }

        return runReportTriggersResults;
	}

	/**
	 * Enque the job to process all the active Report Triggers
	 **/
	global static Id runReportTriggersJob() {
		// Scope size driven by max HTTP callouts per execution scope
		return Database.executeBatch(
			new LittleBitsReportTriggerJob(), 
			Limits.getLimitCallouts());
	}

	/**
	 * Schedules the job to process all the active Report Triggers (default for now, once every hour)
	 **/
	global static Id scheduleRunReportTriggers() {
		return System.schedule('LittleBits Connector Report Triggers', 
			'0 0 * * * ?', new LittleBitsReportTriggerScheduler());
	}

	/**
	 * Process an event from a LittleBits device (these are not received in bulk)
	 *   e.g. {"type":"amplitude","timestamp":1438506243653,"user_id":43303,"bit_id":"00e04c035309","payload":{"percent":100,"delta":"ignite"}}
	 **/
	global static void processSubscriptionEvent(Map<String, Object> littleBitPayload) {

		// Unpack event data
		// TODO: More error handling!
		Map<String, Object> flowParams = new Map<String, Object>();
		flowParams.put('lbc_type', littleBitPayload.get('type'));
		flowParams.put('lbc_timestamp', littleBitPayload.get('timestamp'));
		flowParams.put('lbc_user_id', littleBitPayload.get('user_id'));
		flowParams.put('lbc_bit_id', littleBitPayload.get('bit_id'));
		flowParams.put('lbc_payload_percent', ((Map<String, Object>)littleBitPayload.get('payload')).get('percent'));
		flowParams.put('lbc_payload_delta', ((Map<String, Object>)littleBitPayload.get('payload')).get('delta'));

		// Query for the associated device subscription
		Set<String> deviceIds = new Set<String>();
		deviceIds.add((String)littleBitPayload.get('bit_id'));
		List<LittleBitsDeviceSubscription__c> deviceSubscriptions = 
			new LittleBitsDeviceSubscriptionsSelector().getAllActiveByDeviceId(deviceIds);
		if(deviceSubscriptions.size()==0)
			// TODO: Debug / logging?
			return;

		// Pass record Id of Subscription, permits users to add custom fields to this object that can be used
		// to help configure the behaviour in the Flow called below
		LittleBitsDeviceSubscription__c deviceSubscription = deviceSubscriptions[0];
		flowParams.put('lbc_subscriptionRecordId', deviceSubscription.Id);

		// Process the subscription and forward to a Flow
		// TODO: More error handling in case the factory doesn't exist
        ILittleBitsFlowFactory flowFactory = 
        	(ILittleBitsFlowFactory) Type.forName(null, FlowFactoryClass).newInstance();
        // TODO: More error handling incase the factory doesn't know the FLow name
		Flow.Interview flow = flowFactory.newInstance(deviceSubscription.FlowName__c, flowParams);
		if(flow!=null)
			flow.start();

		// TODO: Think about some kind of logging mode or leave this purely to thd test mode i'm thinking about?
		// ....
	}

	@TestVisible
	private static String FlowFactoryClass = 'LittleBitsFlowFactory';

	/**
	 * Update device subscriptions via LittleBits Cloud API based on the given device subscriptions
	 *   NOTE: Since this service method makes callout outs, its scalability is limited by the remaining callouts in the request scope
	 **/
	global static void updateDeviceSubscriptions(Set<Id> subscriptioIds) {

		String callbackUrl = generateCallbackURL();
		List<LittleBitsDeviceSubscription__c> deviceSubscriptions = 
			new LittleBitsDeviceSubscriptionsSelector().selectById(subscriptioIds);
		for(LittleBitsDeviceSubscription__c deviceSubscription : deviceSubscriptions) {
			getDevice(deviceSubscription.AccessToken__c, deviceSubscription.DeviceID__c).
				// TODO: This approach does not currently support multiple events (will document for first release)
				subscribe(callbackUrl, deviceSubscription.Event__c);
		}
	}

	/**
	 * Remove device subscriptions via LittleBits Cloud API based on the given device subscriptions
	 *   NOTE: Since this service method makes callout outs, its scalability is limited by the remaining callouts in the request scope
	 **/
	global static void deleteDeviceSubscriptions(Set<Id> subscriptioIds) {

		String callbackUrl = generateCallbackURL();
		List<LittleBitsDeviceSubscription__c> deviceSubscriptions = 
			new LittleBitsDeviceSubscriptionsSelector().selectById(subscriptioIds);
		for(LittleBitsDeviceSubscription__c deviceSubscription : deviceSubscriptions) {
			getDevice(deviceSubscription.AccessToken__c, deviceSubscription.DeviceID__c).
				unsubscribe(callbackUrl);
		}
	}

	public class LittleBitsServiceException extends Exception {}

	/**
	 * Obtain an instance of the LittleBits Apex Device class (leverages Custom Setting config routes accordingly)
	 **/
	private static LittleBits.Device getDevice(String accessToken, String deviceId) {
		LittleBits lb = accessToken != null ? 
        	new LittleBits(accessToken) : new LittleBits();
		LittleBIts.Device device = deviceId != null ? 
			lb.getDevice(deviceId) : lb.getDevice();
		return device;
	}	

	/**
	 * Uses the configured Force.com site to generate the fully callback URL to pass to LittleBits API subscription resource
	 **/
	private static String generateCallbackURL() {

		// Namespace context?
		Schema.DescribeSObjectResult describe = LittleBitsAPI__c.sObjectType.getDescribe();
		String name = describe.getName();
		String localName = describe.getLocalName();
		String namespace = name.removeEnd(localName).removeEnd('__');

		// Generate URL, factoring in namespace dynamically (permits development and testing in unmanaged contexts)
		LittleBitsAPI__c settings = LittleBitsAPI__c.getInstance(); 
		if(settings==null || settings.SubscriptionSiteURL__c==null)
			throw new LittleBitsServiceException('Please specify the Subscription Site URL in the LittleBits Custom Setting under Setup.');
		return settings.SubscriptionSiteURL__c + '/services/apexrest' + (namespace.length()>0 ? '/' + namespace : '') + '/subscriber';
	}
}