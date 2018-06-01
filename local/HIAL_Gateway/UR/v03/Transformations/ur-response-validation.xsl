<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
		xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
		xmlns:wsa="http://www.w3.org/2005/08/addressing"
		xmlns:fault="http://fault.sts.ur.idm.ehealth.gov.on.ca/"
		xmlns:wst="http://docs.oasis-open.org/ws-sx/ws-trust/200512/" 
		xmlns:ssm="http://security.bea.com/ssmws/ssm-soap-types-1.0.xsd"
		xmlns:dp="http://www.datapower.com/extensions" 
		exclude-result-prefixes="xsl soap wsa fault wst ssm dp"
		extension-element-prefixes="dp">
	<xsl:output method="xml" encoding="UTF-8" indent="yes"/>
	<xsl:template match="/">
		<xsl:variable name="error-message">
			<xsl:choose>
				<xsl:when test="/soap:Envelope/soap:Body/soap:Fault">
					<xsl:value-of select="concat('From Backend: ', /soap:Envelope/soap:Body/soap:Fault/faultcode, '-', /soap:Envelope/soap:Body/soap:Fault/faultstring)"/>
				</xsl:when>
				<xsl:when test="/soap:Envelope/soap:Body/wst:RequestSecurityTokenResponse/fault:FaultToken">
					<xsl:value-of select="concat('From Backend: ', /soap:Envelope/soap:Body/wst:RequestSecurityTokenResponse/fault:FaultToken/fault:fault/fault:code, '-', /soap:Envelope/soap:Body/wst:RequestSecurityTokenResponse/fault:FaultToken/fault:fault/fault:messageEn)"/>
				</xsl:when>
				<xsl:when test="/soap:Envelope/soap:Body/ssm:xacmlFailure">
					<xsl:value-of select="concat('From Backend: ', /soap:Envelope/soap:Body/ssm:xacmlFailure)"/>
				</xsl:when>
				<xsl:when test="/soap:Envelope/soap:Body/ssm:serviceFailure">
					<xsl:value-of select="concat('From Backend: ', /soap:Envelope/soap:Body/ssm:serviceFailure)"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:if test="string-length($error-message) > 0">
			<dp:set-variable name="'var://context/error/fault-from-backend'" value="boolean(true())"/>
			<dp:reject>
				<xsl:value-of select="$error-message"/>
			</dp:reject>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>
