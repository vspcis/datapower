<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>CommonPEP.xsl</Filename>
<revisionlog>v1.0.0</revisionlog>
<Description>
  This is the common PEP logic
</Description>
<Owner>eHealthOntario</Owner>
<LastUpdate>Setp 29, 2015</LastUpdate>
<Copyright>
**************************************************************
  Copyright (c) ehealthOntario, 2015
**************************************************************
</Copyright>
</CodeHeader>
-->

<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:date="http://exslt.org/dates-and-times" 
    xmlns:dp="http://www.datapower.com/extensions" 
    xmlns:dpwsm="http://www.datapower.com/schemas/transactions" 
    xmlns:dpconfig="http://www.datapower.com/param/config" 
    xmlns:hiallib="http://www.ehealthontario.on.ca/hial/lib"
    exclude-result-prefixes="xsl dp date dpwsm dpconfig hiallib"
    extension-element-prefixes="dp" 
    version="1.0">
    
    <xsl:include href="local:Framework/Lib/Log4GateWay.xsl" />
    <xsl:import href="ContxtDataUtil.xsl"/>

    <xsl:param name="dpconfig:PEPName"/>
    <xsl:variable name="PEP" select="$dpconfig:PEPName"/>

    <xsl:variable name="wsPolicyPath" select="document('Config/Config.xml')/Config/CachePath/text()"/>   

    <xsl:template match="/">

 
        <!-- 
            load context and sla here in case transaction failed before the first transform action, such as schema validation failure
            this can only happened at error case
         -->  
        <xsl:variable name="currentFlow" select="dp:variable('var://service/transaction-rule-type')"/>
        <xsl:if test="( $currentFlow = 'error') and ( not (dp:variable('var://context/hialPEP/txnContext')))">
            <xsl:variable name="initContext">
                <xsl:call-template name="loadInitContext"/>
            </xsl:variable>
            <dp:set-variable name="'var://context/hialPEP/txnContext'" value="$initContext"/>
            <dp:set-variable name="'var://context/logging/seq'" value="'1'"/>
            
            <!-- the following template will load the SLA policy into dp variable -->
            <xsl:call-template name="loadSLAContext"/>
        </xsl:if>

        <!-- load all sla policies from context and the the tatal number of pep policy --> 
        <xsl:variable name="cnPolicy"      select="dp:variable('var://context/hialPEP/cnPolicy')"/>
        <xsl:variable name="groupPolicy"   select="dp:variable('var://context/hialPEP/groupPolicy')"/>
        <xsl:variable name="defaultPolicy" select="dp:variable('var://context/hialPEP/defaultPolicy')"/>
        <xsl:variable name="countOfCNPepPolicy"      select="count($cnPolicy/SLA/Policy/PolicyName[contains(text(), $PEP)])"/> 
        <xsl:variable name="countOfGroupPepPolicy"   select="count($groupPolicy/SLA/Policy/PolicyName[contains(text(), $PEP)])"/> 
        <xsl:variable name="countOfDefaultPepPolicy" select="count($defaultPolicy/SLA/Policy/PolicyName[contains(text(), $PEP)])"/> 
        <xsl:variable name="totalCountOfPepPolicy" select="$countOfCNPepPolicy + $countOfGroupPepPolicy + $countOfDefaultPepPolicy"/>

        <xsl:call-template name="captureExecutedPep">
            <xsl:with-param name="pepValue" select="$PEP"/>
        </xsl:call-template>

        <xsl:choose>
            <xsl:when test="($countOfCNPepPolicy &gt; 1) or ($countOfGroupPepPolicy &gt; 1) or ($countOfDefaultPepPolicy &gt; 1) ">
                <xsl:call-template name="logAndReject">
                    <xsl:with-param name="errorMsg" select="concat('SLA contains multiple policies for PEP ', $PEP )"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$totalCountOfPepPolicy = 0">
                <xsl:call-template name="logAndReject">
                    <xsl:with-param name="errorMsg" select="concat('policy is not available for PEP ', $PEP )"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="executePEP"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>


    <!-- This template will execute the PEP-->
    <xsl:template name="executePEP">
        
        <xsl:variable name="cnPolicy"      select="dp:variable('var://context/hialPEP/cnPolicy')"/>
        <xsl:variable name="groupPolicy"   select="dp:variable('var://context/hialPEP/groupPolicy')"/>
        <xsl:variable name="defaultPolicy" select="dp:variable('var://context/hialPEP/defaultPolicy')"/>
        
        <xsl:variable name="policyName">
            <xsl:choose>
                <xsl:when test="$cnPolicy/SLA/Policy/PolicyName[contains(text(), $PEP)]">
                    <xsl:value-of select="$cnPolicy/SLA/Policy/PolicyName[contains(text(), $PEP)]/text()"/>
                </xsl:when>
                <xsl:when test="$groupPolicy/SLA/Policy/PolicyName[contains(text(), $PEP)]">
                    <xsl:value-of select="$groupPolicy/SLA/Policy/PolicyName[contains(text(), $PEP)]/text()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$defaultPolicy/SLA/Policy/PolicyName[contains(text(), $PEP)]/text()"/>
                </xsl:otherwise>
            </xsl:choose>            
        </xsl:variable>        
        
        <xsl:variable name="policyFile" select="concat($wsPolicyPath, $policyName, '.xml')"/>
        <xsl:variable name="wsPolicy" select="document($policyFile)"/>        
        
        <xsl:choose>
            <xsl:when test="$wsPolicy/*">
                
                <xsl:call-template name="captureExecutedPolicy">
                    <xsl:with-param name="policyName" select="$policyName"/>
                </xsl:call-template>

                <xsl:variable name="enforceFlag" select="$wsPolicy//*[local-name()='ExecuteXSL']/*[local-name()='Parameter' and  contains(@Name, 'Enforce')]/@Value"/>
                
                <xsl:choose>
                    <xsl:when test="starts-with($PEP, 'AAA')">
                        
                        <xsl:variable name="aaaPolicyName" select="$wsPolicy//*[local-name()='Parameter' and @Name='AAA_Policy_Pattern']/@Value"/>
                        <xsl:if test="string-length($aaaPolicyName) = 0">
                            <xsl:call-template name="logAndReject">
                                <xsl:with-param name="errorMsg" select="concat('AAA policy does not contains the policy value in file: ', $policyFile )"/>
                            </xsl:call-template>                            
                        </xsl:if>
                        
                        <AAAType>
                            <Action>
                                <xsl:attribute name="name">
                                    <xsl:value-of select="$aaaPolicyName"/>
                                </xsl:attribute>
                            </Action>
                        </AAAType>
                    </xsl:when>
                    <xsl:otherwise>
                        
                        <xsl:variable name="xslFile"     select="$wsPolicy//*[local-name()='ExecuteXSL']/*[local-name()='Stylesheet']/text()"/>
                        <dp:set-variable name="'var://context/hialPEP/TransformAction'" value="string($xslFile)"/>
                        
                        <!-- retrieve the enforce flag -->
                        <xsl:choose>
                            <xsl:when test="$enforceFlag = 'true'">
                                <dp:set-variable name="'var://context/hialPEP/pepEnforcedFlag'" value="'true'"/>                                                                
                            </xsl:when>
                            <xsl:otherwise>
                                <dp:set-variable name="'var://context/hialPEP/pepEnforcedFlag'" value="'false'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        
                        <!-- retrieve the transient data map -->
                        <xsl:variable name="transientDataMap" select="$wsPolicy//*[local-name()='ExecuteXSL']/*[local-name()='Parameter' and  @Name='TransientDataMap']/@Value"/>
                        <xsl:choose>
                            <xsl:when test="string-length($transientDataMap) = 0">
                                <dp:set-variable name="'var://context/hialPEP/transientDataMap'" value="''"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="transientDataMapFile" select="concat($wsPolicyPath, $transientDataMap, '.xml')"/>
                                <dp:set-variable name="'var://context/hialPEP/transientDataMap'" value="$transientDataMapFile"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        
                    </xsl:otherwise>
                </xsl:choose>
                
                <xsl:call-template name="logPEPEvent">
                    <xsl:with-param name="logLevel" select="'info'"/>
                    <xsl:with-param name="logContent" select="concat('performed policy enforcement for PEP [', $PEP, '] with optional enforceFlag value ', $enforceFlag)"/>
                </xsl:call-template>                
                
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="logAndReject">
                    <xsl:with-param name="errorMsg" select="concat('WS Mediation Policy file is not found in the cache, file name is: ', $policyFile )"/>
                </xsl:call-template>          
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    
    <xsl:template name="logAndReject">
        <xsl:param name="errorMsg"/>    
        <xsl:call-template name="logPEPEvent">
            <xsl:with-param name="logLevel" select="'error'"/>
            <xsl:with-param name="errorCode" select="'0x00'"/>
            <xsl:with-param name="logContent" select="$errorMsg"/>
        </xsl:call-template>
        <dp:reject>
            <xsl:value-of select="$errorMsg"/>
        </dp:reject>
    </xsl:template>
   
    
    <!-- simplified logging method -->
    <xsl:template name="logPEPEvent">
        <xsl:param name="logLevel"/>
        <xsl:param name="errorCode"/>
        <xsl:param name="logContent"/> 
        
        <xsl:variable name="txnContext" select="dp:variable('var://context/hialPEP/txnContext')"/>
        <xsl:variable name="txnID" select="$txnContext/txnContext/globalID/text()"/>        
        
        <xsl:call-template name="hiallib:logEvent">
            <xsl:with-param name="logLevel" select="$logLevel"/>
            <xsl:with-param name="errorCode" select="$errorCode"/>
            <xsl:with-param name="facility" select="'TRN'"/>
            <xsl:with-param name="logGroup" select="'PCY'"/>
            <xsl:with-param name="activity" select="'GIN'"/>
            <xsl:with-param name="transactionId" select="$txnContext/txnContext/globalID/text()"/>
            <xsl:with-param name="logContent" select="$logContent"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- This template log all the pep node name on the running flow -->
    <xsl:template name="captureExecutedPep">
        <xsl:param name="pepValue"/>
        <xsl:variable name="processedPep" select="dp:variable('var://context/logging/ExecutedPeps')"/>
        <xsl:variable name="pepItems" select="concat($processedPep, ';', $pepValue)"/>
        <dp:set-variable name="'var://context/logging/ExecutedPeps'" value="string($pepItems)"/>
    </xsl:template>
    
    <!-- -->
    <xsl:template name="captureExecutedPolicy">
        <xsl:param name="policyName"/>
        
        <xsl:variable name="savedExecutedPolicies" select="dp:variable('var://context/logging/ExecutedPolicies')"/>
        <xsl:variable name="executedPolicies" select="concat($savedExecutedPolicies,';',$policyName)"/>
        
        <dp:set-variable name="'var://context/logging/ExecutedPolicies'" value="string($executedPolicies)"/>
    </xsl:template>

</xsl:stylesheet>
