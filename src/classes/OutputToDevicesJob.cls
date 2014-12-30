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
 * Collects device output requets and emits them (useful in a trigger context)
 **/
public class OutputToDevicesJob implements /* Queueable,*/ Database.AllowsCallouts {

	private List<Output> outputs = new List<Output>();

	/**
	 * Add an output that will be sent once the job executes
	 **/
	public void addOutput(String accessToken, String deviceId, Integer percent, Integer durationMs) {
		if(percent==null)
			throw new OutputToDevicesJobException('percent cannot be null');
		if(durationMs==null)
			throw new OutputToDevicesJobException('durationMs cannot be null');
		Output output = new Output();
		output.AccessToken = accessToken;
		output.DeviceId = deviceId;
		output.Percent = percent;
		output.DurationMS = durationMs;
	 	outputs.add(output);
	}

	/**
	 * Outputs the stored outputs to the devices via the LittleBits Cloud API
	 **/
	public void execute(QueueableContext context) {
		for(Output output : outputs) {
			LittleBits lb = new LittleBits(output.AccessToken);
			LittleBIts.Device device = lb.getDevice(output.DeviceId);
			device.output(output.Percent, output.DurationMS);
		}
	}

	private class Output {
		public String AccessToken;
		public String DeviceId;
		public Integer Percent;
		public Integer DurationMS;
	}

	public class OutputToDevicesJobException extends Exception {}
}