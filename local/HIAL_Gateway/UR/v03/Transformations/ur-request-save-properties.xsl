<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
		xmlns:dp="http://www.datapower.com/extensions" 
		exclude-result-prefixes="xsl" 
		extension-element-prefixes="dp">
	<xsl:include href="local:///Common/v03/Transformations/bkbn-common-library.xslt"/>
	<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

	<xsl:template match="/">
		<xsl:call-template name="save-request-properties"/>

		<dp:remove-http-request-header name="SDN"/>				
		<dp:remove-http-request-header name="TID"/>				
	</xsl:template>
</xsl:stylesheet>