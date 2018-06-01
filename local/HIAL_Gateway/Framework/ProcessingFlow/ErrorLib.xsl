<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>ErrorLib.xsl</Filename>
<revisionlog>Initial</revisionlog>
<Description>
  This has common library for raising xslt based errors
</Description>
<Owner>eHealthOntario</Owner>
<LastUpdate>
</LastUpdate>
<Copyright>
**************************************************************
  Copyright (c) ehealthOntario, 2015 ~ 2020
**************************************************************
</Copyright>
</CodeHeader>
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions" 
    extension-element-prefixes="dp" 
    version="1.0">
    
    <!-- Template function for raising errors within xslt with specific error code to be handled in error handling -->
    <xsl:template name="raiseError">
        <xsl:param name="errorCode"/>
        
        <dp:set-variable name="'var://context/hial_ctx/error-code'" value="$errorCode"/>
    </xsl:template>
</xsl:stylesheet>