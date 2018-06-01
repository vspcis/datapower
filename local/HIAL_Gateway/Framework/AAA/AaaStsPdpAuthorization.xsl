<?xml version="1.0" encoding="UTF-8"?>
<!-- Code Revisions: 
    Oct 21 2015 :  6617 Added logging events for Business start and results
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

    <xsl:template match="/">
        <xsl:variable name="busStartTime">
            <xsl:call-template name="logAAABusEvent">
                <xsl:with-param name="authentication" select="false()"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="assertion" select="/container/mapped-credentials/entry/saml:Assertion"/>
        <xsl:variable name="decision">
            <xsl:choose>
                <xsl:when test="$assertion">
                    <xsl:variable name="checkPdpResult">
                        <xsl:call-template name="aaaStsPdpCheckPdp">
                            <xsl:with-param name="assertion" select="$assertion"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="$checkPdpResult != &apos;&apos;">
                            <!--declined or errors -->
                            <dp:set-variable name="'var://context/aaa/error-message'"
                                value="string($checkPdpResult)"/>
                            <declined/>
                        </xsl:when>
                        <xsl:otherwise>
                            <approved/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <!--no credentials -->
                    <declined/>
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

    <!-- Begin of aaaStsPdpCheckPdp.  This template makes a call to PDP -->
    <xsl:template name="aaaStsPdpCheckPdp">
        <xsl:param name="assertion"/>
        <xsl:param name="resource"/>

        <xsl:variable name="urConfig" select="dp:variable('var://context/aaa/ur-config')"/>
        <xsl:variable name="pdpUrl" select="$urConfig/pdp-url"/>
        <xsl:variable name="timeoutConfig" select="dp:variable('var://context/aaa/timeout-config')"/>
        <xsl:variable name="pdpTimeout" select="$timeoutConfig/pdp"/>

        <xsl:variable name="pdpRequest">
            <xsl:call-template name="aaaStsPdpGetPdpRequest">
                <xsl:with-param name="assertion" select="$assertion"/>
            </xsl:call-template>
        </xsl:variable>

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
                timeout="{$pdpTimeout}" http-method="post">
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
                    <xsl:value-of select="&apos;From UR-PDP: access denied&apos;"/>
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

    <!-- end of aaaStsPdpCheckPdp -->

    <!-- Begin of aaaStsPdpGetPdpRequest.  This template constructs the PDP request. -->
    <!-- Additional Attribute for UR v5.0 is added									 -->
    <xsl:template name="aaaStsPdpGetPdpRequest">
        <xsl:param name="assertion"/>
        <xsl:variable name="webServiceAlias"
            select="dp:variable('var://context/aaa/web_service_alias')"/>
        <xsl:variable name="operationAlias"
            select="dp:variable('var://context/aaa/operation_alias')"/>
        <xsl:variable name="destinationOID"
            select="dp:variable('var://context/aaa/destination_OID')"/>
        <soap:Envelope>
            <soap:Body>
                <xacml:Request>
                    <xacml:Subject>
                        <!-- extract subject-id attribute from Subject node -->
                        <xsl:for-each select="$assertion/saml:Subject/saml:NameID">
                            <xacml:Attribute
                                AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id"
                                DataType="PlainTextIdentityAsserter">
                                <xacml:AttributeValue>
                                    <plaintext>
                                        <xsl:value-of select="text()"/>
                                    </plaintext>
                                </xacml:AttributeValue>
                            </xacml:Attribute>
                            <!-- Additional Attribute for the UR v5.0  -->
                            <xacml:Attribute
                                AttributeId="urn:ehealth:names:idm:attribute:nameId"
                                DataType="xsd:string">
                                <xacml:AttributeValue>
                                        <xsl:value-of select="text()"/>
                                </xacml:AttributeValue>
                            </xacml:Attribute>
                        </xsl:for-each>
                        <!-- subject locality -->
                        <xsl:for-each select="$assertion/saml:AuthnStatement/saml:SubjectLocality">
                            <xsl:element name="xacml:Attribute">
                                <xsl:attribute name="AttributeId"
                                    >urn:ehealth:names:idm:attribute:subjectLocalityIPAddress</xsl:attribute>
                                <xsl:attribute name="DataType">xsd:string</xsl:attribute>
                                <xacml:AttributeValue>
                                    <xsl:choose>
                                        <xsl:when test="string-length(@saml:Address) = 0">
                                            <xsl:value-of select="@Address"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="@saml:Address"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xacml:AttributeValue>
                            </xsl:element>
                        </xsl:for-each>
                        <!-- various roll up attributes -->
                        <xsl:for-each
                            select="$assertion/saml:AuthnStatement/saml:AuthnContext/saml:AuthnContextDecl/ac:Identification/ac:Extension/*">
                            <xsl:element name="xacml:Attribute">
                                <xsl:attribute name="AttributeId"
                                        >urn:ehealth:names:idm:attribute:<xsl:value-of
                                        select="local-name()"/></xsl:attribute>
                                <xsl:attribute name="DataType">xsd:string</xsl:attribute>
                                <xacml:AttributeValue>
                                    <xsl:choose>
                                        <xsl:when test="string-length(@ehoext:value) = 0">
                                            <xsl:value-of select="@value"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="@ac:value"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xacml:AttributeValue>
                            </xsl:element>
                        </xsl:for-each>
                        <!-- authentication mechanisms (primary and compensating), ProtectedNetwork -->
                        <xsl:for-each
                            select="$assertion/saml:AuthnStatement/saml:AuthnContext/saml:AuthnContextDecl/ac:AuthnMethod/ac:PrincipalAuthenticationMechanism/ac:Extension/*">
                            <xsl:element name="xacml:Attribute">
                                <xsl:attribute name="AttributeId"
                                        >urn:ehealth:names:idm:attribute:<xsl:value-of
                                        select="local-name()"/></xsl:attribute>
                                <xsl:attribute name="DataType">xsd:string</xsl:attribute>
                                <xacml:AttributeValue>
                                    <xsl:choose>
                                        <xsl:when test="string-length(@ehoext:type) = 0">
                                            <xsl:value-of select="@type"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="@ehoext:type"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xacml:AttributeValue>
                            </xsl:element>
                        </xsl:for-each>
                        <!-- IdentityProvider, AssertingParty -->
                        <xsl:for-each
                            select="$assertion/saml:AuthnStatement/saml:AuthnContext/saml:AuthnContextDecl/ac:AuthnMethod/ac:Extension/*">
                            <xsl:element name="xacml:Attribute">
                                <xsl:attribute name="AttributeId"
                                        >urn:ehealth:names:idm:attribute:<xsl:value-of
                                        select="local-name()"/></xsl:attribute>
                                <xsl:attribute name="DataType">xsd:string</xsl:attribute>
                                <xsl:for-each select="ac:AuthenticatingAuthority">
                                    <xacml:AttributeValue>
                                        <xsl:apply-templates select="node()"/>
                                    </xacml:AttributeValue>
                                </xsl:for-each>
                            </xsl:element>
                        </xsl:for-each>
                        <!-- extract attributes from AttributeStatement node -->
                        <xsl:for-each select="$assertion/saml:AttributeStatement/saml:Attribute">
                            <xsl:variable name="attr_name" select="@Name"/>
                            <xsl:element name="xacml:Attribute">
                                <xsl:attribute name="AttributeId">
                                    <xsl:value-of select="@Name"/>
                                </xsl:attribute>
                                <xsl:attribute name="DataType">xsd:string</xsl:attribute>
                                <xsl:for-each select="saml:AttributeValue">
                                    <xacml:AttributeValue>
                                        <xsl:apply-templates select="node()"/>
                                    </xacml:AttributeValue>
                                </xsl:for-each>
                            </xsl:element>
                        </xsl:for-each>
                    </xacml:Subject>
                    <!-- The following 2 subjects are moved from the bottom -->
                    <xacml:Subject>
                        <xacml:Attribute
                            AttributeId="urn:ehealth:names:idm:attribute:destination-id"
                            DataType="xsd:string">
                            <xacml:AttributeValue>
                                <xsl:value-of select="$destinationOID"/>
                            </xacml:AttributeValue>
                        </xacml:Attribute>
                    </xacml:Subject>
                    <xacml:Subject>
                        <xacml:Attribute AttributeId="urn:ehealth:names:idm:attribute:calling-ssid"
                            DataType="xsd:string">
                            <xacml:AttributeValue>
                                <dp:set-variable name="'var://context/aaa/calling-ssid'"
                                    value="$assertion/saml:AuthnStatement/saml:AuthnContext/saml:AuthnContextDecl/ac:AuthnMethod/ac:Extension/ehoext:AssertingParty/ac:AuthenticatingAuthority/text()"/>
                                <xsl:value-of select="dp:variable('var://context/aaa/calling-ssid')"
                                />
                            </xacml:AttributeValue>
                        </xacml:Attribute>
                    </xacml:Subject>
                    <!-- The following is boilerplate -->
                    <xacml:Resource>
                        <xacml:Attribute
                            AttributeId="urn:oasis:names:tc:xacml:2.0:resource:resource-id"
                            DataType="xsd:string">
                            <xacml:AttributeValue>
                                <xsl:value-of select="$webServiceAlias"/>
                            </xacml:AttributeValue>
                        </xacml:Attribute>
                    </xacml:Resource>
                    <xacml:Action>
                        <xacml:Attribute AttributeId="urn:oasis:names:tc:xacml:1.0:action:action-id"
                            DataType="xsd:string">
                            <xacml:AttributeValue>
                                <xsl:value-of select="$operationAlias"/>
                            </xacml:AttributeValue>
                        </xacml:Attribute>
                    </xacml:Action>
                    <xacml:Environment/>
                </xacml:Request>
            </soap:Body>
        </soap:Envelope>
    </xsl:template>
    <!-- end of aaaStsPdpGetPdpRequest -->

</xsl:stylesheet>
