<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:wss="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" 
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" 
	xmlns:dsig="http://www.w3.org/2000/09/xmldsig#" 
	xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
	xmlns:dp="http://www.datapower.com/extensions" 
	xmlns:exslt="http://exslt.org/common" 
	extension-element-prefixes="dp exslt" 
	exclude-result-prefixes="soap saml wss dsig dp exslt">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<xsl:include href="AaaCommonLibrary.xsl"/>
	
	<xsl:template match="/">
        <xsl:variable name="busStartTime">
            <xsl:call-template name="logAAABusEvent">
                <xsl:with-param name="authentication" select="true()"/>
            </xsl:call-template>
        </xsl:variable>
		<!-- DN from the client cert for HTTPS/SSL  endpoint -->
		<xsl:variable name="sslDomainName" select="/identity/entry[@type='client-ssl']/dn/text()"/>
		<!-- DN from the transient data context for HTTP  endpoint -->
		<xsl:variable name="ConsumerSystem" select="dp:variable('var://context/aaa/ConsumerSystem')"/>
		
		<!-- no authentication required for this AAA policy. Simply checks DN exists in context for authorization -->
		<xsl:choose>
			<xsl:when test="string-length($sslDomainName) > 0">
				<xsl:call-template name="logAAABusResultEvent">
					<xsl:with-param name="startTime" select="$busStartTime"/>
					<xsl:with-param name="passed" select="true()"/>
					<xsl:with-param name="authentication" select="true()"/>
				</xsl:call-template>
				<xsl:value-of select="$sslDomainName"/>
			</xsl:when>
			<xsl:when test= "string-length($ConsumerSystem) > 0" >
				<xsl:call-template name="logAAABusResultEvent">
					<xsl:with-param name="startTime" select="$busStartTime"/>
					<xsl:with-param name="passed" select="true()"/>
					<xsl:with-param name="authentication" select="true()"/>
				</xsl:call-template>
				<xsl:value-of select="$ConsumerSystem"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="logAAABusResultEvent">
					<xsl:with-param name="startTime" select="$busStartTime"/>
					<xsl:with-param name="passed" select="false()"/>
					<xsl:with-param name="authentication" select="true()"/>
				</xsl:call-template>
				<dp:reject/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>	
	
</xsl:stylesheet>