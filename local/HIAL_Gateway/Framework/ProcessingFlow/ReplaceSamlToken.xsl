<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>ReplaceSamlToken.xsl</Filename>
<revisionlog>Bug Fix for soap 1.1 namespace recognition</revisionlog>
<Description>

In context, this stylesheet is used to both remove the existing security from the output context,
and then inject the STS Response saml into the output context.

Notes: It always drops the client's Saml token regardless of whether there is a STS token.

Created for use with the DHDR service.

In future this could potentially be policy driven. 

</Description>
<Owner>eHealthOntario</Owner>
<Copyright>
**************************************************************
  Copyright (c) ehealthOntario, 2016
  
  This unpublished material is proprietary to ehealthOntario.
  All rights reserved. Reproduction or distribution, in whole 
  or in part, is forbidden except by express written permission 
  of ehealthOntario.
**************************************************************
</Copyright>
</CodeHeader>

-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:date="http://exslt.org/dates-and-times" xmlns:dp="http://www.datapower.com/extensions"
	xmlns:dpwsm="http://www.datapower.com/schemas/transactions"
	xmlns:dpconfig="http://www.datapower.com/param/config"
	xmlns:wsmp="http://www.ibm.com/xmlns/stdwip/2011/02/ws-mediation"
	xmlns:hiallib="http://www.ehealthontario.on.ca/hial/lib"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
	xmlns:xacml="urn:oasis:names:tc:xacml:2.0:context:schema:os"
	exclude-result-prefixes="xsl dp date dpwsm dpconfig wsmp hiallib"
	extension-element-prefixes="dp" version="1.0">

	<xsl:template match="@*|node()">
		<xsl:choose>
			<xsl:when test="local-name()='Security'"> </xsl:when>
			<xsl:when
				test="local-name()='Header' and (namespace-uri() = 'http://www.w3.org/2003/05/soap-envelope' or namespace-uri() = 'http://schemas.xmlsoap.org/soap/envelope/')">

				<xsl:copy>
					<xsl:if test="dp:variable('var://context/aaa/ur-saml-token')">
						<Security
							xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
							<xsl:variable name="stsToken"
								select="dp:variable('var://context/aaa/ur-saml-token')//saml:Assertion"/>
							<xsl:copy-of select="$stsToken"/>
						</Security>
					</xsl:if>
					<xsl:apply-templates select="@*|node()"/>
				</xsl:copy>
			</xsl:when>

			<xsl:otherwise>
				<xsl:copy>
					<xsl:apply-templates select="@*|node()"/>
				</xsl:copy>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!--    
	<xsl:template match="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='Security']/*[local-name()='Assertion']">
	</xsl:template>
	
	<xsl:template match="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='Security']">
			<Security xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
			</Security>
	</xsl:template>
	
	<xsl:template match="/*[local-name()='Envelope']/*[local-name()='Header']">

	<xsl:if test="count(./*[local-name()='Security']) = 0">
			<Security xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
			</Security>
			</xsl:if>
	</xsl:template>
	-->
</xsl:stylesheet>
