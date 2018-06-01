<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:include href="AaaCommonLibrary.xsl"/>
    
	<xsl:template match="/">
	    <xsl:call-template name="saveInitCtxPropertes"/>
	</xsl:template>
    
</xsl:stylesheet>