<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>FullMessageBodyLogging.xsl</Filename>
<revisionlog>v2.0.0</revisionlog>
<Description>
  Logic for performing full message body logging
</Description>
<Owner>eHealthOntario</Owner>
July 5 2017 - Extra error handling logic in error flow since FMBL errors can occur in the error flow.
May 11 2017 - added support for Error flow FMBL
May 9 2017 - extracted the serialization part of the code into function that can be overridden getSerializatedData
May 23 - Corrected removed newer code
May 15 - base64 encoding for FMBL.
Mar 23 - added extenable getPEPEnforcedFlag</LastUpdate>
<LastUpdate>August 18, 2016 - Fix for FMBL on Message adapters</LastUpdate>
<Copyright>
**************************************************************
  Copyright (c) ehealthOntario, 2017
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
    xmlns:regexp="http://exslt.org/regular-expressions"
    xmlns:wsmp="http://www.ibm.com/xmlns/stdwip/2011/02/ws-mediation"
    xmlns:hiallib="http://www.ehealthontario.on.ca/hial/lib"
    exclude-result-prefixes="xsl dp date dpwsm dpconfig wsmp"
    extension-element-prefixes="dp" 
    version="1.0">
    
    <xsl:strip-space elements="*"/>
    
    <xsl:include href="store:///utilities.xsl"/>
    <xsl:include href="local:Framework/Lib/Log4GateWay.xsl" />
    <xsl:include href="ConstructTransientData.xsl"/>
    <!-- added for Executed Policies tracking -->
    <xsl:import href="SOAPPEPTransformLib.xsl"/>
    <xsl:import href="ErrorLib.xsl"/>
    
    
    <xsl:variable name="logLeadingChar" select="'&lt;181&gt;'"/>
    <xsl:variable name="txnContext"   select="dp:variable('var://context/hialPEP/txnContext')"/>
    <xsl:variable name="forwardSlash">/</xsl:variable>
    <xsl:variable name="dobleQuote">"</xsl:variable>
    <xsl:variable name="enCodedForwardSlash">\/</xsl:variable>
    <xsl:variable name="enCodedDoubleQuote">\"</xsl:variable>
    <xsl:variable name="processingRule" select="dp:variable('var://service/transaction-rule-type')" /> 
    
    
    <!-- Added template such that it can be overridden -->
    <xsl:template name="getPEPEnforcedFlag">
        <xsl:value-of select="dp:variable('var://context/hialPEP/pepEnforcedFlag')"/>
    </xsl:template>
    
    <xsl:template match= "/" xml:space="default">
        
        <xsl:call-template name="captureExecutedPolicy">
            <xsl:with-param name="PEPName" select="$PEPName"/>
        </xsl:call-template>
        
        <xsl:variable name="pepEnforcedFlag">
            <xsl:call-template name="getPEPEnforcedFlag"/>
        </xsl:variable>
        
        <xsl:if test="$pepEnforcedFlag = 'true'">          
           <xsl:call-template name="performFMBL"/>
        </xsl:if>
        
    </xsl:template>


    <!-- This template perform the FMBL -->
    <xsl:template name="performFMBL">

        <!-- build transient data based on current flow progress -->
        <xsl:call-template name="buildTransientData">
            <xsl:with-param name="Operation" select="concat('FMBL', $processingRule)"/>
        </xsl:call-template>
        
        <!-- Load the MQ configuration -->
        <xsl:variable name="fmblConfig" select="document('Config/Config.xml')"/>
        <xsl:variable name="dqmq" select="$fmblConfig/Config/FMBL/DPMQ/text()"/>
        <xsl:variable name="queueName" select="$fmblConfig/Config/FMBL/QueueName/text()"/>
        <xsl:variable name="mqURL" select="concat('dpmq://', $dqmq, '/?RequestQueue=', $queueName, ';Sync=true')"/>        
        
        <!-- construct MQ Header -->
        <xsl:variable name="MQMD">
            <MQMD>
                <Format>MQSTR</Format>
                <Expiry>-1</Expiry>
            </MQMD>
        </xsl:variable>
        
        <!-- Serialize header -->
        <xsl:variable name="serializedMQMD">
            <dp:serialize select="$MQMD" omit-xml-decl="yes"/>
        </xsl:variable>
        
        <!-- Prepare the for use in url-open() -->
        <xsl:variable name="finalHeader">
            <header name= "MQMD">
                <xsl:value-of select= "$serializedMQMD"/>
            </header>
        </xsl:variable>        
        
     
        <!-- serialize the incoming soap request and replace all double quote and forward slash with the backslash format -->
        <xsl:variable name="serializedXmlLData">
