<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>WSDLPolicyService.xsl</Filename>
<revisionlog>
Initial Version 
</revisionlog>
<Description>

Specialization template for handling WSDLs and generating the wsdl policy attachment file

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
    <xsl:template name="updateAllWSDLMaps">
        <xsl:variable name="rtypemap">
            <resourcerel>
                <List>WSDLList</List>
                <Base>WSDLAttachment</Base>
            </resourcerel>
        </xsl:variable>
        <xsl:call-template name="updateAll">
            <xsl:with-param name="resourceType" select="$rtypemap"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- this pattern is different from the norm, as we have to do a 3 level query
        Only issue here is we dn't have the ID nor the filename, in fact this pattern works,
        the approach is to convert the event into another which we will recognize.
    -->
    <xsl:template name="updateWSDLCache">
        <xsl:param name="filename"/>
        <xsl:param name="id"/>
        
        <xsl:call-template name="updateResource">
            <xsl:with-param name="resourceType" select="'WSDLAttachment'"/>
            <xsl:with-param name="filename" select="$filename"/>
            <xsl:with-param name="id" select="$id"/>
        </xsl:call-template>
        
    </xsl:template>
    
    <!-- match on the SLA attachment, this will provide the logic to process a SLA attachment to 
        transform it into an SLA file -->
    <xsl:template match="/resourcewrapper[@type='WSDLAttachment']">
        <Wsdl>
            <Name>
                <xsl:value-of select="./context/name/text()"/>
            </Name>
            <Operations>
            <xsl:for-each select="//*[local-name() = 'operation']">
               <xsl:variable name="inputWsAction" select="string(./*[local-name()='input']/@*[local-name()='Action'])" />
               <xsl:variable name="outputWsAction" select="string(./*[local-name()='output']/@*[local-name()='Action'])" />
                <Operation>
                    <Name>
                        <xsl:value-of select="@name"/>
                    </Name>
                    <xsl:if test="string-length($inputWsAction) &gt; 0" >
                        <InputWSAction><xsl:value-of select="$inputWsAction"/></InputWSAction>
                    </xsl:if>
                    <xsl:if test="string-length($outputWsAction) &gt; 0" >
                        <OutputWSAction><xsl:value-of select="$outputWsAction"/></OutputWSAction>
                    </xsl:if>                    
                    <Policies>
                    <xsl:for-each select="./*[local-name()= 'Policy']">
                        <!-- Strip URN if it exists otherwise leave alone -->
                        <Policy>
                        <xsl:variable name="uri">
                            <xsl:call-template name="removeURN">
                                <xsl:with-param name="uriString" select="@Name"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:value-of select="$uri/uri/text()"/>
                        </Policy>                
                    </xsl:for-each>
                    </Policies>
                    <!-- Change due to latest spec update July 21 2015 -->
                    <!--<PolicyVersion>
                        <xsl:value-of select="@bsrURI"/>
                    </PolicyVersion>-->
                </Operation>
            </xsl:for-each>
            </Operations>
        </Wsdl>
    </xsl:template>
    
    <!-- Custom temlate for generating filename for the attachment -->
    <xsl:template match="/filecontext[@type='WSDLAttachment']">
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
            <!-- chop the .wsdl off -->
            <xsl:value-of select="concat(substring-before(./name/text(), '.wsdl'),'.xml')"/>
        </File>
    </xsl:template>
    
    
</xsl:stylesheet>