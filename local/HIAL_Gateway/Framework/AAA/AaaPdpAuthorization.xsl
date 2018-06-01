<?xml version="1.0" encoding="UTF-8"?>
<!-- Change Log: Oct 19 2015 : 6617 added AAA Business event logging 
    May 25-2016: Added the organization Id attribute for CDR Data In 
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:soap12="http://www.w3.org/2003/05/soap-envelope/"
    xmlns:sts="http://fault.sts.ur.idm.ehealth.gov.on.ca/"
    xmlns:wss="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
    xmlns:wst="http://docs.oasis-open.org/ws-sx/ws-trust/200512/"
    xmlns:xacml="urn:oasis:names:tc:xacml:2.0:context:schema:os"
    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" xmlns:ac="urn:oasis:names:tc:SAML:2.0:ac"
    xmlns:ssm="http://security.bea.com/ssmws/ssm-soap-types-1.0.xsd"
    xmlns:ehoext="urn:ehealth:names:idm:ac:extension" xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpfunc="http://www.datapower.com/extensions/functions"
    xmlns:str="http://exslt.org/strings" xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="dp"
    exclude-result-prefixes="xsl soap sts wss wst xacml saml ac ssm ehoext dpfunc str date dp">
    
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    <xsl:include href="AaaCommonLibrary.xsl"/>
    
    <xsl:variable name="webServiceAlias" select="dp:variable('var://context/aaa/web_service_alias')"/>
    <xsl:variable name="operationAlias" select="dp:variable('var://context/aaa/operation_alias')"/>
    <xsl:variable name="wsmOperation" select="dp:variable('var://service/wsm/operation')"/>
    <xsl:variable name="fullQulifiedDomainName" select="dp:variable('var://context/log/subjectDN')"/>
    <xsl:variable name="txnCtx" select="dp:variable('var://context/hialPEP/txnContext')"/>     
    
    <!-- This is the main template -->
    <xsl:template match="/">
        
        
        
        <xsl:variable name="busStartTime">
            <xsl:call-template name="logAAABusEvent">
                <xsl:with-param name="authentication" select="false()"/>
            </xsl:call-template>
        </xsl:variable>
        
        
        <xsl:variable name="pdpResponse">
            <xsl:call-template name="checkPdp"/>
        </xsl:variable>
        <xsl:variable name="decision">
            <xsl:choose>
                <xsl:when test="$pdpResponse != &apos;&apos;">
                    <dp:set-variable name="'var://context/aaa/error-message'"
                        value="string($pdpResponse)"/>
                    <xsl:call-template name="logError">
                        <xsl:with-param name="error" select="$pdpResponse"/>
                    </xsl:call-template>
                    <declined/>
                </xsl:when>
                
                <xsl:otherwise>
                    <approved/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:call-template name="logAAABusResultEvent">
            <xsl:with-param name="authentication" select="false()"/>
            <xsl:with-param name="startTime" select="$busStartTime"/>
            <xsl:with-param name="passed" select="count($decision/approved) &gt; 0"/>
        </xsl:call-template>
        
        <xsl:copy-of select="$decision"/>
    </xsl:template>
    
    <!-- This template calls the PDP and returns the status -->
    <xsl:template name="checkPdp">
        
        <xsl:variable name="urConfig" select="dp:variable('var://context/aaa/ur-config')"/>
        <xsl:variable name="pdpUrl" select="$urConfig/pdp-url"/>
        <xsl:variable name="timeoutConfig" select="dp:variable('var://context/aaa/timeout-config')"/>
        <xsl:variable name="pdpTimeout" select="$timeoutConfig/pdp"/>
        
        <xsl:variable name="pdpRequest">
            <xsl:call-template name="createPdpRequest"/>
        </xsl:variable>
        <dp:set-variable name="'var://context/aaa/pdp-request'" value="$pdpRequest"/>
        
        <xsl:variable name="serialPdpRequest">
            <dp:serialize select="$pdpRequest" omit-xml-decl="yes"/>
        </xsl:variable>
        
        <xsl:variable name="headerValues">
            <header name="x-dp-cache-key">
                <xsl:value-of
                    select="dp:hash('http://www.w3.org/2000/09/xmldsig#sha1', $serialPdpRequest)"/>
            </header>
            <header name="TID">
                <xsl:value-of select="dp:variable('var://context/log/transactionID')"/>
            </header>
            <header name="SDN">
                <xsl:value-of select="dp:variable('var://context/log/subjectDN')"/>
            </header>
        </xsl:variable>
        
        <xsl:variable name="pdpCallStartTimeStamp">
            <xsl:call-template name="getCurrentDateTime"/>
        </xsl:variable>
        
        <!-- Logging of AAA business activity - beginning of calls to UR PDP -->
        <xsl:call-template name="logAAAEvent">
            <xsl:with-param name="startTime" select="$pdpCallStartTimeStamp"/>
            <xsl:with-param name="logContent" select="'UR-PDP call begin'"/>
        </xsl:call-template>
        
        <!-- call PDP here -->
        <xsl:variable name="pdpResult">
            <dp:url-open target="{$pdpUrl}" http-headers="$headerValues" response="responsecode"
                http-method="post" timeout="{$pdpTimeout}">
                <xsl:copy-of select="$pdpRequest"/>
            </dp:url-open>
        </xsl:variable>
        
        <xsl:variable name="pdpCallEndTimeStamp">
            <xsl:call-template name="getCurrentDateTime"/>
        </xsl:variable>
        
        <xsl:variable name="pdpCacheAge" select="$pdpResult/url-open/headers/header[@name='Age']"/>
        <dp:set-variable name="'var://context/aaa/pdp-cache-age'" value="$pdpCacheAge"/>
        <xsl:message dp:type="aaa" dp:priority="debug">
            <xsl:value-of select="concat(&apos;pdp-cache-age: &apos;, $pdpCacheAge)"/>
        </xsl:message>
        
        <xsl:variable name="pdpResultResponse" select="$pdpResult/url-open/response"/>
        <dp:set-variable name="'var://context/aaa/pdp-result'" value="$pdpResultResponse"/>
        
        <xsl:variable name="pdpErrorResponse">
            <xsl:choose>
                <xsl:when test="not($pdpResultResponse) or $pdpResultResponse = &apos;&apos;">
                    <xsl:value-of
                        select="concat(&apos; pdp-url-open: Remote error on url &apos;, $pdpUrl)"/>
                </xsl:when>
                
                <xsl:when test="$pdpResultResponse/soap:Envelope/soap:Body/soap:Fault">
                    <xsl:value-of
                        select="concat(&apos;From UR-PDP:&apos;, $pdpResultResponse/soap:Envelope/soap:Body/soap:Fault/faultcode, &apos;-&apos;, $pdpResultResponse/soap:Envelope/soap:Body/soap:Fault/faultstring)"
                    />
                </xsl:when>
                
                <xsl:when
                    test="$pdpResultResponse/soap:Envelope/soap:Body/wst:RequestSecurityTokenResponse/sts:FaultToken">
                    <xsl:value-of
                        select="concat(&apos;From UR-PDP:&apos;, $pdpResultResponse/soap:Envelope/soap:Body/wst:RequestSecurityTokenResponse/sts:FaultToken/sts:fault/sts:code, &apos;-&apos;, $pdpResultResponse/soap:Envelope/soap:Body/wst:RequestSecurityTokenResponse/sts:FaultToken/sts:fault/sts:messageEn)"
                    />
                </xsl:when>
                
                <xsl:when test="$pdpResultResponse/soap:Envelope/soap:Body/ssm:serviceFailure">
                    <xsl:value-of
                        select="concat(&apos;From UR-PDP:&apos;, $pdpResultResponse/soap:Envelope/soap:Body/ssm:serviceFailure)"
                    />
                </xsl:when>
                
                <xsl:when
                    test="$pdpResultResponse/soap:Envelope/soap:Body/xacml:Response/xacml:Result/xacml:Decision[.='Deny']">
                    <xsl:value-of select="'From UR-PDP: access denied.'"/>
                </xsl:when>
                
                <xsl:otherwise>
                    <xsl:value-of select="&apos;&apos;"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="logContent">
            <xsl:choose>
                <xsl:when test="$pdpErrorResponse != &apos;&apos;">
                    <xsl:value-of select="$pdpErrorResponse"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'UR-PDP call completed successfully'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- Logging of AAA business activity - end of calls to UR PDP -->
        <xsl:call-template name="logAAAEvent">
            <xsl:with-param name="startTime" select="$pdpCallStartTimeStamp"/>
            <xsl:with-param name="endTime" select="$pdpCallEndTimeStamp"/>
            <xsl:with-param name="logContent" select="$logContent"/>
        </xsl:call-template>
        
        <xsl:value-of select="$pdpErrorResponse"/>
    </xsl:template>
    
    <!-- This template creates a PDP request -->
    <xsl:template name="createPdpRequest">
        <!-- Soap message of PDP request -->
        <soap:Envelope>
            <soap:Body>
                <xacml:Request>
                    <!-- append a special subject according to DII specification -->
                    <xacml:Subject>
                        <xacml:Attribute
                            AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id"
                            DataType="PlainTextIdentityAsserter">
                            <xacml:AttributeValue>
                                <plaintext>
                                    <xsl:choose>
                                        <xsl:when test="string-length($fullQulifiedDomainName) > 0">
                                            <xsl:value-of select="$fullQulifiedDomainName"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="string(dp:variable('var://context/aaa/ConsumerSystem'))"/>
                                            
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </plaintext>
                            </xacml:AttributeValue>
                        </xacml:Attribute>
						<!-- Include UPI in UAO attribute if available in context. Set UAO type to "org" -->
                        <xacml:Attribute AttributeId="urn:ehealth:names:idm:attribute:uao"
                            DataType="xsd:string">
							<xsl:choose>
							    <xsl:when test="dp:variable('var://context/aaa/srcUpi')">
									<xacml:AttributeValue><xsl:value-of select="dp:variable('var://context/aaa/srcUpi')"/></xacml:AttributeValue>
								</xsl:when>
								<xsl:otherwise>
								    <xacml:AttributeValue/>
								</xsl:otherwise>
							</xsl:choose> 
                        </xacml:Attribute>
                        <xacml:Attribute AttributeId="urn:ehealth:names:idm:attribute:uaoType"
                            DataType="xsd:string">
							<xsl:choose>
							    <xsl:when test="dp:variable('var://context/aaa/srcUpi')">
									<xacml:AttributeValue>org</xacml:AttributeValue>
								</xsl:when>
								<xsl:otherwise>
								    <xacml:AttributeValue/>
								</xsl:otherwise>
							</xsl:choose> 
                        </xacml:Attribute>
                        
                        
                        <xacml:Attribute AttributeId="urn:ehealth:names:idm:attribute:calling-ssid"
                            DataType="xsd:string">
                            <xacml:AttributeValue>
                                <xsl:choose>
                                    <xsl:when test="string-length($fullQulifiedDomainName) > 0">
                                        <xsl:value-of select="$fullQulifiedDomainName"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="string(dp:variable('var://context/aaa/ConsumerSystem'))"/>
                                        
                                    </xsl:otherwise>
                                </xsl:choose>  
                                
                            </xacml:AttributeValue>
                        </xacml:Attribute>
                        <!-- May 25-2016 Added this code to accommodate CDR Data In -->
                        
                        <xsl:if test="string-length($txnCtx/txnContext/consumerOrganization/text()) &gt; 0" >
                            <xacml:Attribute AttributeId="urn:ehealth:names:idm:attribute:organization-oid" DataType="xsd:string">
                                <xacml:AttributeValue>
                                    <xsl:value-of select="$txnCtx/txnContext/consumerOrganization/text()"/>
                                </xacml:AttributeValue>
                            </xacml:Attribute> 
                        </xsl:if>
                        <!--end of added code -->
                    </xacml:Subject>
                    <!-- define the resource by using web-service alias name -->
                    <xacml:Resource>
                        <xacml:Attribute
                            AttributeId="urn:oasis:names:tc:xacml:2.0:resource:resource-id"
                            DataType="xsd:string">
                            <xacml:AttributeValue>
                                <xsl:value-of select="$webServiceAlias"/>
                            </xacml:AttributeValue>
                        </xacml:Attribute>
                    </xacml:Resource>
                    
                    <!-- define the action(operation alias) -->
                    <xacml:Action>
                        <xacml:Attribute AttributeId="urn:oasis:names:tc:xacml:1.0:action:action-id"
                            DataType="xsd:string">
                            <xacml:AttributeValue>
                                <xsl:value-of select="$operationAlias"/>
                            </xacml:AttributeValue>
                        </xacml:Attribute>
                    </xacml:Action>
                    
                    <!-- empty environment element -->
                    <xacml:Environment/>
                </xacml:Request>
            </soap:Body>
        </soap:Envelope>
    </xsl:template>
    
    <!-- This template logs the error message in the service variable -->
    <xsl:template name="logError">
        <xsl:param name="error" select="dp:variable('var://service/error-message')"/>
    </xsl:template>
    
</xsl:stylesheet>
