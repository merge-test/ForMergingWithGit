<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Lead_Assigned</fullName>
        <description>Lead Assigned</description>
        <protected>false</protected>
        <recipients>
            <field>Sales_Head__c</field>
            <type>contactLookup</type>
        </recipients>
        <senderAddress>michaelt@ny-engineers.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Lead_Assigned</template>
    </alerts>
    <alerts>
        <fullName>Not_Yet_Contacted</fullName>
        <description>Not Yet Contacted</description>
        <protected>false</protected>
        <recipients>
            <field>Sales_Head__c</field>
            <type>contactLookup</type>
        </recipients>
        <senderAddress>michaelt@ny-engineers.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Not_Yet_Contacted_Email</template>
    </alerts>
    <alerts>
        <fullName>Not_Yet_Contacted_NJ</fullName>
        <description>Not Yet Contacted_NJ</description>
        <protected>false</protected>
        <recipients>
            <field>Sales_Head__c</field>
            <type>contactLookup</type>
        </recipients>
        <senderAddress>alexg@nj-engineers.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Not_Yet_Contacted_Email_NJ</template>
    </alerts>
    <fieldUpdates>
        <fullName>SFDC_TEST2</fullName>
        <field>Client_Value_Dollar__c</field>
        <formula>18000</formula>
        <name>SFDC TEST2</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>SFDC_TEST3</fullName>
        <field>Client_Value_Dollar__c</field>
        <formula>8000</formula>
        <name>SFDC TEST3</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>SFDC_TEST4</fullName>
        <field>Client_Value_Dollar__c</field>
        <formula>85000</formula>
        <name>SFDC TEST4</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>TEST_SFDC</fullName>
        <field>Client_Value_Dollar__c</field>
        <formula>35000</formula>
        <name>TEST SFDC</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Days Not contacted</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Contact.Follow_Up_Status__c</field>
            <operation>equals</operation>
            <value>Not Yet Contacted</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Not Yet Contacted Email</fullName>
        <actions>
            <name>Lead_Assigned</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contact.Follow_Up_Status__c</field>
            <operation>equals</operation>
            <value>Not Yet Contacted</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Not_Yet_Contacted</name>
                <type>Alert</type>
            </actions>
            <timeLength>7</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>SFDC TEST2</fullName>
        <actions>
            <name>SFDC_TEST2</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contact.Client_Value__c</field>
            <operation>equals</operation>
            <value>Average</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>SFDC TEST3</fullName>
        <actions>
            <name>SFDC_TEST3</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contact.Client_Value__c</field>
            <operation>equals</operation>
            <value>low</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>SFDC TEST4</fullName>
        <actions>
            <name>SFDC_TEST4</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contact.Client_Value__c</field>
            <operation>equals</operation>
            <value>MEGA</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>SFDCTEST</fullName>
        <actions>
            <name>TEST_SFDC</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contact.Client_Value__c</field>
            <operation>equals</operation>
            <value>HIGH</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
