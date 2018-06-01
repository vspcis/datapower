<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>ConstructTransientData.xsl</Filename>
<revisionlog>v1.0.1</revisionlog>
<Description>
  This is the transient data build template
</Description>
<Owner>eHealthOntario</Owner>
<LastUpdate>
June 29, 2017 - Fixed the filering issue when template applied with some fields filtered.
May 29, 2017 - service_name now is generated from transientDataServiceName as to allow both soap/rest services
               Also contains fix for SLA Name
May 19, 2017 - Added overridable handling for HL7 Response Interaction, updates to namespaces response interaction
May 18, 2017 - Fixed namespace Issue with HL7 Context/RestContext
May 04, 2017 - Added schema validation status
May 02, 2017 - Fixed issue with SLA Name.
Apr 13, 2017 - Fixed WS Mediation Policy Text generation, Security Context is now logged, but will not have date fields
Mar 31, 2017 - Added HL7_Context/HL7_Response_Interaction - Fixed Response interaction incase of REST
Mar 24, 2017 - buildTransientDataWithMap updated to use the extensible function to get the map filename
Mar 23, 2017 - Added extensible function to return the transient data map
Mar 19, 2017 - Added HL7_Context/HL7_Response_Interaction
Mar 17, 2017 - Added HL7 Context and Rest Context
Aug 18, 2016 - FMBL Fix for Message Adapters
</LastUpdate>
<Copyright>
**************************************************************
  Copyright (c) ehealthOntario, 2015 ~ 2020
