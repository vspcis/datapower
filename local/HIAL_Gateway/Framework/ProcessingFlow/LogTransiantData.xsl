<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>LogTransientData.xsl</Filename>
<revisionlog>v1.0.0</revisionlog>
<Description>
  This is the common PEP logic
</Description>
<Owner>eHealthOntario</Owner>
<LastUpdate>
April 4 2017 updated support exensible code library to let extenders perform updates to transient data - import
             SOAPPEPTransformLib.xsl
Mar 24 2017 changed include ConstructTransientData to import, it is necssary to override the gettransientmap function </LastUpdate>
<Copyright>
**************************************************************
  Copyright (c) ehealthOntario, 2015
**************************************************************
</Copyright>
</CodeHeader>
-->
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:date="http://exslt.org/dates-and-times" 
    xmlns:dp="http://www.datapower.com/extensions" 
    xmlns:dpfunc="http://www.datapower.com/extensions/functions"
    xmlns:dpwsm="http://www.datapower.com/schemas/transactions" 
    xmlns:dpconfig="http://www.datapower.com/param/config" 
    xmlns:wsmp="http://www.ibm.com/xmlns/stdwip/2011/02/ws-mediation"
    xmlns:hiallib="http://www.ehealthontario.on.ca/hial/lib"
    xmlns:txndata="http://www.ehealthontario.on.ca/hial/transientdata"
    exclude-result-prefixes="xsl dp date dpwsm dpconfig wsmp hiallib"
    extension-element-prefixes="dp" 
    version="1.0">
    
    <xsl:include href="store:///utilities.xsl"/>
    <xsl:include href="ContxtDataUtil.xsl"/>
    <xsl:import href="ConstructTransientData.xsl"/>
    <!-- added soap pep transform lib for sow 9 -->
    <xsl:import href="SOAPPEPTransformLib.xsl"/>
    
    
    
    
    
    <xsl:variable name="collon">"</xsl:variable>
    <xsl:variable name="logLeadingChar" select="'&lt;140&gt;'"/>
    <xsl:variable name="lineFeed"><xsl:text>&#10;</xsl:text></xsl:variable>
    <xsl:variable name="processingRule" select="dp:variable('var://service/transaction-rule-type')" /> 
    <xsl:variable name="txnContext"   select="dp:variable('var://context/hialPEP/txnContext')"/>
    
    <!-- Added template such that it can be overridden -->
    <xsl:template name="getPEPEnforcedFlag">
        <xsl:value-of select="dp:variable('var://context/hialPEP/pepEnforcedFlag')"/>
        <xsl:message dp:priority="error">YYY: GWLogResponseRule <xsl:value-of select="dp:variable('var://context/hialPEP/pepEnforcedFlag')"/></xsl:message>
    </xsl:template>
    
    
    <xsl:template match="/">
        <!-- execute the correct transient data update -->
        <xsl:call-template name="captureExecutedPolicy">
            <xsl:with-param name="PEPName" select="$PEPName"/>
        </xsl:call-template>
        
        
        <xsl:variable name="pepEnforcedFlag">
            <xsl:call-template name="getPEPEnforcedFlag"/>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$pepEnforcedFlag = 'true'">
               <xsl:call-template name="performLoggingTransientData"/>
               <LoggingTransientData>true</LoggingTransientData> 
            </xsl:when>
            <xsl:otherwise>
               <LoggingTransientData>false</LoggingTransientData>
            </xsl:otherwise>
        </xsl:choose>
        
        
    </xsl:template>
    
    
    <!-- This template will perform the logic to log the transient data -->
    <xsl:template name="performLoggingTransientData">
        
        <!-- derive the activity type -->
        <xsl:variable name="activity">
            <xsl:choose>
                <xsl:when test="$processingRule = 'response'">
                    <xsl:value-of select="'ERP'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'EER'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Log the current business event -->        
        <xsl:call-template name="hiallib:logEvent">
            <xsl:with-param name="logLevel" select="'info'"/>
            <xsl:with-param name="facility" select="'BUS'"/>
            <xsl:with-param name="logGroup" select="'FLW'"/>
            <xsl:with-param name="activity" select="$activity"/>
            <xsl:with-param name="transactionId" select="$txnContext/txnContext/globalID/text()"/>
            <xsl:with-param name="logContent" select="concat('Starting log the transient data to Rsyslog service for rule ', $processingRule)"/>
        </xsl:call-template>

        <!-- build transient data based on current flow progress -->
        <xsl:call-template name="buildTransientData"/>
        
        <xsl:variable name="transientData" select="dp:variable('var://context/logging/transientData')"/>
        <xsl:variable name="txnCtx" select="dp:variable('var://context/hialPEP/txnContext')"/>        
        <xsl:variable name="globeId" select="$txnCtx/txnContext/globalID/text()"/>
        
        <!-- construct the log content base on error codes -->
        <xsl:variable name="logContent">
            <xsl:choose>
                <xsl:when test="dp:variable('var://service/transaction-rule-type') = 'error'">
                    <xsl:value-of select="'Log transient data for error response'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'Log transient data for successful response'"/>
                </xsl:otherwise>
            </xsl:choose>            
        </xsl:variable>
        
        <!-- distinguish the log level -->
        <xsl:variable name="logLevel">
            <xsl:choose>
                <xsl:when test="dp:variable('var://service/transaction-rule-type') = 'error'">
                    <xsl:value-of select="'error'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'info'"/>
                </xsl:otherwise>
            </xsl:choose>            
        </xsl:variable>        
        
        <!-- call template to build the transient data log entry -->
        <xsl:variable name="transitientDataJson">
            <xsl:call-template name="buildTransientDataLogEntry"/>
        </xsl:variable> 
        
        <!-- Get the UTC Time -->
        <xsl:variable name="timeStamp" select="number(dp:time-value())"/>
        <xsl:variable name="millionSeconds" select="substring($timeStamp, 11, 3)"/>
        <xsl:variable name="utcTimeStamp" select="concat(substring(dpfunc:zulu-time(), 1, 19), '.',$millionSeconds,'+00:00')"/>
        
        <xsl:variable name="jsonLogEntry">{"header":{"facility":"AUD","log_group":"LOG","activity":"BUS","Severity":"LOG_INFO","transaction_ID":"<xsl:value-of select="$globeId"/>","log_timestamp":"<xsl:value-of select="$utcTimeStamp"/>"},<xsl:value-of select="string($transitientDataJson)"/>,"MsgPayload":"<xsl:value-of select="$logContent"/>"}</xsl:variable>     
        
        <!-- get the host name of hial gateway with value in IP address -->
        <xsl:variable name="localServiceAddress"  select="dp:variable('var://service/local-service-address')"/>
        <xsl:variable name="gatewayHost" select="substring-before($localServiceAddress,':')"/>
        
        <!-- Concat all log entry part together -->
        <xsl:variable name="logEntry" select="concat($logLeadingChar, $utcTimeStamp,' ',$gatewayHost,' HIALGATEWAY: ', normalize-space($jsonLogEntry), $lineFeed)"/>
        
        <!-- put the prepared log entry to context variable which will be picked up by Result action -->
        <dp:set-variable name="'var://context/syslogContent'"   value="$logEntry" />
        
        <!-- Log the current business event -->        
        <xsl:call-template name="hiallib:logEvent">
            <xsl:with-param name="logLevel" select="'info'"/>
            <xsl:with-param name="facility" select="'BUS'"/>
            <xsl:with-param name="logGroup" select="'FLW'"/>
            <xsl:with-param name="activity" select="$activity"/>
            <xsl:with-param name="transactionId" select="$txnContext/txnContext/globalID/text()"/>
            <xsl:with-param name="logContent" select="concat('End of logging the transient data to Rsyslog service for rule ', $processingRule)"/>
        </xsl:call-template>        
        
    </xsl:template>

</xsl:stylesheet>
