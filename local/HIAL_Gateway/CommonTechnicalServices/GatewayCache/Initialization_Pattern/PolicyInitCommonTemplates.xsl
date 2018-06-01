<?xml version="1.0" encoding="UTF-8"?>

<!--
<CodeHeader>
<Filename>PolicyInitCommonTemplates.xsl</Filename>
<revisionlog>
Initial Version
July23 - Added common removeURI template to strip urn from uri strings
</revisionlog>
<Description>

WSRR resource to Cache management common module. 
Given the resource type this module can correctly download and place the resource into cache.

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
    xmlns:wsrrf="http://ehealthontario.on.ca/wsrr/proxy"
    xmlns:dpcp="http://ehealthontario.on.ca/datapower/cache/proxy"
    xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
    exclude-result-prefixes="xsl dp wsrrf dpcp wsdl" extension-element-prefixes="dp" version="1.0">

    <xsl:import href="WSRRProxyService.xsl"/>
    <xsl:import href="dpCacheProxyService.xsl"/>
    <xsl:import href="LoggingUtility.xsl"/>
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

    <!-- ********* Module External Templates ******************************************** -->

    <!-- Updates a cache with WSRR resources based on Resource List Retrieval and subsequently
         retrievng all referenced resources and placing into cache
         -->
    <xsl:template name="updateAll">
        <xsl:param name="resourceType"/>
        <!-- Resource type in WSRR, this is defined by the WSRR configuration file -->
        <xsl:variable name="rtypeString" select="string($resourceType/resourcerel/List/text())"/>
        <xsl:variable name="btypeString" select="string($resourceType/resourcerel/Base/text())"/>
        <dp:set-variable name="'var://context/parameter/rtype'" value="$rtypeString"/>
        <xsl:variable name="resourceList">
            <xsl:call-template name="wsrrf:getResourceList">
                <xsl:with-param name="resourceType" select="$rtypeString"/>
            </xsl:call-template>
        </xsl:variable>


        <!-- some error handling here -->
        <xsl:choose>
            <xsl:when test="count($resourceList/Error) &gt; 0">

                <xsl:call-template name="AddErrorMessage">
                    <xsl:with-param name="OperationName" select="'updateall-resourcelist'"/>
                    <xsl:with-param name="Message"
                        select="concat('Could not execute WSRR Query for ', $rtypeString)"/>
                </xsl:call-template>

            </xsl:when>

            <xsl:otherwise>
                <!-- run thru each BSRID and download from WSRR -->
                <xsl:variable name="updatedfileset">
                    <FileList>

                        <xsl:for-each select="$resourceList/resources/resource">

                            <xsl:call-template name="updateResource">
                                <xsl:with-param name="id"
                                    select="properties/property[@name='bsrURI']/@value"/>
                                <xsl:with-param name="filename"
                                    select="properties/property[@name='name']/@value"/>
                                <xsl:with-param name="resourceType" select="$btypeString"
                                > </xsl:with-param>
                            </xsl:call-template>

                        </xsl:for-each>
                    </FileList>
                </xsl:variable>

                <xsl:call-template name="dpcp:refreshFiles">
                    <xsl:with-param name="filelist" select="$updatedfileset"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <!-- Updates cache for individual updates to WSRR
         Template upon successful operation will return a list of 
         filenames which were placed into cache
    -->
    <xsl:template name="updateResource">
        <xsl:param name="id"/>
        <!-- The bsrURI of the WSRR resource -->
        <xsl:param name="filename"/>
        <!-- The name of the file as will be stored into the cache -->
        <xsl:param name="resourceType"/>
        <!-- The type of resource that will be retrieved and stored into cache, defined by
            the wsrr configuration file -->

        <!-- updates 1 particular sla referenced by ID-->
        <xsl:variable name="returnedResource">
            <xsl:call-template name="wsrrf:getResource">
                <xsl:with-param name="bsrURI" select="$id"/>
                <xsl:with-param name="resourceType" select="$resourceType"/>
            </xsl:call-template>
        </xsl:variable>

                <dp:set-variable name="'var://context/config/wsrr/wsrrresponse'" value="$returnedResource"/>
        <xsl:choose>
            <xsl:when test="count($returnedResource/Error) &gt; 0">
                <!-- stop processing, nothing returned -->
                <xsl:call-template name="AddErrorMessage">
                    <xsl:with-param name="OperationName" select="'update-getresource'"/>
                    <xsl:with-param name="Message"
                        select="concat('WSRR query for bsrURI=',$id, ' resourcetype ', $resourceType,' failed')"
                    />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>


                <xsl:variable name="newFilename">
                    <xsl:call-template name="generateFilename">
                        <xsl:with-param name="filename" select="$filename"/>
                        <xsl:with-param name="id" select="$id"/>
                        <xsl:with-param name="resourceType" select="$resourceType"/>
                        <xsl:with-param name="returnedResource" select="$returnedResource"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:message>
                    <xsl:value-of select="concat('new filename ', $newFilename/File/text())"/>
                </xsl:message>


                <!--  possible override of the returned resource -->
                <xsl:call-template name="handleOverrideResource">
                    <xsl:with-param name="retrivedResource" select="$returnedResource"/>
                    <xsl:with-param name="filename" select="$filename"/>
                    <xsl:with-param name="resourceType" select="$resourceType"/>
                </xsl:call-template>
                
                <xsl:variable name="overridedFlag" select="dp:variable('var://context/override/overridedFlag')"/>


                <!-- perform a resource specific transform here -->
                <xsl:variable name="wrappedresource">
                    <resourcewrapper>
                        <xsl:attribute name="type">
                            <xsl:value-of select="$resourceType"/>
                        </xsl:attribute>
                        <context>
                            <name>
                                <xsl:value-of select="$filename"/>
                            </name>
                        </context>
                        
                        <xsl:choose>
                            <xsl:when test="$overridedFlag = 'true'">
                                <xsl:variable name="overridedResource" select="dp:variable('var://context/override/overridedResource')"/>
                                <xsl:copy-of select="$overridedResource"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:copy-of select="$returnedResource"/>
                            </xsl:otherwise>
                        </xsl:choose>                        
                        
                    </resourcewrapper>
                </xsl:variable>
                <!-- Calls a specific transform to convert the returned resource to 
                        the cache format -->
                <xsl:variable name="cachedResource">
                    <xsl:for-each select="$wrappedresource">
                        <xsl:apply-templates/>
                    </xsl:for-each>
                </xsl:variable>

                <xsl:variable name="cacheupdatestatus">
                    <xsl:call-template name="dpcp:writeToCache">
                        <xsl:with-param name="localResource" select="$cachedResource"/>
                        <xsl:with-param name="cacheResource" select="$newFilename/File/text()"/>
                    </xsl:call-template>
                </xsl:variable>

                <dp:set-variable name="'var://context/config/mgmt/response'"
                    value="$cacheupdatestatus"/>
                <!--count($cacheupdatestatus/Error) &gt; 0-->
                <xsl:if test="count($cacheupdatestatus/Error) &gt; 0">
                    <dp:set-variable name="'var://context/config/mgmt/inside'" value="true()"/>
                    <xsl:call-template name="AddErrorMessage">
                        <xsl:with-param name="Message"
                            select="concat('Cache Write after Update failed for ', $filename, ' bsrid=',$id)"/>
                        <xsl:with-param name="OperationName" select="'update-writecache'"/>
                    </xsl:call-template>
                </xsl:if>

                <xsl:copy-of select="$newFilename"/>


            </xsl:otherwise>
        </xsl:choose>




    </xsl:template>



    <!-- Check if policy present -->    
    <xsl:template name="isOperationPolicyAttached">
        <xsl:param name="retrivedResource"/>
        
        <xsl:variable name="wsdlName" select="$retrivedResource/wsdl:definitions/@name"/>
        <xsl:choose>
            
            <xsl:when test="$retrivedResource/wsdl:definitions/wsdl:portType/wsdl:operation/*[local-name()='Policy']">                            
                <xsl:message dp:priority="debug">Policy init::WSP Policy definition in port type is found for WSDL <xsl:value-of select="$wsdlName" /></xsl:message>
                <xsl:value-of select="'true'"/>
            </xsl:when>
            <xsl:when test="$retrivedResource/wsdl:definitions/wsdl:binding/wsdl:operation/*[local-name()='Policy']">
                <xsl:message dp:priority="debug">Policy init::WSP Policy definition in binding is found for WSDL <xsl:value-of select="$wsdlName" /></xsl:message>
                <xsl:value-of select="'true'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message dp:priority="debug">Policy init::WSP Policy definition is not found for WSDL <xsl:value-of select="$wsdlName" /></xsl:message>
                <xsl:value-of select="'false'"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <!-- This is a nested template to handle potencial override -->
    <xsl:template name="handleOverrideResource">
        <xsl:param name="resourceType"/>        
        <xsl:param name="retrivedResource"/>
        <xsl:param name="filename"/>
        
        <dp:set-variable name="'var://context/override/overridedFlag'" value="'false'"/>                    
        
        <xsl:if test="$resourceType = 'WSDLAttachment'">
            
            <xsl:variable name="wsdlName" select="$retrivedResource/wsdl:definitions/@name"/>
            
            <xsl:variable name="policyAttached">
                <xsl:call-template name="isOperationPolicyAttached">
                    <xsl:with-param name="retrivedResource" select="$retrivedResource"/>
                </xsl:call-template>
            </xsl:variable> 
            
            <xsl:choose>
                <!-- -->
                <xsl:when test="string($policyAttached) = 'true'">                            
                    <xsl:message dp:priority="debug">Policy init::WSP policy is found for WSDL file <xsl:value-of select="$filename" /> inside WSLD definition <xsl:value-of select="$wsdlName"/></xsl:message>
                    <dp:set-variable name="'var://context/override/overridedFlag'" value="'true'"/>                    
                    <dp:set-variable name="'var://context/override/overridedResource'" value="$retrivedResource"/>                    
                    <dp:set-variable name="'var://context/config/wsrr/wsrrresponse'" value="$retrivedResource"/>
                </xsl:when>
                <xsl:otherwise>
                    
                    <xsl:message dp:priority="debug">Policy init::WSP definition not yet found for WSDL <xsl:value-of select="$filename"/>, Will trace up to get more information</xsl:message>
                    
                    <!-- If there is no operatoin defined in the current WSDL, then it must imported another one, try to fetch that ! -->
                    <xsl:variable name="wsdlLocation" select="string($retrivedResource/wsdl:definitions/wsdl:import/@location)"/>
                    <xsl:if test="string-length($wsdlLocation) &gt; 0">
                        
                        <xsl:variable name="overridedBsrURI" select="substring-after($wsdlLocation,'WSDL?bsrURI=')"/>
                        <xsl:message dp:priority="debug">Policy init::Found wsdl:import for <xsl:value-of select="$wsdlLocation"/></xsl:message>
                        
                        <!-- make wsrr call only if the overrided BSRuri exists -->
                        <xsl:if test="string-length($overridedBsrURI) &gt; 0">
                            
                            <xsl:variable name="overridedResource">
                                <xsl:call-template name="wsrrf:getResource">
                                    <xsl:with-param name="bsrURI" select="$overridedBsrURI"/>
                                    <xsl:with-param name="resourceType" select="$resourceType"/>
                                </xsl:call-template>
                            </xsl:variable>
                            
                            <xsl:choose>
                                <xsl:when test="count($overridedResource/Error) &gt; 0">
                                    <xsl:call-template name="AddErrorMessage">
                                        <xsl:with-param name="OperationName" select="'update-getresource'"/>
                                        <xsl:with-param name="Message" select="concat('WSRR query for bsrURI=',$overridedBsrURI, ' resourcetype ', $resourceType,' failed')" />
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:otherwise>
                                    
                                    <xsl:call-template name="handleOverrideResource">
                                        <xsl:with-param name="retrivedResource" select="$overridedResource"/>
                                        <xsl:with-param name="filename" select="$filename"/>
                                        <xsl:with-param name="resourceType" select="$resourceType"/>
                                    </xsl:call-template>
                                    
                                </xsl:otherwise>
                            </xsl:choose>
                            
                        </xsl:if>
                        
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        
    </xsl:template>


    <!-- Deletes a cached resource based on it's id and filename -->

    <xsl:template name="deleteResource">
        <xsl:param name="filename"/>
        <!-- Filename is based on the filename in cache, no path information -->
        <xsl:param name="id"/>
        <!-- The bsrURI of the file in wsrr -->
        <xsl:param name="resourceType"/>
        <!-- The resource type defined by wsrr config file -->
        <xsl:param name="returnedResource"/>
        <!-- The context of the call to this template, eg. if wsrr notification was used, then the
             whole notification message is placed into this parameter
        -->
        <!-- Need to add resource type parameter and perform the same name translation logic -->
        <xsl:variable name="newFilename">
            <xsl:call-template name="generateFilename">
                <xsl:with-param name="filename" select="$filename"/>
                <xsl:with-param name="id" select="$id"/>
                <xsl:with-param name="resourceType" select="$resourceType"/>
                <xsl:with-param name="returnedResource" select="$returnedResource"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="deleteStatus">
            <xsl:call-template name="dpcp:deletecache">
                <xsl:with-param name="cacheResource" select="$newFilename"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="count($deleteStatus/Error) &gt; 0">
                <xsl:call-template name="AddErrorMessage">
                    <xsl:with-param name="OperationName" select="'deletecache'"/>
                    <xsl:with-param name="Message"
                        select="concat('Cache Delete failed for ', $filename)"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <File>
                    <xsl:value-of select="$filename"/>
                </File>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>
    
    <!--
        Strip URN off of URN strings 
        -->
    
    <xsl:template name="removeURN">
        <xsl:param name="uriString"/>
        
        <xsl:variable name="upper" select="'URN'"/>
        <xsl:variable name="lower" select="'urn'"/>
        <uri>
        <xsl:choose>
            <xsl:when test="starts-with(translate($uriString,$upper,$lower), 'urn:')">
                <xsl:value-of select="substring($uriString,5)"/>
                <!-- Strip URN: -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$uriString"/>
            </xsl:otherwise>
        </xsl:choose>
        </uri>
    </xsl:template>

    <!-- ********** Module Internal Templates ********************************************************** -->
    <xsl:template name="generateFilename">
        <xsl:param name="filename"/>
        <xsl:param name="resourceType"/>
        <xsl:param name="id"/>
        <xsl:param name="returnedResource"/>
        <xsl:variable name="filenameContext">
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
                <xsl:copy-of select="$returnedResource"/>
            </filecontext>
        </xsl:variable>

        <xsl:for-each select="$filenameContext">
            <xsl:apply-templates/>
            <!-- Make call to specialization classes -->
        </xsl:for-each>
    </xsl:template>



</xsl:stylesheet>