**************************************************************
</Copyright>
</CodeHeader>
-->
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:exslt="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times" 
    xmlns:dp="http://www.datapower.com/extensions" 
    xmlns:dpwsm="http://www.datapower.com/schemas/transactions" 
    xmlns:regexp="http://exslt.org/regular-expressions"
    xmlns:dpconfig="http://www.datapower.com/param/config" 
    xmlns:dpfunc="http://www.datapower.com/extensions/functions"
    xmlns:wsmp="http://www.ibm.com/xmlns/stdwip/2011/02/ws-mediation"
    xmlns:hiallib="http://www.ehealthontario.on.ca/hial/lib"
    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" 
    xmlns:xacml="urn:oasis:names:tc:xacml:2.0:context:schema:os"
    xmlns:xacmlPolicy="urn:oasis:names:tc:xacml:2.0:policy:schema:os"
    xmlns:txndata="urn:http://com.eho.hial/TransientData"
    exclude-result-prefixes="exslt regexp saml xacml xacmlPolicy xsl dp date dpwsm dpconfig wsmp hiallib"
    extension-element-prefixes="dp" 
    version="1.0">
   
    <xsl:include href="store:///utilities.xsl"/>
    
    <xsl:variable name="txnCtx" select="dp:variable('var://context/hialPEP/txnContext')"/>    
    <xsl:variable name="doubleColon">"</xsl:variable>
    <xsl:variable name="comma">:</xsl:variable>
    <xsl:variable name="leadingBraces">{</xsl:variable>
    <xsl:variable name="endingBraces">}</xsl:variable>
    <xsl:variable name="colonComma">":"</xsl:variable>
  
    <!-- This template build transient data based on current status -->
    <xsl:template name="buildTransientData">
        <xsl:param name="Operation" select="'default'"/>
        
        <!-- get the current processing rule, it could be request, response, error -->
        <xsl:variable name="currentProcessingRule" select="dp:variable('var://service/transaction-rule-type')" /> 
        
        <!-- build security context -->
        <xsl:variable name="securityCtx">
            <xsl:call-template name="buildSecurityCtx"/>
        </xsl:variable>        
        
        <xsl:variable name="responseMsgId">
            <xsl:choose>
                <xsl:when test="$currentProcessingRule = 'response'">
                    <xsl:value-of select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='MessageID']/text()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="transientData">
            <!-- TODO: Refactor this can we just rebuild this from the HialPEP/txnContext , no need to gather/compute this information again
                 is there? When transaciton volume is high even the most basic system calls cost time.
            -->
            <TransientData xmlns="urn:http://com.eho.hial/TransientData" xmlns:td="urn:http://com.eho.hial/TransientData">                

                    <xsl:if test="$currentProcessingRule = 'error'">
                      <Error>
                        <xsl:variable name="transientError" select="dp:variable('var://context/logging/transientError')"/>
                        <xsl:choose>
                            <xsl:when test="$transientError">
                                <Business_Error>
                                    <error_Activity><xsl:value-of select="$transientError/TransientError/Activity/text()"/></error_Activity>
                                    <error_Code><xsl:value-of select="$transientError/TransientError/ErrorCode/text()"/></error_Code>
                                    <error_Description><xsl:value-of select="$transientError/TransientError/Description/text()"/></error_Description>
                                    <error_Node_Name>GateWay</error_Node_Name>
                                    <error_Severity>Error</error_Severity>
                                    <error_Timestamp><xsl:call-template name="getFormattedGMT"/></error_Timestamp>
                                </Business_Error>                                
                            </xsl:when>
                            <xsl:otherwise>
                                <Business_Error>
                                    <error_Activity>ERR</error_Activity>
                                    <error_Code><xsl:value-of select="dp:variable('var://service/error-code')"/></error_Code>
                                    <error_Description><xsl:value-of select="dp:variable('var://service/error-message')"/></error_Description>
                                    <error_Node_Name>GateWay</error_Node_Name>
                                    <error_Severity>Error</error_Severity>
                                    <error_Timestamp><xsl:call-template name="getFormattedGMT"/></error_Timestamp>
                                </Business_Error>                                
                            </xsl:otherwise>
                        </xsl:choose>                        
                      </Error>  
                    </xsl:if>
               
                
                <Transaction_Flow>
                    <delivery_Method>Gateway</delivery_Method>
                    
                    <xsl:choose>
                        <xsl:when test="$currentProcessingRule = 'request' and not($Operation = 'FMBLresponse')">
                            <gateway_End_Time/>
                        </xsl:when>
                        <xsl:when test="$txnCtx/txnContext/disableGatewayEndTime/text() = 'true' and not($Operation = 'FMBLresponse')">
                            <gateway_End_Time/>
                        </xsl:when>
                        <xsl:otherwise>
                            <gateway_End_Time>
                                <xsl:call-template name="getFormattedGMT"/>
                            </gateway_End_Time>        
                        </xsl:otherwise>
                    </xsl:choose>
                    <gateway_Start_Time>
                        <xsl:choose>
                            <xsl:when test="starts-with($Operation, 'FMBL')">
                                <xsl:value-of select="$txnCtx/txnContext/gatewayStartTimeFMBL/text()"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$txnCtx/txnContext/gatewayStartTime/text()"/>
                            </xsl:otherwise>
                        </xsl:choose>
                      
                    </gateway_Start_Time>
                    <global_ID>
                        <xsl:value-of select="$txnCtx/txnContext/globalID/text()"/>
                    </global_ID>
                    <global_ID_Assigner>
                        <xsl:value-of select="$txnCtx/txnContext/globalIDAssigner/text()"/>
                    </global_ID_Assigner>
                    <HIB_End_Time></HIB_End_Time>
                    <HIB_Start_Time></HIB_Start_Time>
                    <is_Asynchronous>false</is_Asynchronous>
                    <request_Message_Size><xsl:value-of select="dp:variable('var://service/mpgw/request-size')"/></request_Message_Size>
                    <response_Message_Size><xsl:value-of select="dp:variable('var://service/mpgw/response-size')"/></response_Message_Size>
                    <message_ID><xsl:value-of select="$txnCtx/txnContext/messageID/text()"/></message_ID>
                    <operation>
                        <xsl:value-of select="$txnCtx/txnContext/operation/text()"/>
                    </operation>
                    <originating_System><xsl:value-of select="$txnCtx/txnContext/originatingSystem/text()"/></originating_System>
                    
                    <response_Delivery_Endpoint></response_Delivery_Endpoint>
                    <response_Message_ID><xsl:value-of select="$responseMsgId"/></response_Message_ID>
                    <response_URL></response_URL>
                    
                    <consumer_Organization>
                        <xsl:choose>
                            <xsl:when test="string-length($txnCtx/txnContext/consumerOrganization/text()) &gt; 0">
                                <xsl:value-of select="$txnCtx/txnContext/consumerOrganization/text()"/>                        
                            </xsl:when>
                            <xsl:when test="string-length($txnCtx/txnContext/samlAssertionUao/text()) &gt; 0">
                                <xsl:value-of select="$txnCtx/txnContext/samlAssertionUao/text()"/>                        
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="''"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </consumer_Organization>
                    <consumer_System>
                        <xsl:choose>
                            <xsl:when test="string-length($txnCtx/txnContext/samlAssertingParty/text()) &gt; 0">
                                <xsl:variable name="parsedConsumerSys" select=" substring-before( substring-after($txnCtx/txnContext/samlAssertingParty/text(), 'CN='), ',')"/>
                                <xsl:value-of select="$parsedConsumerSys"/>
                            </xsl:when>
                            <xsl:when test="string-length($txnCtx/txnContext/clientCommonName/text()) &gt; 0">
                                <xsl:variable name="parsedConsumerSys" select="$txnCtx/txnContext/clientCommonName/text()"/>
                                <xsl:value-of select="$parsedConsumerSys"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="''"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </consumer_System>
                    <consumer>
                        <xsl:value-of select="$txnCtx/txnContext/samlSubjectNameId/text()"/>
                    </consumer>
                    
                    <sequence_ID>
                        <xsl:value-of select="dp:variable('var://context/logging/seq')"/>
                    </sequence_ID>
                    <service_Name>
                        <xsl:value-of select="$txnCtx/txnContext/transientDataServiceName/text()"/>
                    </service_Name>
                    <service_Version>
                        <xsl:value-of select="$txnCtx/txnContext/wsdlVersion/text()"/>
                    </service_Version>
                    <SLA>
                     
                        <xsl:variable name="cnPolicy" select="string(dp:variable('var://context/hialPEP/cnPolicy')//*[local-name() ='SLA']/@name)"/>
                        <xsl:variable name="groupPolicy" select="string(dp:variable('var://context/hialPEP/groupPolicy')//*[local-name() ='SLA']/@name)"/>
                        <xsl:variable name="defaultPolicy" select="string(dp:variable('var://context/hialPEP/defaultPolicy')//*[local-name() ='SLA']/@name)"/>
                        <dp:set-variable name="'var://context/debug/SLAName'" value="$defaultPolicy"/>
                        <xsl:choose>
                            <xsl:when test="$cnPolicy">
                                <xsl:value-of select="$cnPolicy"/>    
                            </xsl:when>
                            <xsl:when test="$groupPolicy">
                                <xsl:value-of select="$groupPolicy"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$defaultPolicy"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </SLA>
                      
                                  
                    <transaction_ID>
                        <xsl:value-of select="$txnCtx/txnContext/globalID/text()"/>
                    </transaction_ID>
                    <consumer_Message_ID>
                        <xsl:value-of select="$txnCtx/txnContext/consumerMessageID/text()"/>
                    </consumer_Message_ID>
                    <eHealth_Transaction_ID>
                        <xsl:value-of select="$txnCtx/txnContext/globalID/text()"/>
                    </eHealth_Transaction_ID>
                    <LOB_Repository_ID></LOB_Repository_ID>
                    
                </Transaction_Flow>
                
                <xsl:copy-of select="dp:variable('var://context/logging/attachedPolicies')/AllAttachedPolicies/*"/>
                
                <!--xsl:copy-of select="dp:variable('var://context/logging/parsedSlaPolicies')/AllPolicies/*"/-->
                
                <xsl:variable name="allSlaPolicies"     select="dp:variable('var://context/logging/parsedSlaPolicies')/AllPolicies" />
                <xsl:variable name="executedPolicies"   select="dp:variable('var://context/logging/ExecutedPolicies')"/>
                <xsl:variable name="executedPolicyNode" select="exslt:node-set($allSlaPolicies)" />
                
                <xsl:variable name="countOfSlaPolicy" select="count($executedPolicyNode//*[local-name()='policy_Name'])" />
                <dp:set-variable name="'var://context/logging/countOfSlaPolicy'" value="string($countOfSlaPolicy)" />
                
                <xsl:for-each select="$executedPolicyNode//*[local-name()='policy_Name']">
                    <xsl:variable name="policyName" select="./text()"/>
                    <Policy_And_Rules>
                        <policy_Name><xsl:value-of select="$policyName"/></policy_Name>
                        <policy_Type>WS-Mediation</policy_Type>
                        <xsl:choose>
                            <xsl:when test="contains($executedPolicies, $policyName)">
                                <rule_Response>Executed</rule_Response>                                
                            </xsl:when>
                            <xsl:otherwise>
                                <rule_Response/>
                            </xsl:otherwise>
                        </xsl:choose>
                        
                    </Policy_And_Rules>
                </xsl:for-each>

                <xsl:copy-of select="$securityCtx"/>
                <xsl:if test="$txnCtx/txnContext/*[local-name()='HL7_Context']">
                <HL7_Context>
                    <!-- Was not part of R1B 
                    <HL7_Interaction>HL7_Interaction</HL7_Interaction>
                    <HL7_Response_Interaction>HL7_Response_Interaction</HL7_Response_Interaction>
                    <schema_Validation_Description>schema_Validation_Description</schema_Validation_Description>
                    
                    --> 
                    
                    <!-- 1 determine the payload Type - , 2 - Determine the Protocol, 3 - Determine the Interaction Todo: what about for a GET what is the interaction-->
                    <!-- copy sub elements from context to here -->
                    <xsl:copy-of select="$txnCtx/txnContext/*[local-name()='HL7_Context']/*"/>
                    
                    <xsl:variable name="schemaValidationStatus" select="string(dp:variable('var://context/hial_ctx/schemaValidationStatus'))"/>
                    
                    <schema_Validation_Status>
                      <xsl:choose>
                        <xsl:when test="$schemaValidationStatus = 'true' or $schemaValidationStatus = 'false'">
                          <xsl:value-of select="'Completed'"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="'Not Executed'"/>
                        </xsl:otherwise>
                      </xsl:choose>

                    </schema_Validation_Status>
                    <schema_Validation_Description>
                        <xsl:choose>
                            <xsl:when test="$schemaValidationStatus = 'true'">
                                <xsl:value-of select="'Schema Correct'"/>
                            </xsl:when>
                            <xsl:when test="$schemaValidationStatus = 'false'">
                                <xsl:value-of select="'Schema Incorrect'"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="'Schema Not Validated'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </schema_Validation_Description>
                    
                    <!-- Determine if this is a response rule -->
                    <xsl:call-template name="getHL7ResponseInteraction"/>
                   
                </HL7_Context>
                </xsl:if>
                
                <xsl:if test="$txnCtx/txnContext/*[local-name() = 'REST_Context']">
                <REST_Context>
                    
                    <xsl:copy-of select="$txnCtx/txnContext/*[local-name() = 'REST_Context']/*"/>
                    
                </REST_Context>
                </xsl:if>
            </TransientData>
        </xsl:variable>
        
        <dp:set-variable name="'var://context/logging/transientData'" value="$transientData"/>
        
    </xsl:template>
    
    <xsl:template name="getHL7ResponseInteraction">
        <xsl:variable name="currentProcessingRule" select="dp:variable('var://service/transaction-rule-type')" /> 
        <xsl:choose>
            <xsl:when test="$currentProcessingRule = 'response'">
                <!-- Handles the NON soap Fault case -->
                <!-- HL7 Response is always the Root Element -->
                <HL7_Response_Interaction xmlns="urn:http://com.eho.hial/TransientData">
                    <!-- we  have to test here for Soap or FHIR -->
                    <xsl:choose>
                        <xsl:when test="contains(namespace-uri(*),'http://www.w3.org/2003/05/soap-envelope') or contains(namespace-uri(*),'http://schemas.xmlsoap.org/soap/envelope/')">
                            <xsl:value-of select="local-name(/*[local-name() = 'Envelope']/*[local-name() = 'Body']/node())"/>         
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="local-name(/node())"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                </HL7_Response_Interaction>
                
            </xsl:when>
            <xsl:otherwise>
                <!-- handles the (error and request) soap fault case and request case -->
                <HL7_Response_Interaction xmlns="urn:http://com.eho.hial/TransientData"></HL7_Response_Interaction>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- This template build security context -->
    <xsl:template name="buildSecurityCtx">
        <xsl:if test="dp:variable('var://context/aaa/ur-saml-token') or dp:variable('var://context/aaa/pdp-result')">
            <xsl:variable name="stsSamlToken" select="dp:variable('var://context/aaa/ur-saml-token')//saml:Assertion"/>
            <xsl:variable name="pdpResponse"  select="dp:variable('var://context/aaa/pdp-result')//xacml:Response" />
            
            <xsl:variable name="authorizationResult" select="$pdpResponse/xacml:Result/xacml:Decision/text()"/>            
            <xsl:variable name="obligations">
                <dp:serialize select="$pdpResponse/xacml:Result/xacmlPolicy:Obligations" omit-xml-decl="yes" />
            </xsl:variable>
            <dp:set-variable name="'var://context/logging/obligations'" value="string($obligations)" />
            
            
            <Security_Context xmlns="urn:http://com.eho.hial/TransientData">
                <on_Behalf_Of>not available for R1b</on_Behalf_Of>
                <authentication_Level>placeholder</authentication_Level>
                <authentication_Result>Passed</authentication_Result>
                <authentication_Result_Expiry></authentication_Result_Expiry>
                <!--<authentication_Result_Expiry><xsl:value-of select="$stsSamlToken//saml:Conditions/@NotOnOrAfter"/></authentication_Result_Expiry>-->
                <authorization_Result><xsl:value-of select="$authorizationResult"/></authorization_Result>
                
                <authorization_Result_Expiry></authorization_Result_Expiry>
                <SAML_Token_Issuer><xsl:value-of select="$txnCtx/txnContext/samlAssertionIssuer/text()"/></SAML_Token_Issuer> 
                <authenticated_System>Place Holder</authenticated_System>
                <originating_System><xsl:value-of select="$txnCtx/txnContext/originatingSystem/text()"/></originating_System>
                <under_Authority_Of><xsl:value-of select="$txnCtx/txnContext/samlAssertingParty/text()"/></under_Authority_Of>
                <user_Subject><xsl:value-of select="dp:client-subject-dn()"/></user_Subject>
                <list_Of_Obligations><xsl:value-of select="string($obligations)"/></list_Of_Obligations>
            </Security_Context>
            
        </xsl:if>        
    </xsl:template>

    <!-- Add extensible function -->
    <xsl:template name="getTransientDataMap">
        <xsl:value-of select="string(dp:variable('var://context/hialPEP/transientDataMap'))"/>
    </xsl:template>
    
    <!-- This template build the transient data log entry for transient data logging and FMBL -->
    <xsl:template name="buildTransientDataLogEntry">
        
        <xsl:variable name="templateFileName">
            <xsl:call-template name="getTransientDataMap"/>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="string-length($templateFileName) = 0">
                <xsl:call-template name="buildDefaultTransientDataLogEntry"/>
            </xsl:when>
            <xsl:when test="document($templateFileName)/XMLTemplate">
                <xsl:call-template name="buildTransientDataLogEntryWithTemplate"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="buildDefaultTransientDataLogEntry"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    
    <!-- This template build json message for transient data -->
    <xsl:template name="buildDefaultTransientDataLogEntry" xml:space="default">
        <xsl:variable name="transitData"   select="dp:variable('var://context/logging/transientData')"/>
        <xsl:variable name="root" select="$transitData/*[1]"/>
        <xsl:variable name="rootName" select="local-name($root)"/>
        
        <xsl:variable name="TransientDataJson">
            
            <!-- open tag for TransientData -->
            <xsl:value-of select="concat( $doubleColon, $rootName, $doubleColon , $comma)"/>
            <xsl:value-of select="$leadingBraces"/>
            
            <xsl:for-each select="$root/*">
                
                <xsl:variable name="currentIndex" select="position()"/>
                
                <!-- add a comma if the element is not the first one -->
                <xsl:if test="$currentIndex &gt; 1">
                    <xsl:value-of select="','"/>
                </xsl:if>
                
                <!-- call the template -->
                <xsl:call-template name="bulidContentNodeJsonMsg">
                    <xsl:with-param name="contentNode" select="."/>
                </xsl:call-template>
                
            </xsl:for-each>
            
            <!-- close tag for TransientData  -->
            <xsl:value-of select="$endingBraces"/>
            
        </xsl:variable>
        
        <xsl:value-of select="string($TransientDataJson)"/>
        
    </xsl:template>
    
    
    <xsl:template name="bulidContentNodeJsonMsg">
        <xsl:param name="contentNode"/>
        
        <xsl:variable name="countOfChild" select="count(./*)"/>
        <xsl:variable name="fieldName"  select="local-name()"/>
        
        <xsl:choose>
            <xsl:when test="$countOfChild = 0">
                
                <xsl:variable name="fieldValue">
                    <xsl:choose>
                        <xsl:when test="$fieldName = 'list_Of_Obligations'">                                 
                            <xsl:variable name="doubleQuotes">"</xsl:variable>
                            <xsl:variable name="formattedDoubleQuotes">\"</xsl:variable>                                 
                            <xsl:variable name="formattedObligation" select="regexp:replace(string(./text()), string($doubleQuotes),  'g',  string($formattedDoubleQuotes))"/>
                            <xsl:value-of select="$formattedObligation"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="string(./text())"/>
                        </xsl:otherwise>
                    </xsl:choose>                         
                </xsl:variable>                     
                
                <xsl:value-of select="concat($doubleColon, $fieldName, $doubleColon, $comma, $doubleColon, $fieldValue, $doubleColon)"/>
                
            </xsl:when>
            <xsl:otherwise>
                
                <xsl:value-of select="concat($doubleColon, $fieldName, $doubleColon, $comma)"/>
                <xsl:value-of select="$leadingBraces"/>
                
                <!-- loop each child element -->
                <xsl:for-each select="./*">
                    
                    <xsl:variable name="currentIndex" select="position()"/>
                    
                    <!-- add a comma if the element is not the first one -->
                    <xsl:if test="$currentIndex &gt; 1">
                        <xsl:value-of select="','"/>
                    </xsl:if>
                    
                    <!-- call the template -->
                    <xsl:call-template name="bulidContentNodeJsonMsg">
                        <xsl:with-param name="contentNode" select="."/>
                    </xsl:call-template>
                    
                </xsl:for-each>                     
                
                <xsl:value-of select="$endingBraces"/>
                
            </xsl:otherwise>
        </xsl:choose>        
        
    </xsl:template>
    
    
    
    
    <!-- This template build the transient data log entry for transient data logging and FMBL -->
    <xsl:template name="buildTransientDataLogEntryWithTemplate" xml:space="default">
        
        <xsl:variable name="transitData"   select="dp:variable('var://context/logging/transientData')"/>
        <xsl:variable name="root" select="$transitData/*[1]"/>
        <xsl:variable name="rootName" select="local-name($root)"/>
        
        <!-- loading the template -->
        <xsl:variable name="templateFileName">
            <xsl:call-template name="getTransientDataMap"/>
        </xsl:variable>
        <xsl:variable name="templateNode" select="document($templateFileName)"/>        
        
        <dp:set-variable name="'var://context/A_Debug/Template1'" value="$templateNode"/>
        
        <xsl:variable name="TransientDataJson">
            
            <!-- open tag for TransientData -->
            <xsl:value-of select="concat( $doubleColon, $rootName, $doubleColon , $comma)"/>
            <xsl:value-of select="$leadingBraces"/>
            
            <!-- set a flag for first node -->
            <dp:set-variable name="'var://context/tmp/firstNode'" value="'true'" />
            
            <!-- Loop each level 2 and lower nodes -->
            <xsl:for-each select="$root/*">
                
                <!-- get the first node flag again -->
                <xsl:variable name="firstNodeFlag" select="string(dp:variable('var://context/tmp/firstNode'))"/>
                <xsl:variable name="currentNodeName" select="local-name()"/>
                
                <xsl:if test="$templateNode//*[@name=$currentNodeName]">
                    
                    <!-- add a comma if the element is not the first one -->
                    <xsl:choose>
                        <xsl:when test="$firstNodeFlag = 'true'">
                            <dp:set-variable name="'var://context/tmp/firstNode'" value="'false'" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="','"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                    <!-- call the template -->
                    <xsl:call-template name="bulidContentNodeJsonMsgWithTemplate">
                        <xsl:with-param name="contentNode"   select="."/>
                        <xsl:with-param name="templateMap"  select="$templateNode"/>                            
                    </xsl:call-template>
                    
                </xsl:if>                    
                
            </xsl:for-each>
            
            <!-- close tag for TransientData  -->
            <xsl:value-of select="$endingBraces"/>
            
        </xsl:variable>
        
        <xsl:value-of select="string($TransientDataJson)"/>
        
    </xsl:template>
    
    
    
    <!-- build a content node for transient data with template -->
    <xsl:template name="bulidContentNodeJsonMsgWithTemplate">
        <xsl:param name="contentNode"/>
        <xsl:param name="templateMap"/>
        
        <xsl:variable name="countOfChild" select="count(./*)"/>
        <xsl:variable name="fieldName"  select="local-name()"/>
        
        <xsl:choose>
            
            <!--  for those leaf nodes only-->
            <xsl:when test="$countOfChild = 0">
                
                <xsl:variable name="fieldValue">
                    <xsl:choose>
                        <xsl:when test="$fieldName = 'list_Of_Obligations'">                                 
                            <xsl:variable name="doubleQuotes">"</xsl:variable>
                            <xsl:variable name="formattedDoubleQuotes">\"</xsl:variable>                                 
                            <xsl:variable name="formattedObligation" select="regexp:replace(string(./text()), string($doubleQuotes),  'g',  string($formattedDoubleQuotes))"/>
                            <xsl:value-of select="$formattedObligation"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="string(./text())"/>
                        </xsl:otherwise>
                    </xsl:choose>                         
                </xsl:variable>                     
                
                <xsl:value-of select="concat($doubleColon, $fieldName, $doubleColon, $comma, $doubleColon, $fieldValue, $doubleColon)"/>
                
            </xsl:when>
            
            <!-- This is for non-leaf node, it handles the comma -->
            <xsl:otherwise>
                
                <xsl:value-of select="concat($doubleColon, $fieldName, $doubleColon, $comma)"/>
                <xsl:value-of select="$leadingBraces"/>
                
                <xsl:variable name="firstNodeVariableName" select="concat('var://context/logging/', $fieldName, 'FirstFlag')"/>
                <dp:set-variable name="$firstNodeVariableName" value="'true'" />
                
                <!-- loop each child element -->
                <xsl:for-each select="./*">
                    
                    <xsl:variable name="firstNodeFlag" select="dp:variable($firstNodeVariableName)"/>                    
                    <xsl:variable name="currentNodeName" select=" local-name()"/>
                    
                    <xsl:if test="$templateMap//*[@name=$currentNodeName] or $templateMap//FieldName[text()=$currentNodeName]">
                        
                        <xsl:choose>
                            <xsl:when test="$firstNodeFlag = 'true'">
                                <dp:set-variable name="$firstNodeVariableName" value="'false'" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="','"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        
                        <!-- call the template -->
                        <xsl:call-template name="bulidContentNodeJsonMsgWithTemplate">
                            <xsl:with-param name="contentNode"  select="."/>
                            <xsl:with-param name="templateMap" select="$templateMap"/>
                        </xsl:call-template>
                        
                    </xsl:if>
                    
                </xsl:for-each>                     
                
                <xsl:value-of select="$endingBraces"/>
                
            </xsl:otherwise>
        </xsl:choose>        
        
    </xsl:template>
    
    <!-- This template format the time Stamp -->
    <xsl:template name="getFormattedGMT">
        <xsl:variable name="timeStamp" select="number(dp:time-value())"/>
        <xsl:variable name="millionSeconds" select="substring($timeStamp, 11, 3)"/>
        <xsl:variable name="utcTimeStamp" select="concat(substring(dpfunc:zulu-time(), 1, 19), '.',$millionSeconds)"/>
        <xsl:value-of select="regexp:replace(string($utcTimeStamp), 'T', 'g', ' ')"/>        
    </xsl:template>
    
    <!-- This template will replace the T in the GMT to a space ' '-->
    <xsl:template name="reformatGmtForRsyslog">
        <xsl:param name="gmtTime"/>
        <xsl:choose>
            <xsl:when test="contains($gmtTime, 'T')">
                <xsl:value-of select="regexp:replace(string($gmtTime), 'T', 'g', ' ')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$gmtTime"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>
