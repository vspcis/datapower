<?xml version="1.0" encoding="UTF-8"?>
<!--  
    Author:         PCIS Development Team   
    Company:        eHealthOntario
    Created   :     June 22, 2012
    Refactored:     July 30, 2015
    Description:    Common template library for AAA
    Change Log:     October 7, 2015 - for defect 6617 - There was an overrided NOT accept in the code which was not necssary and which affects
                                                        Processing of the updated AD SAML AAA Policy, a failure in the authentication step will
                                                        override. Perhaps it is needed in other AAA Policy but it seems to run through regression
                                                        testing with no issues.
                                                      - New wrapper for logged AAA validations
                    Nov 26, 2015 - 6741 - Added Empty Saml token detection  
                       
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
    xmlns:dsig="http://www.w3.org/2000/09/xmldsig#"
    xmlns:ehoext="urn:ehealth:names:idm:ac:extension" xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpfunc="http://www.datapower.com/extensions/functions"
    xmlns:dpconfig="http://www.datapower.com/param/config" xmlns:dyn="http://exslt.org/dynamic"
    xmlns:date="http://exslt.org/dates-and-times" xmlns:str="http://exslt.org/strings"
    xmlns:hial="http://ehealthontario.on.ca/xmlns/2015/HIAL"
    xmlns:hiallib="http://www.ehealthontario.on.ca/hial/lib" extension-element-prefixes="dp"
    exclude-result-prefixes="xsl soap sts wss wst xacml saml ac ssm ehoext dpfunc str date dp">

    <xsl:output method="xml" version="1.0" indent="yes"/>
    <xsl:include href="store:///dp/verify.xsl"/>
    <xsl:include href="store:///utilities.xsl"/>
    <xsl:include href="local:Framework/Lib/Log4GateWay.xsl"/>


    <xsl:template name="loggedGroupMembershipValidation">
        <xsl:param name="subjectDN"/>
        <xsl:param name="group" select="&apos;?!?&apos;"/>

        <xsl:variable name="callStartTimeStamp">
            <xsl:call-template name="getCurrentDateTime"/>
        </xsl:variable>

        <xsl:call-template name="logAAAEvent">
            <xsl:with-param name="startTime" select="$callStartTimeStamp"/>
            <xsl:with-param name="logContent" select="'Group Membership Validation Starting'"/>
        </xsl:call-template>

        <xsl:variable name="result">
            <xsl:call-template name="groupMembershipValidation">
                <xsl:with-param name="subjectDN" select="$subjectDN"/>
                <xsl:with-param name="group" select="$group"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="callEndTimeStamp">
            <xsl:call-template name="getCurrentDateTime"/>
        </xsl:variable>


        <xsl:choose>
            <xsl:when test="$result = &apos;&apos;">           
                <xsl:call-template name="logAAAEvent">
                    <xsl:with-param name="logLevel" select="'info'"/>
                    <xsl:with-param name="startTime" select="$callStartTimeStamp"/>
                    <xsl:with-param name="endTime" select="$callEndTimeStamp"/>
                    <xsl:with-param name="logContent"
                        select="'Group Membership Validation Success'"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="logAAAEvent">
                    <xsl:with-param name="logLevel" select="'error'"/>
                    <xsl:with-param name="startTime" select="$callStartTimeStamp"/>
                    <xsl:with-param name="endTime" select="$callEndTimeStamp"/>
                    <xsl:with-param name="logContent" select="concat('Group Membership Validation Failed: ', $result)"
                    />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:copy-of select="$result"/>
    </xsl:template>

    <xsl:template name="groupMembershipValidation">
        <xsl:param name="subjectDN"/>
        <xsl:param name="group" select="&apos;?!?&apos;"/>

        <!--ldap config parameters-->
        <xsl:variable name="ldapConfig" select="dp:variable('var://context/aaa/ldap-config')"/>
        <xsl:variable name="loadBalancer" select="$ldapConfig/load-balancer"/>
        <xsl:variable name="bindDN" select="$ldapConfig/bind-dn"/>

        <!-- Decrypt the password string -->
        <xsl:variable name="bindPassword">
            <xsl:call-template name="decryptString">
                <xsl:with-param name="privateKeyName" select="$ldapConfig/decryption-key-name"/>
                <xsl:with-param name="encryptedString" select="$ldapConfig/bind-password"/>
            </xsl:call-template>
        </xsl:variable>


        <xsl:variable name="startTime">
            <xsl:call-template name="getCurrentDateTime"/>
        </xsl:variable>
        <xsl:variable name="adCallStartTimeStamp" select="number(dp:time-value())"/>

        <!-- Logging of AAA business activity - end of calls to UR STS -->
        <xsl:call-template name="logAAAEvent">
            <xsl:with-param name="startTime" select="$startTime"/>
            <xsl:with-param name="logContent" select="'Start to query AD to verify membership'"/>
        </xsl:call-template>


        <!-- call the LDAP server to verify the membership -->
        <xsl:variable name="ldapSearchResults"
            select="dp:ldap-search('','', $bindDN, $bindPassword, $subjectDN, 'memberOf', '(&amp;(objectClass=*))', 'base', '', $loadBalancer, 'v3')"/>

        <xsl:variable name="endTime">
            <xsl:call-template name="getCurrentDateTime"/>
        </xsl:variable>

        <xsl:call-template name="logAAAEvent">
            <xsl:with-param name="endTime" select="$endTime"/>
            <xsl:with-param name="logContent"
                select="concat('AD Call to ', $loadBalancer, ' with result ', $ldapSearchResults)"/>
        </xsl:call-template>

        <!--<xsl:message dp:type="if-gtwy" dp:priority="error"><xsl:value-of select="$ldap-search-results"/></xsl:message>-->
        <xsl:choose>
            <xsl:when test="$ldapSearchResults/LDAP-search-error/error">
                <xsl:value-of select="$ldapSearchResults/LDAP-search-error/error"/>
            </xsl:when>
            <xsl:when
                test="not($ldapSearchResults/LDAP-search-results/result[*]/attribute-value[. = $group])">
                <xsl:variable name="allGroups">
                    <xsl:for-each
                        select="$ldapSearchResults/LDAP-search-results/result/attribute-value">
                        <xsl:value-of select="concat('[', string(.), ']')"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:value-of
                    select="concat(&apos;The client SSL/SAML certificate is not part of the AD group membership ([&apos;, $group, &apos;] vs. existing memberships: &apos;, $allGroups, &apos;)&apos;)"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="&apos;&apos;"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!---->
    <xsl:template name="decryptString">
        <xsl:param name="privateKeyName"/>
        <xsl:param name="encryptedString"/>

        <xsl:variable name="decryptedString"
            select="dp:decrypt-key($encryptedString, concat('name:', $privateKeyName), 'http://www.w3.org/2001/04/xmlenc#rsa-1_5')"/>
        <xsl:variable name="decodedString" select="dp:decode($decryptedString, 'base-64')"/>
        <xsl:value-of select="$decodedString"/>
    </xsl:template>

    <xsl:template name="encryptString">
        <xsl:param name="certName"/>
        <xsl:param name="decryptedString"/>


        <xsl:variable name="encodedString" select="dp:encode($decryptedString, 'base-64')"/>
        <xsl:variable name="encryptedString"
            select="dp:encrypt-key($encodedString, concat('name:', $certName), 'http://www.w3.org/2001/04/xmlenc#rsa-1_5')"/>

        <xsl:value-of select="$encryptedString"/>
    </xsl:template>


    <xsl:template name="getSubjectDN">
        <xsl:param name="dn" select="dp:client-subject-dn()"/>
        <xsl:variable name="tokenizedDN" select="str:tokenize($dn,'/')"/>
        <xsl:variable name="sortedSubjectDN">
            <xsl:for-each select="$tokenizedDN">
                <xsl:sort data-type="number" order="descending" select="position()"/>
                <xsl:value-of select="."/>
                <xsl:if test="position() != count($tokenizedDN)">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="$sortedSubjectDN"/>
    </xsl:template>

    <!-- Wrapper for 6617 this function logs the samlValidation transactional events -->
    
    <xsl:template name="loggedSamlValidation">
        <xsl:param name="assertion"/>
        
        <xsl:variable name="callStartTimeStamp">
            <xsl:call-template name="getCurrentDateTime"/>
        </xsl:variable>
        
        <xsl:call-template name="logAAAEvent">
            <xsl:with-param name="startTime" select="$callStartTimeStamp"/>
            <xsl:with-param name="logContent" select="'Saml Token Authentication Starting'"/>
        </xsl:call-template>
        
        
        <xsl:variable name="result">
            <xsl:call-template name="samlValidation">
                <xsl:with-param name="assertion" select="$assertion"/>
            </xsl:call-template>
        </xsl:variable>
        
        
        <xsl:variable name="callEndTimeStamp">
            <xsl:call-template name="getCurrentDateTime"/>
        </xsl:variable>
        
        
        <xsl:choose>
            <xsl:when test="$result = &apos;&apos;">
                <xsl:call-template name="logAAAEvent">
                    <xsl:with-param name="logLevel" select="'info'"/>
                    <xsl:with-param name="startTime" select="$callStartTimeStamp"/>
                    <xsl:with-param name="endTime" select="$callEndTimeStamp"/>
                    <xsl:with-param name="logContent"
                        select="'Saml Token Authenticated Successfully'"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="logAAAEvent">
                    <xsl:with-param name="logLevel" select="'error'"/>
                    <xsl:with-param name="startTime" select="$callStartTimeStamp"/>
                    <xsl:with-param name="endTime" select="$callEndTimeStamp"/>
                    <xsl:with-param name="logContent" select="concat('Saml Token Authentication Failed: ', $result )"
                    />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:copy-of select="$result"/>
        
    </xsl:template>
    
    <!-- Template to validate SAML token signature and validity period -->
    <xsl:template name="samlValidation">
        <xsl:param name="assertion"/>
        <xsl:variable name="saml-config" select="dp:variable('var://context/aaa/saml-config')"/>
        <xsl:variable name="policy" select="dp:parse(dp:get-aaa-policy())"/>

        <xsl:call-template name="dp-verify-saml-signature">
            <xsl:with-param name="assertion" select="$assertion"/>
            <xsl:with-param name="validate-certificate" select="true()"/>
            <xsl:with-param name="valcred-name" select="$policy/AAAPolicy/SAMLValcred"/>
        </xsl:call-template>

        <xsl:choose>
            <xsl:when test="not(dp:accepting())">
                <!--dp:accept /-->
                <xsl:value-of select="&apos;The client SAML signature does not verify&apos;"/>
            </xsl:when>
            <xsl:when test="count($assertion/*) = 0">
                <xsl:value-of select="&apos;Saml Token Not Found&apos;"/>
            </xsl:when>
            <xsl:when
                test="($assertion and not(dpfunc:check-saml-timestamp(string($assertion/saml:Conditions/@NotBefore), string($assertion/saml:Conditions/@NotOnOrAfter), string($saml-config/skew-time))))">
                <xsl:message dp:type="aaa" dp:priority="debug">
                    <xsl:value-of
                        select="concat(&apos;Custom Skew Time: &apos;, $saml-config/skew-time)"/>
                </xsl:message>
                <xsl:value-of
                    select="concat(&apos;The current time (&apos;, date:date-time(), &apos;) is outside the validity period of SAML (&apos;, $assertion/saml:Conditions/@NotBefore, &apos; - &apos;, $assertion/saml:Conditions/@NotOnOrAfter, &apos;)&apos;)"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="&apos;&apos;"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="getStsToken">
        <xsl:param name="assertion"/>
        <xsl:variable name="urConfig" select="dp:variable('var://context/aaa/ur-config')"/>
        <xsl:variable name="stsUrl" select="$urConfig/sts-url"/>

        <xsl:variable name="timeoutConfig" select="dp:variable('var://context/aaa/timeout-config')"/>
        <xsl:variable name="stsTimeout" select="$timeoutConfig/sts"/>

        <xsl:variable name="filteredAssertion">
            <xsl:call-template name="filter-sts-assertion">
                <xsl:with-param name="assertion-org" select="$assertion"/>
            </xsl:call-template>
        </xsl:variable>

        <dp:set-variable name="'var://context/aaa/filtered-assertion'" value="$filteredAssertion"/>

        <xsl:variable name="serialStsRequest">
            <dp:serialize select="$filteredAssertion" omit-xml-decl="yes"/>
        </xsl:variable>

        <xsl:variable name="headerValuesSts">
            <header name="x-dp-cache-key">
                <xsl:value-of
                    select="dp:hash('http://www.w3.org/2000/09/xmldsig#sha1', $serialStsRequest)"/>
            </header>
            <header name="TID">
                <xsl:value-of select="dp:variable('var://context/log/transactionID')"/>
            </header>
            <header name="SDN">
                <xsl:value-of select="dp:variable('var://context/log/subjectDN')"/>
            </header>
        </xsl:variable>

        <xsl:message dp:type="aaa" dp:priority="debug">
            <xsl:value-of select="concat(&apos;#3-headerValues-sts: &apos;, $headerValuesSts)"/>
        </xsl:message>

        <xsl:variable name="stsCallStartTimeStamp">
            <xsl:call-template name="getCurrentDateTime"/>
        </xsl:variable>

        <!-- Logging of AAA business activity - beginning of calls to UR STS -->
        <xsl:call-template name="logAAAEvent">
            <xsl:with-param name="startTime" select="$stsCallStartTimeStamp"/>
            <xsl:with-param name="logContent" select="'UR-STS call begin'"/>
        </xsl:call-template>

        <xsl:variable name="stsResult">
            <dp:url-open target="{$stsUrl}" http-headers="$headerValuesSts" response="responsecode"
                timeout="{$stsTimeout}" http-method="post">
                <soap:Envelope>
                    <soap:Body>
                        <wst:RequestSecurityToken>
                            <wst:TokenType>
                                <xsl:value-of
                                    select="'http://docs.oasis-open.org/wss/oasis-wss-saml-token-profile-1.1#SAMLV2.0'"
                                />
                            </wst:TokenType>
                            <wst:RequestType>
                                <xsl:value-of
                                    select="'http://docs.oasis-open.org/ws-sx/ws-trust/200512/Validate'"
                                />
                            </wst:RequestType>
                            <wst:ValidateTarget>
                                <xsl:copy-of select="$assertion"/>
                            </wst:ValidateTarget>
                        </wst:RequestSecurityToken>
                    </soap:Body>
                </soap:Envelope>
            </dp:url-open>
        </xsl:variable>

        <xsl:variable name="stsCallEndTimeStamp">
            <xsl:call-template name="getCurrentDateTime"/>
        </xsl:variable>

        <dp:set-variable name="'var://context/aaa/sts-result'" value="$stsResult"/>

        <xsl:variable name="stsCacheAge" select="$stsResult/url-open/headers/header[@name='Age']"/>

        <dp:set-variable name="'var://context/aaa/sts-cache-age'" value="$stsCacheAge"/>
        <xsl:message dp:type="aaa" dp:priority="debug">
            <xsl:value-of select="concat(&apos;sts-cache-age: &apos;, $stsCacheAge)"/>
        </xsl:message>

        <xsl:variable name="stsResultResponse" select="$stsResult/url-open/response"/>
        <dp:set-variable name="'var://context/aaa/sts-result-response'" value="$stsCacheAge"/>

        <xsl:variable name="parsedStsResponse">
            <xsl:choose>
                <xsl:when test="not($stsResultResponse) or $stsResultResponse = &apos;&apos;">
                    <xsl:value-of
                        select="concat(&apos; sts-url-open: Remote error on url &apos;, $stsUrl)"/>
                </xsl:when>
                <xsl:when test="$stsResultResponse/soap:Envelope/soap:Body/soap:Fault">
                    <xsl:value-of
                        select="concat(&apos;From UR-STS:&apos;, $stsResultResponse/soap:Envelope/soap:Body/soap:Fault/faultcode, &apos;-&apos;, $stsResultResponse/soap:Envelope/soap:Body/soap:Fault/faultstring)"
                    />
                </xsl:when>
                <xsl:when
                    test="$stsResultResponse/soap:Envelope/soap:Body/wst:RequestSecurityTokenResponse/sts:FaultToken">
                    <xsl:value-of
                        select="concat(&apos;From UR-STS:&apos;, $stsResultResponse/soap:Envelope/soap:Body/wst:RequestSecurityTokenResponse/sts:FaultToken/sts:fault/sts:code, &apos;-&apos;, $stsResultResponse/soap:Envelope/soap:Body/wst:RequestSecurityTokenResponse/sts:FaultToken/sts:fault/sts:messageEn)"
                    />
                </xsl:when>
                <xsl:when
                    test="$stsResultResponse/soap:Envelope/soap:Body/xacml:Response/xacml:Result/xacml:Decision[. = &apos;Deny&apos;]">
                    <xsl:value-of
                        select="&apos;From UR-STS: The token presented by the client has been rejected&apos;"
                    />
                </xsl:when>
                <xsl:when test="$stsResultResponse/soap:Envelope/soap:Body/ssm:xacmlFailure">
                    <xsl:value-of
                        select="concat(&apos;From UR-STS:&apos;, $stsResultResponse/soap:Envelope/soap:Body/ssm:xacmlFailure)"
                    />
                </xsl:when>
                <xsl:when test="$stsResultResponse/soap:Envelope/soap:Body/ssm:serviceFailure">
                    <xsl:value-of
                        select="concat(&apos;From UR-STS:&apos;, $stsResultResponse/soap:Envelope/soap:Body/ssm:serviceFailure)"
                    />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of
                        select="$stsResultResponse/soap:Envelope/soap:Body/wst:RequestSecurityTokenResponse/wst:RequestedSecurityToken/saml:Assertion"
                    />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="logContent">
            <xsl:choose>
                <xsl:when test="$parsedStsResponse//saml:Assertion">
                    <xsl:value-of select="'UR-STS call completed successfully'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$parsedStsResponse"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Logging of AAA business activity - end of calls to UR STS -->
        <xsl:call-template name="logAAAEvent">
            <xsl:with-param name="startTime" select="$stsCallStartTimeStamp"/>
            <xsl:with-param name="endTime" select="$stsCallEndTimeStamp"/>
            <xsl:with-param name="logContent" select="$logContent"/>
        </xsl:call-template>

        <xsl:copy-of select="$parsedStsResponse"/>

    </xsl:template>

    <!---->
    <xsl:template name="check-pdp">
        <xsl:param name="assertion"/>
        <xsl:param name="resource"/>

        <xsl:variable name="ur-config" select="dp:variable('var://context/aaa/ur-config')"/>
        <xsl:variable name="pdp-url" select="$ur-config/pdp-url"/>
        <xsl:variable name="timeout-config" select="dp:variable('var://context/aaa/timeout-config')"/>
        <xsl:variable name="pdp-timeout" select="$timeout-config/pdp"/>

        <!-- adding cache -->

        <!-- disable PDP cache for now -->

        <xsl:variable name="pdp-request">
            <xsl:call-template name="get-pdp-request">
                <xsl:with-param name="assertion" select="$assertion"/>
                <xsl:with-param name="resource" select="$resource"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="headerValues">
            <header name="x-dp-cache-key"/>
        </xsl:variable>

        <xsl:variable name="pdp-result">
            <dp:url-open target="{$pdp-url}" http-headers="$headerValues" timeout="{$pdp-timeout}"
                http-method="post">
                <xsl:copy-of select="$pdp-request"/>
            </dp:url-open>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$pdp-result = &apos;&apos;">
                <xsl:value-of select="concat(&apos; url-open: Remote error on url &apos;, $pdp-url)"
                />
            </xsl:when>
            <xsl:when test="$pdp-result/soap:Envelope/soap:Body/soap:Fault">
                <xsl:value-of
                    select="concat(&apos;From UR-PDP:&apos;, $pdp-result/soap:Envelope/soap:Body/soap:Fault/faultcode, &apos;-&apos;, $pdp-result/soap:Envelope/soap:Body/soap:Fault/faultstring)"
                />
            </xsl:when>
            <xsl:when
                test="$pdp-result/soap:Envelope/soap:Body/wst:RequestSecurityTokenResponse/sts:FaultToken">
                <xsl:value-of
                    select="concat(&apos;From UR-PDP:&apos;, $pdp-result/soap:Envelope/soap:Body/wst:RequestSecurityTokenResponse/sts:FaultToken/sts:fault/sts:code, &apos;-&apos;, $pdp-result/soap:Envelope/soap:Body/wst:RequestSecurityTokenResponse/sts:FaultToken/sts:fault/sts:messageEn)"
                />
            </xsl:when>
            <xsl:when test="$pdp-result/soap:Envelope/soap:Body/ssm:xacmlFailure">
                <xsl:value-of
                    select="concat(&apos;From UR-PDP:&apos;, $pdp-result/soap:Envelope/soap:Body/ssm:xacmlFailure)"
                />
            </xsl:when>
            <xsl:when test="$pdp-result/soap:Envelope/soap:Body/ssm:serviceFailure">
                <xsl:value-of
                    select="concat(&apos;From UR-PDP:&apos;, $pdp-result/soap:Envelope/soap:Body/ssm:serviceFailure)"
                />
            </xsl:when>
            <xsl:when
                test="$pdp-result/soap:Envelope/soap:Body/xacml:Response/xacml:Result/xacml:Decision[.='Deny']">
                <xsl:value-of select="&apos;From UR-PDP: access denied&apos;"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="&apos;&apos;"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!---->
    <xsl:template name="get-pdp-request">
        <xsl:param name="assertion"/>
        <xsl:param name="resource" select="'resource_not_supplied'"/>
        <xsl:param name="app" select="'UserRegistry'"/>
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
                    <!-- The following is boilerplate -->
                    <xacml:Resource>
                        <xacml:Attribute
                            AttributeId="urn:oasis:names:tc:xacml:2.0:resource:resource-id"
                            DataType="xsd:string">
                            <xacml:AttributeValue>
                                <xsl:value-of select="$app"/>
                                <xsl:value-of select="$resource"/>
                            </xacml:AttributeValue>
                        </xacml:Attribute>
                    </xacml:Resource>
                    <xacml:Action>
                        <xacml:Attribute AttributeId="urn:oasis:names:tc:xacml:1.0:action:action-id"
                            DataType="xsd:string">
                            <xacml:AttributeValue>view </xacml:AttributeValue>
                        </xacml:Attribute>
                    </xacml:Action>
                    <xacml:Environment/>
                </xacml:Request>
            </soap:Body>
        </soap:Envelope>
    </xsl:template>

    <!-- Filter out all transit values from SAML, used to generate key of STS cache -->
    <xsl:template name="filter-sts-assertion">
        <xsl:param name="assertion-org"/>
        <saml:Assertion>
            <xsl:copy-of select="$assertion-org/saml:Issuer"/>
            <dsig:Signature>
                <dsig:KeyInfo>
                    <dsig:X509Data>
                        <xsl:copy-of
                            select="$assertion-org/dsig:Signature/dsig:KeyInfo/dsig:X509Data/dsig:X509IssuerSerial"/>
                        <xsl:copy-of
                            select="$assertion-org/dsig:Signature/dsig:KeyInfo/dsig:X509Data/dsig:X509SubjectName"/>
                        <xsl:copy-of
                            select="$assertion-org/dsig:Signature/dsig:KeyInfo/dsig:X509Data/dsig:X509SKI"
                        />
                    </dsig:X509Data>
                </dsig:KeyInfo>
            </dsig:Signature>
            <xsl:copy-of select="$assertion-org/saml:Subject"/>
            <saml:Conditions>
                <xsl:copy-of select="$assertion-org/saml:Conditions/saml:AudienceRestriction"/>
            </saml:Conditions>
            <saml:AuthnStatement>
                <xsl:copy-of select="$assertion-org/saml:AuthnStatement/saml:SubjectLocality"/>
                <xsl:copy-of select="$assertion-org/saml:AuthnStatement/saml:AuthnContext"/>
            </saml:AuthnStatement>
            <xsl:copy-of select="$assertion-org/saml:AttributeStatement"/>
        </saml:Assertion>
    </xsl:template>

    <!-- This template is called by AAA policy to load initial context properties.  -->
    <xsl:template name="saveInitCtxPropertes">
        <!-- Transaction core data: startTimeStamp, startTimeString, globalTransactionID-->
        <xsl:variable name="txnStartTimeStamp" select="number(dp:time-value())"/>
        <xsl:variable name="ms" select="substring($txnStartTimeStamp, 11, 3)"/>
        <xsl:variable name="txnStartTimeString"
            select="concat(date:format-date(date:date-time(), 'EEE MMM dd yyyy HH:mm:ssZ'), '.', $ms)"/>

        <!--  xsl:variable name="txnStartTimeString" select="date:format-date( date:date-time(), 'EEE MMM dd yyyy HH:mm:ss.SSSZ')"/ -->
        <!-- xsl:variable name="txnStartTimeString" select="date:date-time()"/ -->
        <dp:set-variable name="'var://context/log/txnStartTimeStamp'" value="$txnStartTimeStamp"/>
        <dp:set-variable name="'var://context/log/txnStartTimeString'" value="$txnStartTimeString"/>

        <xsl:variable name="inltxnID"
            select="/*[local-name()='Envelope']/*[local-name()='Header']/hial:HIALContext/hial:TxnID/text()"/>
        <xsl:message dp:type="if-gtwy" dp:priority="debug">
            <xsl:value-of select="concat('TxnID: ',$inltxnID)"/>
        </xsl:message>

        <xsl:variable name="ltxnID">
            <xsl:choose>
                <xsl:when test="string-length($inltxnID) > 0">
                    <xsl:value-of select="$inltxnID"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="dp:generate-uuid()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <dp:set-variable name="'var://context/log/transactionID'" value="string($ltxnID)"/>

        <xsl:variable name="inlseqs"
            select="/*[local-name()='Envelope']/*[local-name()='Header']/hial:HIALContext/hial:Seq/text()"/>
        <xsl:message dp:type="if-gtwy" dp:priority="debug">
            <xsl:value-of select="concat('Seq: ',$inlseqs)"/>
        </xsl:message>

        <xsl:variable name="prefixSequence">
            <xsl:choose>
                <xsl:when test="string-length($inlseqs) > 0">
                    <xsl:value-of select="concat($inlseqs,'.')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <dp:set-variable name="'var://context/log/prefixSequence'" value="string($prefixSequence)"/>

        <!-- ws-addressing -->
        <xsl:variable name="wsaMessageID"
            select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='MessageID']/text()"/>
        <xsl:variable name="wsaAction"
            select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='Action']/text()"/>
        <xsl:variable name="wsaTo"
            select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='To']/text()"/>
        <xsl:variable name="wsaReplyToEndpointID"
            select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='ReplyTo']/*[local-name()='ReferenceParameters']/*[local-name()='endpointID']/text()"/>

        <dp:set-variable name="'var://context/log/wsa-messageID'" value="$wsaMessageID"/>
        <dp:set-variable name="'var://context/log/wsa-action'" value="$wsaAction"/>
        <dp:set-variable name="'var://context/log/wsa-to'" value="$wsaTo"/>
        <dp:set-variable name="'var://context/log/wsa-replyTo-endpointID'"
            value="$wsaReplyToEndpointID"/>

        <!--extract the client IP address -->
        <xsl:variable name="sourceIP">
            <xsl:choose>
                <xsl:when test="dp:request-header('X-Forwarded-For') != &apos;&apos;">
                    <xsl:value-of select="dp:request-header('X-Forwarded-For')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="dp:variable('var://service/transaction-client')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <dp:set-variable name="'var://context/log/sourceIP'" value="$sourceIP"/>

        <!--service profile-->
        <xsl:variable name="serviceUri" select="dp:variable('var://service/URI')"/>
        <xsl:variable name="serviceProcessorName"
            select="dp:variable('var://service/processor-name')"/>
        <xsl:variable name="service"
            select="document('local:///Framework/AAA/Config/GtwyProfile.xml')/Profile/Service[@gatewayUri=$serviceUri and @name=$serviceProcessorName]"/>
        <xsl:variable name="returnOriginalFault" select="string($service/@returnOriginalFault)"/>
        <dp:set-variable name="'var://context/profile/return-original-fault'"
            value="$returnOriginalFault"/>

        <!--aaa properties-->
        <xsl:variable name="samlCertADGroup" select="string($service/../@samlADGroupMembership)"/>
        <xsl:variable name="sslCertADGroup" select="string($service/@sslADGroupMembership)"/>

        <dp:set-variable name="'var://context/aaa/saml-cert-ad-group'" value="$samlCertADGroup"/>
        <dp:set-variable name="'var://context/aaa/ssl-cert-ad-group'" value="$sslCertADGroup"/>

        <!-- This is required by the PIX/PDQ v2 for the Client DN-->
        <!--<xsl:variable name="consumerSystem"
            select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='HIALContext']/*[local-name()='ConsumerData']/*[local-name()='ConsumerSystem']/text()"/>-->
        <!-- Added on 7/6/2016 -->
        <xsl:variable name="consumerSystem">
            <xsl:choose>
                <xsl:when test="string(/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='HIALContext']/*[local-name()='ConsumerData']/*[local-name()='ConsumerSystem']/text()) != '' ">
                    <xsl:value-of select="string(/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='HIALContext']/*[local-name()='ConsumerData']/*[local-name()='ConsumerSystem']/text())" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="string(/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='TransientData']/*[local-name()='Transaction_Flow']/*[local-name()='consumer_System']/text())"/>
                </xsl:otherwise>
            </xsl:choose>
        <!--   select="string(/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='TransientData']/*[local-name()='Transaction_Flow']/*[local-name()='consumer_System']/text()) -->
        </xsl:variable> 
        <!-- End of addedd code 7/6/2016 -->
        <dp:set-variable name="'var://context/aaa/ConsumerSystem'" value="$consumerSystem"/>

		<!-- Extract the UPI from transient data if exist - for FHIR authorization -->
		<xsl:variable name="srcUpi" 
		    select="string(/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='TransientData']/*[local-name()='Transaction_Flow']/*[local-name()='consumer_Organization']/text())"/>
		<xsl:if test="$srcUpi != &apos;&apos;">
			<dp:set-variable name="'var://context/aaa/srcUpi'" value="$srcUpi"/>
		</xsl:if>
		
        <!-- operation profile used by the UR PDP verification-->
        <xsl:variable name="wsmOperation" select="dp:variable('var://service/wsm/operation')"/>
        <xsl:variable name="operation"
            select="document('local:///Framework/AAA/Config/AaaCommonMap.xml')/Profile/Service[@name=$serviceProcessorName]/Operation[@name=$wsmOperation]"/>
        <xsl:variable name="operationAlias" select="string($operation/@operationAlias)"/>
        <xsl:variable name="webServiceAlias" select="string($operation/@webServiceAlias)"/>


        <dp:set-variable name="'var://context/aaa/operation'" value="$operation"/>
        <dp:set-variable name="'var://context/aaa/operation_alias'" value="$operationAlias"/>
        <dp:set-variable name="'var://context/aaa/web_service_alias'" value="$webServiceAlias"/>

        <!-- PIX/PDQ v2 Extra variables for 2nd PDP  -->
        <xsl:variable name="alternateoperationAlias"
            select="string($operation/AlternateAlias/@operationAlias)"/>
        <xsl:variable name="alternatewebServiceAlias"
            select="string($operation/AlternateAlias/@webServiceAlias)"/>
        <dp:set-variable name="'var://context/aaa/alternate_operation_alias'"
            value="$alternateoperationAlias"/>
        <dp:set-variable name="'var://context/aaa/alternate_web_service_alias'"
            value="$alternatewebServiceAlias"/>

        <!-- <xsl:variable name="destination_OID_xPath" select="concat(&apos;/soap:Envelope/soap:Body/&apos;,string($operation/@oidXpath))"/> -->
        <xsl:variable name="destinationOIDxPath" select="string($operation/@oidXpath)"/>
        <xsl:variable name="destinationOID" select="string(dyn:evaluate($destinationOIDxPath))"/>
        <dp:set-variable name="'var://context/aaa/destination_OID'" value="$destinationOID"/>

        <!-- common AAA config records: LDAP, UR, SAML, TimeOut -->
        <xsl:variable name="urConfig"
            select="document('local:///Framework/AAA/Config/AaaCommonConfig.xml')/parameters/ur"/>
        <xsl:variable name="samlConfig"
            select="document('local:///Framework/AAA/Config/AaaCommonConfig.xml')/parameters/saml"/>
        <xsl:variable name="timeoutConfig"
            select="document('local:///Framework/AAA/Config/AaaCommonConfig.xml')/parameters/timeout"/>
        <xsl:variable name="ldapConfig"
            select="document('local:///Framework/AAA/Config/AaaCommonConfig.xml')/parameters/ldap"/>

        <dp:set-variable name="'var://context/aaa/ur-config'" value="$urConfig"/>
        <dp:set-variable name="'var://context/aaa/saml-config'" value="$samlConfig"/>
        <dp:set-variable name="'var://context/aaa/timeout-config'" value="$timeoutConfig"/>
        <dp:set-variable name="'var://context/aaa/ldap-config'" value="$ldapConfig"/>

        <xsl:call-template name="loadRuntimeSecurityCtx"/>

    </xsl:template>

    <!-- Helper template for saveInitCtxPropertes. -->
    <xsl:template name="loadRuntimeSecurityCtx">

        <!-- Save the client side subject DN -->
        <dp:set-variable name="'var://context/log/subjectDN-ldap'"
            value="dp:client-subject-dn('ldap')"/>

        <!-- load information from the HIAL SAML Assertion -->
        <xsl:if
            test="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='Security']/*[local-name()='Assertion']">
            <xsl:for-each
                select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='Security']/*[local-name()='Assertion']">
                <!-- get subject DN from asserting party-->
                <xsl:variable name="subjectDN"
                    select="./*[local-name()='AuthnStatement']/*[local-name()='AuthnContext']/*[local-name()='AuthnContextDecl']/*[local-name()='AuthnMethod']/*[local-name()='Extension']/*[local-name()='AssertingParty']/*[local-name()='AuthenticatingAuthority']/text()"/>
                <xsl:variable name="srcUao"
                    select="./*[local-name()='AttributeStatement']/*[local-name()='Attribute' and @Name='urn:ehealth:names:idm:attribute:uao']/*[local-name()='AttributeValue']/text()"/>
                <xsl:variable name="srcUser"
                    select="./*[local-name()='Subject']/*[local-name()='NameID']/text()"/>
                <xsl:variable name="srcRole">
                    <xsl:for-each
                        select="./*[local-name()='Advice']/*[local-name()='XACMLAuthzDecisionStatement']/*[local-name()='Response']/*[local-name()='Result']/*[local-name()='Obligations']/*[local-name()='Obligation' and @ObligationId='http://security.bea.com/ssmws/ssm-ws-1.0.wsdl#Roles' ]">
                        <xsl:for-each select="./*[local-name()='AttributeAssignment']">
                            <xsl:if test="position() > 1">
                                <xsl:value-of select="'|'"/>
                            </xsl:if>
                            <xsl:value-of select="./text()"/>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:variable>
                <dp:set-variable name="'var://context/log/subjectDN'" value="$subjectDN"/>
                <dp:set-variable name="'var://context/log/uao'" value="$srcUao"/>
                <dp:set-variable name="'var://context/log/samlUser'" value="$srcUser"/>
                <dp:set-variable name="'var://context/log/role'" value="$srcRole"/>
            </xsl:for-each>
        </xsl:if>

        <xsl:variable name="protocol" select="dp:variable('var://service/protocol')"/>

        <xsl:if test="$protocol = 'https'">
            <dp:set-variable name="'var://context/log/subjectDN'" value="dp:client-subject-dn()"/>
        </xsl:if>

    </xsl:template>

    <!-- Call this at the start of each PDP event -->
    <xsl:template name="logPDPBusEvent">
        <xsl:call-template name="logAAAEvent">
            <xsl:with-param name="facility" select="'BUS'"/>
            <xsl:with-param name="startTime">
                <xsl:call-template name="getCurrentDateTime"/>
            </xsl:with-param>
            <xsl:with-param name="logContent" select="'Performing UR-PDP Verification'"/>
        </xsl:call-template>
    </xsl:template>


    <xsl:template name="logAAABusEvent">
        <xsl:param name="authentication"/>
        <xsl:variable name="startTime">
            <xsl:call-template name="getCurrentDateTime"/>
        </xsl:variable>
        
        <xsl:variable name="message">
            <xsl:value-of select="'AAA '"/>
            <xsl:choose>
                <xsl:when test="$authentication">
                    <xsl:value-of select="'Authentication'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'Authorization'"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="' Verification Starting'"/>
        </xsl:variable>
        
        <xsl:call-template name="logAAAEvent">
            <xsl:with-param name="facility" select="'BUS'"/>
            <xsl:with-param name="startTime" select="$startTime"/>
            <xsl:with-param name="logContent" select="$message"/>
        </xsl:call-template>
        <xsl:value-of select="$startTime"/>
    </xsl:template>
    
    <xsl:template name="logAAABusResultEvent">
        <xsl:param name="startTime"/>
        <xsl:param name="authentication"/>
        <xsl:param name="passed"/>
        
        <xsl:variable name="contentOperation">
            <xsl:choose>
                <xsl:when test="$authentication">
                    <xsl:value-of select="'AAA Authentication '"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'AAA Authorization '"/>
                </xsl:otherwise>
            </xsl:choose> 
        </xsl:variable>
        <xsl:variable name="contentPosition">
            <xsl:choose>
                <xsl:when test="$passed">
                    <xsl:value-of select="'Passed'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'Failed'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="contentMessage" select="concat($contentOperation, $contentPosition)"/>
        <xsl:variable name="logLevel">
            <xsl:choose>
                <xsl:when test="$passed">
                    <xsl:value-of select="'info'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'error'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:call-template name="logAAAEvent">
            <xsl:with-param name="facility" select="'BUS'"/>
            <xsl:with-param name="startTime" select="$startTime"/>
            <xsl:with-param name="endTime">
                <xsl:call-template name="getCurrentDateTime"/>
            </xsl:with-param>
            <xsl:with-param name="logContent" select="$contentMessage"/>
            <xsl:with-param name="logLevel" select="$logLevel"/>
        </xsl:call-template>
    </xsl:template>
    



    <!-- This template log AAA business events (aka business activities) to syslog-->
    <xsl:template name="logAAAEvent">
        <xsl:param name="logLevel" select="'info'"/>
        <xsl:param name="startTime"/>
        <xsl:param name="endTime"/>
        <xsl:param name="logContent"/>
        <xsl:param name="facility" select="'TRN'"/>
        <!-- by default always a transational event -->
        <!-- These are standard logging parameters for AAA -->
        <xsl:variable name="facility" select="$facility"/>
        <xsl:variable name="logGroup" select="'PRC'"/>
        <xsl:variable name="activity" select="'SEC'"/>

        <!-- Calls the template from processing flow library to log the AAA business activities -->
        <xsl:call-template name="hiallib:logEvent">
            <xsl:with-param name="logLevel" select="$logLevel"/>
            <xsl:with-param name="facility" select="$facility"/>
            <xsl:with-param name="logGroup" select="$logGroup"/>
            <xsl:with-param name="activity" select="$activity"/>

            <xsl:with-param name="startTime" select="$startTime"/>
            <xsl:with-param name="endTime" select="$endTime"/>
            <xsl:with-param name="logContent" select="$logContent"/>
        </xsl:call-template>
    </xsl:template>

</xsl:stylesheet>
