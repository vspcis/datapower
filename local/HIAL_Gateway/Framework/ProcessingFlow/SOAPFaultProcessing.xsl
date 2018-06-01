<?xml version="1.0" encoding="UTF-8"?>
<!--
    <CodeHeader>
    <Filename>SOAPFaultProcessing.xsl</Filename>
    <revisionlog>v1.2.1</revisionlog>
    <Description>
    This is the error handling for the common flow
    </Description>
    <Owner>eHealthOntario</Owner>
    <LastUpdate>
    July 5, 2017 : Updated code to include custom application error codes, this is done for application detected FMBL error
    
    Nov 20, 2015 : Updated code in order to remove logic for the user exception in gateway. Defect 6727  </LastUpdate>
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
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:variable name="txnContext"   select="dp:variable('var://context/hialPEP/txnContext')"/>
    
    <xsl:template match="/">
        
        <!-- ErrorMask variable -->	
        <xsl:variable name="ErrorMask" select="dp:variable('var://system/hial_managment/errorMaskoverride')" />
        
        <!-- Service Name variable-->  
        <xsl:variable name="svcName" select="$txnContext/txnContext/wsdlName/text()"/>
        
        <!-- variable returning boolean if the service exists or does exist in the ErrorMaskOverride system variable-->  
        <xsl:variable name="errMaskOvrrideexist">
            <xsl:value-of select="boolean($ErrorMask/ErrorMaskOverride/Service[@wsdl=string($svcName)])"  />  	
        </xsl:variable>
       
        
        
        <xsl:variable name="errcode">
            <xsl:choose>
                <!-- SOW9 added ability to handle xslt rejects - eg. ehealth.customerror.0009 -->
                <xsl:when test="string-length(dp:variable('var://context/hial_ctx/error-code')) &gt; 0">
                    <xsl:value-of select="dp:variable('var://context/hial_ctx/error-code')"/>
                </xsl:when>
                <xsl:when test="dp:variable('var://service/error-subcode') = '0x00000000'">
                    <xsl:value-of select="dp:variable('var://service/error-code')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="dp:variable('var://service/error-subcode')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        
        <!-- Sept 23: end of error-subcode change -->
        <!--This file contains all error codes and corresponding description as per error handling PAD-->        
        <xsl:variable name="cstmCodes" select="document('Config/CustomErrors.xml')" />
        
        <xsl:variable name="errorMessage">
            <xsl:choose>
                <xsl:when test="$cstmCodes/ErrorMap/ErrorList/Error[ErrorCode = $errcode]">
                    <!-- Sept 23: Replaced /MappedErrorMessage by /ErrorMessage  -->
                    <xsl:value-of select="$cstmCodes/ErrorMap/ErrorList/Error[ErrorCode = $errcode]/MappedErrorMessage"  />  
                    <!-- Sept 23: End of  /MappedErrorMessage change -->
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'Internal System Error'"/>
                </xsl:otherwise>	
            </xsl:choose>
        </xsl:variable> 
        
        <xsl:variable name="formattedErrorMessage" select="dp:variable('var://service/formatted-error-message')"/>
        <xsl:variable name="soapNs">
            <xsl:if test="contains($formattedErrorMessage, 'http://schemas.xmlsoap.org/soap/envelope/')">
                <xsl:copy-of select="'http://schemas.xmlsoap.org/soap/envelope/'"/>  
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="inputMsgName" select="local-name(/*[local-name()='Envelope']/*[local-name()='Body']/*[1])"/>
        
        <xsl:variable name="faultCode11" select="/soap11:Envelope/soap11:Body/soap11:Fault/faultcode/text()" />        
        <xsl:variable name="faultCode12" select="/soap12:Envelope/soap12:Body/soap12:Fault/soap12:Code/soap12:Value/text()" /> 
                
                <!-- Sept 23: switch the if statement condition and removed the word 'false' when checking the condition -->
                <xsl:choose>
                    <!-- if the service exists, unmask the error by returning datapower error. Then, pass it to the client -->         
                    <xsl:when test="$ErrorMask/ErrorMaskOverride/Service[@wsdl=string($svcName)]">                
                        
                        <xsl:copy>
                            <dp:parse select="$formattedErrorMessage"/>
                        </xsl:copy>            
                    </xsl:when>	
                    <!--If the error was masked. Mask the error for the specific service-->        
                    <xsl:otherwise>
                        
                        
                        <xsl:call-template name="getsoapfault">
                            <xsl:with-param name="errorMessage" select="$errorMessage"/>
                            <xsl:with-param name="soapNs" select="$soapNs"/>
                        </xsl:call-template>
                                   
                    </xsl:otherwise>
                </xsl:choose>
                <!-- Sept 23: end of the if statement condition switch  -->
                 
            
       <!-- Nov 4, 2015: moved logging block outside the if statement. Relted to defect 6727 -->
        <xsl:variable name="errorDesc">
            <xsl:value-of select="dp:variable('var://service/error-message')"/>
        </xsl:variable>
        <xsl:call-template name="hiallib:logEvent">
            <xsl:with-param name="logLevel" select="'error'"/>
            <xsl:with-param name="facility" select="'TRN'"/>
            <xsl:with-param name="logGroup" select="'EHF'"/>
            <xsl:with-param name="activity" select="'ERR'"/>
            <xsl:with-param name="transactionId" select="$txnContext/txnContext/globalID/text()"/>
            <xsl:with-param name="logContent" select="concat('Error Code :', string($errcode),', Error: ',$errorDesc )"/>
        </xsl:call-template>
        <!--End block Nov 4:2015 -->
    </xsl:template>
    
    <xsl:template name="getsoapfault">
        <xsl:param name="errorMessage" select="'Internal Error'"/>
        <xsl:param name="soapNs" select="'http://schemas.xmlsoap.org/soap/envelope/'"/>
        <xsl:choose>
            <xsl:when test="$soapNs = 'http://schemas.xmlsoap.org/soap/envelope/'">
                <!-- Soap Fault 1.1 -->
                <soap11:Envelope>
                    <soap11:Body>
                        <soap11:Fault>
                            <faultcode>
                                <xsl:text>soap11:Client</xsl:text>
                            </faultcode>
                            <faultstring>
                                <xsl:value-of select="$errorMessage"/>
                            </faultstring>
                        </soap11:Fault>
                    </soap11:Body>
                </soap11:Envelope>
            </xsl:when>
            <xsl:otherwise>                
                <!--soap 1.2 force the content type to be set as application/soap+xml for soap 1.2 -->
                <dp:set-http-request-header name="'Content-Type'" value="'application/soap+xml;charset=UTF-8'"/>
                <dp:freeze-headers/>
                <soap12:Envelope>
                    <soap12:Body>
                        <soap12:Fault>
                            <soap12:Code>
                                <soap12:Value>
                                    <xsl:text>soap12:Sender</xsl:text>
                                </soap12:Value>
                                
                            </soap12:Code>
                            <soap12:Reason>
                                <soap12:Text xml:lang='en'>
                                    <xsl:value-of select="$errorMessage"/>
                                </soap12:Text>
                            </soap12:Reason>
                        </soap12:Fault>
                    </soap12:Body>
                </soap12:Envelope>
            </xsl:otherwise>
        </xsl:choose>  
    </xsl:template>
</xsl:stylesheet>