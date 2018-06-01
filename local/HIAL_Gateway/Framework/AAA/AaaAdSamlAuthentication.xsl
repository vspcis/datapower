<?xml version="1.0" encoding="UTF-8"?>
<!-- Change Log: 
				Oct 19 2015 - 6617 Added business and transactional event logging for AAA events.
				Oct 15 2015 - 6666 -No cerficate DN also should fail Authentication. 
	            Oct 7 2015 - 6617, moved the Authorization code of checking groups into the Authorization step.
	                          most of the group check code was inside the Authentication step, which is incorrect
	                          System logs always show both an Authentication Error and Authorization error whenever
	                          There is just an Authorization Error
	                          
	                          
	                          -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:wss="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
	xmlns:dsig="http://www.w3.org/2000/09/xmldsig#"
	xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
	xmlns:dp="http://www.datapower.com/extensions" xmlns:exslt="http://exslt.org/common"
	extension-element-prefixes="dp exslt" exclude-result-prefixes="soap saml wss dsig dp exslt">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<xsl:include href="AaaCommonLibrary.xsl"/>

	<xsl:template match="/">
		<xsl:variable name="busStartTime">
			<xsl:call-template name="logAAABusEvent">
				<xsl:with-param name="authentication" select="true()"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="sslSubjectDN">
			<xsl:call-template name="getSubjectDN">
				<xsl:with-param name="dn" select="/identity/entry[@type='client-ssl']/dn"/>
			</xsl:call-template>
		</xsl:variable>
		<!-- we should fail authentication if no ssl certificate presented as well -->
		<xsl:choose>
			<xsl:when test="string-length($sslSubjectDN) = 0">
				<dp:set-variable name="'var://context/aaa/error-message'"
					value="'No client certificate found'"/>
				<dp:xreject reason="'No client certificate found'"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="samlValidation">
					<xsl:call-template name="loggedSamlValidation">
						<xsl:with-param name="assertion"
							select="/identity/entry[@type = 'saml-authen-name']/assertion/saml:Assertion"
						/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="$samlValidation = &apos;&apos;">
						<xsl:copy-of
							select="/identity/entry[@type = 'saml-authen-name']/assertion/saml:Assertion"
						/>
					</xsl:when>
					<xsl:otherwise>
						<dp:set-variable name="'var://context/aaa/error-message'"
							value="string($samlValidation)"/>
						<dp:xreject reason="string($samlValidation)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>


		<xsl:call-template name="logAAABusResultEvent">
			<xsl:with-param name="startTime" select="$busStartTime"/>
			<xsl:with-param name="passed" select="dp:accepting()"/>
			<xsl:with-param name="authentication" select="true()"/>
		</xsl:call-template>
	</xsl:template>
</xsl:stylesheet>