<!--            <dp:serialize select="." omit-xml-decl="yes" />-->
            <xsl:call-template name="getSerializedData">
                <xsl:with-param name="targetData" select="/"></xsl:with-param>
            </xsl:call-template>
            
        </xsl:variable>
        
		
		<!-- Base64 encode the serialized request -->		
		<xsl:variable name="finalXmlData" select="dp:binary-encode($serializedXmlLData)"/>
			
        
        <!-- call template to build the transient data log entry -->
        <xsl:variable name="transitientDataJson">
            <xsl:call-template name="buildTransientDataLogEntry"/>
        </xsl:variable>  
        
        <!--  derive the name of activity base on the reqeust/response case -->
        <xsl:variable name="activity">
           <xsl:choose>
                <xsl:when test="$processingRule = 'request'">
                    <xsl:value-of select="'GRQ'"/>
                </xsl:when>
               <xsl:when test="$processingRule = 'response'">
                   <xsl:value-of select="'GRS'"/>
               </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'GRE'"/>
                </xsl:otherwise>
           </xsl:choose>        
        </xsl:variable>

        <xsl:variable name="jsonLogEntry">
            {"header":{"facility":"AUD","log_group":"FML","activity":"<xsl:value-of select="$activity"/>","Severity":"LOG_INFO","transaction_ID":"<xsl:value-of select="$txnContext/txnContext/globalID/text()"/>"},<xsl:value-of select="string($transitientDataJson)"/>,"MsgPayload":"<xsl:value-of select="string($finalXmlData)"/>"} 
        </xsl:variable>    

        <!-- Get the UTC Time -->
        <xsl:variable name="timeStamp" select="number(dp:time-value())"/>
        <xsl:variable name="millionSeconds" select="substring($timeStamp, 11, 3)"/>
        <xsl:variable name="utcTimeStamp" select="concat(substring(dpfunc:zulu-time(), 1, 19), '.',$millionSeconds,'+00:00')"/>
        
        <!-- get the host name of hial gateway with value in IP address -->
        <xsl:variable name="localServiceAddress"  select="dp:variable('var://service/local-service-address')"/>
        <xsl:variable name="gatewayHost" select="substring-before($localServiceAddress,':')"/>
        
        <!-- Concat all log entry part together -->
        <xsl:variable name="logEntry" select="concat($txnContext/txnContext/globalID/text(), $logLeadingChar, $utcTimeStamp,' ',$gatewayHost,' HIALGATEWAY: ', normalize-space($jsonLogEntry) )"/>
        
        <!-- Log the current business event -->        
        <xsl:call-template name="hiallib:logEvent">
            <xsl:with-param name="logLevel" select="'info'"/>
            <xsl:with-param name="facility" select="'BUS'"/>
            <xsl:with-param name="logGroup" select="'FLW'"/>
            <xsl:with-param name="activity" select="$activity"/>
            <xsl:with-param name="transactionId" select="$txnContext/txnContext/globalID/text()"/>
            <xsl:with-param name="logContent" select="concat('Start to performing full message body logging to MQ for flow ', $processingRule)"/>
        </xsl:call-template>
        
        <!-- Send the message via MQ manager and save the response to check result -->
        <xsl:variable name= "mqResponse">
            <dp:url-open target= "{$mqURL}" http-headers= "$finalHeader" response= "binaryNode">
                <xsl:value-of select="string($logEntry)"/>
            </dp:url-open>
        </xsl:variable>
        
        <xsl:variable name="mqResponseCode" select="$mqResponse/result/responsecode/text()"/>        
        <dp:set-variable name="'var://context/logging/MQResponseCode'" value="$mqResponseCode"/>
        <dp:set-variable name="'var://context/logging/MQBinaryNode'" value="$mqResponse"/>
        
        <!-- check if the mq response code is 0 and handle the scenario accordingly -->
        <xsl:choose>
            
            <xsl:when test="$mqResponseCode = '0'">
                
                <xsl:call-template name="hiallib:logEvent">
                    <xsl:with-param name="logLevel" select="'info'"/>
                    <xsl:with-param name="facility" select="'BUS'"/>
                    <xsl:with-param name="logGroup" select="'FLW'"/>
                    <xsl:with-param name="activity" select="$activity"/>
                    <xsl:with-param name="logContent" select="concat('End of performing full message body logging to MQ for flow ', $processingRule,' successfully')"/>
                </xsl:call-template>                

            </xsl:when>
            
            <xsl:otherwise>
                
                <!-- get the error details and error code-->
                <xsl:variable name="errorCode">
                    <xsl:choose>
                        <xsl:when test="string-length($mqResponseCode) = 0">
                            <xsl:value-of select="dp:variable('var://service/error-code')"/>                            
                            <dp:set-variable name="'var://context/error/errorDetails'" value="dp:variable('var://service/error-message')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$mqResponseCode"/>
                            <xsl:variable name="detailedResponse">
                                <dp:serialize select="$mqResponse" omit-xml-decl="yes" />
                            </xsl:variable>
                            <dp:set-variable name="'var://context/error/errorDetails'" value="$detailedResponse"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:variable name="errorDetails" select="dp:variable('var://context/error/errorDetails')"/>

                <xsl:call-template name="hiallib:logEvent">
                    <xsl:with-param name="logLevel" select="'error'"/>
                    <xsl:with-param name="errorCode" select="$errorCode"/>
                    <xsl:with-param name="facility" select="'BUS'"/>
                    <xsl:with-param name="logGroup" select="'FLW'"/>
                    <xsl:with-param name="activity" select="$activity"/>
                    <xsl:with-param name="logContent" select="concat('Failed to perform full message body logging to MQ for flow ', $processingRule, ', go to datapower system log to get failure details')"/>
                </xsl:call-template>     

                <xsl:call-template name="raiseError">
                    <xsl:with-param name="errorCode" select="'ehealth.customerror.0011'"/>
                </xsl:call-template>
                
                    <xsl:if test="$processingRule = 'request' or $processingRule = 'response'">
                        <dp:reject>
                            Failed to perform full message body logging, please contact system admin.
                        </dp:reject>        
                    </xsl:if>
                   
                
            </xsl:otherwise>
            
        </xsl:choose>        
        
    </xsl:template>
    
    <xsl:template name="getSerializedData">
        <xsl:param name="targetData"/>
        <dp:serialize select="$targetData" omit-xml-decl="yes" />
    </xsl:template>
    
</xsl:stylesheet>
