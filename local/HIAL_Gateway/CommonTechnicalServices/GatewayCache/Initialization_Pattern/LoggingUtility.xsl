<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>LoggingUtility.xsl</Filename>
<revisionlog>Initial Version
July 31: Updated Log Cateory, Facility codes</revisionlog>
<Description>

Logging utilities template file.

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
    xmlns:hiallib="http://www.ehealthontario.on.ca/hial/lib"
    extension-element-prefixes="dp" 
    exclude-result-prefixes="xsl dp" 
    version="1.0">
    
<!--    <xsl:import href="lib/CommonLoggingIntegration/CommonLogging.xsl"/>-->
    <!--<xsl:import href="lib/CommonLoggingIntegration/Log4GateWay.xsl"/>-->
    <xsl:import href="local:///Lib/CommonLogging.xsl"/> <!-- by importing a non versioned library, I'm letting the environment
                                                             control what logging mechanism is used -->
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    
    <!-- Need to to wrap this code -->
    <xsl:template name="doLog">
        <xsl:param name="ErrorCode"></xsl:param>
        <xsl:param name="Message"></xsl:param>
        <xsl:param name="Level"/>
        
        <xsl:variable name="JSONstring">
        <xsl:value-of select="concat('{ &quot;version&quot;: &quot;1.0.1&quot;,&quot;header&quot;: {
            &quot;facility&quot;: &quot;APP&quot;,
            &quot;log_group&quot;: &quot;GEN &quot;,
            &quot;activity&quot;: &quot;LOG&quot;,
            &quot;transactionID&quot;: &quot;&quot; },
            &quot;log&quot;: &quot;', $Message, '&quot;}')"/>
        </xsl:variable>
        
        <!--<xsl:call-template name="LogApplicationEvent">
            <xsl:with-param name="LogActivityName" select="'LOG'"/>
            <xsl:with-param name="LogDescription" select="$JSONstring"/>
            <xsl:with-param name="Loglevel" select="$Level"/>
        </xsl:call-template>-->
        
        
  <!--      <xsl:template name="hiallib:logCommonEvent">
            
            <xsl:param name="logLevel" select="'debug'"/>
            <xsl:param name="facility"/>
            <xsl:param name="logGroup"/>
            <xsl:param name="activity"/>
            <xsl:param name="transactionId"/>
            <xsl:param name="logContent"/>
            <xsl:param name="extraEncodedFields"/>     -->  
            
            
        <xsl:call-template name="hiallib:logCommonEvent">
            <xsl:with-param name="activity" select="'GIN'"/>
            <xsl:with-param name="facility" select="'APP'"/>
            <xsl:with-param name="logLevel" select="$Level"/>
            <xsl:with-param name="logGroup" select="'GCH'"/>
            <xsl:with-param name="logContent" select="$Message"/>
        </xsl:call-template>
        
        <!--<xsl:message>
            <xsl:value-of select="$JSONstring"/>
        </xsl:message>-->
    </xsl:template>
    
    
    <xsl:template name="AddErrorMessage">
        <xsl:param name="Message"/>
        <xsl:param name="OperationName"/>
        <!-- copy the error message block from the datapower variable and add to it -->
        <!-- <operationalstatus><errormessage operationame> -->
        <xsl:variable name="currentStatus" select="dp:variable('var://context/log/operationstatus')"/>
        <xsl:variable name="newStatus">
            <operationalstatus>
                <xsl:for-each select="$currentStatus/operationalstatus/errormessage">
                    <xsl:copy-of select="."/>
                </xsl:for-each>
                <errormessage>
                    <xsl:value-of select="$Message"/>
                    <xsl:attribute name="operationname"><xsl:value-of select="$OperationName"/></xsl:attribute>
                </errormessage>
            </operationalstatus>
        </xsl:variable>
        <dp:set-variable name="'var://context/log/operationstatus'" value="$newStatus"/>
    </xsl:template>
    
    
    <xsl:template name="checkForErrorsAndLog">
        <xsl:variable name="errors" select="dp:variable('var://context/log/operationstatus')"/>
        <xsl:for-each select="$errors/operationalstatus/errormessage">
            <!-- trasnform into error logs -->
            <xsl:call-template name="doLog">
                <xsl:with-param name="ErrorCode" select="'TBD'"/>
                <xsl:with-param name="Message" select="./text()"/>
                <xsl:with-param name="Level" select="Error"></xsl:with-param>
            </xsl:call-template>
        </xsl:for-each>
        <xsl:copy-of select="$errors"/>
    </xsl:template>
</xsl:stylesheet>