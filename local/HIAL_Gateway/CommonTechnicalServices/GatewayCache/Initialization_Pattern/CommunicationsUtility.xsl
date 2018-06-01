<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>CommunicationsUtility.xsl</Filename>
<revisionlog>Initial Version
Aug 10: Added code to determine if the ssl proxy is being used.
Datapower's url-open command uses the ssl proxy as long as it's specified on the arguements,
if the object specified does not exist, the url-open will fail. This will not support cases where
standard http is being used. This has been fixed.
</revisionlog>
<Description>Communications utility for making rest and/or soap calls to external interfaces,
supports retries and and logging to datapower variables
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
    xmlns:dpcom="http://ehealthontario.on.ca/datapower/communicationsutil"
    xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp"
    exclude-result-prefixes="xsl dp dpcom" version="1.0">
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

    <!-- ********* Module External Templates ******************************************** -->

    <!-- This template invokes a soap interface and handles the retry 
        Side effects:
        var://context/log/invokefailures 
        is cleared and set to all the error responses from the external service being called.
     -->
    <xsl:template name="dpcom:invokeSoapWithRetry">
        <xsl:param name="retry"/>
        <!-- Integer number of Retries -->
        <xsl:param name="external"/>
        <!-- true()/false() always use true(), false is only used internally to this function-->
        <xsl:param name="invokeid"/>
        <!-- A unique identifier for user with logging , logging will be tagged with this id -->
        <xsl:param name="soapconfig"/>
        <!--  soapconfig sample format:       
           <serviceURL>
               http://host/service/etc/etc
            </serviceURL>
            <identity>
                 name of the ssl proxy
            </identity>
            <httpheaders>
                <header name="httpheadername">value</header>
                ...
            </httpheaders>
            <timeout>
                60
            </timeout>
        -->

        <xsl:if test="$external">
            <dp:set-variable name="'var://context/log/invokefailures'"
                value="&apos;{$invokeid}&apos;"/>
        </xsl:if>

        <xsl:variable name="response">
            <xsl:choose>
                <xsl:when test="count($soapconfig/soapcall/*) &gt; 0">
                    <xsl:choose>
                        <xsl:when test="string-length($soapconfig/identity) &gt; 0">
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
                                timeout="{$soapconfig/timeout}" http-method="post">
                                <xsl:copy-of select="$soapconfig/soapcall/*"/>
                            </dp:url-open>
                        </xsl:otherwise>
                    </xsl:choose>

                </xsl:when>
                <xsl:otherwise>

                    <xsl:choose>
                        <xsl:when test="count($soapconfig/soapcall/*) &gt; 0">
                            <dp:url-open target="{$soapconfig/serviceURL}" response="responsecode"
                                http-headers="$soapconfig/httpheaders/*" content-type="text/xml"
                                ssl-proxy="{$soapconfig/identity}" timeout="{$soapconfig/timeout}"
                                http-method="get"> </dp:url-open>
                        </xsl:when>
                        <xsl:otherwise>
                            <dp:url-open target="{$soapconfig/serviceURL}" response="responsecode"
                                http-headers="$soapconfig/httpheaders/*" content-type="text/xml"
                                timeout="{$soapconfig/timeout}" http-method="get"> </dp:url-open>
                        </xsl:otherwise>
                    </xsl:choose>

                </xsl:otherwise>
            </xsl:choose>

        </xsl:variable>

        <!--        <dp:set-variable name="'var://context/log/soapResponse'" value="$response"/>-->
        <xsl:choose>
            <xsl:when test="not($response/url-open/responsecode = 200)">
                <!-- put respone in fail log -->
                <xsl:variable name="new">
                    <xsl:copy-of select="dp:variable('var://context/log/invokefailures')"/>
                    <xsl:copy-of select="$response/url-open"/>
                </xsl:variable>
                <dp:set-variable name="'var://context/log/invokefailures'" value="$new"/>
                <!-- recursive invoke if retry count has not been reached -->
                <xsl:choose>

                    <xsl:when test="count($new/url-open) &lt; (number($retry) +1 )">
                        <xsl:call-template name="dpcom:invokeSoapWithRetry">
                            <xsl:with-param name="retry" select="$retry"/>
                            <xsl:with-param name="external" select="false()"/>
                            <xsl:with-param name="invokeid" select="$invokeid"/>
                            <xsl:with-param name="soapconfig" select="$soapconfig"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Indicate the an Error, all retries have been completed and no positive response is obtained -->
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
