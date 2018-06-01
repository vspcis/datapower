<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>AntiVirusScan.xsl</Filename>
<revisionlog>
Initial Version
Sept 23, 2015: Added PEP Flag to enable/disable antivirus action
Mar 23, 2017: Added extendable function to getPEPEnforcementFlag
</revisionlog>
<Description>
Trigger Antivirus action. Calls IBM default antivirus actions:
- store:antivirus.xsl
- store:antivirus-trendmicro.xsl
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
    xmlns:dpconfig="http://www.datapower.com/param/config"
    xmlns:hiallib="http://www.ehealthontario.on.ca/hial/lib"    
    extension-element-prefixes="dp" 
    exclude-result-prefixes="dp dpconfig" version="1.0">
    
    <xsl:output method="xml"/>

    <xsl:import href="store:antivirus-trendmicro.xsl" />
    <xsl:include href="local:Framework/Lib/Log4GateWay.xsl" />    
    <xsl:import href="SOAPPEPTransformLib.xsl"/>
    
    
    <!-- Antivirus connection parameters setting -->
    <xsl:variable name="avConfigFile" select="'Config/Config.xml'" />
    <xsl:param name="dpconfig:ICAPRemoteHost" select="document($avConfigFile)/Config/AntiVirus/icaphost" />
    <xsl:param name="dpconfig:ICAPRemotePort" select="document($avConfigFile)/Config/AntiVirus/icapport" />
    <xsl:param name="dpconfig:ICAPRemoteURI" select="document($avConfigFile)/Config/AntiVirus/icapuri" />
    <xsl:param name="dpconfig:ICAPHostType" select="document($avConfigFile)/Config/AntiVirus/icaptype" />
    <xsl:param name="dpconfig:AntiVirusProcessingMode" select="document($avConfigFile)/Config/AntiVirus/avprocessingmode" /> 
    <xsl:variable name="avTimeout" select="document($avConfigFile)/Config/AntiVirus/icaptimeout" />


    <!-- Added template such that it can be overridden -->
    <xsl:template name="getPEPEnforcedFlag">
        <xsl:value-of select="dp:variable('var://context/hialPEP/pepEnforcedFlag')"/>
    </xsl:template>
    
    
    <!-- Overriding root match template from store:antivirus.xsl -->
    <xsl:template match="/">
        
        <!-- for captureing executed state do nothing for wsp -->
        <xsl:call-template name="captureExecutedPolicy">
            <xsl:with-param name="PEPName" select="$PEPName"/>
        </xsl:call-template>
        
        <xsl:variable name="pepEnforcedFlag">
            <xsl:call-template name="getPEPEnforcedFlag"/>
        </xsl:variable>

        <!-- Call Trendmicro only when AV is enabled via WSRR policy -->
        <xsl:if test="$pepEnforcedFlag = 'true'">
            <!-- call the parent root match template from store:antivirus.xsl -->
            <xsl:apply-imports />
        </xsl:if>
    </xsl:template>

    <!-- 
        Code inherited from standard ICAP integration from store:antivirus-trendmicro.xsl. 
        Added business events logging to antivirus.
    -->
    <xsl:template name="icap-test">
        <xsl:param name="icap-data"/>
        <xsl:param name="icap-data-type"/>
        <xsl:variable name="httpHeaders">
            <header name="X-ICAP-Method">Request</header>
            <header name="Host">127.0.0.1</header>
            <header name="Allow">204</header>
            <header name="Encapsulated">
                <xsl:value-of select="concat('req-hdr=0, req-body=60', $eol, $eol, 'POST /0 HTTP/1.1', $eol, 'Host: test', $eol, 'Transfer-Encoding: chunked')"/>
            </header>
        </xsl:variable>
        
        <!-- Logging of AAA business activity - beginning of calls to Trendmicro Antivirus -->
        <xsl:variable name="avCallStartTimeStamp">  
            <xsl:call-template name="getCurrentDateTime"/>
        </xsl:variable>
        <xsl:call-template name="hiallib:logEvent">           
            <xsl:with-param name="logLevel" select="'information'"/>
            <xsl:with-param name="facility" select="'BUS'"/>
            <xsl:with-param name="logGroup" select="'FLW'"/>
            <xsl:with-param name="activity" select="'AVS'"/>            
            <xsl:with-param name="startTime" select="$avCallStartTimeStamp"/>      
            <xsl:with-param name="logContent" select="'Antivirus call begin'"/>             
        </xsl:call-template> 
        
        <xsl:variable name="test-result">
            <dp:url-open target="{$icap-url}" response="responsecode-ignore" data-type="{$icap-data-type}" timeout="{$avTimeout}" http-headers="$httpHeaders">
                <xsl:copy-of select="$icap-data"/>
            </dp:url-open>
        </xsl:variable>
        
        <xsl:variable name="avCallEndTimeStamp">  
            <xsl:call-template name="getCurrentDateTime"/>
        </xsl:variable>    
         
        <xsl:choose>
            <xsl:when test="string($test-result/url-open/responsecode) = '403' or string($test-result/url-open/responsecode) = '200'">
                <virus/>
            </xsl:when>
            <xsl:when test="string($test-result/url-open/responsecode) != '204'">
                <error>
                    <xsl:text>Unrecognized response code "</xsl:text>
                    <xsl:value-of select="$test-result/url-open/responsecode"/>
                    <xsl:text>".</xsl:text>
                    <xsl:if test="$test-result/url-open/errorstring">
                        <xsl:text> Error: "</xsl:text>
                        <xsl:value-of select="$test-result/url-open/errorstring"/>
                        <xsl:text>"</xsl:text>
                    </xsl:if>
                </error>
            </xsl:when>
        </xsl:choose>
       
        <!-- constructing antivirus scan result for logging -->
        <xsl:variable name="logContent">
            <xsl:choose>
                <xsl:when test="not($test-result) or $test-result = &apos;&apos; ">
                    <xsl:value-of select="concat('antivirus-open-url: Remote error on url', $icap-url)" />
                </xsl:when>
                 <xsl:when test="string($test-result/url-open/responsecode) = '204'">
                    <xsl:value-of select="'Antivirus call completed successfully'" />
                 </xsl:when>
                 <xsl:when test="string($test-result/url-open/responsecode) = '403' or string($test-result/url-open/responsecode) = '200'">
                    <xsl:value-of select="'Virus found'" />
                 </xsl:when>
                 <xsl:otherwise>
                    <xsl:value-of select="concat('Antivirus error: ', $test-result//errorstring)" />
                 </xsl:otherwise>
            </xsl:choose>    
        </xsl:variable>
        
        <!-- determining log level -->
        <xsl:variable name="logLevel">
            <xsl:choose>
                <xsl:when test="string($test-result/url-open/responsecode) = '204'">
                    <xsl:value-of select="'information'" />
                </xsl:when>   
                <xsl:otherwise>
                    <xsl:value-of select="'error'" />
                </xsl:otherwise> 
            </xsl:choose>
        </xsl:variable>        
        
        <!-- Logging of AAA business activity - end of calls to Tremdmicro Antivirus -->
        <xsl:call-template name="hiallib:logEvent">           
            <xsl:with-param name="logLevel" select="$logLevel"/>
            <xsl:with-param name="facility" select="'BUS'"/>
            <xsl:with-param name="logGroup" select="'FLW'"/>
            <xsl:with-param name="activity" select="'AVS'"/>            
            <xsl:with-param name="startTime" select="$avCallStartTimeStamp"/>
            <xsl:with-param name="endTime" select="$avCallEndTimeStamp"/>                     
            <xsl:with-param name="logContent" select="$logContent"/>             
        </xsl:call-template> 
    </xsl:template>
   
</xsl:stylesheet>