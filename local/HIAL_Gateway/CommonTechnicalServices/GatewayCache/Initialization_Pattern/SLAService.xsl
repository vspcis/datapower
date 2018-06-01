<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>SLAService.xsl</Filename>
<revisionlog>
Intial Revision:
July 23: Policy Version Removed from output file format due to GUUID added to policy name by convention.
</revisionlog>
<Description>

Specialization template for handling Retrieving SLAs from WSRR and Populating into
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
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy" extension-element-prefixes="dp"
    exclude-result-prefixes="xsl dp wsp" version="1.0">


    <xsl:import href="dpCacheProxyService.xsl"/>
    <xsl:import href="PolicyInitCommonTemplates.xsl"/>

    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    <xsl:template name="updateAllSLACache2">
        <xsl:variable name="rtypemap">
            <resourcerel>
                <List>SLAList</List>
                <Base>SLAAttachment</Base>
            </resourcerel>
        </xsl:variable>
        <xsl:call-template name="updateAll">
            <xsl:with-param name="resourceType" select="$rtypemap"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="updateSLACache2">
        <xsl:param name="filename"/>
        <xsl:param name="id"/>

        <xsl:call-template name="updateResource">
            <xsl:with-param name="resourceType" select="'SLAAttachment'"/>
            <xsl:with-param name="filename" select="$filename"/>
            <xsl:with-param name="id" select="$id"/>
        </xsl:call-template>

    </xsl:template>

    <!-- match on the SLA attachment, this will provide the logic to process a SLA attachment to 
        transform it into an SLA file -->
    <xsl:template match="/resourcewrapper[@type='SLAAttachment']">
        <SLA>
            <xsl:attribute name="name">
                <xsl:value-of select="./context/name/text()"/>
            </xsl:attribute>
            <xsl:for-each select="//*[local-name() = 'PolicyReference']">
                <Policy>
                    <PolicyName>
                        <!-- Strip URN if it exists otherwise leave alone -->
                        <xsl:variable name="uri">
                            <xsl:call-template name="removeURN">
                                <xsl:with-param name="uriString" select="@URI"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:value-of select="$uri/uri/text()"/>
                        <!--<xsl:variable name="upper" select="'URN'"/>
                        <xsl:variable name="lower" select="'urn'"/>
                        <xsl:choose>
                            <xsl:when test="starts-with(translate(@URI,$upper,$lower), 'urn:')">
                                <xsl:value-of select="substring(@URI,5)"/>
                                <!-\- Strip URN: -\->
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="@URI"/>
                            </xsl:otherwise>
                        </xsl:choose>-->


                    </PolicyName>
                    <!-- Change due to latest spec update July 21 2015 -->
                    <!--<PolicyVersion>
                        <xsl:value-of select="@bsrURI"/>
                    </PolicyVersion>-->
                </Policy>
            </xsl:for-each>
        </SLA>
    </xsl:template>

    <!-- Custom temlate for generating filename for the attachment -->
    <xsl:template match="/filecontext[@type='SLAAttachment']">
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
            <xsl:value-of select="concat(./name/text(),'.xml')"/>
        </File>
    </xsl:template>


</xsl:stylesheet>
