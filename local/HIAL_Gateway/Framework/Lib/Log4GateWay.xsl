<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>ConstructTransientData.xsl</Filename>
<revisionlog>v1.0.0</revisionlog>
<Description>
  This is the common PEP logic
</Description>
<Owner>eHealthOntario</Owner>
<LastUpdate>Setp 29, 2015</LastUpdate>
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
    xmlns:dpwsm="http://www.datapower.com/schemas/transactions" 
    xmlns:dpconfig="http://www.datapower.com/param/config"
    xmlns:hiallib="http://www.ehealthontario.on.ca/hial/lib"
    exclude-result-prefixes="xsl dp date dpwsm dpconfig"
    extension-element-prefixes="dp" 
    version="1.0">
    
    <xsl:import href="local:Lib/CommonLogging.xsl"/>
    
    <!-- 
       This template perform the logging, caller need to specify each parameter
       and the log level is using a default level as debug
    -->
    <xsl:template name="hiallib:logEvent">

        <xsl:param name="logLevel" select="'debug'"/>
        <xsl:param name="errorCode" select="&apos;&apos;"/>
        <xsl:param name="facility"/>
        <xsl:param name="logGroup"/>
        <xsl:param name="activity"/>
        <xsl:param name="transactionId"/>        
        <xsl:param name="startTime"/>
        <xsl:param name="endTime"/>
        <xsl:param name="logContent"/>
        
        <xsl:variable name="txnContext" select="dp:variable('var://context/hialPEP/txnContext')"/>
        
        <xsl:variable name="sequence">
            <xsl:call-template name="getNextSequence"/>
        </xsl:variable>
        
        <xsl:variable name="txnId">
            <xsl:choose>
                <xsl:when test="string-length($transactionId) &gt; 0">
                    <xsl:value-of select="$transactionId"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$txnContext/txnContext/globalID/text()"/>              
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="extraFields">
            <xsl:if test="string-length($startTime) &gt; 0">
            startTime: <xsl:value-of select="$startTime"/>,
            </xsl:if>            
            <xsl:if test="string-length($endTime) &gt; 0">
            endTime: <xsl:value-of select="$endTime"/>,  
            </xsl:if>            
            <xsl:if test="string-length($errorCode) &gt; 0">
            errorCode: <xsl:value-of select="$errorCode"/>
            </xsl:if>
        </xsl:variable>
        
        <xsl:call-template name="hiallib:logCommonEvent">
            <xsl:with-param name="logLevel" select="$logLevel"/>
            <xsl:with-param name="facility" select="$facility"/>
            <xsl:with-param name="logGroup" select="$logGroup"/>
            <xsl:with-param name="activity" select="$activity"/>
            <xsl:with-param name="transactionId" select="$txnId"/>
            <xsl:with-param name="sequence" select="$sequence"/>            
            <xsl:with-param name="extraEncodedFields" select="$extraFields"/>
            <xsl:with-param name="logContent" select="$logContent"/>
        </xsl:call-template>

        <!-- store the current error logging details into context except for soapFaultProcessing -->
        <xsl:if test="($logLevel = 'error') and ( not($activity = 'ERR')) ">            
            <xsl:variable name="timeStamp">
                <xsl:call-template name="getCurrentDateTime"/>
            </xsl:variable>
            
            <xsl:variable name="transientError">
                <TransientError>
                    <Activity><xsl:value-of select="$activity"/></Activity>
                    <ErrorCode><xsl:value-of select="dp:variable('var://service/error-code')"/></ErrorCode>
                    <Timestamp><xsl:value-of select="$timeStamp"/></Timestamp>
                    <Description><xsl:value-of select="$logContent"/></Description>
                </TransientError>
            </xsl:variable>

            <dp:set-variable name="'var://context/logging/transientError'" value="$transientError" />
        </xsl:if>

    </xsl:template>

    <!-- a template that retrieve the next sequence number -->
    <xsl:template name="getNextSequence">
        <xsl:variable name="currentSeq">
            <xsl:choose>
                <xsl:when test="dp:variable('var://context/logging/seq')">
                    <xsl:value-of select="number(dp:variable('var://context/logging/seq'))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="number(1)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="next" select="$currentSeq  + 1"/>
        <dp:set-variable name="'var://context/logging/seq'" value="string($next)"/>
        <xsl:value-of select="$currentSeq"/>
    </xsl:template>
    
    <!-- This template will retrieve the sequence number in previous logg-->
    <xsl:template name="getPreviousLoggingSeq">
        <xsl:variable name="previousLogResult" select="dp:variable('var://context/logging/logResult')"/>
        <xsl:variable name="seqNumber" select="$previousLogResult/output/sequence/text()"/>
    </xsl:template>
    
    <!-- This template retrieve the current date time with million seconds value -->
    <xsl:template name="getCurrentDateTime">
        <xsl:variable name="timeStamp" select="number(dp:time-value())"/>
        <xsl:variable name="millionSeconds" select="substring($timeStamp, 11, 3)"/>        
        <xsl:variable name="formattedTime" select="concat(date:format-date(date:date-time(), 'yyyy-MM-dd HH:mm:ssZ'), '.', $millionSeconds)"/>
        <xsl:value-of select="string($formattedTime)"/>
    </xsl:template>
    
    <!-- log debug information -->
    <xsl:template name="debugLog">
        <xsl:param name="logContent"/>
        <xsl:param name="fileName"/>
        
        <xsl:variable name="logEntry">
            { TimeStamp:<xsl:call-template name="getCurrentDateTime"/>,
              File:<xsl:value-of select="$fileName"/>,
              Content:<xsl:value-of select="$logContent"/>
            }
        </xsl:variable>        

        <xsl:message dp:type="Gateway_Debug" dp:priority="debug">
            <xsl:value-of select="normalize-space($logEntry)"/>
        </xsl:message>
    </xsl:template>
    
</xsl:stylesheet>