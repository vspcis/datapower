<?xml version="1.0" encoding="UTF-8"?>

<!--
<CodeHeader>
<Filename>WSRRInternalProxyGateway.xsl</Filename>
<revisionlog>Initial Version - September 8, 2015
</revisionlog>
<Description>

This transform serves as proxy between the Common Processing Policy and WSRR.  
It receives WSRR query from Common Processing Policy and insert the HTTP headers
required for authentication.  It then construct the correct WSRR URI and proxy
the request to WSRR.  This proxy is developed to solve a cache issue discovered when
Common Processing Policy communicates directly to WSRR.

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

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions" 
    xmlns:body="http://www.ibm.com/xmlns/prod/serviceregistry/HttpPostNotifierPluginMsgBody"
    xmlns:wsrradapter="http://ehealthontario.on.ca/wsrrnotificationadapter"
    xmlns:wsrrf="http://ehealthontario.on.ca/wsrr/proxy"
    xmlns:wsrr="http://www.ibm.com/xmlns/prod/serviceregistry/6/2/wspolicy"
    extension-element-prefixes="dp"
    exclude-result-prefixes="xsl dp wsrradapter body wsrrf wsrr">
                
    <xsl:import href="WSRRProxyService.xsl"/>
     
    <xsl:template match="/">
        <xsl:variable name="wsrrHttpHeader">
            <xsl:call-template name="wsrrf:generateHeader" />
        </xsl:variable>
        <xsl:variable name="wsrrIPAddress" select="dp:variable('var://context/config/wsrr/serviceURL')" />
        <xsl:variable name="timeout" select="dp:variable('var://context/config/wsrr/timeout')" />
        <xsl:variable name="serviceUri" select="dp:variable('var://service/URI')" />
               
        <dp:set-http-request-header name="'Authorization'" value="$wsrrHttpHeader/header[@name='Authorization']" />
        <dp:set-variable name="'var://service/mpgw/backend-timeout'" value="$timeout" />
        <dp:set-variable name="'var://service/routing-url'" value="concat($wsrrIPAddress, $serviceUri)" />
    </xsl:template>
    
</xsl:stylesheet>