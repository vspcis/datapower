<?xml version="1.0" encoding="UTF-8"?>
<!-- Initial Revision -->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
	xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp"
	exclude-result-prefixes="xsl saml dp">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<xsl:include href="AaaCommonLibrary.xsl"/>

	<xsl:template match="/">
		<xsl:variable name="busStartTime">
			<xsl:call-template name="logAAABusEvent">
				<xsl:with-param name="authentication" select="false()"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="assertion" select="/container/mapped-credentials/entry[@type='custom']/text()"/>
		<dp:set-variable name="'var://context/aaa/containerVal'" value="/container/*"/>
		<xsl:variable name="decision">
			<xsl:choose>
				<xsl:when test="$assertion != &apos;&apos;">
					<approved/>
				</xsl:when>
				<xsl:otherwise>
					<!--no credentials -->
					<declined/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:call-template name="logAAABusResultEvent">
			<xsl:with-param name="authentication" select="false()"/>
			<xsl:with-param name="startTime" select="$busStartTime"/>
			<xsl:with-param name="passed" select="count($decision/approved) &gt; 0"/>
		</xsl:call-template>
		
		<xsl:copy-of select="$decision"/>
	</xsl:template>
</xsl:stylesheet>
