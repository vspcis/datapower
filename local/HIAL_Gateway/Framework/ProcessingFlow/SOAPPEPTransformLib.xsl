<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>SOAPPEPTransformLib.xsl</Filename>
<revisionlog>v1.0.1</revisionlog>
<Description>
Meant to be extended by all PEP Transforms.
Logging the executed transformation becomes automatically executed
This is the implementation for SOAP, does nothing since the commonPEP handles this.
</Description>
<Owner>eHealthOntario</Owner>
<LastUpdate>Initial Check in</LastUpdate>
<Copyright>
**************************************************************
  Copyright (c) ehealthOntario, 2015 ~ 2020
**************************************************************
</Copyright>
</CodeHeader>
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions"  
    xmlns:dpconfig="http://www.datapower.com/param/config" 
    exclude-result-prefixes="xsl dp date dpwsm dpconfig wsmp"
    extension-element-prefixes="dp" 
    version="1.0">

    <xsl:variable name="PEPName" select="'n/a'"/>
    
    <xsl:template name="captureExecutedPolicy">
        <xsl:param name="PEPName"/>
        <!-- do nothing -->
    </xsl:template>
    
     
</xsl:stylesheet>