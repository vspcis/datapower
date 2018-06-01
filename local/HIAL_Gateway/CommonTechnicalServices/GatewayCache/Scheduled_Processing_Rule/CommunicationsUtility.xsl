<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>CommunicationsUtility.xsl</Filename>
<revisionlog>Initial Version</revisionlog>
<Description>

Communications utility for making rest and/or soap calls to external interfaces,
supports retries and and logging to datapower variables

This particular version of the communication utility does not leverage 
datapower variables for retry logic. The retry logic is instead wrapped
within the template parameters.

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
    xmlns:dpcom2="http://ehealthontario.on.ca/datapower/communicationsutil/v2"
    xmlns:dp="http://www.datapower.com/extensions"
    extension-element-prefixes="dp" 
    exclude-result-prefixes="xsl dp dpcom2" 
    version="1.0">
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

    <!-- This template invokes a soap interface and handles the retry
        Service variables: 
     -->
    <xsl:template name="dpcom2:invokeSoapWithRetry">
        <xsl:param name="retry"/>
        <xsl:param name="invokationLog"/>
        <xsl:param name="external"/>
        <xsl:param name="invokeid"/>
        <xsl:param name="soapconfig"/>
        
   
        <!-- do something -->
        <!--ssl-proxy="$soapconfig/identity"-->
        <xsl:variable name="response">
            
            <xsl:choose>
                <xsl:when test="count($soapconfig/soapcall/*) &gt; 0">
                    <dp:url-open target="{$soapconfig/serviceURL}" response="responsecode"
                        http-headers="$soapconfig/httpheaders/*" content-type="text/xml"
                        ssl-proxy="{$soapconfig/identity}" timeout="{$soapconfig/timeout}"
                        http-method="post">
                        <xsl:copy-of select="$soapconfig/soapcall/*"/>
                    </dp:url-open>        
                </xsl:when>
                <xsl:otherwise>
                    
                    <dp:url-open target="{$soapconfig/serviceURL}" response="responsecode"
                        http-headers="$soapconfig/httpheaders/*" content-type="text/xml"
                        ssl-proxy="{$soapconfig/identity}" timeout="{$soapconfig/timeout}"
                        http-method="get">
                      
                    </dp:url-open>
                </xsl:otherwise>
            </xsl:choose>
            
        </xsl:variable>
                
        <xsl:choose>
            <xsl:when test="not($response/url-open/responsecode = 200)">
                <!-- put something in fail log -->
                <xsl:variable name="new">
                    <xsl:copy-of select="$invokationLog"/>
                    <xsl:copy-of select="$response/url-open"/>
                </xsl:variable>
                
                <!-- recursive invoke if retry count has not been reached -->
                <xsl:choose>
                    
                    <xsl:when test="count($new/url-open) &lt; (number($retry) +1 )">
                        <xsl:call-template name="dpcom2:invokeSoapWithRetry">
                            <xsl:with-param name="retry" select="$retry"/>
                            <xsl:with-param name="invokationLog" select="$new"/>
                            <xsl:with-param name="external" select="false()"/>
                            <xsl:with-param name="invokeid" select="$invokeid"/>
                            <xsl:with-param name="soapconfig" select="$soapconfig"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                       <!-- <xsl:copy-of select="$response"/>-->
                        <Error/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$response/url-open/response/*"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
