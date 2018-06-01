<xsl:stylesheet version="1.0" 
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
		xmlns:dp="http://www.datapower.com/extensions" 
		xmlns:dpconfig="http://www.datapower.com/param/config" 
		extension-element-prefixes="dp">
	<xsl:output method="html" encoding="UTF-8" indent="yes"/>
	<xsl:include href="local://Framework/AAA/AaaCommonLibrary.xsl"/>

	<xsl:template match="/">
		<xsl:variable name="password" select="//args[@src='body']/arg[@name='password']"/>
		<xsl:variable name="certificate" select="//args[@src='body']/arg[@name='certificate']"/>

		<xsl:choose>
			<xsl:when test="$certificate = &apos;&apos;">
				<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
					<head>
						<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
						<title>Password Encryption Response</title>
					</head>
					<body>
						<table>
							<tr>
								<td/>
								<td align="left">
									<div style="color: #666666; font-size: 100%;"> No Certificate found!</div>
								</td>
							</tr>
						</table>
					</body>
				</html>
			</xsl:when>
			<xsl:otherwise>
			<xsl:variable name="encrypted-password">
				<xsl:call-template name="encryptString">
					<xsl:with-param name="certName" select="$certificate"/>
					<xsl:with-param name="decryptedString" select="$password"/>
				</xsl:call-template>
			</xsl:variable>
				<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
					<head>
						<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
						<title>Password Encryption Response</title>
					</head>
					<body>
						<table>
							<tr>
								<td/>
								<td align="left">
									<div style="color: #666666; font-size: 100%;"> Encrypted Password Below:</div>
								</td>
							</tr>
							<tr id="password-row" class="enabled">
								<td align="right" nowrap="nowrap">
									<span class="gaia le lbl"/>
								</td>
								<td>
									<textarea type="text" name="Passwd" id="Passwd" size="50" readonly="readonly" class="gaia le val" rows="10" cols="100">
										<xsl:value-of select="$encrypted-password"/>
									</textarea>
								</td>
							</tr>
						</table>
					</body>
				</html>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
