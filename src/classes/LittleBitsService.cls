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
	 * Determine if the given records should result in a LittleBit trigger executing
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
					send(accessToken, deviceId, percent, durationMs);
					// lbtJob.addOutput(accessToken, deviceId, percent, durationMs);
				}
				// System.enqueueJob((lbtJob));
			}
		}		
	}

	/**
	 * Main entry point for LittleBits triggers (currently only updates handled)
	 **/
	global static void triggerHandler() {
		if(Trigger.isUpdate && Trigger.isAfter)
			triggerHandler(Trigger.oldMap, Trigger.newMap);
	}

	/**
	 * Temporary while i get Queueable working
	 **/
	@future(callout=true)
	public static void send(String accessToken, String deviceId, Integer percent, Integer durationMs) {
		LittleBits lb = new LittleBits(accessToken);
		LittleBIts.Device device = lb.getDevice(deviceId);
		device.output(percent, durationMs);		
	}	
}