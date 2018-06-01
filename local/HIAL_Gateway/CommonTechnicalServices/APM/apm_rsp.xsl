<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2016. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
  apm_rsp.xsl version 1.07.

  Intention of this transform:

  1. If an ARM_CORRELATOR is received from the frontend,
     process it as userdata, update it and pass it on.

  2. If an ITCAMCorrelator or KD4SoapHeaderV2 is received from the frontend,
     process it for our userdata and strip it.
     The response to the frontend should have a matching header as well.

-->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:kd4="http://www.ibm.com/KD4Soap"
    xmlns:soap11="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"
    xmlns:itcam="http://www.ibm.com/xmlns/prod/tivoli/itcam"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    exclude-result-prefixes="dp kd4 fn itcam"
    extension-element-prefixes="dp">

    <xsl:variable name="varuserdata" select="'var://service/wsm/user-data'" />
    <xsl:variable name="filename" select="'apm_rsp.xsl'"/>

    <!-- Add another element to the wsm user data field -->
    <xsl:template name="update-userdata-field">
        <xsl:param name="pName" />
        <xsl:param name="pValue" />
        <xsl:message><xsl:value-of select="($filename)"/>: update-userdata-field(
            pName=<xsl:value-of select="$pName"/>,
            pValue=<xsl:value-of select="$pValue"/>)
        </xsl:message>
        <xsl:variable name="olddata" select="dp:variable($varuserdata)"/>
        <xsl:variable name="userdata-field">
            <xsl:copy-of select="$olddata"/>
            <xsl:element name="{$pName}">
                <xsl:value-of select="$pValue" />
            </xsl:element>
        </xsl:variable>
        <dp:set-variable name="$varuserdata" value="$userdata-field" />
    </xsl:template>

    <!-- IdentityTransform -->
    <xsl:template match="@* | node()">
        <xsl:message><xsl:value-of select="($filename)"/>: IDENTITY transform on <xsl:value-of select="name(.)"/>: <xsl:value-of select="."/> </xsl:message>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" />
        </xsl:copy>
    </xsl:template>

    <xsl:template name="update-kd4header">
        <xsl:variable name="varuserdata" select="'var://service/wsm/user-data'" />
        <xsl:variable name="olddata" select="dp:variable($varuserdata)"/>
        <xsl:variable name="in-kd4-id" select="$olddata/INBOUND_REQUEST_KD4_CORRELATOR/text()"/>
        <xsl:if test="($in-kd4-id)">
            <xsl:message><xsl:value-of select="($filename)"/>: Running KD4SoapHeaderV2 update template</xsl:message>
            <!-- no KD4 header from backend but the frontend provided one, respond with one -->
            <kd4:KD4SoapHeaderV2><xsl:value-of select="dp:exter-correlator( 'NEW_CORRELATOR', '1' )"/></kd4:KD4SoapHeaderV2>
        </xsl:if>
    </xsl:template>

    <xsl:template name="update-itcamcorrelator">
        <!-- Update sent ITCAM_CORRELATOR from request -->
        <xsl:variable name="varuserdata" select="'var://service/wsm/user-data'" />
        <xsl:variable name="olddata" select="dp:variable($varuserdata)"/>
        <xsl:variable name="in-itcam-id" select="$olddata/INBOUND_REQUEST_ITCAM_CORRELATOR/text()"/>
        <xsl:if test="$in-itcam-id">
            <xsl:message><xsl:value-of select="($filename)"/>: Running ITCAMCorrelator update template</xsl:message>
            <xsl:element name="ITCAMCorrelator" namespace="http://www.ibm.com/xmlns/prod/tivoli/itcam">
                <xsl:value-of select="$in-itcam-id"/>
            </xsl:element>
            <!-- Store ITCAM_CORRELATOR-->
            <xsl:call-template name="update-userdata-field">
                <xsl:with-param name="pName"     select="'OUTBOUND_RESPONSE_ITCAM_CORRELATOR'"/>
                <xsl:with-param name="pValue"    select="$in-itcam-id"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template match="/">
        <xsl:message><xsl:value-of select="($filename)"/>: ROOT template </xsl:message>
        <!-- Store Response Code in wsm user data -->
        <xsl:variable name="response-code" select="normalize-space(dp:response-header('x-dp-response-code'))" />
        <xsl:if test="$response-code">
            <xsl:call-template name="update-userdata-field">
                <xsl:with-param name="pName"     select="'INBOUND_RESPONSE_CODE'"/>
                <xsl:with-param name="pValue"    select="$response-code"/>
            </xsl:call-template>
        </xsl:if>

        <!-- Retrieve any received ARM_CORRELATOR from headers -->
        <xsl:variable name="in-arm-id" select="dp:request-header('ARM_CORRELATOR')"/>
        <xsl:message><xsl:value-of select="($filename)"/>: in-arm-id=<xsl:value-of select="$in-arm-id"/></xsl:message>

        <xsl:variable name="olddata" select="dp:variable($varuserdata)"/>
        <xsl:message><xsl:value-of select="($filename)"/>: olddata=<xsl:value-of select="$olddata"/></xsl:message>

        <!-- Get the inbound ARM_CORRELATOR before updating wsm user data -->
        <xsl:variable name="out-arm-id" select="$olddata/INBOUND_REQUEST_ARM_CORRELATOR/text()"/>
        <xsl:message><xsl:value-of select="($filename)"/>: out-arm-id=<xsl:value-of select="$out-arm-id"/></xsl:message>

        <!-- choose what ARM_CORRELATOR to store in wsm user data -->
        <xsl:variable name="store-arm-id">
            <xsl:choose>
                <xsl:when test="$in-arm-id">
                    <xsl:copy-of select="substring($in-arm-id,9,80)" />
                </xsl:when>
                <xsl:otherwise>
                    <!-- Reuse outbound request ARM_CORRELATOR as is seems WAS doesn't respond with the header-->
                    <xsl:copy-of select="$olddata/OUTBOUND_REQUEST_ARM_CORRELATOR/text()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:message><xsl:value-of select="($filename)"/>: store-arm-id=<xsl:value-of select="$store-arm-id"/></xsl:message>

        <!-- Store ARM_CORRELATOR in wsm user data -->
        <xsl:if test="$store-arm-id">
            <xsl:call-template name="update-userdata-field">
                <xsl:with-param name="pName"     select="'INBOUND_RESPONSE_ARM_CORRELATOR'"/>
                <xsl:with-param name="pValue"    select="concat($store-arm-id, 'FF')"/>
            </xsl:call-template>
            <xsl:message><xsl:value-of select="($filename)"/>: Ran update-userdata-field</xsl:message>
        </xsl:if>

        <!-- Update sent ARM_CORRELATOR from headers -->
        <!-- Store any received or sent ARM_CORRELATOR in wsm user data -->
        <xsl:if test="$out-arm-id">
            <!-- It seems other data collectors don't set the response header -->
            <dp:set-response-header name="'ARM_CORRELATOR'" value="$out-arm-id"/>
            <xsl:call-template name="update-userdata-field">
                <xsl:with-param name="pName"     select="'OUTBOUND_RESPONSE_ARM_CORRELATOR'"/>
                <xsl:with-param name="pValue"    select="concat($out-arm-id, 'FF')"/>
            </xsl:call-template>
            <xsl:message><xsl:value-of select="($filename)"/>: Called update-userdata-field, output ARM_CORRELATOR should be set</xsl:message>
        </xsl:if>

        <xsl:apply-templates/>

    </xsl:template>
    
    <xsl:template match="soap11:Envelope">
        <xsl:message><xsl:value-of select="($filename)"/>: Running SOAP 1.1 envelope template</xsl:message>
        <xsl:copy>
           <xsl:if test="not(soap11:Header)">
                <xsl:message><xsl:value-of select="($filename)"/>: No SOAP 1.1 header</xsl:message>
                <soap11:Header>
                    <xsl:call-template name="update-kd4header"/>
                    <xsl:call-template name="update-itcamcorrelator"/>
                </soap11:Header>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="soap12:Envelope">
        <xsl:message><xsl:value-of select="($filename)"/>: Running SOAP 1.2 envelope template</xsl:message>
        <xsl:copy>
            <xsl:if test="not(soap12:Header)">
                <xsl:message><xsl:value-of select="($filename)"/>: No SOAP 1.2 header</xsl:message>
                <soap12:Header>
                    <xsl:call-template name="update-kd4header"/>
                    <xsl:call-template name="update-itcamcorrelator"/>
                </soap12:Header>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="soap11:Envelope/soap11:Header | soap12:Envelope/soap12:Header">
        <xsl:message><xsl:value-of select="($filename)"/>: Running header template</xsl:message>
        <xsl:copy>
            <xsl:if test="not(kd4:KD4SoapHeaderV2)">
                <xsl:call-template name="update-kd4header"/>
            </xsl:if>    
            <xsl:if test="not(itcam:ITCAMCorrelator)">
                <xsl:call-template name="update-itcamcorrelator"/>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="soap11:Envelope/soap11:Header/itcam:ITCAMCorrelator | soap12:Envelope/soap12:Header/itcam:ITCAMCorrelator">
        <xsl:message><xsl:value-of select="($filename)"/>: Running incoming ITCAMCorrelator template</xsl:message>
        <xsl:call-template name="update-userdata-field">
            <xsl:with-param name="pName"     select="'INBOUND_RESPONSE_ITCAM_CORRELATOR'"/>
            <xsl:with-param name="pValue"    select="."/>
        </xsl:call-template>
        <xsl:call-template name="update-itcamcorrelator"/>
    </xsl:template>

    <xsl:template match="soap11:Envelope/soap11:Header/kd4:KD4SoapHeaderV2 | soap12:Envelope/soap12:Header/kd4:KD4SoapHeaderV2">
        <xsl:message><xsl:value-of select="($filename)"/>: Running incoming KD4SoapHeaderV2 template</xsl:message>
        <xsl:call-template name="update-userdata-field">
            <xsl:with-param name="pName"     select="'INBOUND_RESPONSE_KD4_CORRELATOR'"/>
            <xsl:with-param name="pValue"    select="."/>
        </xsl:call-template>
        <xsl:call-template name="update-kd4header"/>
    </xsl:template>

</xsl:stylesheet>