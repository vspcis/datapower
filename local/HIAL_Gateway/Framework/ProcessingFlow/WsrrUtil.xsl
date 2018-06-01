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
    xmlns:wsmp="http://www.ibm.com/xmlns/stdwip/2011/02/ws-mediation"
    xmlns:hiallib="http://www.ehealthontario.on.ca/hial/lib"
    exclude-result-prefixes="xsl dp date dpwsm dpconfig wsmp"
    extension-element-prefixes="dp" 
    version="1.0">
    
    <xsl:include href="local:Framework/Lib/Log4GateWay.xsl" />
    
    <xsl:variable name="debugURL"  select="'DebugURL'"/>
    <xsl:variable name="normalURL" select="'NormalURL'"/>
    <xsl:variable name="debugSetting" select="dp:variable('var://system/hial_managment/debugControl')"/>
    <xsl:variable name="txnContext"   select="dp:variable('var://context/hialPEP/txnContext')"/>
    <xsl:variable name="slaPolicy"    select="dp:variable('var://context/hialPEP/slaPolicy')"/>
    
    <xsl:template name="queryWsrrMetaData">
          
        <xsl:param name="resourceType"/>
        <xsl:param name="queryParameter"/>
        <xsl:param name="queryPurpose"/>
        

        <!-- starting to call the WSRR, perform logging before invoking it -->
        <xsl:variable name="wsrrConfig" select="document('Config/Config.xml')"/>
        
        <xsl:variable name="serviceUrl"  select="$wsrrConfig/Config/WSRRConfiguration/ServiceURL/text()"/>
        <xsl:variable name="resourceUrl" select="$wsrrConfig/Config/WSRRConfiguration/ServiceURLMap/ResourceURL[@resourceType=$resourceType]/text()"/>
        <xsl:variable name="wsrrUrl" select="concat($serviceUrl, $resourceUrl, $queryParameter)"/>
        <xsl:variable name="timeOut"  select="$wsrrConfig/Config/WSRRConfiguration/Timeout/text()" />
        <xsl:variable name="cacheKey" select="dp:hash('http://www.w3.org/2000/09/xmldsig#sha1', $wsrrUrl)"/>
        
        
        <!-- log this event before call WSRR -->
        <xsl:variable name="startTime"><xsl:call-template name="getCurrentDateTime"/></xsl:variable>
        <xsl:call-template name="logWsrrEvent">
            <xsl:with-param name="logLevel" select="'info'"/>
            <xsl:with-param name="facility" select="'TRN'"/>
            <xsl:with-param name="startTime" select="$startTime"/>
            <xsl:with-param name="logContent" select="concat('starting to query wsrr for ', $queryPurpose, ' with cache key: ', $cacheKey)"/>
        </xsl:call-template>
        
        <!-- setup the authentication http header -->
        <xsl:variable name="headerValues">
            <header name="x-dp-cache-key"><xsl:value-of select="$cacheKey" /></header>
        </xsl:variable>
        
        <!-- call the WSRR and keep the response code for result checking -->        
        <xsl:variable name="response">
             <dp:url-open target="{$wsrrUrl}" http-headers="$headerValues" response="responsecode" timeout="{$timeOut}" http-method="get"/>
        </xsl:variable>

        <!-- keep the wsrr response -->
        <xsl:variable name="wsrrResponses">            
            <WSRR-Responses>
                <xsl:copy-of select="dp:variable('var://context/logging/wsrrCallResponses')/WSRR-Responses/*"/>
                <Response> 
                    <Url><xsl:value-of select="$wsrrUrl"/></Url>
                    <CacheKey><xsl:value-of select="$cacheKey"/></CacheKey>
                    <QueryPurpose><xsl:value-of select="$queryPurpose"/>></QueryPurpose>
                    <xsl:copy-of select="$response"/>
                </Response>    
            </WSRR-Responses>
        </xsl:variable>
        <dp:set-variable name="'var://context/logging/wsrrCallResponses'" value="$wsrrResponses" />

        <xsl:variable name="wsrrRespCode" select="$response/url-open/responsecode/text()"/>
        <xsl:variable name="endTime"><xsl:call-template name="getCurrentDateTime"/></xsl:variable>
        
        <!-- handle the response, happy path is the code equals 200 -->
        <xsl:choose>
            <xsl:when test="$wsrrRespCode = '200'">                
                <xsl:call-template name="logWsrrEvent">
                    <xsl:with-param name="logLevel" select="'info'"/>
                    <xsl:with-param name="facility" select="'TRN'"/>
                    <xsl:with-param name="startTime" select="$startTime"/>
                    <xsl:with-param name="endTime" select="$endTime"/>
                    <xsl:with-param name="logContent" select="concat('retrieved query result from wsrr for', $queryPurpose)"/>
                </xsl:call-template>
                
                <xsl:copy-of select="$response"/>                
            </xsl:when>
            
            <xsl:otherwise>
                
                <xsl:variable name="logContent">
                    <xsl:choose>
                        <xsl:when test="string-length($wsrrRespCode) = 0">
                            <xsl:value-of select="concat('failed to get response from wsrr:', dp:variable('var://service/error-message'))"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat('received unexpected error response from wsrr, http code:', $wsrrRespCode )"/>
                        </xsl:otherwise>
                    </xsl:choose>                    
                </xsl:variable> 
                
                <xsl:call-template name="logWsrrEvent">
                    <xsl:with-param name="logLevel"  select="'error'"/>
                    <xsl:with-param name="facility" select="'TRN'"/>
                    <xsl:with-param name="startTime" select="$startTime"/>
                    <xsl:with-param name="endTime" select="$endTime"/>
                    <xsl:with-param name="errorCode" select="'WSRR'"/>
                    <xsl:with-param name="logContent" select="$logContent"/>
                </xsl:call-template>

                <dp:reject><xsl:value-of select="$logContent"/></dp:reject>
                
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>
    
    <!-- simplified logging method -->
    <xsl:template name="logWsrrEvent">
        <xsl:param name="logLevel"/>
        <xsl:param name="facility"/>
        <xsl:param name="errorCode"/>
        <xsl:param name="logContent"/> 
        <xsl:param name="startTime"/>
        <xsl:param name="endTime"/>
        
        <xsl:variable name="txnId" select="dp:variable('var://context/logging/globalTxnId')"/>
        
        <xsl:call-template name="hiallib:logEvent">
            <xsl:with-param name="logLevel" select="$logLevel"/>
            <xsl:with-param name="errorCode" select="$errorCode"/>
            <xsl:with-param name="facility" select="$facility"/>
            <xsl:with-param name="logGroup" select="'PRC'"/>
            <xsl:with-param name="activity" select="'CON'"/>
            <xsl:with-param name="transactionId" select="$txnId"/>
            <xsl:with-param name="startTime" select="$startTime"/>
            <xsl:with-param name="endTime" select="$endTime"/>
            <xsl:with-param name="logContent" select="$logContent"/>
        </xsl:call-template>
    </xsl:template>
    
</xsl:stylesheet>