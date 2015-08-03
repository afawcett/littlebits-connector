/**
 * Copyright (c), Cory Cowgill and Andrew Fawcett
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
 * - Neither the name of the Cory Cowgill and Andrew Fawcett, nor the names of its contributors 
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
 * Wrapper around the LittleBits.cc Cloud API 
 *   http://developer.littlebitscloud.cc/preview
 **/
public class LittleBits {

	public String AccessToken {get; private set;}

	/**
	 * Uses Access Token from Custom Setting
	 **/
	public LittleBits() {
		this(LittleBitsAPI__c.getInstance().AccessToken__c);
	}
	/**
	 * Access token is available under Settings at http://control.littlebitscloud.cc/
	 **/
	public LittleBits(String accessToken) {
		if(accessToken==null)
			throw new LittleBitsException('Must specify an Access Token, either as parameter or Custom Setting configuration.');
		this.AccessToken = accessToken;
	}

	/**
	 * Returns the default Device as per the Custom Setting
	 **/
	public Device getDevice() {
		return new Device(AccessToken);
	}

	/**
	 * Device ID is available under Settings at http://control.littlebitscloud.cc/
	 **/
	public Device getDevice(String deviceId) {
		return new Device(AccessToken, deviceId);
	}	

	public class Device {

		/** 
		 * Id of this Device 
		 **/
		public String Id {get; private set;}

		private String accessToken;

		/**
		 * Constructs the default device as per the custom setting 
		 **/
		private Device(String accessToken) {
			this(accessToken, LittleBitsAPI__c.getInstance().DeviceID__c);
		}

		/**
		 * Constructs a Device for the given Id
		 **/
		private Device(String accessToken, String deviceId) {
			if(deviceId==null)
				throw new LittleBitsException('Must specify a Device Id, either as parameter or Custom Setting configuration.');			
			this.Id = deviceId;
			this.accessToken = accessToken;
		}				

		/**
		 * By default maximum amplitude is sent for 3 seconds
		 **/
		public void output() {
			output(null, null);
		}

		/**
		 * Passing 10 and 10000, outputs 10% amplitude for 10 seconds
		 **/
		public void output(Integer percent, Integer durationMs) {
  			Http h = new Http();
        	HttpRequest request = new HttpRequest();
        	request.setEndpoint('https://api-http.littlebitscloud.cc/devices/'+Id+'/output');
        	request.setHeader('Authorization', 'Bearer ' + accessToken);
        	request.setHeader('Accept', 'application/vnd.littlebits.v2+json');
        	request.setMethod('POST');
        	// http://discuss.littlebits.cc/t/littlebits-cloud-api-giving-bad-request-from-devices-id-output-post/11969
        	if(percent!=null && durationMs!=null)
        		request.setBody('percent='+percent+'&duration_ms='+durationMs);
        	HttpResponse response = h.send(request);
        	if(response.getStatusCode()!=200)
        		throw new LittleBitsException(response.getBody());
		}
		
		/**
		 * Subscribe to the Device for an event.
		 * 
		 * Events String (littleBitEvent String) to listen for are:
		 * 
		 * 	amplitude                  –––– when there is any voltage (catch-all, default)
		 *	amplitude:delta:sustain    –––– when high voltage is constant (eg button being held)
		 *	amplitude:delta:ignite     –––– when there is significant voltage jump (eg button press)
		 *	amplitude:delta:release    –––– when there is significant voltage drop (eg button release)
		 *	amplitude:delta:nap        –––– when low voltage is constant (eg idle bitSnap system)
		 *	amplitude:level:active     –––– generic, when there is high voltage (eg during a sustain or maybe just ignited)
		 *	amplitude:level:idle       –––– generic, when there is low voltage (eg during a long nap or maybe just released)
		 * 
		 **/		
		public void subscribe(String endpoint, String littleBitEvent){
			Http h = new Http();
			HttpRequest req = new HttpRequest(); 
          	req.setMethod('POST'); 
          	req.setEndpoint('https://api-http.littlebitscloud.cc/subscriptions');
			req.setHeader('Authorization','Bearer ' + accessToken);
			req.setHeader('Accept', 'application/vnd.littlebits.v2+json');
			req.setBody('publisher_id=' + Id + '&subscriber_id=' + endpoint + '&publisher_events=' + littleBitEvent);
			HttpResponse response = h.send(req);
			if(response.getStatusCode()!=201)
				throw new LittleBitsException(response.getBody());
		}

		/** 
		 * Delete a Subscription from a device
		 **/
		public void unsubscribe(String endpoint) {
			Http h = new Http();
			HttpRequest req = new HttpRequest(); 
          	req.setMethod('DELETE'); 
          	req.setEndpoint('https://api-http.littlebitscloud.cc/subscriptions');
			req.setHeader('Authorization','Bearer ' + accessToken);
			req.setHeader('Accept', 'application/vnd.littlebits.v2+json');
			req.setBody('publisher_id=' + Id + '&subscriber_id=' + endpoint);
			HttpResponse response = h.send(req);
			if(response.getStatusCode()!=200)
				throw new LittleBitsException(response.getBody());

		}

		/**
		 * Retrieve Subscriptions for a device
		 **/
		public Subscription getSubscription(String endpoint) {
			Http h = new Http();
			HttpRequest req = new HttpRequest(); 
          	req.setMethod('GET'); 
          	req.setEndpoint('https://api-http.littlebitscloud.cc/subscriptions');
			req.setHeader('Authorization','Bearer ' + accessToken);
			req.setHeader('Accept', 'application/vnd.littlebits.v2+json');
			req.setBody('publisher_id=' + Id + '&subscriber_id=' + endpoint);
			HttpResponse response = h.send(req);
			if(response.getStatusCode()!=201)
				throw new LittleBitsException(response.getBody());
			return (Subscription) JSON.deserialize(response.getBody(), Subscription.class);
		}
	}

	/**
	 * Describes the response from /subscriptions resource
	 **/
	public class Subscription {
		public String publisher_id;
		public String subscriber_id;
		public List<PublisherEvent> publisher_events;

	}
	public class PublisherEvent {
		public String name;
	}

	public class LittleBitsException extends Exception { }
}
