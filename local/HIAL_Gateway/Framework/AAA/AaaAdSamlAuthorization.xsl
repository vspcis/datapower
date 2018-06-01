<?xml version="1.0" encoding="UTF-8"?>
<!-- Change Log: 
	Oct 19 2015 - 6617  Added Business and Transactional Events for AAA
	Oct 15 2015 - 6666, Issue with using the dp:accept command to check Authentication step. The only way to 
	              identify if the Authentication step Passed is to check the mapped-credentials of the input, if no
	              mapped credentials, then Authentication failed.
	Oct 7 2015 - 6617, moved the Authorization code of checking groups into the Authorization step.
	                          most of the group check code was inside the Authentication step, which is incorrect
	                          System logs always show both an Authentication Error and Authorization error whenever
	                          There is just an Authorization Error
	                          
	                          
	                          -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:wss="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
	xmlns:dp="http://www.datapower.com/extensions" xmlns:dsig="http://www.w3.org/2000/09/xmldsig#"
	xmlns:exslt="http://exslt.org/common" extension-element-prefixes="dp exslt"
	exclude-result-prefixes="xsl saml dp dsig exslt wss">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<xsl:include href="AaaCommonLibrary.xsl"/>
	<xsl:template match="/">

		<xsl:variable name="busStartTime">
			<xsl:call-template name="logAAABusEvent">
				<xsl:with-param name="authentication" select="false()"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:variable name="mappedCredentials"
			select="//mapped-credentials/entry[@type='custom']/saml:Assertion"/>

		<xsl:variable name="decision">
			<xsl:choose>

				<xsl:when test="count($mappedCredentials) = 0">
					<declined/>
				</xsl:when>
				<xsl:otherwise>

					<xsl:variable name="sslSubjectDN">
						<xsl:call-template name="getSubjectDN">
							<xsl:with-param name="dn"
								select="/container/identity/entry[@type='client-ssl']/dn"/>
						</xsl:call-template>
					</xsl:variable>
					<xsl:variable name="sslCertADGroup"
						select="dp:variable('var://context/aaa/ssl-cert-ad-group')"/>
					<!--SSL cert membership validation-->
					<xsl:variable name="sslCertValidation">
						<xsl:call-template name="loggedGroupMembershipValidation">
							<xsl:with-param name="subjectDN" select="$sslSubjectDN"/>
							<xsl:with-param name="group" select="$sslCertADGroup"/>
						</xsl:call-template>
					</xsl:variable>

					<xsl:choose>
						<xsl:when test="$sslCertValidation = &apos;&apos;">
							<xsl:variable name="samlCertValidation">
								<xsl:call-template name="loggedGroupMembershipValidation">
									<xsl:with-param name="subjectDN"
										select="/container/identity/entry[@type='saml-authen-name']/assertion/saml:Assertion/dsig:Signature/dsig:KeyInfo/dsig:X509Data/dsig:X509SubjectName"/>
									<xsl:with-param name="group"
										select="dp:variable('var://context/aaa/saml-cert-ad-group')"
									/>
								</xsl:call-template>
							</xsl:variable>
							<xsl:choose>
								<xsl:when test="$samlCertValidation = &apos;&apos;">
									<!--    <xsl:copy-of select="/identity/entry[@type = 'saml-authen-name']/assertion/saml:Assertion"/>-->
									<approved/>
								</xsl:when>
								<xsl:otherwise>
									<dp:set-variable name="'var://context/aaa/error-message'"
										value="string($samlCertValidation)"/>
									<declined/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>
							<dp:set-variable name="'var://context/aaa/error-message'"
								value="string($sslCertValidation)"/>
							<declined/>
						</xsl:otherwise>
					</xsl:choose>


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
