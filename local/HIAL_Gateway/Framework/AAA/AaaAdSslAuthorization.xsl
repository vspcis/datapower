<?xml version="1.0" encoding="UTF-8"?>
<!-- Change Log: 
	Oct 21 2015 - 6617 - Added Business event for Start/Result 
	Oct 7 2015 - 6617, moved the Authorization code of checking groups into the Authorization step.
	                          most of the group check code was inside the Authentication step, which is incorrect
	                          System logs always show both an Authentication Error and Authorization error whenever
	                          There is just an Authorization Error
	                          
	                          
	                          -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
	xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp"
	exclude-result-prefixes="xsl saml dp">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<xsl:include href="AaaCommonLibrary.xsl"/>

	<xsl:template match="/">
		<!--credential & resources-->
		<!--<xsl:variable name="sslClientSubject" select="/container/mapped-credentials/entry/dn"/>-->
		<!--<xsl:variable name="resource" select="/container/mapped-resource/resource/item/resource"/>-->
		<xsl:variable name="busStartTime">
			<xsl:call-template name="logAAABusEvent">
				<xsl:with-param name="authentication" select="false()"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:variable name="sslSubjectDN">
			<xsl:call-template name="getSubjectDN">
				<xsl:with-param name="dn" select="/container/identity/entry[@type='client-ssl']/dn"
				/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="sslCertADGroup"
			select="dp:variable('var://context/aaa/ssl-cert-ad-group')"/>
		<xsl:variable name="sslCertValidation">
			<xsl:call-template name="loggedGroupMembershipValidation">
				<xsl:with-param name="subjectDN" select="$sslSubjectDN"/>
				<xsl:with-param name="group" select="$sslCertADGroup"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="decision">
			<xsl:choose>
				<xsl:when test="$sslCertValidation = &apos;&apos;">
					<!--<xsl:copy-of select="/identity/entry[@type='client-ssl']/dn"/>	-->
					<approved/>
				</xsl:when>
				<xsl:otherwise>
					<dp:set-variable name="'var://context/aaa/error-message'"
						value="string($sslCertValidation)"/>
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
