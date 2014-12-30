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
 * Class encapsulates query logic for LittleBitsTrigger__c
 *
 * https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Selector_Layer
 **/
public class LittleBitsTriggerSelector extends fflib_SObjectSelector
	implements ILittleBitsTriggerSelector
{
	public List<Schema.SObjectField> getSObjectFieldList()
	{
		return new List<Schema.SObjectField> {
				LittleBitsTrigger__c.Id,
				LittleBitsTrigger__c.AccessToken__c,
				LittleBitsTrigger__c.Active__c,
				LittleBitsTrigger__c.DeviceID__c,
				LittleBitsTrigger__c.DurationInMilliseconds__c,
				LittleBitsTrigger__c.DurationInMillisecondsField__c,
				LittleBitsTrigger__c.Percent__c,
				LittleBitsTrigger__c.PercentField__c,
				LittleBitsTrigger__c.RecordID__c,
				LittleBitsTrigger__c.WhenFieldsModified__c
			};
	}

	public Schema.SObjectType getSObjectType()
	{
		return LittleBitsTrigger__c.sObjectType;
	}

	public List<LittleBitsTrigger__c> selectById(Set<ID> idSet)
	{
		return (List<LittleBitsTrigger__c>) selectSObjectsById(idSet);
	}

	public List<LittleBitsTrigger__c> selectActiveByRecordId(Set<Id> idSet) 
	{
		return (List<LittleBitsTrigger__c>)
			Database.query(
				newQueryFactory().setCondition('Active__c = true And RecordID__c in :idSet').toSOQL());
	}
}