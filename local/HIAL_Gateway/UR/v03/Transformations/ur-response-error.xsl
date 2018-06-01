<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
		xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
		xmlns:dp="http://www.datapower.com/extensions" 
		exclude-result-prefixes="xsl soap" 
		extension-element-prefixes="dp">
	<xsl:output method="xml" encoding="UTF-8" indent="yes"/>
	<xsl:template match="/">
		<xsl:variable name="fault-from-backend" select="dp:variable('var://context/error/fault-from-backend')"/>
		<xsl:variable name="formatted-error-message" select="dp:variable('var://service/formatted-error-message')"/>
		
		<xsl:choose>
			<xsl:when test="$fault-from-backend">
				<xsl:copy-of select="."/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy>
					<dp:parse select="$formatted-error-message"/>
				</xsl:copy>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>