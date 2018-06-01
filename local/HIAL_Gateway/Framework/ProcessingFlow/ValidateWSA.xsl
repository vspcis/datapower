<?xml version="1.0" encoding="UTF-8"?>
<!--
    <CodeHeader>
    <Filename>ValidateWSA.xsl</Filename>
    <revisionlog>v1.0.0</revisionlog>
    <Description>
    Validation logic for WSA Headers
    </Description>
    <Owner>eHealthOntario</Owner>
    <LastUpdate>
    
    <Copyright>
    **************************************************************
    Copyright (c) ehealthOntario, 2015
    **************************************************************
    </Copyright>
    </CodeHeader>
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:soap11="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing"
    exclude-result-prefixes="xsl soap11 soap12 dp" extension-element-prefixes="dp" version="1.0">
    <xsl:import href="ErrorLib.xsl"/>
    
    <xsl:template name="validateBasicWSA">
        <xsl:param name="input"/>
        
        <!-- Generated Validations and triggered error codes -->
        <xsl:if test="false()">
            <!-- raise error -->
            <xsl:call-template name="raiseError">
                <xsl:with-param name="errorCode" select="'ehealth.wsaerror.0001'"/>
            </xsl:call-template>
            <dp:reject/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="getWSAResponseAction">
        <xsl:param name="input"/>
        <xsl:param name="wsdlInfo"/>
        <!-- check if the input action exists and then check if corresponding action exists -->
        <xsl:if test="$wsdlInfo/Wsdl/Operations/Operation/InputWSAction">
            <!-- this is a wsa wsdl .. so now the input action must match otherwise raise error -->
            <!-- the response operation is also defined -->
            <xsl:variable name="responseAction" select="$wsdlInfo/Wsdl/Operations/Operation/InputWSAction[text() = $input/*[local-name() = 'Envelope']/*[local-name()='Header']/wsa:Action/text()]/parent::node()/OutputWSAction/text()"/>
            <xsl:choose>
                <xsl:when test="string-length($responseAction) = 0">
                    <xsl:call-template name="raiseError">
                        <xsl:with-param name="errorCode" select="'ehealth.wsaerror.action'"/>
                    </xsl:call-template>
                    <dp:reject/>     
                </xsl:when>
                <xsl:otherwise>
                    <!-- set the wsa response context -->
                    <xsl:value-of select="$responseAction"/>
                </xsl:otherwise>
            </xsl:choose>
            
        </xsl:if>
        
    </xsl:template>
</xsl:stylesheet>