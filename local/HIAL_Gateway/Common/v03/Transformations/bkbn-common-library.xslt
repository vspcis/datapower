<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
		xmlns:soap12="http://www.w3.org/2003/05/soap-envelope" 
		xmlns:wsa200403="http://schemas.xmlsoap.org/ws/2004/03/addressing"
		xmlns:wsa200408="http://schemas.xmlsoap.org/ws/2004/08/addressing"
		xmlns:wsa200508="http://www.w3.org/2005/08/addressing"
		xmlns:eho="http://ehealthontario.on.ca/xmlns/common"
		xmlns:wss="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"	
		xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
		xmlns:dp="http://www.datapower.com/extensions"
		xmlns:ehodi="http://ehealthontario.on.ca/xmlns/v01/di"
		xmlns:date="http://exslt.org/dates-and-times"	
		exclude-result-prefixes="xsl soap soap12 wsa200403 wsa200408 wsa200508 wss saml eho" 
		extension-element-prefixes="dp">
	<xsl:output method="xml" encoding="UTF-8" indent="yes"/>
	
	
	<!--  New log transaction template with the HIAL logging signature -->
	<xsl:template name="bkbn-log-transaction" mode="HIAL1.0">
		<xsl:variable name="systemName" select="dp:variable('var://context/profile/system-name')" />		
		<xsl:variable name="nodeName" select="dp:variable('var://service/domain-name')"/>
		<xsl:variable name="appName" select="dp:variable('var://service/processor-name')"/>
		<xsl:variable name="svcPortName" select="dp:variable('var://context/log/service-port')"/>
		<xsl:variable name="svcPortOperation" select="dp:variable('var://context/log/service-port-operation')"/>
		<xsl:variable name="globalTxnId" select="dp:variable('var://context/log/transactionID')"/>		 	
		<xsl:variable name="sequence" select="dp:variable('var://context/log/global-sequence')"/>
		<xsl:variable name="nodeTxnId" select="dp:variable('var://service/transaction-id')"/>
		<xsl:variable name="startTime" select="dp:variable('var://context/log/start-time')"/>
		<xsl:variable name="elapsedTime" select= "ehodi:get-time-elapsed()"/><!--"dp:variable('var://service/time-elapsed')"/> -->
		<xsl:variable name="backendElapsedTime"  select="dp:variable('var://context/log/backend-time-elapsed')"/>
		<xsl:variable name="wsa-messageID" select="dp:variable('var://context/log/wsa-messageID')"/>
		<xsl:variable name="requestSize" select="dp:variable('var://service/mpgw/request-size')"/>
		<xsl:variable name="responseSize" select="dp:variable('var://service/mpgw/response-size')"/>
		<xsl:variable name="consumerSystem" select="dp:variable('var://context/log/subjectDN')"/>
		<xsl:variable name="consumerOrg" select="dp:variable('var://context/log/saml-uao')"/>
		<xsl:variable name="consumerUser" select="dp:variable('var://context/log/saml-nameid')"/>
		<xsl:variable name="consumerRole" select="dp:variable('var://context/log/saml-role')"/>		
		<xsl:variable name="sourceClientIP" select="dp:variable('var://context/log/source-client-IP')"/>
		<xsl:variable name="targetURI" select="dp:variable('var://service/routing-url')"/>

		<xsl:message dp:type="if-bkbn" dp:priority="info">
			<xsl:variable name="logEntry">
				Sys=<xsl:value-of select="$systemName"/>,
				Node=<xsl:value-of select="$nodeName"/>,
				App=<xsl:value-of select="$appName"/>,
				TxId=<xsl:value-of select="$globalTxnId"/>,
				Seq=<xsl:value-of select="$sequence"/>,		
				Srv=<xsl:value-of select="$svcPortName"/>,
				Op=<xsl:value-of select="$svcPortOperation"/>,
				NodeTid=<xsl:value-of select="$nodeTxnId"/>,
				StartTime=<xsl:value-of select="$startTime"/>,
				ElapsedTime=<xsl:value-of select="$elapsedTime"/>,
				MsgId=<xsl:value-of select="$wsa-messageID"/>,	
				MsgSizeReq=<xsl:value-of select="$requestSize"/>,
				MsgSizeRes=<xsl:value-of select="$responseSize"/>,				
				SrcSys=<xsl:value-of select="$consumerSystem"/>,
				SrcOrg=<xsl:value-of select="$consumerOrg"/>,
				SrcUser=<xsl:value-of select="$consumerUser"/>,
				SrcRole=<xsl:value-of select="$consumerRole"/>,
				SrcIP=<xsl:value-of select="$sourceClientIP"/>,
				TargetURI=<xsl:value-of select="$targetURI"/>,
				Status=SUCCESS,
				BackendElapsedTime=<xsl:value-of select="ehodi:get-backend-time-elapsed()"/>						
			</xsl:variable>
			<xsl:value-of select="normalize-space($logEntry)"/>
		</xsl:message>
	</xsl:template>
	
	
	<!--  New log error template with the HIAL logging signature -->
	<xsl:template name="bkbn-log-error" mode="HIAL1.0">
		<xsl:variable name="systemName" select="dp:variable('var://context/profile/system-name')" />		 	
		<xsl:variable name="nodeName" select="dp:variable('var://service/domain-name')"/>
		<xsl:variable name="appName" select="dp:variable('var://service/processor-name')"/>
		<xsl:variable name="svcPortName" select="dp:variable('var://context/log/service-port')"/>
		<xsl:variable name="svcPortOperation" select="dp:variable('var://context/log/service-port-operation')"/>
		<xsl:variable name="globalTxnId" select="dp:variable('var://context/log/transactionID')"/>		 	
		<xsl:variable name="sequence" select="dp:variable('var://context/log/global-sequence')"/>
		<xsl:variable name="nodeTxnId" select="dp:variable('var://service/transaction-id')"/>
		<xsl:variable name="startTime" select="dp:variable('var://context/log/start-time')"/>
		<xsl:variable name="elapsedTime" select="ehodi:get-time-elapsed()"/> <!--"dp:variable('var://service/time-elapsed')"/>-->
		<xsl:variable name="backendElapsedTime"  select="dp:variable('var://context/log/backend-time-elapsed')"/>
		<xsl:variable name="wsa-messageID" select="dp:variable('var://context/log/wsa-messageID')"/>
		<xsl:variable name="requestSize" select="dp:variable('var://service/mpgw/request-size')"/>
		<xsl:variable name="responseSize" select="dp:variable('var://service/mpgw/response-size')"/>
		<xsl:variable name="consumerSystem" select="dp:variable('var://context/log/subjectDN')"/>
		<xsl:variable name="consumerOrg" select="dp:variable('var://context/log/saml-uao')"/>
		<xsl:variable name="consumerUser" select="dp:variable('var://context/log/saml-nameid')"/>
		<xsl:variable name="consumerRole" select="dp:variable('var://context/log/saml-role')"/>		
		<xsl:variable name="sourceClientIP" select="dp:variable('var://context/log/source-client-IP')"/>
		<xsl:variable name="targetURI" select="dp:variable('var://service/routing-url')"/>
		<xsl:variable name="error" select="dp:variable('var://service/error-message')"/>

		<xsl:message dp:type="if-bkbn" dp:priority="error">
			<xsl:variable name="logEntry">
				Sys=<xsl:value-of select="$systemName"/>,
				Node=<xsl:value-of select="$nodeName"/>,
				App=<xsl:value-of select="$appName"/>,
				TxId=<xsl:value-of select="$globalTxnId"/>,
				Seq=<xsl:value-of select="$sequence"/>,		
				Srv=<xsl:value-of select="$svcPortName"/>,
				Op=<xsl:value-of select="$svcPortOperation"/>,
				NodeTid=<xsl:value-of select="$nodeTxnId"/>,
				StartTime=<xsl:value-of select="$startTime"/>,
				ElapsedTime=<xsl:value-of select="$elapsedTime"/>,
				MsgId=<xsl:value-of select="$wsa-messageID"/>,	
				MsgSizeReq=<xsl:value-of select="$requestSize"/>,
				MsgSizeRes=<xsl:value-of select="$responseSize"/>,				
				SrcSys=<xsl:value-of select="$consumerSystem"/>,
				SrcOrg=<xsl:value-of select="$consumerOrg"/>,
				SrcUser=<xsl:value-of select="$consumerUser"/>,
				SrcRole=<xsl:value-of select="$consumerRole"/>,
				SrcIP=<xsl:value-of select="$sourceClientIP"/>,
				TargetURI=<xsl:value-of select="$targetURI"/>,
				Status=FAIL,
				Error=<xsl:value-of select="$error"/>,
				BackendElapsedTime=<xsl:value-of select="ehodi:get-backend-time-elapsed()"/>			
			</xsl:variable>
			<xsl:value-of select="normalize-space($logEntry)"/>
		</xsl:message>
	</xsl:template>
	
	<xsl:template name="save-request-properties">
	
		<!--if client transaction id is present, msgid=clienttransactionid, otherwise msgid=wsa:messageID -->		
		<xsl:variable name="wsa-messageID">
			<xsl:choose>
				<xsl:when test="dp:variable('var://context/log/client-transaction-id') != ''">
					<xsl:value-of select="dp:variable('var://context/log/client-transaction-id')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="/soap:Envelope/soap:Header/wsa200403:MessageID | 
					/soap:Envelope/soap:Header/wsa200408:MessageID | 
					/soap:Envelope/soap:Header/wsa200508:MessageID |
					/soap12:Envelope/soap12:Header/wsa200403:MessageID | 
					/soap12:Envelope/soap12:Header/wsa200408:MessageID | 
					/soap12:Envelope/soap12:Header/wsa200508:MessageID"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<!--ws-addressing-->		
		<xsl:variable name="wsa-action"  select="
				/soap:Envelope/soap:Header/wsa200403:Action | 
				/soap:Envelope/soap:Header/wsa200408:Action | 
				/soap:Envelope/soap:Header/wsa200508:Action |
				/soap12:Envelope/soap12:Header/wsa200403:Action | 
				/soap12:Envelope/soap12:Header/wsa200408:Action | 
				/soap12:Envelope/soap12:Header/wsa200508:Action"/>
		<xsl:variable name="wsa-to"  select="
				/soap:Envelope/soap:Header/wsa200403:To | 
				/soap:Envelope/soap:Header/wsa200408:To | 
				/soap:Envelope/soap:Header/wsa200508:To |
				/soap12:Envelope/soap12:Header/wsa200403:To | 
				/soap12:Envelope/soap12:Header/wsa200408:To | 
				/soap12:Envelope/soap12:Header/wsa200508:To"/>
		<xsl:variable name="wsa-replyTo-endpointID"  select="
				/soap:Envelope/soap:Header/wsa200403:ReplyTo/wsa200403:ReferenceParameters/eho:endpointID | 
				/soap:Envelope/soap:Header/wsa200408:ReplyTo/wsa200408:ReferenceParameters/eho:endpointID | 
				/soap:Envelope/soap:Header/wsa200508:ReplyTo/wsa200508:ReferenceParameters/eho:endpointID |
				/soap12:Envelope/soap12:Header/wsa200403:ReplyTo/wsa200403:ReferenceParameters/eho:endpointID | 
				/soap12:Envelope/soap12:Header/wsa200408:ReplyTo/wsa200408:ReferenceParameters/eho:endpointID | 
				/soap12:Envelope/soap12:Header/wsa200508:ReplyTo/wsa200508:ReferenceParameters/eho:endpointID"/>
		
		<!--saml-->
		<xsl:variable name="saml-uao" select="
				/soap:Envelope/soap:Header/wss:Security/saml:Assertion/saml:AttributeStatement/saml:Attribute[@Name='urn:ehealth:names:idm:attribute:uao']/saml:AttributeValue |
				/soap12:Envelope/soap12:Header/wss:Security/saml:Assertion/saml:AttributeStatement/saml:Attribute[@Name='urn:ehealth:names:idm:attribute:uao']/saml:AttributeValue"/>
        
        <!-- retrieve the srcRole information, try to get it firstly from the PDP response field obligation. If not available then get it from the saml attributestatement-->
	    <xsl:variable name="samlrole" select="
				/soap:Envelope/soap:Header/wss:Security/saml:Assertion/saml:AttributeStatement/saml:Attribute[@Name='urn:ehealth:names:idm:attribute:roles']/saml:AttributeValue |
				/soap12:Envelope/soap12:Header/wss:Security/saml:Assertion/saml:AttributeStatement/saml:Attribute[@Name='urn:ehealth:names:idm:attribute:roles']/saml:AttributeValue"/>
	    <xsl:variable name="pdpRole">
	        <xsl:for-each select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='Security']/*[local-name()='Assertion']/*[local-name()='Advice']/*[local-name()='XACMLAuthzDecisionStatement']/*[local-name()='Response']/*[local-name()='Result']/*[local-name()='Obligations']/*[local-name()='Obligation' and @ObligationId='http://security.bea.com/ssmws/ssm-ws-1.0.wsdl#Roles' ]">
	            <xsl:for-each select="./*[local-name()='AttributeAssignment']">                        
	                <xsl:if test="position() > 1">
	                    <xsl:value-of select="'|'"/>
	                </xsl:if>
	                <xsl:value-of select="./text()"/>
	            </xsl:for-each>    
	        </xsl:for-each>
	    </xsl:variable>
	    <xsl:variable name="srcRole">
	        <xsl:choose>
	            <xsl:when test="string-length($pdpRole) = 0">
	                <xsl:value-of select="string($samlrole)"/>
	            </xsl:when>
	            <xsl:otherwise>
	                <xsl:value-of select="string($pdpRole)"/>
	            </xsl:otherwise>
	        </xsl:choose>	        
	    </xsl:variable>
	    <dp:set-variable name="'var://context/log/samlAttributeRole'" value="$samlrole"/>
	    <dp:set-variable name="'var://context/log/pdpObligationRole'" value="$pdpRole"/>
	    
		<xsl:variable name="saml-nameid" select="
				/soap:Envelope/soap:Header/wss:Security/saml:Assertion/saml:Subject/saml:NameID |
				/soap12:Envelope/soap12:Header/wss:Security/saml:Assertion/saml:Subject/saml:NameID"/>
		

		<xsl:variable name="uri" select="dp:variable('var://service/URI')"/>
		<xsl:variable name="bkbnProfile" select="document('bkbn-profile.xml')"/>			
		<xsl:variable name="sysName" select="$bkbnProfile/Profile/@systemName"/>

		
		
		<!--upload into DP variables-->
	    <dp:set-variable name="'var://context/log/wsa-messageID'" value="string($wsa-messageID)"/>
	    <dp:set-variable name="'var://context/log/wsa-action'" value="string($wsa-action)"/>
	    <dp:set-variable name="'var://context/log/wsa-to'" value="string($wsa-to)"/>
	    <dp:set-variable name="'var://context/log/wsa-replyTo-endpointID'" value="string($wsa-replyTo-endpointID)"/>
		<!--<dp:set-variable name="'var://context/log/sourceIP'" value="$sourceIP"/>-->
	    <dp:set-variable name="'var://context/log/saml-uao'" value="string($saml-uao)"/>
	    <dp:set-variable name="'var://context/log/saml-role'" value="string($srcRole)"/>
	    <dp:set-variable name="'var://context/log/saml-nameid'" value="string($saml-nameid)"/>
			
				
		<xsl:variable name="newTxnId">
			<xsl:choose>
				<xsl:when test="dp:http-request-header('TID') != ''">
					<xsl:value-of select = "dp:http-request-header('TID')" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select = "dp:generate-uuid()"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dp:set-variable name="'var://context/log/transactionID'" value="$newTxnId"/>					
		<dp:set-request-header name="'TID'" value="$newTxnId"/>		
		
		
		<!--source/client IP-->
		<xsl:variable name="sourceIP">
			<xsl:choose>
				<xsl:when test="dp:request-header('X-Forwarded-For') != &apos;&apos;">
					<xsl:value-of select="dp:request-header('X-Forwarded-For')"/>
				</xsl:when>
				<xsl:when test="dp:variable('var://service/transaction-client') != ''">
					<xsl:value-of select="dp:variable('var://service/transaction-client')"/>
				</xsl:when>
				<xsl:otherwise test="dp:http-request-header('SRCIP') != ''">
					<xsl:value-of select="dp:http-request-header('SRCIP')"/>
				</xsl:otherwise>				
			</xsl:choose>
		</xsl:variable>		
		<dp:set-variable name="'var://context/log/source-client-IP'" value="$sourceIP"/>					
		<dp:set-http-request-header name="'SRCIP'" value="$sourceIP"/>
		
		<!--Sending system will be srcip for non-secure services-->
		<xsl:choose>
			<xsl:when test="dp:http-request-header('SDN') != ''">
					<dp:set-variable name="'var://context/log/subjectDN'" value="dp:http-request-header('SDN')"/>				
			</xsl:when>
			<xsl:otherwise>
				<dp:set-variable name="'var://context/log/subjectDN'" value="$sourceIP"/>
			</xsl:otherwise>
		</xsl:choose>
		
		
		<xsl:variable name="svcPort" select="dp:variable('var://service/wsm/service-port')"/>
		<xsl:variable name="newSvcPort">
			<xsl:choose>
				<xsl:when test="$svcPort = 'var://service/wsm/service-port'">
					<xsl:value-of select="$uri"/>					
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$svcPort"/>
				</xsl:otherwise>				
			</xsl:choose>
		</xsl:variable>
		<dp:set-variable name="'var://context/log/service-port'" value="$newSvcPort"/>	
		
		<xsl:variable name="svcPortOperation" select="dp:variable('var://service/wsm/service-port-operation')"/>
		<xsl:variable name="newSvcPortOperation">
			<xsl:choose>
				<xsl:when test="$svcPortOperation = 'var://service/wsm/service-port-operation'">
					<xsl:variable name="soapAction" select="dp:http-request-header('SOAPAction')"/>
					<xsl:choose>
						<xsl:when test="($soapAction != '')">
							<xsl:value-of select="$soapAction"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="local-name(.//soap12:Body/*[1])"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$svcPortOperation"/>
				</xsl:otherwise>				
			</xsl:choose>
		</xsl:variable>
		<dp:set-variable name="'var://context/log/service-port-operation'" value="$newSvcPortOperation"/>
		
		<dp:set-variable name="'var://context/profile/backbone-profile'" value="$bkbnProfile"/>
		<dp:set-variable name="'var://context/profile/system-name'" value="$sysName"/>
		
		
		<dp:set-variable name="'var://context/log/global-sequence'" value="string(ehodi:get-next-global-sequence())"/>
		<dp:set-http-request-header name="'SEQ'" value="dp:variable('var://context/log/global-sequence')"/>
		<dp:set-variable name="'var://context/log/start-time-mili'" value="dp:time-value()"/>
		<dp:set-variable name="'var://context/log/start-time'" value="ehodi:format-time(dp:time-value())"/>
		<!--<dp:set-variable name="'var://context/log/elapsed-time'" value="dp:variable('var://service/time-elapsed')"/>-->
		<dp:set-variable name="'var://context/log/backend-time-elapsed'" value="ehodi:get-backend-time-elapsed()"/>
		
		
	</xsl:template>
	
	
	
	<func:function name="ehodi:get-next-global-sequence" xmlns:func="http://exslt.org/functions">
		<xsl:variable name="seq" select="dp:variable('var://context/log/global-sequence')"/>
		<xsl:variable name="newSeq">
			<xsl:choose>				
				<xsl:when test="not($seq)">				
					<xsl:choose>
						<xsl:when test="dp:http-request-header('SEQ') != ''">
							<xsl:value-of select="concat(dp:http-request-header('SEQ'), '.1')"/>							
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="1"/>
							
						</xsl:otherwise>
					</xsl:choose>				
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="contains($seq, '.' )">
							<xsl:variable name="bkbnSeq" select="ehodi:substring-after-last($seq, '.')"/>
							<xsl:value-of select="concat(ehodi:substring-before-last($seq, '.'), '.', string(number($bkbnSeq) + 1))"/>							
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="number($seq) + 1"/>							
						</xsl:otherwise>
					</xsl:choose>								
				</xsl:otherwise>	
			</xsl:choose>	
		</xsl:variable>
		
		<func:result><xsl:value-of select="$newSeq"/></func:result>
	</func:function>	
	
	
	
	<func:function name="ehodi:get-backend-time-elapsed" xmlns:func="http://exslt.org/functions">
		<xsl:variable name="backendTimeElapsed" select="dp:variable('var://service/time-response-complete')"/>
		<xsl:variable name="timeForwarded" select="dp:variable('var://service/time-forwarded')"/>
		<func:result><xsl:value-of select="number($backendTimeElapsed) - number($timeForwarded)"/></func:result>
	</func:function>
	
	
	<func:function name="ehodi:substring-after-last"  xmlns:func="http://exslt.org/functions">
		<xsl:param name="str"/>
		<xsl:param name="del"/>
				
		<xsl:choose>
			<xsl:when test="contains($str, $del)">
				<func:result>
					<xsl:value-of select="ehodi:substring-after-last(substring-after($str,$del), $del)"/>			
				</func:result>
			</xsl:when>
			<xsl:otherwise>
				<func:result>
					<xsl:value-of select="$str"/>
				</func:result>
			</xsl:otherwise>
		</xsl:choose>					
	</func:function>
	
	
	<func:function name="ehodi:substring-before-last" xmlns:func="http://exslt.org/functions">
		<xsl:param name="str"/>
		<xsl:param name="del"/>
		
		<xsl:variable name="temp" select="ehodi:substring-after-last($str, $del)"	/>
		<xsl:variable name="last" select="string-length($temp)"/>	
		<func:result><xsl:value-of select="substring($str, 1, number(string-length($str) - number($last) - 1)) "/></func:result>
	</func:function>
	
	    
	 <func:function name="ehodi:format-time" xmlns:func="http://exslt.org/functions">  
	 	<xsl:param name="time"/>	
	 	    
        <xsl:variable name="ms" select="substring($time, 11, 3)"/>
        <xsl:variable name="timeString" select="concat(date:format-date(date:date-time(), 'EEE MMM dd yyyy HH:mm:ssZ'), '.', $ms)"/>
        <func:result><xsl:value-of select="$timeString"/></func:result>
	</func:function>
	
	<func:function name="ehodi:get-time-elapsed"  xmlns:func="http://exslt.org/functions">
		<xsl:variable name="OLISElapsedTime" select="dp:variable('var://context/log/OLIS-elapsed-time')"/>
		<xsl:variable name="res">
			<xsl:choose>
				<xsl:when test= "($OLISElapsedTime) and ($OLISElapsedTime != '')">
					<xsl:value-of select="$OLISElapsedTime"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="dp:variable('var://service/time-elapsed')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dp:set-variable name="'var://context/log/OLIS-elapsed-time'" value="''"/>		
		<func:result><xsl:value-of select="$res"/></func:result>
	</func:function>
</xsl:stylesheet>