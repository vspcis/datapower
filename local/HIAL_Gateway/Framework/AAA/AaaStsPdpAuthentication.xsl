<?xml version="1.0" encoding="UTF-8"?>
<!-- Change Log: Oct 19 2015 : 6617 added AAA Business event logging 
    
    
    -->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:wss="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" 
    xmlns:dsig="http://www.w3.org/2000/09/xmldsig#"
    xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:exslt="http://exslt.org/common" 
    extension-element-prefixes="dp exslt"
    exclude-result-prefixes="soap saml wss dsig dp exslt">
    
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" />
    <xsl:include href="AaaCommonLibrary.xsl" />
    
    <!-- This is the main template -->
    <xsl:template match="/">
        <xsl:variable name="busStartTime">
            <xsl:call-template name="logAAABusEvent">
                <xsl:with-param name="authentication" select="true()"/>
            </xsl:call-template>
        </xsl:variable>
        <!-- save the client request SAML assertion into DP variable -->
        <dp:set-variable name="'var://context/aaa/request-saml-token'" value="/identity/entry[@type = 'saml-authen-name']/assertion/saml:Assertion" />

        <!--saml validation (signature and time) -->
        <xsl:variable name="samlValidation">
            <xsl:call-template name="loggedSamlValidation">
                <xsl:with-param name="assertion" select="/identity/entry[@type = 'saml-authen-name']/assertion/saml:Assertion" />
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:message>
            saml-validation: <xsl:value-of select="$samlValidation" />
        </xsl:message>
        
        <xsl:variable name="decision">
        <xsl:choose>
            <xsl:when test="$samlValidation = &apos;&apos;">
                
                <!-- STS call for a UR saml -->
                <xsl:variable name="stsTokenResult">
                    <xsl:call-template name="getStsToken">
                        <xsl:with-param name="assertion" select="/identity/entry[@type='saml-authen-name']/assertion/saml:Assertion" />
                    </xsl:call-template>
                </xsl:variable>
                
                <xsl:choose>
                    <xsl:when test="$stsTokenResult//saml:Assertion">
                        <xsl:copy-of select="$stsTokenResult" />
                        <dp:set-variable name="'var://context/aaa/ur-saml-token'" value="$stsTokenResult" />
                    </xsl:when>
                    <xsl:otherwise>
                        <dp:set-variable name="'var://context/aaa/error-message'" value="string($stsTokenResult)" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            
            <xsl:otherwise>
                <dp:set-variable name="'var://context/aaa/error-message'" value="string($samlValidation)" />
            </xsl:otherwise>
        </xsl:choose>
        </xsl:variable>
        <xsl:call-template name="logAAABusResultEvent">
            <xsl:with-param name="startTime" select="$busStartTime"/>
            <xsl:with-param name="passed" select="count($decision/*) &gt; 0"/>
            <xsl:with-param name="authentication" select="true()"/>
        </xsl:call-template>
        <xsl:copy-of select="$decision"/>
    </xsl:template>
</xsl:stylesheet>
