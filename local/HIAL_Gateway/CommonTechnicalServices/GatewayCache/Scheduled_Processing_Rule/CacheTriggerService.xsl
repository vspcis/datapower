<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>CacheTriggerService.xsl</Filename>
<revisionlog>Initial Version</revisionlog>
<Description>

Creates a trigger message and sends it to the cache initialization mpg service

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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpcom2="http://ehealthontario.on.ca/datapower/communicationsutil/v2"
    extension-element-prefixes="dp" exclude-result-prefixes="xsl dp dpcom2" version="1.0">

    <xsl:import href="CommunicationsUtility.xsl"/>

    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>


    <xsl:template match="/">
        <xsl:variable name="config">
            <xsl:call-template name="getConfiguration"/>
        </xsl:variable>


        <xsl:variable name="soapcall">
            <Trigger>
                <xsl:value-of select="dp:generate-uuid()"/>
            </Trigger>
        </xsl:variable>


        <xsl:variable name="cacheinitconfig">
            <serviceURL>
                <xsl:value-of select="$config/CacheInitConfiguration/ServiceURL"/>
            </serviceURL>
            <soapcall>
                <xsl:copy-of select="$soapcall"/>
            </soapcall>
            <identity> </identity>
            <httpheaders> </httpheaders>
            <timeout>
                <xsl:value-of select="$config/CacheInitConfiguration/timeout"/>
            </timeout>
        </xsl:variable>


        <xsl:variable name="result">
            <xsl:call-template name="dpcom2:invokeSoapWithRetry">
                <xsl:with-param name="external" select="true()"/>
                <xsl:with-param name="invokationLog"/>
                <xsl:with-param name="invokeid" select="'Trigger'"/>
                <xsl:with-param name="retry" select="$config/retry"/>
                <xsl:with-param name="soapconfig" select="$cacheinitconfig"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:if test="count(result/operationalstatus/errormessage) = 0">
            <!-- ok -->
            <xsl:message>Policy Init has triggered Cache Init MPG Successfully</xsl:message>
        </xsl:if>
        <xsl:if test="count(result/operationalstatus/errormessage) &gt; 0">
            <!-- fail -->
            <xsl:message>Policy Init could not trigger Cache Init MPG</xsl:message>
        </xsl:if>

    </xsl:template>


    <xsl:template name="getConfiguration">
        <xsl:copy-of select="document('config/cacheinitconfig.xml')"/>
    </xsl:template>

</xsl:stylesheet>
