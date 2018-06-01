<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>UR5ResponseTransform.xsl</Filename>
<revisionlog>v1.0.0</revisionlog>
<Description>
  This is the UR4 to UR5 interface adapter transform logic
</Description>
<Owner>eHealthOntario</Owner>
<LastUpdate>Sept 6, 2016</LastUpdate>
<Copyright>
**************************************************************
  Copyright (c) ehealthOntario, 2016 ~ 2020
**************************************************************
</Copyright>
</CodeHeader>
-->
<xsl:stylesheet 
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  
   xmlns:xacml="urn:oasis:names:tc:xacml:2.0:context:schema:os"
  exclude-result-prefixes="xsl" 
   version="1.0">

    <!-- copy through all elements by default -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <!--  
       The following template will validate the decision field, it will
       1. return Permit if UR provide permit value
       2. return Deny for any other returned value, including NotApplicable, Deny, Indeterminate, 
    -->
    <xsl:template match="//xacml:Response/xacml:Result/xacml:Decision">
        <xsl:variable name="decisionValue" select="normalize-space(./text())" />
        <xsl:choose>
            <xsl:when test="$decisionValue = 'Permit'">
                <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:otherwise>
                <xacml:Decision>Deny</xacml:Decision>                
            </xsl:otherwise>
        </xsl:choose>  
    </xsl:template>

</xsl:stylesheet>
