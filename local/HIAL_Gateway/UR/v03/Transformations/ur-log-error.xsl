<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
		xmlns:dp="http://www.datapower.com/extensions" 
		exclude-result-prefixes="xsl"
		extension-element-prefixes="dp">
	<xsl:include href="local:///Common/v03/Transformations/bkbn-common-library.xslt"/>
	<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

	<xsl:template match="/">
		<xsl:call-template name="bkbn-log-error" />
	</xsl:template>
</xsl:stylesheet>
