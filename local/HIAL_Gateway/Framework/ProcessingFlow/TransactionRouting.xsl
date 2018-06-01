<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>ConstructTransientData.xsl</Filename>
<revisionlog>v1.0.0</revisionlog>
<Description>
  Not for Production use
</Description>
<Owner>eHealthOntario</Owner>
<LastUpdate>Oct 20, 2015</LastUpdate>
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
    xmlns:regexp="http://exslt.org/regular-expressions"
    exclude-result-prefixes="xsl dp date dpwsm dpconfig wsmp regexp"
    extension-element-prefixes="dp" 
    version="1.0">
    
    <xsl:include href="local:Framework/Lib/Log4GateWay.xsl" />
    
    <xsl:variable name="debugURL"  select="'http://eHealthOntario/Classifications/2015/01#Alternate_EP'"/>
    <xsl:variable name="normalURL" select="'http://eHealthOntario/Classifications/2015/01#PrimaryEP'"/>
    <xsl:variable name="urlPrefix" select="'http://eHealthOntario/Classifications/2015/01#'"/>
    <xsl:variable name="debugSetting" select="dp:variable('var://system/hial_managment/debugControl')"/>
    <xsl:variable name="txnContext"   select="dp:variable('var://context/hialPEP/txnContext')"/>
    <xsl:variable name="slaPolicy"    select="dp:variable('var://context/hialPEP/slaPolicy')"/>
    
    <xsl:template match="/">

        <xsl:variable name="serviceName"  select="$txnContext/txnContext/wsdlName/text()"/>
        <xsl:variable name="opertionName" select="$txnContext/txnContext/operation/text()"/>
        <xsl:variable name="clientCN"     select="$txnContext/txnContext/clientCommonName/text()"/>

        <xsl:variable name="destination">
            <xsl:choose>
                <xsl:when test="$debugSetting/debugflow/Service[@Name=$serviceName and @Operation=$opertionName and @CN=$clientCN]">
                    <xsl:value-of select="$debugURL"/>
                </xsl:when>
                <xsl:otherwise> 
                    <xsl:value-of select="$normalURL"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="destinationType" select="substring-after($destination,$urlPrefix)"/>
        
        <xsl:variable name="property" select="//property[@name='classificationURIs' and contains(@value, $destination)]"/>
        <xsl:variable name="url" select="$property/../property[@name='name']/@value"/>
      <!--dp:set-variable name="'var://service/routing-url'" value="string($url)"/-->

      <!-- Test Routing , accept http headers to control routing test-hib-host, and test-hib-port -->
      <xsl:variable name="test-hib-host" select="dp:http-request-header('test-hib-host')"/>
      <xsl:variable name="test-hib-port" select="dp:http-request-header('test-hib-port')"/>
      <xsl:variable name="hostReplacedURL">
        <xsl:choose>

          <xsl:when test="string-length($test-hib-host) &gt; 0 or string-length($test-hib-port) &gt; 0">
            <xsl:variable name="expression">  
              <xsl:value-of select="'$2://'"/>
              <xsl:choose>
                <xsl:when test="string-length($test-hib-host) &gt; 0">
                  <xsl:value-of select="concat($test-hib-host, ':')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="'$3:'"/>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:choose>
                <xsl:when test="string-length($test-hib-port) &gt; 0">
                  <xsl:value-of select="concat($test-hib-port, '$6$8')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="'$5$6$8'"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:value-of select="regexp:replace(normalize-space($url), '^((http[s]?|ftp):\/)?\/?([^:\/\s]+)(:([^\/]*))?((\/\w+)*\/)([\w\-\.]+[^#?\s]+)(\?([^#]*))?(#(.*))?$', 'g', $expression)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$url"/>
          </xsl:otherwise>
        </xsl:choose>
        </xsl:variable>
        <dp:set-variable name="'var://context/debug/routing-url'" value="string($hostReplacedURL)"/>
        <dp:set-variable name="'var://service/routing-url'" value="$hostReplacedURL"/>
        
        <xsl:variable name="txnContext" select="dp:variable('var://context/hialPEP/txnContext')"/>
        <xsl:variable name="txnID" select="$txnContext/txnContext/globalID/text()"/>        
        
        <xsl:call-template name="hiallib:logEvent">
            <xsl:with-param name="logLevel" select="'info'"/>
            <xsl:with-param name="facility" select="'TRN'"/>
            <xsl:with-param name="logGroup" select="'FLW'"/>
            <xsl:with-param name="activity" select="'CON'"/>
            <xsl:with-param name="transactionId" select="$txnContext/txnContext/globalID/text()"/>
            <xsl:with-param name="logContent" select="concat('Transaction is routed with flow ', $destinationType,', the url is:', $url)"/>
        </xsl:call-template>
        
    </xsl:template>    
    
</xsl:stylesheet>
