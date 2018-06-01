<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>AaaTwoPdpAuthorization.xsl</Filename>
<revisionlog>
Aug 25, Initial Version
Oct 21, 6617 - Added Business Events Logging for Start and Result
</revisionlog>
<Description>
For services that require the first PDP call to verify the SSL certificate, and then
a second call to PDP to verify a client DN.

The service making the connection to the gateway is a Proxy for client traffic, where the client 
traffic contains a clientDN, see below example <ConsumerSystem>

Ths is the header which this AAA Policy interprets:


  <soap:Header>
       <HIALContext xmlns="http://ehealthontario.on.ca/xmlns/2015/HIAL"> 
            <TxnID>741d8cb4-f57a-4312-ba05-f143ebcc6e53</TxnID>
            <ConsumerData>
            	<ConsumerSystem>/DC=ssh/DC=subscribers/OU=Subscribers/OU=eHealthUsers/OU=Applications/CN=BLUEWATERHEALTH.NODE1</ConsumerSystem>
            </ConsumerData>
        </HIALContext>
	   
   </soap:Header>

<todo>
Convert log time format to readable
</todo>
</Description>
<Owner>eHealthOntario</Owner>

<Copyright>
**************************************************************
  Copyright (c) ehealthOntario, 2015
  
  This unpublished material is proprietary to ehealthOntario.
  All rights reserved. Reproduction or distribution, in whole 
  or in part, is forbidden except by express written permission 
  of ehealthOntario.
**************************************************************
</Copyright>

</CodeHeader>

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

    <!-- Jan 13, 2014 -->

    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

    <xsl:include href="AaaCommonLibrary.xsl"/>


    <xsl:variable name="web_service_alias"
        select="dp:variable('var://context/aaa/web_service_alias')"/>
    <xsl:variable name="operation_alias" select="dp:variable('var://context/aaa/operation_alias')"/>
    <xsl:variable name="alternate_web_service_alias"
        select="dp:variable('var://context/aaa/alternate_web_service_alias')"/>
    <xsl:variable name="alternate_operation_alias"
        select="dp:variable('var://context/aaa/alternate_operation_alias')"/>
    <xsl:variable name="fullQulifiedDomainName" select="dp:variable('var://context/log/subjectDN')"/>
    <xsl:variable name="wsm-operation" select="dp:variable('var://service/wsm/operation')"/>
    <xsl:variable name="consumerSystem" select="dp:variable('var://context/aaa/ConsumerSystem')"/>


    <xsl:template match="/">
        <xsl:variable name="busStartTime">
            <xsl:call-template name="logAAABusEvent">
                <xsl:with-param name="authentication" select="false()"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="check-pdp-result1">
            <xsl:call-template name="check-pdp">
                <xsl:with-param name="fullQualifiedDomainNameParam" select="$fullQulifiedDomainName"/>
                <xsl:with-param name="web_service_alias" select="$web_service_alias"/>
                <xsl:with-param name="operation_alias" select="$operation_alias"/>

                <!--  Debug-->
                <!-- xsl:with-param name="fullQualifiedDomainNameParam" select="$consumerSystem"/ -->
                <!--  Debug End-->

            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="decision">
            <xsl:choose>
                <xsl:when test="$check-pdp-result1 != &apos;&apos;">
                    <dp:set-variable name="'var://context/aaa/error-message'"
                        value="string($check-pdp-result1)"/>
                    <declined/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Need to update the subjectDN as this turn is the Client's DN.  Also for the Error logging as well -->
                    <dp:set-variable name="'var://context/log/subjectDN'" value="$consumerSystem"/>
                    <xsl:variable name="check-pdp-result2">
                        <xsl:call-template name="check-pdp">
                            <xsl:with-param name="fullQualifiedDomainNameParam"
                                select="$consumerSystem"/>
                            <xsl:with-param name="web_service_alias"
                                select="$alternate_web_service_alias"/>
                            <xsl:with-param name="operation_alias"
                                select="$alternate_operation_alias"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="$check-pdp-result2 != &apos;&apos;">
                            <dp:set-variable name="'var://context/aaa/error-message'"
                                value="string($check-pdp-result2)"/>
                            <declined/>
                        </xsl:when>
                        <xsl:otherwise>
                            <approved/>
                        </xsl:otherwise>
                    </xsl:choose>

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

    <!-- This template will call the PDP and return the status -->
    <xsl:template name="check-pdp">
        <xsl:param name="fullQualifiedDomainNameParam"/>
        <xsl:param name="web_service_alias"/>
        <xsl:param name="operation_alias"/>

        <xsl:variable name="ur-config" select="dp:variable('var://context/aaa/ur-config')"/>
        <xsl:variable name="pdp-url" select="$ur-config/pdp-url"/>
        <xsl:variable name="pdp-info"
            select="concat('WSM-Operation:[', $wsm-operation,'], FQDN:[', $fullQualifiedDomainNameParam , '], operation:[', $operation_alias,'], WebServiceAlias:[', $web_service_alias,']')"/>
        <xsl:variable name="timeout-config" select="dp:variable('var://context/aaa/timeout-config')"/>
        <xsl:variable name="pdp-timeout" select="$timeout-config/pdp"/>

        <xsl:variable name="pdp-request">
            <xsl:call-template name="create_pdp_request">
                <xsl:with-param name="fullQualifiedDomainNameParam"
                    select="$fullQualifiedDomainNameParam"/>
                <xsl:with-param name="web_service_alias" select="$web_service_alias"/>
                <xsl:with-param name="operation_alias" select="$operation_alias"/>
            </xsl:call-template>
        </xsl:variable>

        <dp:set-variable name="'var://context/aaa/pdp-request'" value="$pdp-request"/>

        <xsl:variable name="serial-pdp-request">
            <dp:serialize select="$pdp-request" omit-xml-decl="yes"/>
        </xsl:variable>
        <!-- logging stuff -->
        <xsl:variable name="sequenceNumber">
            <xsl:call-template name="getNextSequence"/>
        </xsl:variable>
        <!--<xsl:call-template name="increaseSequenceNumber"/>
        <xsl:variable name="startTime">
            <xsl:call-template name="getCurrentDateTime"/>
        </xsl:variable>
