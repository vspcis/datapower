<?xml version="1.0" encoding="UTF-8"?>
<!-- Change Log: Initial Revision -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:wss="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
	xmlns:dsig="http://www.w3.org/2000/09/xmldsig#"
	xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
	xmlns:dp="http://www.datapower.com/extensions" xmlns:exslt="http://exslt.org/common"
	extension-element-prefixes="dp exslt" exclude-result-prefixes="soap saml wss dsig dp exslt">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<xsl:include href="AaaCommonLibrary.xsl"/>

	<!-- note , this transform must exist, because the alternative is to skip the authentication step
		all together by configuring the policy, however that is done, datapower throws and Authentication error 
		by default-->
	<xsl:template match="/">
		<xsl:variable name="busStartTime">
			<xsl:call-template name="logAAABusEvent">
				<xsl:with-param name="authentication" select="true()"/>
			</xsl:call-template>
		</xsl:variable>
		<!-- Grab the CN from the transient data context -->
		<xsl:variable name="ConsumerSystem" select="dp:variable('var://context/aaa/ConsumerSystem')"/>
		
		<xsl:variable name="mapconfig">
			<xsl:copy-of select="document('Config/aaa-whitelist.xml')"/>
		</xsl:variable>
		<!--dp:set-variable name="'var://context/aaa/aaa-whitelist'" value="$mapconfig"/-->
		
		<xsl:variable name="serviceName" select="dp:variable('var://service/wsm/service')"/>
		
		<xsl:choose>
			<xsl:when test="$mapconfig/ws_service_aaa_map/ws_service[@wsm_service = $serviceName]/acceptcn/text() = $ConsumerSystem">
				<xsl:call-template name="logAAABusResultEvent">
					<xsl:with-param name="startTime" select="$busStartTime"/>
					<xsl:with-param name="passed" select="true()"/>
					<xsl:with-param name="authentication" select="true()"/>
				</xsl:call-template>
				<xsl:value-of select="$ConsumerSystem"/>						
			</xsl:when>
			<!-- If we ever want to do Operation level authorization we can insert another when statement that checks at operation level,
				but the semantic is that service level takes precedence -->
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
