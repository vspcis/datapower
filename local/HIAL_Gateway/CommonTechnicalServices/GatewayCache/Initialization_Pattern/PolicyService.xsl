<?xml version="1.0" encoding="UTF-8"?>

<!--
<CodeHeader>
<Filename>PolicyService.xsl</Filename>
<revisionlog>
Initial Version
July 23: Policy filename changed to due to addition of GUUID added in WSRR to policy names by convention
</revisionlog>
<Description>

Specialization template for handling Retrieving Policies from WSRR and Populating into
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


    <xsl:import href="dpCacheProxyService.xsl"/>
    <xsl:import href="PolicyInitCommonTemplates.xsl"/>


    <xsl:template name="updateAllPolicyCache">
        <xsl:variable name="rtypemap">
            <resourcerel>
                <List>GTW_PolicySearch</List>
                <Base>GenericContentPolicy</Base>
            </resourcerel>
        </xsl:variable>
        <xsl:call-template name="updateAll">
            <xsl:with-param name="resourceType" select="$rtypemap"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="updatePolicyCache">
        <xsl:param name="filename"/>
        <xsl:param name="id"/>

        <xsl:call-template name="updateResource">
            <xsl:with-param name="resourceType" select="'GenericContentPolicy'"/>
            <xsl:with-param name="filename" select="$filename"/>
            <xsl:with-param name="id" select="$id"/>
        </xsl:call-template>

    </xsl:template>

    <xsl:template match="/resourcewrapper[@type='GenericContentPolicy']">
        <xsl:copy-of select="./*[not(local-name() = 'context')]"/>
    </xsl:template>


    <!-- Custom temlate for generating filename for the attachment -->
    <xsl:template match="/filecontext[@type='GenericContentPolicy']">
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
                            <resourcefrom wsrr/>
                        </filecontext>
            -->
        <!--<File>
            <xsl:value-of
                select="concat(./*[local-name() = 'Policy']/@URI, '_', ./bsruri/text(), '.xml')"/>
        </File>-->
        <File>
            <!--<xsl:value-of
                select="concat(./*[local-name() = 'Policy']/@Name,'.xml')"/>-->
            <xsl:variable name="uri">
            <xsl:call-template name="removeURN">
                <xsl:with-param name="uriString" select="./*[local-name() = 'Policy']/@Name"/>
            </xsl:call-template>
            </xsl:variable>
            <xsl:value-of select="concat($uri/uri/text(),'.xml')"/>
        </File>
    </xsl:template>
</xsl:stylesheet>
