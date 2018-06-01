<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>PolicyAttachmentEventAdapter.xsl</Filename>
<revisionlog>
Initial Version 
</revisionlog>
<Description>

This module will convert wsrr policy attachment events into WSDL event notifications

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
    xmlns:body="http://www.ibm.com/xmlns/prod/serviceregistry/HttpPostNotifierPluginMsgBody"
    xmlns:wsrradapter="http://ehealthontario.on.ca/wsrrnotificationadapter"
    xmlns:wsrrf="http://ehealthontario.on.ca/wsrr/proxy"
    xmlns:wsrr="http://www.ibm.com/xmlns/prod/serviceregistry/6/2/wspolicy"
    xmlns:exslt="http://exslt.org/common"
    extension-element-prefixes="dp exslt"
    exclude-result-prefixes="xsl dp wsrradapter body wsrrf wsrr" version="1.0">

    <xsl:import href="WSRRProxyService.xsl"/>
    <xsl:import href="LoggingUtility.xsl"/>
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>


    <!-- This template will return the converted event -->
    <xsl:template name="convertToWSDLEvent">
        <xsl:param name="event"/>
        <dp:set-variable name="'var://context/log/EVENTCOPY'" value="$event"/>
        <xsl:variable name="RT-PAC" select="'PolicyAttachmentContent'"/>
        <xsl:variable name="RT-WSDLMeta" select="'WSDLMetadata'"/>
        <xsl:variable name="RT-WSDLData" select="'WSDLData'"/>

        <wsrradapter:resources
            xmlns:wsrradapter="http://ehealthontario.on.ca/wsrrnotificationadapter">
<!--            <dp:set-variable name="'var://context/log/EVENTResource'" value="exslt:node-set($event)/*[local-name()='resources']/*[local-name()='resource']"/>-->
            <xsl:for-each select="$event/*[local-name()='resources']/*[local-name()='resource']/*[local-name() ='notificationResource']">
                <wsrradapter:resource>
                    <!-- the bsr uri may not be important here if we don't consume it -->
                    <wsrradapter:notificationResource event="UPDATE" subscribedType="WSDLDocument">
                        <xsl:variable name="id" select="string(@resourceBsrURI)"/>
                        <dp:set-variable name="'var://context/log/bsrURI'" value="$id"/>
                        <!-- call make Content Query to obtain Policy Attachment-->
                        <xsl:variable name="policyAttachment">
                            <xsl:call-template name="wsrrf:getResource">
                                <xsl:with-param name="bsrURI" select="$id"/>
                                <xsl:with-param name="resourceType" select="$RT-PAC"/>
                            </xsl:call-template>
                        </xsl:variable>


                        <xsl:choose>
                            <xsl:when test="count($policyAttachment/Error) &gt; 0">
                                <!-- stop processing, nothing returned -->
                                <xsl:call-template name="AddErrorMessage">
                                    <xsl:with-param name="OperationName"
                                        select="'convertToWSDLEvent-policyAttachment'"/>
                                    <xsl:with-param name="Message"
                                        select="concat('WSRR query for bsrURI=',$id, ' resourcetype ', $RT-PAC,' failed')"
                                    />
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="wsdlOperationID">
                                    <xsl:value-of
                                        select="$policyAttachment//*[local-name()='PolicySubjectQuery' and starts-with(@wsrr:xpath, '//WSDLOperation')]/@wsrr:xpath"
                                    />
                                </xsl:variable>

                                <xsl:if test="string-length($wsdlOperationID) &gt; 0">
                                    <!-- now need to chop the ID from the stirng which looks like:
                                        //WSDLOperation[@bsrURI='xysdfdsfs'] -->
                                    <dp:set-variable name="'var://context/log/wsdloperationID'" value="string($wsdlOperationID)"/>
                                    <xsl:variable name="opID" select='translate(substring-before(substring-after($wsdlOperationID,"@bsrURI="), "]"), "&apos;","")'/>
                                    <!-- call get metadata to obtain the wsdl bsr ID -->
                                    <xsl:variable name="wsdlBsrID">
                                        <xsl:call-template name="wsrrf:getResource">
                                            <xsl:with-param name="bsrURI" select="$opID"/>
                                            <xsl:with-param name="resourceType"
                                                select="$RT-WSDLMeta"/>
                                        </xsl:call-template>
                                    </xsl:variable>
                                    <xsl:choose>
                                        <xsl:when test="count($wsdlBsrID/Error) &gt; 0">
                                            <!-- stop processing, nothing returned -->
                                            <xsl:call-template name="AddErrorMessage">
                                                <xsl:with-param name="OperationName"
                                                  select="'convertToWSDLEvent-wsdlBsrID'"/>
                                                <xsl:with-param name="Message"
                                                    select="concat('WSRR query for bsrURI=',$opID, ' resourcetype ', $RT-WSDLMeta,' failed')"
                                                />
                                            </xsl:call-template>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:variable name="wsdlID" select="$wsdlBsrID/resources/resource/relationships/relationship[@targetType='WSDLDocument']/@targetBsrURI"/>
                                                
                                            
                                            <xsl:attribute name="resourceBsrURI">
                                                <xsl:value-of
                                                  select="$wsdlID"
                                                />
                                            </xsl:attribute>
                                            <xsl:attribute name="subscribedBsrUri">
                                                <xsl:value-of
                                                    select="$wsdlID"
                                                />
                                            </xsl:attribute>
                                            <!-- call to get WSDL to get meta data wsdl name -->
                                            <xsl:variable name="wsdlData">
                                                <xsl:call-template name="wsrrf:getResource">
                                                  <xsl:with-param name="bsrURI" select="$wsdlID"/>
                                                  <xsl:with-param name="resourceType"
                                                  select="$RT-WSDLData"/>
                                                </xsl:call-template>
                                            </xsl:variable>

                                            <xsl:choose>
                                                <xsl:when test="count($wsdlData/Error) &gt; 0">
                                                  <!-- stop processing, nothing returned -->
                                                  <xsl:call-template name="AddErrorMessage">
                                                  <xsl:with-param name="OperationName"
                                                  select="'convertToWSDLEvent-wsdlBsrID'"/>
                                                  <xsl:with-param name="Message"
                                                  select="concat('WSRR query for bsrURI=',$wsdlID, ' resourcetype ', $RT-WSDLData,' failed')"
                                                  />
                                                  </xsl:call-template>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                  <xsl:attribute name="subscribedName">
                                                  <xsl:value-of
                                                  select="$wsdlData/properties/property[@name='name']/@value"
                                                  />
                                                  </xsl:attribute>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:if>



                            </xsl:otherwise>
                        </xsl:choose>
                    </wsrradapter:notificationResource>
                </wsrradapter:resource>
            </xsl:for-each>
        </wsrradapter:resources>


        <!-- Output format     
            
            <wsrradapter:resources
            xmlns:wsrradapter="http://ehealthontario.on.ca/wsrrnotificationadapter">
            <wsrradapter:resource bsrURI="b0cba7b0-b534-4414.8c89.d03778d08973" type="Subscription">
                <wsrradapter:notificationResource event="UPDATE"
                    resourceBsrURI="ofTheWSDL-fb57-47db.977d.0e7b900e7d7f" 
                    subscribedBsrUri="ofTheWSDL-fb57-47db.977d.0e7b900e7d7f"
                    subscribedName="xyz.wsdl"
                    subscribedType="WSDLDocument"/>
            </wsrradapter:resource>
        </wsrradapter:resources>-->



    </xsl:template>
</xsl:stylesheet>
