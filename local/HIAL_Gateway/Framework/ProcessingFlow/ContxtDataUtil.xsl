<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>ContxtDataUtil.xsl</Filename>
<revisionlog>v2.2.0</revisionlog>
<Description>
  This is the common PEP logic
</Description>
<Owner>eHealthOntario</Owner>
<LastUpdate>
Jan 28, 2017 - WSA updates
Dec 8 , 2017 - Group policy write flush to transient data was incorrect, did not flush group policies.
Dec 6 , 2017 - Group lookup is based on DN and not CN now , there can be many CN with the same name
Nov 21, 2017 - updated group support
May 29, 2017 - added transientDataServiceName field to in memory transient data context, to support
               differences between soap and fhir.
August 18, 2016 - Fix for FMBL on Message adapters</LastUpdate>
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
    xmlns:dpconfig="http://www.datapower.com/param/config" 
    xmlns:dpfunc="http://www.datapower.com/extensions/functions"
    xmlns:wsmp="http://www.ibm.com/xmlns/stdwip/2011/02/ws-mediation"
    xmlns:hiallib="http://www.ehealthontario.on.ca/hial/lib"
    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" 
    xmlns:regexp="http://exslt.org/regular-expressions"
    xmlns:hial="http://ehealthontario.on.ca/xmlns/2015/HIAL"
    xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing"
    exclude-result-prefixes="xsl exslt dp dpfunc date dpwsm dpconfig wsmp hiallib saml regexp hial wsa"
    extension-element-prefixes="dp" 
    version="1.0">
    
    <xsl:include href="store:///utilities.xsl"/>
    <xsl:include href="local:Framework/Lib/Log4GateWay.xsl" />
    <xsl:import href="WsrrUtil.xsl"/>
    <xsl:import href="ValidateWSA.xsl"/>
    
    <xsl:variable name="cachePath" select="document('Config/Config.xml')/Config/CachePath/text()"/>
    
    <!-- This template will load the SLA context into memory -->    
    <xsl:template name="loadSLAContext">
        
        <xsl:variable name="slaPath" select="document('Config/Config.xml')/Config/CachePath/text()"/>        
        <xsl:variable name="wspName"     select="dp:variable('var://service/processor-name')"/>
        <xsl:variable name="initContext" select="dp:variable('var://context/hialPEP/txnContext')"/>
        <xsl:variable name="groupId">
            <xsl:call-template name="creaetGroupIdName">
                <xsl:with-param name="dn" select="string($initContext/txnContext/clientSubjectDn/text())"/>
                <xsl:with-param name="serviceName" select="string($initContext/txnContext/serviceName/text())"></xsl:with-param>
            </xsl:call-template>    
        </xsl:variable>
        
        <xsl:variable name="cnBasedSlaFile"      select="concat($slaPath, $initContext/txnContext/clientCommonName/text(), '_', $initContext/txnContext/wsdlName/text(), '_STD.xml')"/>
        <xsl:variable name="groupIdBasedSlaFile" select="concat($slaPath, $groupId, '_', $initContext/txnContext/wsdlName/text(), '_STD.xml')"/>
        <xsl:variable name="wsdlBasedSlaFile" select="concat($slaPath, $initContext/txnContext/wsdlName/text(), '_STD.xml')"/>        
        
        <dp:set-variable name="'var://context/debug/groupFile'"   value="$groupIdBasedSlaFile"/>     
        <xsl:variable name="cnPolicy"      select="document($cnBasedSlaFile)"/>
        <xsl:variable name="groupPolicy"   select="document($groupIdBasedSlaFile)"/>
        <xsl:variable name="defaultPolicy" select="document($wsdlBasedSlaFile)"/>
        
        <dp:set-variable name="'var://context/hialPEP/cnPolicy'"      value="$cnPolicy"/>
        <dp:set-variable name="'var://context/hialPEP/groupPolicy'"   value="$groupPolicy"/>        
        <dp:set-variable name="'var://context/hialPEP/defaultPolicy'" value="$defaultPolicy"/>
        
        <xsl:choose>
            <xsl:when test="$cnPolicy/SLA or $groupPolicy/SLA or $defaultPolicy/SLA ">
            </xsl:when>
            <xsl:otherwise>
                <dp:set-variable name="'var://context/hialPEP/slaPolicyStatus'" value="'Not Found'" />
                <xsl:variable name="logContent" 
                    select="concat('can not found cached SLA policy for service', dp:variable('var://service/wsm/service'),'. The following sla not present: ', $cnBasedSlaFile, ', ', $groupIdBasedSlaFile, ', ', $wsdlBasedSlaFile)"/>
                <xsl:call-template name="logInitEvent">
                    <xsl:with-param name="logLevel"   select="'error'"/>
                    <xsl:with-param name="errorCode"  select="dp:variable('var://service/error-code')"/>
                    <xsl:with-param name="logContent" select="$logContent"/>
                </xsl:call-template>
                <dp:reject>
                    <xsl:value-of select="$logContent"/>
                </dp:reject>
            </xsl:otherwise>
        </xsl:choose>
        
        
        <xsl:for-each select="exslt:node-set($defaultPolicy)//PolicyName">
            <xsl:variable name="policyPrefix" select="substring-before(./text(),'_')"/>
            
            <xsl:variable name="highPriorityPolicy">
                <xsl:choose>
                    <xsl:when test="$cnPolicy//PolicyName[starts-with(text(), $policyPrefix)]">
                        <xsl:value-of select="$cnPolicy//PolicyName[starts-with(text(), $policyPrefix)]/text()"/>
                    </xsl:when>
                    <xsl:when test="$groupPolicy//PolicyName[starts-with(text(), $policyPrefix)]">
                        <xsl:value-of select="$groupPolicy//PolicyName[starts-with(text(), $policyPrefix)]/text()"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="./text()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:variable name="initLoadedPolicies">
                <AllPolicies>                
                    <xsl:copy-of select="dp:variable('var://context/logging/parsedSlaPolicies')/AllPolicies/*"/>                
                    <Policy_And_Rules xmlns="urn:http://com.eho.hial/TransientData">
                        <policy_Name><xsl:value-of select="$highPriorityPolicy"/></policy_Name>
                        <policy_Type><!--xsl:value-of select="'WS Mediation Policy'"/--></policy_Type>
                        <rule_Response/>
                    </Policy_And_Rules>                
                </AllPolicies>
            </xsl:variable>
            <dp:set-variable name="'var://context/logging/parsedSlaPolicies'" value="$initLoadedPolicies"/>
            
        </xsl:for-each>
        
        <!-- below on each step update the wsa context -->
        <!-- Basic WSA-Validation -->
        <xsl:call-template name="validateBasicWSA">
            <xsl:with-param name="input" select="."/> <!-- current node sent -->
        </xsl:call-template>
        <!-- WSA-Action Validation awnd setup of response action -->
        <xsl:variable name="wsdlName">
            <xsl:call-template name="queryWsdlName"/>
        </xsl:variable>
        <xsl:variable name="wsdlDefinitionFileName" select="concat($cachePath, $wsdlName, 'Definition.xml')"/>
        <xsl:variable name="wsdlInfo" select="document($wsdlDefinitionFileName)"/>
        
        
        <xsl:variable name="wsaResponseAction">
        <xsl:call-template name="getWSAResponseAction">
            <xsl:with-param name="wsdlInfo" select="$wsdlInfo"/>
            <xsl:with-param name="input" select="."/>
        </xsl:call-template>
        </xsl:variable>
        
        
        <xsl:variable name="wsaContext">
            <ws-addressing>
            <xsl:copy-of select="/*[local-name()='Envelope']/*[local-name()='Header']/*[namespace-uri() = 'http://schemas.xmlsoap.org/ws/2004/08/addressing']"/>
                <response>
                    <xsl:if test="string-length($wsaResponseAction) &gt; 0">
                    <wsa:Action><xsl:value-of select="$wsaResponseAction"/></wsa:Action>
                    </xsl:if>
                </response>
            </ws-addressing>
            
        </xsl:variable>
        
        <!--xsl:copy-of select="dp:variable('var://context/wsa/info')"/-->
        <dp:set-variable name="'var://context/wsa/test'" value="$wsaContext"/>        
    </xsl:template>
    
    <!-- -->
    <xsl:template name="creaetGroupIdName">
        <xsl:param name="dn"/>
        <xsl:param name="serviceName"/>
        <!-- Updated to support groups-->
        <xsl:variable name="groupIdMapper" select="concat($cachePath, 'SlaGroupIdMapper.xml')"/>
    
        <xsl:value-of select="document($groupIdMapper)/SLAGroups/Service[@name=$serviceName]/SLAGroup/CN[text()=$dn]/../@name"/>
            
    </xsl:template>
    
    <!-- 
        The below template load initial context from runtime environment    
        SrcSys=/DC=ssh/DC=subscribers/OU=Subscribers/OU=eHealthUsers/OU=Applications/CN=BLUEWATERHEALTH.NODE1 
    -->
    <xsl:template name="loadInitContext">
        
        <!--  parse the external transaction ID sent from HIAL front side adapters -->
        <xsl:variable name="extTxnId" select="string(/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='TransientData']/*[local-name()='Transaction_Flow']/*[local-name()='eHealth_Transaction_ID']/text() | /*[local-name()='Envelope']/*[local-name()='Header']/hial:HIALContext/hial:TxnID/text() )"/>
        <xsl:variable name="globalTxnId">
            <xsl:choose>
                <xsl:when test="string-length($extTxnId) &gt; 0">
                    <xsl:value-of select="$extTxnId"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="dp:generate-uuid()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <dp:set-variable name="'var://context/logging/globalTxnId'" value="string($globalTxnId)"/>
        
        <!--  parse the initial sequence number sent from HIAL front side adapters -->
        <xsl:variable name="initseqs" select="string(/*[local-name()='Envelope']/*[local-name()='Header']/hial:HIALContext/hial:Seq/text())"/>
        <xsl:if test="( string-length($initseqs) &gt; 0 ) and (string(number($initseqs)) != 'NaN')">
            <xsl:variable name="nextSeq" select=" number($initseqs) + 1"/>
            <dp:set-variable name="'var://context/logging/seq'" value="string($nextSeq)"/>
        </xsl:if>
        
        <xsl:variable name="globalIdAssigner">
            <xsl:choose>
                <xsl:when test="string-length($extTxnId) &gt; 0">
                    <xsl:value-of select="'Adapter'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'Gateway'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>        
        
        <xsl:variable name="protocol" select="dp:variable('var://service/protocol')"/>
        <xsl:variable name="samlAssertionIssuer" select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='Security']/*[local-name()='Assertion']/*[local-name()='Issuer']/text()"/>
        <xsl:variable name="samlAssertingParty"  select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='Security']/*[local-name()='Assertion']/*[local-name()='AuthnStatement']/*[local-name()='AuthnContext']/*[local-name()='AuthnContextDecl']/*[local-name()='AuthnMethod']/*[local-name()='Extension']/*[local-name()='AssertingParty']/*[local-name()='AuthenticatingAuthority']/text()"/>
        <xsl:variable name="samlAssertionUao"    select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='Security']/*[local-name()='Assertion']/*[local-name()='AttributeStatement']/*[local-name()='Attribute' and @Name='urn:ehealth:names:idm:attribute:uao']/*[local-name()='AttributeValue']/text()" />
        <xsl:variable name="samlSubjectNameId"   select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='Security']/*[local-name()='Assertion']/*[local-name()='Subject']/*[local-name()='NameID']/text()"/>
        
        <!-- query WSRR to retrieve the WSDL name -->
        <xsl:variable name="wsdlName">
            <xsl:call-template name="queryWsdlName"/>
        </xsl:variable>
        <xsl:variable name="wsdlVersion">
            <xsl:value-of select="dp:variable('var://context/logging/wsdlVersion')"/>
        </xsl:variable>        
        <!-- query WSRR to retrieve the service end point information -->
        <xsl:variable name="currentFlow" select="dp:variable('var://service/transaction-rule-type')"/>
        <xsl:if test="$currentFlow = 'request'">
            <xsl:variable name="response">
                <xsl:call-template name="queryWsrrMetaData">
                    <xsl:with-param name="resourceType"   select="'serviceEndPoint'"/>
                    <xsl:with-param name="queryParameter" select="concat($wsdlName, '_HIB_EP')" />
                    <xsl:with-param name="queryPurpose"   select="'query backbone service endpoint url'"/>
                </xsl:call-template>
            </xsl:variable>            
            <dp:set-variable name="'var://context/WsrrEndPointResult'" value="$response//url-open/response"/>
        </xsl:if>
        
        <!-- load service name -->
        <xsl:variable name="dpServiceName" select="dp:variable('var://service/wsm/service')"/>
        <xsl:variable name="serviceName">
            <xsl:choose>
                <xsl:when test="starts-with($dpServiceName,'{')">
                    <xsl:value-of select="substring-after($dpServiceName, '}')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$dpServiceName"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
 
        <!-- load operation name and then load WSDL attached Policies -->
        <xsl:variable name="dpOperation" select="dp:variable('var://service/wsm/operation')"/>
        <xsl:variable name="operation">
            <xsl:choose>
                <xsl:when test="starts-with($dpOperation,'{')">
                    <xsl:value-of select="substring-after($dpOperation, '}')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$dpOperation"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="wsdlPolicyFileName" select="concat($cachePath, $wsdlName, '.xml')"/>
        <xsl:variable name="wsdlPolicies" select="document($wsdlPolicyFileName)"/>
        <dp:set-variable name="'var://context/logging/wsdlPolicyFlieStatus'" value="$wsdlPolicies"/>
        
        <xsl:if test="$wsdlPolicies/*">
            <!-- Todo: Add the WS-Action details into context -->
            <xsl:variable name="wsdlOperation" select="$wsdlPolicies/Wsdl/Operations/Operation[Name = $operation]"/>
            <dp:set-variable name="'var://context/logging/wsdlOperationResult'" value="$wsdlOperation"/>
            
            <xsl:for-each select="exslt:node-set($wsdlOperation)/Policies/*[local-name()='Policy']">
                
                <xsl:variable name="thePolicyName" select="./text()"/>                
                <xsl:variable name="attachedPolicy">
                    <AllAttachedPolicies>
                        <xsl:copy-of select="dp:variable('var://context/logging/attachedPolicies')/AllAttachedPolicies/*"/>                
                        <Policy_And_Rules xmlns="urn:http://com.eho.hial/TransientData">
                            <policy_Name><xsl:value-of select="$thePolicyName"/></policy_Name>
                            <policy_Type></policy_Type>
                            <rule_Response/>
                        </Policy_And_Rules>                
                    </AllAttachedPolicies>
                </xsl:variable>
                
                <dp:set-variable name="'var://context/logging/attachedPolicies'" value="$attachedPolicy"/>                
                
            </xsl:for-each>
        </xsl:if>        
                
        <!-- Build the transaction context -->
        <xsl:variable name="context">
            <txnContext>

                <soapNameSpace>
                    <xsl:value-of select="namespace-uri(/*)"/>
                </soapNameSpace>
                
                <consumerMessageID>
                    <xsl:value-of select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='MessageID']/text()"/>
                </consumerMessageID>
                
                <xsl:variable name="timeStamp" select="number(dp:time-value())"/>
                <startTimeStamp><xsl:value-of select="$timeStamp"/></startTimeStamp>
                <!--  retrieve the gateway startup time, either from the adapter or from WSP itself -->
                <xsl:variable name="extGatewayStartTime" select="string(/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='TransientData']/*[local-name()='Transaction_Flow']/*[local-name()='gateway_Start_Time']/text())"/>
	            <xsl:choose>
	                <xsl:when test="string-length($extGatewayStartTime) &gt; 0">
		                    <gatewayStartTime><xsl:value-of select="$extGatewayStartTime"/></gatewayStartTime>
	                        <disableGatewayEndTime>true</disableGatewayEndTime>
	                </xsl:when>
	                <xsl:otherwise>
                            <gatewayStartTime><xsl:call-template name="getFormattedGMT"/></gatewayStartTime>
	                </xsl:otherwise>
	            </xsl:choose>
                <gatewayStartTime2>
                    <xsl:value-of select="substring(date:date-time(), 1, 19)"/>
                </gatewayStartTime2>
                <gatewayStartTimeFMBL>
                    <xsl:call-template name="getFormattedGMT"/>
                </gatewayStartTimeFMBL>
                <globalID>
                     <xsl:value-of select="$globalTxnId"/>
                </globalID>           
                <globalIDAssigner>
                     <xsl:value-of select="$globalIdAssigner"/>
                </globalIDAssigner>     
                
                <messageID>
                    <xsl:value-of select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='MessageID']/text()"/>
                </messageID>
                
                <samlAssertingParty>
                    <xsl:value-of select="$samlAssertingParty"/>
                </samlAssertingParty>
                <samlAssertionIssuer>
                    <xsl:value-of select="$samlAssertionIssuer"/>
                </samlAssertionIssuer>
                <samlAssertionUao>
                    <xsl:value-of select="$samlAssertionUao"/>
                </samlAssertionUao>
                <samlSubjectNameId>
                    <xsl:value-of select="$samlSubjectNameId"/>
                </samlSubjectNameId>
                
                
                <protocol>
                    <xsl:value-of select="$protocol"/>
                </protocol>    
                
                <xsl:variable name="consumerSystem" select="string(/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='TransientData']/*[local-name()='Transaction_Flow']/*[local-name()='consumer_System']/text() | /*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='HIALContext']/*[local-name()='ConsumerData']/*[local-name()='ConsumerSystem']/text())"/>
                <consumerSystem>
                    <xsl:value-of select="$consumerSystem"/>
                </consumerSystem>
                
                <xsl:choose>
                    <xsl:when test="$protocol = 'https'">
                        <xsl:variable name="subjectDN"  select="dp:client-subject-dn()"/>
                        <xsl:variable name="commonName" select="substring-after($subjectDN,'CN=')"/>
                        <clientSubjectDn>
                            <xsl:value-of select="$subjectDN"/>
                        </clientSubjectDn>
                        <clientCommonName>
                            <xsl:value-of select="$commonName"/>
                        </clientCommonName>                        
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="string-length($consumerSystem) &gt; 0 ">
                            <xsl:variable name="commonName" select="substring-before(substring-after($consumerSystem,'CN='), ',')"/>
                            <clientCommonName>
                                <xsl:value-of select="$commonName"/>
                            </clientCommonName>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>             
                
                <originatingSystem>
                    <xsl:choose>
                        <xsl:when test="$protocol = 'https'">
                            <xsl:value-of select="dp:client-subject-dn()"/>
                        </xsl:when>
                        <xsl:when test="string-length($consumerSystem) &gt; 0">
                            <xsl:value-of select="$consumerSystem"/>
                        </xsl:when>
                        <xsl:otherwise></xsl:otherwise>
                    </xsl:choose>
                </originatingSystem>
                
                <consumerOrganization>
                    <xsl:value-of select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='TransientData']/*[local-name()='Transaction_Flow']/*[local-name()='consumer_Organization']/text()"/>
                </consumerOrganization>
                
                <responseDeliveryEndPoint>wsa:anonymous</responseDeliveryEndPoint>
                
                <serviceName>
                    <xsl:value-of select="$serviceName"/>
                </serviceName>
                
                <transientDataServiceName>
                    <xsl:value-of select="$wsdlName"/>
                </transientDataServiceName>
                
                <operation>
                     <xsl:value-of select="$operation"/> 
                </operation>
                
                <webserviceProxy>
                    <xsl:value-of select="dp:variable('var://service/processor-name')"/>
                </webserviceProxy>
                
                <wsdlName>
                    <xsl:value-of select="$wsdlName"/>
                </wsdlName>
                <wsdlVersion>
                    <xsl:value-of select="$wsdlVersion"/>
                </wsdlVersion>
                
            </txnContext>
        </xsl:variable>
        
        <xsl:copy-of select="$context"/>
    </xsl:template>
    
    <!-- This template query the WSDL information from WSRR service -->
    <xsl:template name="queryWsdlName">
        <xsl:variable name="schemaLocation" select="dp:variable('var://service/wsm/schemalocation')"/>
        <xsl:choose>
            <xsl:when test="starts-with($schemaLocation,'wsrr')">
                <xsl:variable name="bsrUriParameter" select="concat(dp:variable('var://service/wsm/wsdl'),'/properties')"/>
                <xsl:variable name="wsrrResponse">
                    <xsl:call-template name="queryWsrrMetaData">
                        <xsl:with-param name="resourceType"   select="'wsdlMetaData'"/>
                        <xsl:with-param name="queryParameter" select="$bsrUriParameter"/>
                        <xsl:with-param name="queryPurpose"   select="' query the WSDL name'"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <xsl:variable name="wsdlPropertyValue" select="$wsrrResponse//properties/property[@name='name']/@value"/>
                <xsl:variable name="wsdlVersion" select="$wsrrResponse//properties/property[@name='version']/@value"/>
                <dp:set-variable name="'var://context/logging/wsdlVersion'" value='string($wsdlVersion)' />
                <xsl:value-of select="substring-before($wsdlPropertyValue,'.wsdl')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="dp:variable('var://service/wsm/wsdl')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- simplified logging method -->
    <xsl:template name="logInitEvent">
        <xsl:param name="logLevel"/>
        <xsl:param name="errorCode"/>
        <xsl:param name="logContent"/> 
        
        <xsl:variable name="txnContext" select="dp:variable('var://context/hialPEP/txnContext')"/>        
        
        <xsl:call-template name="hiallib:logEvent">
            <xsl:with-param name="logLevel" select="$logLevel"/>
            <xsl:with-param name="errorCode" select="$errorCode"/>
            <xsl:with-param name="facility" select="'TRN'"/>
            <xsl:with-param name="logGroup" select="'EHF'"/>
            <xsl:with-param name="activity" select="'GIN'"/>
            <xsl:with-param name="transactionId" select="$txnContext/txnContext/globalID/text()"/>
            <xsl:with-param name="logContent" select="$logContent"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- This template format the time Stamp -->
    <xsl:template name="getFormattedGMT">
        <xsl:variable name="timeStamp" select="number(dp:time-value())"/>
        <xsl:variable name="millionSeconds" select="substring($timeStamp, 11, 3)"/>
        <xsl:variable name="utcTimeStamp" select="concat(substring(dpfunc:zulu-time(), 1, 19), '.',$millionSeconds)"/>
        <xsl:value-of select="regexp:replace(string($utcTimeStamp), 'T', 'g', ' ')"/>        
    </xsl:template>
    
    
</xsl:stylesheet>