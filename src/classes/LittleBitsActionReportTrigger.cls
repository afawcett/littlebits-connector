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

global with sharing class LittleBitsActionReportTrigger {

	global class Request {
		@InvocableVariable(Label='Unique Name' Description='Unique Name of the Report Trigger' Required=true)
		global String UniqueName;
	}
	
    /**
     * Run the given Report Trigger
     **/
    @InvocableMethod(Label='Runs the given Report Trigger' Description='Runs the given Report Trigger.')
    global static void run(List<Request> requests) {
    	Set<String> uniqueNames = new Set<String>();
    	for(Request request : requests)
    		uniqueNames.add(request.UniqueName);
    	System.enqueueJob(new RunReportTriggerJob(uniqueNames));
	}	

	/**
	 * Run the Report Triggers in Async since Invocable Methods from Process Builder don't support callouts
	 **/
	public class RunReportTriggerJob implements Queueable, Database.AllowsCallouts {

		private Set<String> uniqueNames =  new Set<String>();

		public RunReportTriggerJob(Set<String> uniqueNames) {
			this.uniqueNames = uniqueNames;
		}

		public void execute(QueueableContext context) {
			LittleBitsService.runReportTriggers(uniqueNames);
		}
	}	
}