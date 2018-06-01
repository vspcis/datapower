<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>ConstructTransientData.xsl</Filename>
<revisionlog>v1.0.0</revisionlog>
<Description>
  This is the common PEP logic
</Description>
<Owner>eHealthOntario</Owner>
<LastUpdate>June 9, 2016</LastUpdate>
<Copyright>
**************************************************************
  Copyright (c) ehealthOntario, 2016
**************************************************************
</Copyright>
</CodeHeader>
-->
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:date="http://exslt.org/dates-and-times" 
    xmlns:dp="http://www.datapower.com/extensions" 
    xmlns:dpwsm="http://www.datapower.com/schemas/transactions" 
    xmlns:dpconfig="http://www.datapower.com/param/config" 
    xmlns:wsmp="http://www.ibm.com/xmlns/stdwip/2011/02/ws-mediation"
    xmlns:hiallib="http://www.ehealthontario.on.ca/hial/lib"
    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" 
    xmlns:xacml="urn:oasis:names:tc:xacml:2.0:context:schema:os"
    xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"
    exclude-result-prefixes="xsl dp date dpwsm dpconfig wsmp hiallib"
    extension-element-prefixes="dp" 
    version="1.0">
    
    <xsl:include href="local:Framework/Lib/Log4GateWay.xsl" />
    <xsl:import href="ConstructTransientData.xsl"/>
    
    <xsl:variable name="processingRule" select="dp:variable('var://service/transaction-rule-type')" /> 
    <xsl:variable name="txnContext"   select="dp:variable('var://context/hialPEP/txnContext')"/>
    <xsl:variable name="soap12NameSpace" select="'http://www.w3.org/2003/05/soap-envelope'" />
    
    <xsl:template match="/">
        
        <xsl:call-template name="prepareTransitData"/>        
        
        <xsl:choose>
            <xsl:when test="/*[local-name()='Envelope']/*[local-name()='Header']">
                <xsl:apply-templates select="@*|node()"/>  
            </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="soapNameSpace" select="namespace-uri(/)"/>
               <xsl:choose>
                   <xsl:when test="$soapNameSpace = $soap12NameSpace">
                       <xsl:element name="soap12:Envelope" >
                           <xsl:copy-of select="@*"/>
                           <xsl:element name="soap12:Header">
                               <xsl:variable name="transitData"   select="dp:variable('var://context/logging/transientData')"/>
                               <xsl:copy-of select="$transitData"/>                        
                           </xsl:element>
                           
                           <xsl:element name="soap12:Body">
                               <xsl:copy-of select="@*"/>
                               <xsl:copy-of select="/*[local-name()='Envelope']/*[local-name()='Body']/*"/>
                           </xsl:element>                    
                       </xsl:element>                       
                   </xsl:when>
                   <xsl:otherwise>
                       <xsl:element name="soapenv:Envelope" >
                           <xsl:copy-of select="@*"/>
                           <xsl:element name="soapenv:Header">
                               <xsl:variable name="transitData"   select="dp:variable('var://context/logging/transientData')"/>
                               <xsl:copy-of select="$transitData"/>                        
                           </xsl:element>
                           
                           <xsl:element name="soapenv:Body">
                               <xsl:copy-of select="@*"/>
                               <xsl:copy-of select="/*[local-name()='Envelope']/*[local-name()='Body']/*"/>
                           </xsl:element>                    
                       </xsl:element>                       
                   </xsl:otherwise>
               </xsl:choose> 
            </xsl:otherwise>
        </xsl:choose>        
    </xsl:template>
    
    <!-- copy through all elements -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- append transiet data into soap header if it exists -->    
    <xsl:template match="/*[local-name()='Envelope']/*[local-name()='Header']">        
        <xsl:copy>
            <xsl:apply-templates select="./*[ not (local-name()='TransientData') ]"/>
            <xsl:variable name="transitData"   select="dp:variable('var://context/logging/transientData')"/>
            <xsl:copy-of select="$transitData"/>
        </xsl:copy>        
    </xsl:template>
    
    <!-- prepare the transient data -->
    <xsl:template name="prepareTransitData">
        
        <xsl:choose>
            <xsl:when test="dp:variable('var://context/logging/transientData')">
                <dp:set-variable name="'var://context/logging/transitDataStatus'" value="'already loaded when send data to backbone'"/>
            </xsl:when>
            <xsl:otherwise>
                <dp:set-variable name="'var://context/logging/transitDataStatus'" value="'Not loaded when send data to backbone'"/>
                <xsl:call-template name="buildTransientData"/>
            </xsl:otherwise>
        </xsl:choose>        

        <!-- Log the current business event -->        
        <xsl:call-template name="hiallib:logEvent">
            <xsl:with-param name="logLevel" select="'info'"/>
            <xsl:with-param name="facility" select="'TRN'"/>
            <xsl:with-param name="logGroup" select="'TRD'"/>
            <xsl:with-param name="activity" select="'ERQ'"/>
            <xsl:with-param name="transactionId" select="$txnContext/txnContext/globalID/text()"/>
            <xsl:with-param name="logContent" select="concat('Update and flush transient data for rule ', $processingRule, '. Starting to invoke HIAL HIB service.')"/>
        </xsl:call-template> 

    </xsl:template>   
    
</xsl:stylesheet>
