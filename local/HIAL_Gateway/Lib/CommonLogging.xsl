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
    xmlns:dpfunc="http://www.datapower.com/extensions/functions"
    xmlns:dpwsm="http://www.datapower.com/schemas/transactions" 
    xmlns:dpconfig="http://www.datapower.com/param/config"
    xmlns:hiallib="http://www.ehealthontario.on.ca/hial/lib"
    exclude-result-prefixes="xsl dp date dpwsm dpconfig"
    extension-element-prefixes="dp" 
    version="1.0">
    
    <xsl:include href="store:///utilities.xsl"/>
    
    <xsl:variable name="smallcase" select="'abcdefghijklmnopqrstuvwxyz'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
    <xsl:variable name="loggingPriority" select="'debug,information,notice,warnning,error,critical,alert,emergency'"/>
    <xsl:variable name="loggingConfig" select="document('local:///Lib/LoggingConf.xml')"/>
    
    <!-- Template to log a business event -->
    <xsl:template name="hiallib:logBusinessEvent">        
        <xsl:param name="logLevel" select="'debug'"/>
        <xsl:param name="logGroup"/>
        <xsl:param name="activity"/>
        <xsl:param name="transactionId"/>
        <xsl:param name="sequence"/>
        <xsl:param name="logContent"/>
        <xsl:param name="extraEncodedFields"/>           
        
        
        <xsl:call-template name="hiallib:logCommonEvent">
            <xsl:with-param name="logLevel" select="$logLevel"/>
            <xsl:with-param name="facility" select="'BUS'"/>
            <xsl:with-param name="activity" select="$activity"/>
            <xsl:with-param name="transactionId" select="$transactionId"/>
            <xsl:with-param name="sequence" select="$sequence"/>
            <xsl:with-param name="logContent" select="$logContent"/>
            <xsl:with-param name="extraEncodedFields" select="$extraEncodedFields"/>
        </xsl:call-template>
    </xsl:template>
    
    
    <!-- Template to log a transaction event -->
    <xsl:template name="hiallib:logTransactionEvent">        
        <xsl:param name="logLevel" select="'debug'"/>
        <xsl:param name="logGroup"/>
        <xsl:param name="activity"/>
        <xsl:param name="transactionId"/>
        <xsl:param name="sequence"/>
        <xsl:param name="logContent"/>
        <xsl:param name="extraEncodedFields"/>           
        
        
        <xsl:call-template name="hiallib:logCommonEvent">
            <xsl:with-param name="logLevel" select="$logLevel"/>
            <xsl:with-param name="facility" select="'TRN'"/>
            <xsl:with-param name="activity" select="$activity"/>
            <xsl:with-param name="transactionId" select="$transactionId"/>
            <xsl:with-param name="sequence" select="$sequence"/>
            <xsl:with-param name="logContent" select="$logContent"/>
            <xsl:with-param name="extraEncodedFields" select="$extraEncodedFields"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- Template to log a transaction event -->
    <xsl:template name="hiallib:logApplicationEvent">        
        <xsl:param name="logLevel" select="'debug'"/>
        <xsl:param name="logGroup"/>
        <xsl:param name="activity"/>
        <xsl:param name="transactionId"/>
        <xsl:param name="sequence"/>
        <xsl:param name="logContent"/>
        <xsl:param name="extraEncodedFields"/>           
        
        
        <xsl:call-template name="hiallib:logCommonEvent">
            <xsl:with-param name="logLevel" select="$logLevel"/>
            <xsl:with-param name="facility" select="'APP'"/>
            <xsl:with-param name="activity" select="$activity"/>
            <xsl:with-param name="transactionId" select="$transactionId"/>
            <xsl:with-param name="sequence" select="$sequence"/>
            <xsl:with-param name="logContent" select="$logContent"/>
            <xsl:with-param name="extraEncodedFields" select="$extraEncodedFields"/>
        </xsl:call-template>
    </xsl:template>    
    
    
    <!-- 
       This template perform the logging, caller need to specify each parameter
       and the log level is using a default level as debug
    -->
    <xsl:template name="hiallib:logCommonEvent">
        
        <xsl:param name="logLevel" select="'debug'"/>
        <xsl:param name="facility"/>
        <xsl:param name="logGroup"/>
        <xsl:param name="activity"/>
        <xsl:param name="transactionId"/>
        <xsl:param name="sequence" select="''"/>
        <xsl:param name="logContent"/>
        <xsl:param name="extraEncodedFields"/>        
        
        <xsl:variable name="parsedLoggingLevel">
            <xsl:call-template name="parseLoggingLevel">
                <xsl:with-param name="facility" select="$facility"/>
                <xsl:with-param name="logGroup" select="$logGroup"/>
                <xsl:with-param name="userLoggingLevel" select="$logLevel"/>
            </xsl:call-template>
        </xsl:variable>        
        
        <!-- parse the proper logging level -->
        <xsl:if test="string-length($parsedLoggingLevel) &gt; 0">
            
            <xsl:variable name="severity">
                <xsl:call-template name="parseSevirity">
                    <xsl:with-param name="loggingLevel" select="$parsedLoggingLevel"/>
                </xsl:call-template>
            </xsl:variable>
            
            <!-- store the datapower internal transaction id to log entry -->
            <xsl:variable name="tid" select="dp:variable('var://service/transaction-id')"/>
            
            <xsl:variable name="msgPayload">
                    <xsl:choose>
                        <xsl:when test="string-length($extraEncodedFields) &gt; 0">
                            <xsl:value-of select="concat('tid=', $tid, '. ', $logContent,'. ',$extraEncodedFields)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat('tid=', $tid, '. ', $logContent)"/>
                        </xsl:otherwise>
                    </xsl:choose>
            </xsl:variable>
            
            <!-- Get the UTC Timestamp -->
            <xsl:variable name="timeStamp" select="number(dp:time-value())"/>
            <xsl:variable name="millionSeconds" select="substring($timeStamp, 11, 3)"/>
            <xsl:variable name="utcTimeStamp" select="concat(substring(dpfunc:zulu-time(), 1, 19), '.',$millionSeconds,'+00:00')"/>            
            
            <xsl:variable name="logEntry"> 
               {"header":{"facility":"<xsl:value-of select="$facility"/>","log_group":"<xsl:value-of select="$logGroup"/>","activity":"<xsl:value-of select="$activity"/>","Severity":"<xsl:value-of select="$severity"/>","transaction_ID":"<xsl:value-of select="$transactionId"/>" 
                <xsl:if test="string-length($sequence) &gt; 0">,"seq":"<xsl:value-of select="$sequence"/>"</xsl:if>,"log_timestamp":"<xsl:value-of select="$utcTimeStamp"/>"},"MsgPayload":"<xsl:value-of select="$msgPayload"/>"} 
            </xsl:variable>

            <xsl:message dp:type="{$facility}" dp:priority="{$parsedLoggingLevel}">
                <xsl:value-of select="normalize-space($logEntry)"/>
            </xsl:message>
        </xsl:if>
        
    </xsl:template>
    
    <!-- 
        This template will parse the logging level
        return empty string if logging is not allowed
        return logging level if logging is allowed
    -->
    <xsl:template name="parseLoggingLevel">
        <xsl:param name="facility"/>
        <xsl:param name="logGroup"/>
        <xsl:param name="userLoggingLevel"/>
        
        <xsl:variable name="configedLevel">
            <xsl:choose>
                <xsl:when test="$loggingConfig/LoggingConfig/Facilities/Facility[@type=$facility]/Group[@type=$logGroup]">
                    <xsl:value-of select="$loggingConfig/LoggingConfig/Facilities/Facility[@type=$facility]/Group[@type=$logGroup]/@level"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$loggingConfig/LoggingConfig/Facilities/Facility[@type=$facility]/@level"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="deniedLevels" select="substring-before($loggingPriority, $configedLevel)"/>
        <xsl:variable name="derivedLoggingLevel">
            <xsl:choose>
                <xsl:when test="$facility = 'BUS'">
                    <xsl:value-of select="$userLoggingLevel"/>
                </xsl:when>
                <xsl:when test="string-length($configedLevel) = 0">
                    <xsl:value-of select="''"/>
                </xsl:when>
                <xsl:when test="contains($deniedLevels, $userLoggingLevel)">
                    <xsl:value-of select="''"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$userLoggingLevel"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!--xsl:message dp:type="xslt" dp:priority="debug">
            <xsl:value-of select="concat('logging level derive, facility:[', $facility, '], logGroup:[', $logGroup, '], userlevel:[', $userLoggingLevel,'], configured level:[', $configedLevel,'], derived level:[', $derivedLoggingLevel,']')"/>
        </xsl:message-->
        
        <xsl:value-of select="$derivedLoggingLevel"/>
    </xsl:template>
    
    
    <!-- -->
    <xsl:template name="parseSevirity">
        <xsl:param name="loggingLevel"/>       
        <xsl:variable name="severityValue" select="concat('LOG_', $loggingLevel)"/>
        <xsl:value-of select="translate($severityValue, $smallcase, $uppercase)" />        
    </xsl:template>    
    
    
    
</xsl:stylesheet>