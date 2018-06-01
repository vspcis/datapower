<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>ConstructTransientData.xsl</Filename>
<revisionlog>v1.0.0</revisionlog>
<Description>
  This is the common PEP logic
</Description>
<Owner>eHealthOntario</Owner>
<LastUpdate>Setp 29, 2015</LastUpdate>
<Copyright>
**************************************************************
  Copyright (c) ehealthOntario, 2015
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
    exclude-result-prefixes="xsl dp date dpwsm dpconfig wsmp"
    extension-element-prefixes="dp" 
    version="1.0">
    
    <xsl:import href="ContxtDataUtil.xsl"/>

    <xsl:template match="/">

        <xsl:variable name="initContext">
            <xsl:call-template name="loadInitContext"/>
        </xsl:variable>
        <dp:set-variable name="'var://context/hialPEP/txnContext'" value="$initContext"/>

        <!-- the following template will load the SLA policy into dp variable -->
        <xsl:call-template name="loadSLAContext"/>

    </xsl:template>

</xsl:stylesheet>
