<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>ValidateResponse.xsl</Filename>
<revisionlog>v1.0.0</revisionlog>
<Description>
  This is the template which validate the HIB response
</Description>
<Owner>eHealthOntario</Owner>
<LastUpdate>Nov 19, 2015</LastUpdate>
<Copyright>
**************************************************************
  Copyright (c) ehealthOntario, 2015
**************************************************************
</Copyright>
</CodeHeader>
-->
<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:soap11="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:soap12="http://www.w3.org/2003/05/soap-envelope" 
    xmlns:hiallib="http://www.ehealthontario.on.ca/hial/lib"
    xmlns:dp="http://www.datapower.com/extensions" 
    exclude-result-prefixes="xsl soap11 soap12 dp"
    extension-element-prefixes="dp">
    
    <xsl:include href="local:Framework/Lib/Log4GateWay.xsl" />
    
    <xsl:variable name="smallcase" select="'abcdefghijklmnopqrstuvwxyz'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
    <xsl:variable name="userException" select="'USEREXCEPTION'"/>
    <xsl:variable name="txnContext"   select="dp:variable('var://context/hialPEP/txnContext')"/>
 
    <xsl:template match="/">
        
        <xsl:variable name="timeForward" select="dp:variable('var://service/time-forwarded')"/>
        <xsl:variable name="timeRespond" select="dp:variable('var://service/time-response-complete')"/>	    
        <xsl:variable name="hibProcessTime" select="$timeRespond - $timeForward"/>        
        
        <!-- Log the transaction event for receiving the hib response -->        
        <xsl:call-template name="hiallib:logEvent">
            <xsl:with-param name="logLevel" select="'info'"/>
            <xsl:with-param name="facility" select="'TRN'"/>
            <xsl:with-param name="logGroup" select="'PRC'"/>
            <xsl:with-param name="activity" select="'CON'"/>
            <xsl:with-param name="transactionId" select="$txnContext/txnContext/globalID/text()"/>
            <xsl:with-param name="logContent" select="concat('Received HIB response, total HIB processing time in millisecond is:[', $hibProcessTime, '].')"/>
        </xsl:call-template>          
        
        <xsl:if test="dp:variable('var://service/soap-fault-response') != '0'">
            
            <xsl:variable name="faultCode" select="/soap11:Envelope/soap11:Body/soap11:Fault/faultcode/text() | /soap12:Envelope/soap12:Body/soap12:Fault/soap12:Code/text()" />
            <xsl:variable name="faultText" select="/soap11:Envelope/soap11:Body/soap11:Fault/faultstring/text() | /soap12:Envelope/soap12:Body/soap12:Fault/soap12:Reason/soap12:Text/text()" />
            <xsl:variable name="captalFaultCode" select="translate($faultCode, $smallcase, $uppercase)"/>
            
            <!-- check if the userException keyword is in the soap fault code field, if it is not there, reject the soapFault and rout to error flow -->
            <xsl:if test="not ( contains($captalFaultCode,$userException))">
                <xsl:variable name="errorMessage">
                    <xsl:value-of select="concat('Received soap fault from HIB:', $faultCode, '-', $faultText)"/>
                </xsl:variable>
                
                <dp:set-variable name="'var://context/error/faultFromHIB'" value="'true'"/>
                <dp:reject>
                    <xsl:value-of select="$errorMessage"/>
                </dp:reject>
            </xsl:if>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>
