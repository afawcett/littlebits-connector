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
private class LittleBitsTest {

	@IsTest
	private static void testConfigWithCustomSetting() {

		// Custom Setting Config
		LittleBitsAPI__c lbConfig = new LittleBitsAPI__c();
		lbConfig.AccessToken__c = 'testaccesstoken';
		lbConfig.DeviceID__c = 'testdeviceid';
		insert lbConfig;

		// Construct API and assert config loaded
		LittleBits lb = new LittleBits();
		LittleBits.Device device = lb.getDevice();
		System.assertEquals('testaccesstoken', lb.AccessToken);
		System.assertEquals('testdeviceid', device.Id);
	}

	@IsTest
	private static void testConfigWithoutCustomSetting() {

		// Validate config error handling
		try {
			LittleBits lb = new LittleBits();
			System.assert(false, 'Expected an exception');
		} catch (LittleBits.LittleBitsException e) {
			System.assertEquals('Must specify an Access Token, either as parameter or Custom Setting configuration.', e.getMessage());
		}
		try {
			LittleBits lb = new LittleBits('testaccesstoken');
			LittleBits.Device device = lb.getDevice();
			System.assert(false, 'Expected an exception');
		} catch (LittleBits.LittleBitsException e) {
			System.assertEquals('Must specify a Device Id, either as parameter or Custom Setting configuration.', e.getMessage());
		}
	}

	@IsTest
	private static void testConfigViaConstructor() {

		// Configure via constructor and method parameters
		LittleBits lb = new LittleBits('testaccesstoken');
		LittleBits.Device device = lb.getDevice('testdeviceid');

		// Assert
		System.assertEquals('testaccesstoken', lb.AccessToken);
		System.assertEquals('testdeviceid', device.Id);
	}

	@IsTest
	private static void testOutputSuccessWihtoutParams() {

		// Test data
		String testAccessToken = 'testaccesstoken';
		String testDeviceId = 'testdeviceId';

		// Mock web service callout to emulate no parameters passed
		Test.setMock(HttpCalloutMock.class, 
			new MockLittleBitsOutputCloudAPI(
				testAccessToken, 
				testDeviceId, 
				null,
				null,
				200,
				null));

		// Configure via constructor and method parameters
		LittleBits lb = new LittleBits(testAccessToken);
		LittleBits.Device device = lb.getDevice(testDeviceId);
		device.output();
	}

	@IsTest
	private static void testOutputSuccessWithParams() {

		// Test data
		String testAccessToken = 'testaccesstoken';
		String testDeviceId = 'testdeviceId';
		Integer testPercent = 80;
		Integer testDurationMs = 10000;

		// Mock web service callout to emulate passing of parameters
		Test.setMock(HttpCalloutMock.class, 
			new MockLittleBitsOutputCloudAPI(
				testAccessToken, 
				testDeviceId, 
				testPercent,
				testDurationMs,
				200,
				null));

		// Configure via constructor and method parameters
		LittleBits lb = new LittleBits(testAccessToken);
		LittleBits.Device device = lb.getDevice(testDeviceId);
		device.output(testPercent, testDurationMs);
	}

	@IsTest
	private static void testOutputFailure() {

		// Test data
		String testAccessToken = 'testaccesstoken';
		String testDeviceId = 'testdeviceId';
		Integer testPercent = 80;
		Integer testDurationMs = 10000;
		String expectedException = 'Bad Request';

		// Mock web service callout to emulate a failure
		Test.setMock(HttpCalloutMock.class, 
			new MockLittleBitsOutputCloudAPI(
				testAccessToken, 
				testDeviceId, 
				testPercent,
				testDurationMs,
				400,
				expectedException));

		try {
			// Configure via constructor and method parameters
			LittleBits lb = new LittleBits(testAccessToken);
			LittleBits.Device device = lb.getDevice(testDeviceId);
			device.output(testPercent, testDurationMs);
			System.assert(false, 'Expected an exception');
		} catch (LittleBits.LittleBitsException e) {
			System.assertEquals(expectedException, e.getMessage());
		}
	}

	/**
	 * Mocks the LittleBits Cloud API for /devices/{id}/output HTTP POST
	 **/
	private class MockLittleBitsOutputCloudAPI implements HttpCalloutMock {

		private String expectedAccessToken;
		private String expectedDeviceId;
		private Integer expectedPercent;
		private Integer expectedDurationMs;
		private Integer mockResponseStatusCode;
		private String mockResponseBody;

		public MockLittleBitsOutputCloudAPI(
			String expectedAccessToken,
			String expectedDeviceId,
			Integer expectedPercent, 
			Integer expectedDurationMs, 
			Integer mockResponseStatusCode,
			String mockResponseBody) {
			this.expectedAccessToken = expectedAccessToken;
			this.expectedDeviceId = expectedDeviceId;
			this.expectedPercent = expectedPercent;
			this.expectedDurationMs = expectedDurationMs;
			this.mockResponseStatusCode = mockResponseStatusCode;
			this.mockResponseBody = mockResponseBody;
		}

		public HTTPResponse respond(HTTPRequest req) {

			// Assert end point
			String endPoint = req.getEndPoint();
			String[] endPointParts = endPoint.split('/');
			System.assertEquals(6, endPointParts.size());
			System.assertEquals(expectedDeviceId, endPointParts[4]);

			// Assert header
			System.assertEquals(req.getHeader('Authorization'), 'Bearer ' + expectedAccessToken);

			// Assert body
			if(expectedPercent!=null && expectedDurationMs!=null)
				System.assertEquals('percent='+expectedPercent+'&duration_ms='+expectedDurationMs, req.getBody());
			else
				System.assertEquals('', req.getBody());
			
			// Mock response
			HttpResponse res = new HttpResponse();
			res.setStatusCode(mockResponseStatusCode);
			if(mockResponseBody!=null)
				res.setBody(mockResponseBody);
			return res;
		}
	}
}