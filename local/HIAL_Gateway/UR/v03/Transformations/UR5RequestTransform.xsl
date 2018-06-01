<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>UR5RequestTransform.xsl</Filename>
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
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   exclude-result-prefixes="xsl" 
   version="1.0">

    <!-- copy through all elements by default -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- for any incoming subject ID attribute, replace it with data predefined by UR  -->
    <xsl:template match="xacml:Attribute[@AttributeId='urn:oasis:names:tc:xacml:1.0:subject:subject-id']">
        <xacml:Attribute AttributeId="urn:oasis:names:tc:xacml:1.0:subject:subject-id" DataType="http://security.bea.com/ssmws/ssm-ws-1.0.wsdl#OESPrincipalInfo" xsi:type="urn:AttributeType">
             <xacml:AttributeValue xsi:type="urn:AttributeValueType">{name=PEP}+(class=weblogic.security.principal.WLSGroupImpl)</xacml:AttributeValue>
        </xacml:Attribute>
    </xsl:template>

   <!--  for any attributeValue element, ignore it if the value is empty there -->
    <xsl:template match="xacml:AttributeValue">    
            <xsl:variable name="attributeValue" select="normalize-space(./text())" />
            <xsl:if test="string-length($attributeValue) &gt; 0  ">
                  <xsl:copy-of select="."/>
            </xsl:if>    
    </xsl:template>
</xsl:stylesheet>
