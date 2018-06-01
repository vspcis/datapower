<?xml version="1.0" encoding="UTF-8"?>

<!--
<CodeHeader>
<Filename>WSRRProxyService.xsl</Filename>
<revisionlog>Initial Version
July28: Enhanced WSRR rest URL query, enables resource ID in between queries to be made
For example supports this type : https://localhost:9443/WSRR/8.5/Metadata/XML/bcd6e9bc-1a6c-4c4f.a3d1.78d84278d111/properties

July31: Added password decrption
</revisionlog>
<Description>

WSRR integration module:
Datapower xsls can use the templates within this stylesheet make calls to WSRR to retrieve
information. All calls leverage CommunicationsUtility and thus support retry logic

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
    xmlns:wsrrf="http://ehealthontario.on.ca/wsrr/proxy"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpcom="http://ehealthontario.on.ca/datapower/communicationsutil"
    exclude-result-prefixes="xsl dp wsrrf dpcom" extension-element-prefixes="dp" version="1.0">

    <xsl:import href="CommunicationsUtility.xsl"/>
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

    <!-- ********* Module External Templates ******************************************** -->

    <!-- Retrieves an WSRR listing of resources by executing a named query againts WSRR -->
    <xsl:template name="wsrrf:getResourceList">
        <xsl:param name="resourceType"/>
        <!-- The resourceType is a string that is configured in the wsrr configuration file
            the resourceType is bound to a named query inside the configuration file
            
         -->
        <!--        <dp:set-variable name="'var://context/config/GETRESLIST'" value="$resourceType"/>-->
        <xsl:call-template name="wsrrf:getConfiguration"/>

        <xsl:variable name="serviceURL">
            <xsl:call-template name="wsrrf:resolveURL">
                <xsl:with-param name="resourceType" select="$resourceType"/>
                <xsl:with-param name="ids"> </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>

        <dp:set-variable name="'var://context/config/wsrr/debugServiceURL'" value="$serviceURL"/>
        <!--        <xsl:message><xsl:value-of select="$serviceURL"/></xsl:message>-->
        <xsl:call-template name="wsrrf:invokeWrapper">
            <xsl:with-param name="serviceURL" select="$serviceURL"/>
        </xsl:call-template>

    </xsl:template>


    <!-- Retrieves an WSRR resource based on it's bsrUri and resourceType -->
    <xsl:template name="wsrrf:getResource">
        <xsl:param name="bsrURI"/>
        <!-- bsrURI is the guuid that identifies the wsrr resource -->
        <xsl:param name="resourceType"/>
        <!-- The resourceType is a string that identifies the type of resource being retrieved
            the type is also bound to the particular URL PART that is published by WSRR, this 
            type and URL binding is in the wsrr configuration file -->

        <!--        <dp:set-variable name="'var://context/config/GETRES'" value="$resourceType"/>-->

        <xsl:variable name="idlist">
            <id>
                <xsl:value-of select="string($bsrURI)"/>
            </id>
        </xsl:variable>
        <dp:set-variable name="'var://context/config/idlist'" value="$idlist"/>
        <xsl:variable name="serviceURL">
            <xsl:call-template name="wsrrf:resolveURL">
                <xsl:with-param name="resourceType" select="$resourceType"/>
                <xsl:with-param name="ids" select="$idlist"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:call-template name="wsrrf:invokeWrapper">
            <xsl:with-param name="serviceURL" select="$serviceURL"/>
        </xsl:call-template>


    </xsl:template>

    <!-- ********** Module Internal Templates ********************************************************** -->
    <!-- Loads configuration for this WSRR Proxy Service into datapower context variables -->
    <xsl:template name="wsrrf:getConfiguration">
        <xsl:variable name="dpconfig" select="dp:variable('var://context/config/wsrr/configloaded')"/>
        <xsl:if test="not($dpconfig)">
            <xsl:variable name="configvalues">
                <xsl:copy-of select="document('config/wsrrconfig.xml')"/>
            </xsl:variable>



            <dp:set-variable name="'var://context/config/wsrr/username'"
                value="$configvalues/WSRRConfiguration/Username[1]"/>
            <dp:set-variable name="'var://context/config/wsrr/key'"
                value="$configvalues/WSRRConfiguration/Key[1]"/>
            <dp:set-variable name="'var://context/config/wsrr/password'"
                value="$configvalues/WSRRConfiguration/Password[1]"/>
            <dp:set-variable name="'var://context/config/wsrr/dpdomain'"
                value="dp:variable('var://service/domain-name')"/>
            <dp:set-variable name="'var://context/config/wsrr/serviceMap'"
                value="$configvalues/WSRRConfiguration/ServiceURLMap"/>
            <dp:set-variable name="'var://context/config/wsrr/serviceURL'"
                value="$configvalues/WSRRConfiguration/ServiceURL"/>
            <dp:set-variable name="'var://context/config/wsrr/retries'"
                value="$configvalues/WSRRConfiguration/retry"/>
            <dp:set-variable name="'var://context/config/wsrr/sslProxy'"
                value="$configvalues/WSRRConfiguration/SSLProxy"/>
            <dp:set-variable name="'var://context/config/wsrr/timeout'"
                value="$configvalues/WSRRConfiguration/timeout"/>


            <dp:set-variable name="'var://context/config/wsrr/configloaded'" value="true()"/>
        </xsl:if>
    </xsl:template>


    <xsl:template name="wsrrf:generateHeader">
        <xsl:call-template name="wsrrf:getConfiguration"/>
        <xsl:variable name="decrypted-password"
            select="dp:decrypt-key(dp:variable('var://context/config/wsrr/password'), concat('name:', dp:variable('var://context/config/wsrr/key')), 'http://www.w3.org/2001/04/xmlenc#rsa-1_5')"/>
        <xsl:variable name="decoded-password" select="dp:decode($decrypted-password, 'base-64')"/>


        <header name="Content-Type">application/soap+xml</header>
        <header name="Authorization">
            <xsl:value-of
                select="concat('Basic ', dp:encode(concat(dp:variable('var://context/config/wsrr/username'),
                    ':',$decoded-password),'base-64'))"
            />
        </header>

    </xsl:template>


    <xsl:template name="wsrrf:invokeWrapper">
        <xsl:param name="serviceURL"/>
        <xsl:variable name="headers">
            <xsl:call-template name="wsrrf:generateHeader"/>
        </xsl:variable>
        <xsl:variable name="ssl" select="dp:variable('var://context/config/wsrr/sslProxy')"> </xsl:variable>
        <xsl:variable name="dpwsrrconfig">
            <serviceURL>
                <xsl:value-of select="$serviceURL"/>
            </serviceURL>

            <identity>
                <xsl:value-of select="$ssl"/>
            </identity>
            <httpheaders>
                <!--header name="Authorization">Basic bWljaGFlbF9odWk6Y2hrZW4wMQ==</header-->
                <xsl:copy-of select="$headers"/>
            </httpheaders>
            <timeout>
                <xsl:value-of select="dp:variable('var://context/config/wsrr/timeout')"/>
            </timeout>
        </xsl:variable>


        <xsl:call-template name="dpcom:invokeSoapWithRetry">
            <xsl:with-param name="retry" select="dp:variable('var://context/config/wsrr/retries')"/>
            <xsl:with-param name="external" select="true()"/>
            <xsl:with-param name="invokeid" select="'abc'"/>
            <xsl:with-param name="soapconfig" select="$dpwsrrconfig"/>
        </xsl:call-template>

    </xsl:template>






    <xsl:template name="wsrrf:resolveURL">
        <xsl:param name="resourceType"/>
        <xsl:param name="ids"/>
        <xsl:call-template name="wsrrf:getConfiguration"/>
        <!-- build the URL string -->
        <xsl:variable name="serviceURL">
            <xsl:value-of
                select="concat(string(dp:variable('var://context/config/wsrr/serviceURL')/text()), 
                string(dp:variable('var://context/config/wsrr/serviceMap')/ResourceURL[@resourceType=$resourceType]/text()))"
            />
        </xsl:variable>


        <xsl:variable name="fullURL">
            <xsl:for-each select="$ids/id">
                <xsl:choose>
                    <xsl:when
                        test="dp:variable('var://context/config/wsrr/serviceMap')/ResourceURL[@resourceType=$resourceType]/@parametertype = 'querystring'">
                        <xsl:value-of
                            select="concat($serviceURL, '?', string(dp:variable('var://context/config/wsrr/serviceMap')/ResourceURL[@resourceType=$resourceType]/@parametername), '=', string(./text()))"/>
                        <dp:set-variable name="'var://context/config/wsrr/querystring'"
                            value="true()"/>
                    </xsl:when>

                    <xsl:when
                        test="dp:variable('var://context/config/wsrr/serviceMap')/ResourceURL[@resourceType=$resourceType]/@parametertype = 'resourceproperties'">
                        <xsl:value-of
                            select="concat($serviceURL, '/', string(./text()),'/properties')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat($serviceURL, '/', string(./text()))"/>
                        <dp:set-variable name="'var://context/config/wsrr/resource'" value="true()"
                        />
                    </xsl:otherwise>
                </xsl:choose>

            </xsl:for-each>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="string-length($fullURL) &gt; 0">
                <dp:set-variable name="'var://context/config/wsrr/fullURL'" value="$fullURL"/>
                <xsl:copy-of select="$fullURL"/>
            </xsl:when>
            <xsl:otherwise>
                <dp:set-variable name="'var://context/config/wsrr/basicURL'" value="$serviceURL"/>
                <xsl:copy-of select="$serviceURL"/>
            </xsl:otherwise>
        </xsl:choose>


    </xsl:template>

</xsl:stylesheet>
