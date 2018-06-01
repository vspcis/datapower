<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>FMBLRetrievalService.xsl</Filename>
<revisionlog>Initial Version</revisionlog>
<Description>

Specialization template for handling Retrieving FMBL/Logging maps from WSRR and Populating into
Gatway Cache

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
    xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp"
    exclude-result-prefixes="xsl dp" version="1.0">

    <!--    <xsl:import href="WSRRProxyService.xsl"/>-->
    <xsl:import href="dpCacheProxyService.xsl"/>
    <xsl:import href="PolicyInitCommonTemplates.xsl"/>


    <xsl:template name="updateAllFMBLCache">
        <xsl:variable name="rtypemap">
            <resourcerel>
                <List>FMBLMaps</List>
                <Base>GenericContentFMBL</Base>
            </resourcerel>
        </xsl:variable>
        <xsl:call-template name="updateAll">
            <xsl:with-param name="resourceType" select="$rtypemap"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="updateFMBLCache">
        <xsl:param name="filename"/>
        <xsl:param name="id"/>

        <xsl:call-template name="updateResource">
            <xsl:with-param name="resourceType" select="'GenericContentFMBL'"/>
            <xsl:with-param name="filename" select="$filename"/>
            <xsl:with-param name="id" select="$id"/>
        </xsl:call-template>

    </xsl:template>


    <xsl:template match="/resourcewrapper[@type='GenericContentFMBL']">

        <xsl:copy-of select="./*[not(local-name() = 'context')]"/>

    </xsl:template>


    <xsl:template match="/filecontext[@type='GenericContentFMBL']">
        <!-- the context coming in looks like 
           <filecontext>
                            <xsl:attribute name="type">
                                <xsl:value-of select="$resourceType"/>
                            </xsl:attribute>
                            <name>
                                <xsl:value-of select="$filename"/>
                            </name>
                            <bsruri>
                                <xsl:value-of select="$id"/>
                            </bsruri>
                        </filecontext>
            -->
        <File>
            <xsl:value-of select="./name/text()"/>
        </File>
    </xsl:template>

</xsl:stylesheet>
