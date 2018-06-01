<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>dpCacheProxyService.xsl</Filename>
<revisionlog>Initial Version
July31: Added password decrption
Oct 2: Performed explicit cast from string to nodeset to get rid of datapower warning
</revisionlog>
<Description>

Proxy module for communicating with gateway cache.
Supports various operations such as:

Write To Cache
Flush Cache
Refresh Cache File

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
    xmlns:dpcp="http://ehealthontario.on.ca/datapower/cache/proxy"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:conv="xalan://com.ibm.wbiserver.transform.util.MapUtils"
    xmlns:dpcom="http://ehealthontario.on.ca/datapower/communicationsutil"
    xmlns:exslt="http://exslt.org/common"
    exclude-result-prefixes="xsl dp dpcp conv dpcom exslt" extension-element-prefixes="dp" version="1.0">

    <xsl:import href="CommunicationsUtility.xsl"/>
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

    <xsl:template name="dpcp:writeToCache">
        <xsl:param name="localResource"/>
        <!--file data -->
        <xsl:param name="cacheResource"/>
        <!-- file name -->

        <!-- do some base 64 stuff open connection etc.. and wite to datapower -->
        <xsl:variable name="binaryRep">
            <dp:serialize select="exslt:node-set($localResource)" omit-xml-decl="no"/>
        </xsl:variable>


        <xsl:variable name="base64encoded" select="dp:encode($binaryRep, 'base-64')"/>

        <!-- Generate the credentials for SOMA -->
        <xsl:call-template name="dpcp:getCacheConfig"/>


        <xsl:variable name="dpdomain" select="dp:variable('var://service/domain-name')"/>

        <xsl:variable name="cachename">
            <xsl:call-template name="dpcp:getCacheName">
                <xsl:with-param name="delete" select="false()"/>
                <xsl:with-param name="filename" select="$cacheResource"/>
            </xsl:call-template>
        </xsl:variable>

        <!-- generate request -->
        <xsl:variable name="soapcall">
            <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
                <soapenv:Body>
                    <dp:request xmlns:dp="http://www.datapower.com/schemas/management">
                        <dp:set-file>
                            <xsl:attribute name="name">
                                <xsl:value-of select="$cachename"/>
                            </xsl:attribute>
                            <xsl:value-of select="$base64encoded"/>
                        </dp:set-file>
                    </dp:request>
                </soapenv:Body>
            </soapenv:Envelope>
        </xsl:variable>


        <xsl:call-template name="dpcp:invokeWrapper">
            <xsl:with-param name="soapcall" select="$soapcall"/>
        </xsl:call-template>


    </xsl:template>




    <!-- template to delete a file -->
    <xsl:template name="dpcp:deletecache">
        <xsl:param name="cacheResource"/>
        <!-- file name -->
        <xsl:call-template name="dpcp:getCacheConfig"> </xsl:call-template>
        <!-- need to build the cache path -->
        <xsl:variable name="cachefilepath">
            <xsl:call-template name="dpcp:getCacheName">
                <xsl:with-param name="filename" select="$cacheResource"/>
                <xsl:with-param name="delete" select="true()"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="domain" select="dp:variable('var://context/config/cache/dpdomain')"/>
        <!-- generate request -->
        <xsl:variable name="soapcall">
            <env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
                <env:Body>
                    <dp:request xmlns:dp="http://www.datapower.com/schemas/management">
                        <xsl:attribute name="domain">
                            <xsl:value-of select="$domain"/>
                        </xsl:attribute>
                        <dp:do-action>
                            <DeleteFile>
                                <File>
                                    <xsl:value-of select="$cachefilepath"/>
                                </File>
                            </DeleteFile>

                        </dp:do-action>
                    </dp:request>
                </env:Body>
            </env:Envelope>
        </xsl:variable>

        <!-- send the flush request -->
        <xsl:call-template name="dpcp:invokeWrapper">
            <xsl:with-param name="soapcall" select="$soapcall"/>
        </xsl:call-template>

    </xsl:template>


    <!-- Expecting a file list to come in 
        <filelist>
        <file></file>
        <file></file>
        <file></file>
        </filelist>
        -->
    <xsl:template name="dpcp:flushcache">
        <xsl:variable name="configvalues">
            <xsl:call-template name="dpcp:getCacheConfig"/>
        </xsl:variable>

        <xsl:variable name="domain" select="dp:variable('var://context/config/cache/dpdomain')"/>
        <xsl:variable name="xmlMgr" select="dp:variable('var://context/config/cache/docCache')"/>
        <!-- generate request -->
        <xsl:variable name="soapcall">
            <env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
                <env:Body>
                    <dp:request xmlns:dp="http://www.datapower.com/schemas/management">
                        <xsl:attribute name="domain">
                            <xsl:value-of select="$domain"/>
                        </xsl:attribute>
                        <dp:do-action>
                            <FlushStylesheetCache>
                                <XMLManager>
                                    <xsl:value-of select="$xmlMgr"/>
                                </XMLManager>
                            </FlushStylesheetCache>
                            <FlushDocumentCache>
                                <XMLManager>
                                    <xsl:value-of select="$xmlMgr"/>
                                </XMLManager>
                            </FlushDocumentCache>

                        </dp:do-action>
                    </dp:request>
                </env:Body>
            </env:Envelope>
        </xsl:variable>

        <!-- send the flush request -->
        <xsl:variable name="result">
            <xsl:call-template name="dpcp:invokeWrapper">
                <xsl:with-param name="soapcall" select="$soapcall"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:copy-of select="$result"/>

    </xsl:template>




    <xsl:template name="dpcp:refreshFiles">
        <xsl:param name="filelist"/>
        <xsl:variable name="configvalues">
            <xsl:call-template name="dpcp:getCacheConfig"/>
        </xsl:variable>

        <xsl:variable name="domain" select="dp:variable('var://context/config/cache/dpdomain')"/>
        <xsl:variable name="xmlMgr" select="dp:variable('var://context/config/cache/docCache')"/>
        <!-- generate request -->
        <xsl:variable name="soapcall">
            <env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
                <env:Body>
                    <dp:request xmlns:dp="http://www.datapower.com/schemas/management">
                        <xsl:attribute name="domain">
                            <xsl:value-of select="$domain"/>
                        </xsl:attribute>
                        <dp:do-action>
                            <xsl:for-each select="$filelist/FileList/File">
                                <!--    <RefreshStylesheet>
                                    <XMLManager>
                                        <xsl:value-of select="$xmlMgr"/>
                                    </XMLManager>
                                   
                                    <Stylesheet>
                                        <xsl:call-template name="dpcp:getCacheName">
                                            <xsl:with-param name="delete" select="false()"/>
                                            <xsl:with-param name="filename" select="./text()"/>
                                        </xsl:call-template>                                       
                                    </Stylesheet>
                                </RefreshStylesheet>-->

                                <RefreshDocument>
                                    <XMLManager>
                                        <xsl:value-of select="$xmlMgr"/>
                                    </XMLManager>

                                    <Document>
                                        <!-- make a triple slash instead of 2 -->
                                        <xsl:call-template name="dpcp:getCacheName">
                                            <xsl:with-param name="delete" select="true()"/>
                                            <xsl:with-param name="filename" select="./text()"/>
                                        </xsl:call-template>

                                    </Document>
                                </RefreshDocument>
                            </xsl:for-each>
                        </dp:do-action>
                    </dp:request>
                </env:Body>
            </env:Envelope>
        </xsl:variable>

        <!-- send the refresh request -->
        <xsl:variable name="result">
            <xsl:call-template name="dpcp:invokeWrapper">
                <xsl:with-param name="soapcall" select="$soapcall"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:copy-of select="$result"/>

        <!-- bootstrap it test code only, we use a different xml manager for services, it would be meaningless to
             bootstrap it into the current xml mangager
        -->
        <!--<xsl:for-each select="$filelist/FileList/File">
            <xsl:variable name="doc">
                <xsl:call-template name="dpcp:getCacheName">
                    <xsl:with-param name="delete" select="true()"/>
                    <xsl:with-param name="filename" select="./text()"/>
                </xsl:call-template>
            </xsl:variable>
            <dp:set-variable name="'var://context/debug/cachefilename'" value="./text()"/>
            <xsl:variable name="temp">

                <xsl:copy-of select="document($doc)"/>
            </xsl:variable>
            <dp:set-variable name="'var://context/debug/cachecontent'" value="$temp"/>
        </xsl:for-each>-->

    </xsl:template>



    <xsl:template name="dpcp:invokeWrapper">
        <xsl:param name="soapcall"/>
        <xsl:variable name="headers">
            <xsl:call-template name="dpcp:generateHeader"/>
        </xsl:variable>
        <xsl:variable name="ssl" select="dp:variable('var://context/config/cache/sslProxy')"> </xsl:variable>
        <xsl:variable name="dpcacheconfig">
            <serviceURL>
                <xsl:value-of select="dp:variable('var://context/config/cache/serviceURL')"/>
            </serviceURL>
            <soapcall>
                <xsl:copy-of select="$soapcall"/>
            </soapcall>
            <identity>
                <xsl:value-of select="$ssl"/>
            </identity>
            <httpheaders>
                <!--header name="Authorization">Basic bWljaGFlbF9odWk6Y2hrZW4wMQ==</header-->
                <xsl:copy-of select="$headers"/>
            </httpheaders>
            <timeout>
                <xsl:value-of select="dp:variable('var://context/config/cache/timeout')"/>
            </timeout>
        </xsl:variable>


        <xsl:call-template name="dpcom:invokeSoapWithRetry">
            <xsl:with-param name="retry" select="dp:variable('var://context/config/cache/retries')"/>
            <xsl:with-param name="external" select="true()"/>
            <xsl:with-param name="invokeid" select="'abc'"/>
            <xsl:with-param name="soapconfig" select="$dpcacheconfig"/>
        </xsl:call-template>


        <!--  <xsl:copy-of select="$result"/>-->
    </xsl:template>



    <xsl:template name="dpcp:getCacheName">
        <xsl:param name="filename"/>
        <xsl:param name="delete"/>
        <xsl:call-template name="dpcp:getCacheConfig"/>
        <xsl:choose>
            <xsl:when test="$delete = true()">
                <xsl:value-of
                    select="concat(dp:variable('var://context/config/cache/cacheDirDelete'),$filename)"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of
                    select="concat(dp:variable('var://context/config/cache/cacheDir'),$filename)"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>


    <!-- Todo: Modify this to use datapower variables, maybe, arguably more efficient since it will cause
         datapower to hit cache anyways, and perhaps it can be stored at the service level-->
    <xsl:template name="dpcp:getCacheConfig">
        <!-- don't load if values already exist -->
        <xsl:variable name="dpconfig" select="dp:variable('var://context/config/cache/ServiceURL')"/>
        <xsl:if test="not($dpconfig)">
            <xsl:variable name="configvalues">
                <xsl:copy-of select="document('config/dpcacheconfig.xml')"/>
            </xsl:variable>

            <dp:set-variable name="'var://context/config/cache/username'"
                value="$configvalues/DPCacheConfiguration/Username[1]"/>
            <dp:set-variable name="'var://context/config/cache/password'"
                value="$configvalues/DPCacheConfiguration/Password[1]"/>
            <dp:set-variable name="'var://context/config/cache/key'"
                value="$configvalues/DPCacheConfiguration/Key[1]"/>
            
            <dp:set-variable name="'var://context/config/cache/dpdomain'"
                value="dp:variable('var://service/domain-name')"/>
            <dp:set-variable name="'var://context/config/cache/cacheDir'"
                value="concat('local://',dp:variable('var://context/config/cache/dpdomain'),'/',$configvalues/DPCacheConfiguration/ResourceMap,'/')"/>
            <dp:set-variable name="'var://context/config/cache/cacheDirDelete'"
                value="concat('local:///',$configvalues/DPCacheConfiguration/ResourceMap,'/')"/>

            <dp:set-variable name="'var://context/config/cache/serviceURL'"
                value="$configvalues/DPCacheConfiguration/ServiceURL"/>
            <dp:set-variable name="'var://context/config/cache/retries'"
                value="$configvalues/DPCacheConfiguration/retry"/>
            <dp:set-variable name="'var://context/config/cache/sslProxy'"
                value="$configvalues/DPCacheConfiguration/SSLProxy"/>
            <dp:set-variable name="'var://context/config/cache/timeout'"
                value="$configvalues/DPCacheConfiguration/timeout"/>
            <dp:set-variable name="'var://context/config/cache/docCache'"
                value="$configvalues/DPCacheConfiguration/DocumentCache"/>


           <!-- <xsl:variable name="headerValues">
                <header name="Content-Type">application/soap+xml</header>
                <header name="Authorization">
                    <xsl:value-of
                        select="concat('Basic ', dp:encode(concat(dp:variable('var://context/config/cache/username'),
                    ':',dp:variable('var://context/config/cache/password')),'base-64'))"
                    />
                </header>
            </xsl:variable>

            <dp:set-variable name="'var://context/config/cache/HttpHeaders'" value="$headerValues"/>-->
        </xsl:if>

    </xsl:template>


    <xsl:template name="dpcp:generateHeader">
        <xsl:call-template name="dpcp:getCacheConfig"/>
        <xsl:variable name="decrypted-password"
            select="dp:decrypt-key(dp:variable('var://context/config/cache/password'), concat('name:', dp:variable('var://context/config/cache/key')), 'http://www.w3.org/2001/04/xmlenc#rsa-1_5')"/>
        <xsl:variable name="decoded-password" select="dp:decode($decrypted-password, 'base-64')"/>
        
        
        <header name="Content-Type">application/soap+xml</header>
        <header name="Authorization">
            <xsl:value-of
                select="concat('Basic ', dp:encode(concat(dp:variable('var://context/config/cache/username'),
                ':',$decoded-password),'base-64'))"
            />
        </header>
        
    </xsl:template>
</xsl:stylesheet>
