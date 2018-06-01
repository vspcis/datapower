<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2016. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
  apm_req.xsl version 1.07.
  
  Intention of this transform:
  
  1. If an ARM_CORRELATOR is received,
     process it as userdata, update it and pass it on.

  2. If no ARM correlator is received,
     create one and pass it on.

  3. If an ITCAMCorrelator or KD4SoapHeaderV2 is received,
     process it for our userdata and strip it.

-->

<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:dp="http://www.datapower.com/extensions" 
    xmlns:kd4="http://www.ibm.com/KD4Soap"
    xmlns:func="http://exslt.org/functions"
    xmlns:arm="https://collaboration.opengroup.org/tech/management/arm/"
    xmlns:soap11="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"
    xmlns:itcam="http://www.ibm.com/xmlns/prod/tivoli/itcam"
    exclude-result-prefixes="dp kd4 func arm itcam"
    extension-element-prefixes="dp">

    <xsl:variable name="varuserdata" select="'var://service/wsm/user-data'" />
    <xsl:variable name="filename" select="'apm_req.xsl'"/>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />

    <!-- Function to generate an UUID without '-' in uppercase -->
    <func:function name="arm:create-uuid">
        <xsl:message><xsl:value-of select="($filename)"/>: arm:create-uuid()</xsl:message>
        <func:result>
            <xsl:value-of select="translate(translate(dp:generate-uuid(), '-', ''), $lowercase, $uppercase)"/>
        </func:result>
    </func:function>

    <xsl:variable name="current-uuid" select="arm:create-uuid()"/>

    <!-- Function to generate an ARM_CORRELATOR -->
    <func:function name="arm:create-arm-id">
    <xsl:variable name="sequence-number" select="substring(arm:create-uuid(),1,16)"/>
    <xsl:message><xsl:value-of select="($filename)"/>: arm:create-arm-id()</xsl:message> 
        <func:result>
            <xsl:copy-of select="concat('002ECC00',
                $current-uuid,
                $current-uuid,
                $sequence-number,
                '0000')"/>
        </func:result>
    </func:function>

    <!-- Function to update an ARM_CORRELATOR arm-id with the current uuid-->
    <func:function name="arm:update-arm-id">
        <xsl:param name="arm-id"/>
        <xsl:param name="uuid"/>
        <xsl:message><xsl:value-of select="($filename)"/>: arm:update-arm-id(
            arm-id=<xsl:value-of select="$arm-id"/>,
            uuid=<xsl:value-of select="$uuid"/>)
        </xsl:message>
        <func:result>
            <xsl:choose>
                <!-- Check if the received ARM_CORRELATOR is Tivoli-->
                <xsl:when test="starts-with($arm-id, '002ECC') and string-length($arm-id) = 92">
                    <!-- Update the received ARM_CORRELATOR replacing the current uuid-->
                    <xsl:copy-of select="concat(substring($arm-id,1,40),$uuid, substring($arm-id,73))" /> 
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="arm:create-arm-id()" />
                </xsl:otherwise>
            </xsl:choose>
        </func:result>
    </func:function>

    <!-- Add another element to the wsm user data field -->
    <xsl:template name="update-userdata-field">
        <xsl:param name="pName" />
        <xsl:param name="pValue" />
        <xsl:param name="pName2" select="''" />
        <xsl:param name="pValue2" select="''" />

        <xsl:message><xsl:value-of select="($filename)"/>: update-userdata-field(
            pName=<xsl:value-of select="$pName"/>,
            pValue=<xsl:value-of select="$pValue"/>,
            pName2=<xsl:value-of select="$pName2"/>,
            pValue2=<xsl:value-of select="$pValue2"/>)
        </xsl:message>

        <xsl:variable name="olddata" select="dp:variable($varuserdata)"/>
        <xsl:variable name="userdata-field">
            <xsl:copy-of select="$olddata"/>
            <xsl:element name="{$pName}">
                <xsl:value-of select="$pValue" />
            </xsl:element>
            <xsl:if test="$pName2">
                <xsl:element name="{$pName2}">
                    <xsl:value-of select="$pValue2" />
                </xsl:element>
            </xsl:if>

        </xsl:variable>
        <dp:set-variable name="$varuserdata" value="$userdata-field" />
    </xsl:template>

    <!-- IdentityTransform -->
    <xsl:template match="@* | node()">
        <xsl:message><xsl:value-of select="($filename)"/>: IDENTITY transform  <xsl:value-of select="name(.)"/>: <xsl:value-of select="."/> </xsl:message>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" />
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/">
        <xsl:message><xsl:value-of select="($filename)"/>: ROOT NODE transform </xsl:message>        
        <!-- Store the Service Name and type (such as Web Service Proxy Name) -->
        <xsl:call-template name="update-userdata-field">
            <xsl:with-param name="pName"     select="'SERVICE_NAME'"/>
            <xsl:with-param name="pValue"    select="dp:variable('var://service/processor-name')"/>
            <xsl:with-param name="pName2"     select="'SERVICE_TYPE'"/>
            <xsl:with-param name="pValue2"    select="dp:variable('var://service/processor-type')"/>
        </xsl:call-template>

        <!-- Retrieve any received ARM_CORRELATOR from headers -->
        <xsl:variable name="in-arm-id" select="dp:request-header('ARM_CORRELATOR')"/>

        <!-- Store any received ARM_CORRELATOR in wsm user data -->
        <xsl:if test="$in-arm-id">
            <xsl:call-template name="update-userdata-field">
                <xsl:with-param name="pName"     select="'INBOUND_REQUEST_ARM_CORRELATOR'"/>
                <xsl:with-param name="pValue"    select="substring($in-arm-id,9,80)"/>
            </xsl:call-template>
        </xsl:if>

        <!-- Update or create an outbound ARM_CORRELATOR -->
        <xsl:variable name="out-arm-id">
            <xsl:choose>
                <xsl:when test="$in-arm-id">
                    <xsl:copy-of select="arm:update-arm-id($in-arm-id,$current-uuid)" /> 
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="arm:create-arm-id()" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Store outbound ARM_CORRELATOR in headers and wsm user data -->
        <xsl:if test="$out-arm-id">
            <dp:set-request-header name="'ARM_CORRELATOR'" value="$out-arm-id"/>
            <xsl:call-template name="update-userdata-field">
                <xsl:with-param name="pName"     select="'OUTBOUND_REQUEST_ARM_CORRELATOR'"/>
                <xsl:with-param name="pValue"    select="substring($out-arm-id,9,80)"/>
            </xsl:call-template>
        </xsl:if>

        <xsl:apply-templates/>

    </xsl:template>

    <xsl:template match="soap11:Envelope/soap11:Header/kd4:KD4SoapHeaderV2 | soap12:Envelope/soap12:Header/kd4:KD4SoapHeaderV2">
        <xsl:message><xsl:value-of select="($filename)"/>: kd4header template <xsl:value-of select="name(.)"/>: <xsl:value-of select="."/> </xsl:message>
        <xsl:variable name="kd4h">
            <xsl:value-of select="."/>
        </xsl:variable>
        <xsl:call-template name="update-userdata-field">
            <xsl:with-param name="pName"     select="'INBOUND_REQUEST_KD4_CORRELATOR'"/>
            <xsl:with-param name="pValue"    select="$kd4h"/>
        </xsl:call-template>
        <xsl:variable name="foo" select="dp:exter-correlator( $kd4h, '0' )"/>
    </xsl:template>

    <xsl:template match="soap11:Envelope/soap11:Header/itcam:ITCAMCorrelator | soap12:Envelope/soap12:Header/itcam:ITCAMCorrelator">
        <xsl:message><xsl:value-of select="($filename)"/>: ITCAMCorrelator template <xsl:value-of select="name(.)"/>: <xsl:value-of select="."/> </xsl:message>
        <xsl:call-template name="update-userdata-field">
            <xsl:with-param name="pName"     select="'INBOUND_REQUEST_ITCAM_CORRELATOR'"/>
            <xsl:with-param name="pValue"    select="."/>
        </xsl:call-template>
    </xsl:template>

</xsl:stylesheet>