-->
        <xsl:variable name="headerValues">
            <header name="x-dp-cache-key">
                <xsl:value-of
                    select="dp:hash('http://www.w3.org/2000/09/xmldsig#sha1', $serial-pdp-request)"
                />
            </header>
            <header name="SEQ">
                <xsl:value-of select="$sequenceNumber"/>
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

        <!-- Debug-->
        <dp:set-variable name="'var://context/aaa/TEMPFirstPDPRequest'" value="$pdp-request"/>
        <dp:set-variable name="'var://context/aaa/Date'" value="$pdpCallStartTimeStamp"/>
        <!-- Debug End-->




        <xsl:variable name="pdp-result">
            <dp:url-open target="{$pdp-url}" http-headers="$headerValues" response="responsecode"
                http-method="post" timeout="{$pdp-timeout}">
                <xsl:copy-of select="$pdp-request"/>
            </dp:url-open>
        </xsl:variable>

        <!-- Debug-->
        <dp:set-variable name="'var://context/aaa/TEMPFirstPDPResponse'" value="$pdp-result"/>
        <!-- Debug End-->

        <xsl:variable name="pdpCallEndTimeStamp">
            <xsl:call-template name="getCurrentDateTime"/>
        </xsl:variable>
        <!--  <xsl:variable name="pdpCallElapseTime" select="$pdpCallEndTimeStamp - $pdpCallStartTimeStamp"/>-->

        <!-- Logging of AAA business activity - beginning of calls to UR PDP -->
        <xsl:call-template name="logAAAEvent">
            <xsl:with-param name="startTime" select="$pdpCallStartTimeStamp"/>
            <xsl:with-param name="logContent" select="'UR-PDP call begin'"/>
        </xsl:call-template>




        <xsl:variable name="pdp-cache-age" select="$pdp-result/url-open/headers/header[@name='Age']"/>
        <dp:set-variable name="'var://context/aaa/pdp-cache-age'" value="$pdp-cache-age"/>
        <xsl:message dp:type="aaa" dp:priority="debug">
            <xsl:value-of select="concat(&apos;pdp-cache-age: &apos;, $pdp-cache-age)"/>
        </xsl:message>

        <xsl:variable name="pdp-result-response" select="$pdp-result/url-open/response"/>
        <dp:set-variable name="'var://context/aaa/pdp-result'" value="$pdp-result-response"/>
        <xsl:variable name="pdpErrorResponse">
            <xsl:choose>
                <xsl:when test="$pdp-result-response = &apos;&apos;">
                    <xsl:value-of
                        select="concat(&apos; url-open: Remote error on url &apos;, $pdp-url)"/>
                </xsl:when>

                <xsl:when test="$pdp-result-response/soap:Envelope/soap:Body/soap:Fault">
                    <xsl:value-of
                        select="concat(&apos;From UR-PDP:&apos;, $pdp-result-response/soap:Envelope/soap:Body/soap:Fault/faultcode, &apos;-&apos;, $pdp-result-response/soap:Envelope/soap:Body/soap:Fault/faultstring)"
                    />
                </xsl:when>

                <xsl:when
                    test="$pdp-result-response/soap:Envelope/soap:Body/wst:RequestSecurityTokenResponse/sts:FaultToken">
                    <xsl:value-of
                        select="concat(&apos;From UR-PDP:&apos;, $pdp-result-response/soap:Envelope/soap:Body/wst:RequestSecurityTokenResponse/sts:FaultToken/sts:fault/sts:code, &apos;-&apos;, $pdp-result-response/soap:Envelope/soap:Body/wst:RequestSecurityTokenResponse/sts:FaultToken/sts:fault/sts:messageEn)"
                    />
                </xsl:when>

                <xsl:when test="$pdp-result-response/soap:Envelope/soap:Body/ssm:serviceFailure">
                    <xsl:value-of
                        select="concat(&apos;From UR-PDP:&apos;, $pdp-result-response/soap:Envelope/soap:Body/ssm:serviceFailure)"
                    />
                </xsl:when>

                <xsl:when
                    test="$pdp-result-response/soap:Envelope/soap:Body/xacml:Response/xacml:Result/xacml:Decision[.='Deny']">
                    <xsl:value-of select="'From UR-PDP: access denied.'"/>
                </xsl:when>

                <xsl:otherwise>
                    <xsl:value-of select="&apos;&apos;"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$pdpErrorResponse != &apos;&apos;">
                <xsl:call-template name="logAAAEvent">
                    <xsl:with-param name="logLevel" select="'error'"/>
                    <xsl:with-param name="startTime" select="$pdpCallStartTimeStamp"/>
                    <xsl:with-param name="endTime" select="$pdpCallEndTimeStamp"/>
                    <xsl:with-param name="logContent" select="$pdpErrorResponse"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="logAAAEvent">
                    <xsl:with-param name="startTime" select="$pdpCallStartTimeStamp"/>
                    <xsl:with-param name="endTime" select="$pdpCallEndTimeStamp"/>
                    <xsl:with-param name="logContent" select="'UR-PDP call completed successfully'"
                    />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>


        <!-- Logging of AAA business activity - end of calls to UR PDP -->



        <xsl:value-of select="$pdpErrorResponse"/>

    </xsl:template>


    <!-- This template creates a PDP request -->
    <xsl:template name="create_pdp_request">
        <xsl:param name="fullQualifiedDomainNameParam"/>
        <xsl:param name="web_service_alias"/>
        <xsl:param name="operation_alias"/>

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
                                    <xsl:value-of select="$fullQualifiedDomainNameParam"/>
                                </plaintext>
                            </xacml:AttributeValue>
                        </xacml:Attribute>
                        <xacml:Attribute AttributeId="urn:ehealth:names:idm:attribute:uao"
                            DataType="xsd:string">
                            <xacml:AttributeValue/>
                        </xacml:Attribute>
                        <xacml:Attribute AttributeId="urn:ehealth:names:idm:attribute:uaoType"
                            DataType="xsd:string">
                            <xacml:AttributeValue/>
                        </xacml:Attribute>
                        <xacml:Attribute AttributeId="urn:ehealth:names:idm:attribute:calling-ssid"
                            DataType="xsd:string">
                            <xacml:AttributeValue>
                                <xsl:value-of select="$fullQualifiedDomainNameParam"/>
                            </xacml:AttributeValue>
                        </xacml:Attribute>
                    </xacml:Subject>
                    <!-- define the resource by using web-service alias name -->
                    <xacml:Resource>
                        <xacml:Attribute
                            AttributeId="urn:oasis:names:tc:xacml:2.0:resource:resource-id"
                            DataType="xsd:string">
                            <xacml:AttributeValue>
                                <xsl:value-of select="$web_service_alias"/>
                            </xacml:AttributeValue>
                        </xacml:Attribute>
                    </xacml:Resource>

                    <!-- define the action(operation alias) -->
                    <xacml:Action>
                        <xacml:Attribute AttributeId="urn:oasis:names:tc:xacml:1.0:action:action-id"
                            DataType="xsd:string">
                            <xacml:AttributeValue>
                                <xsl:value-of select="$operation_alias"/>
                            </xacml:AttributeValue>
                        </xacml:Attribute>
                    </xacml:Action>

                    <!-- empty environment element -->
                    <xacml:Environment/>
                </xacml:Request>
            </soap:Body>
        </soap:Envelope>
    </xsl:template>



</xsl:stylesheet>
