<?xml version="1.0" encoding="UTF-8"?>
<!--
<CodeHeader>
<Filename>MessageDispatcher.xsl</Filename>
<revisionlog>Initial Version</revisionlog>
<Description>

Recieves input Front Side Handler and dispatches message to appropriate handling points.
Understands Trigger and WSRR notifications

</Description>
<Owner>eHealthOntario</Owner>
<Copyright>
**************************************************************
  Copyright (c) ehealthOntario, 2015

  This unpublished material is proprietary to ehealthOntario.
  All rights reserved. Reproduction or distribution, in whole 
  or in part, is forbidden except by express written permission 
  of ehealthOntario.
**************************************************************
</Copyright>
</CodeHeader>

-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:dpcp="http://ehealthontario.on.ca/datapower/cache/proxy"
   xmlns:dp="http://www.datapower.com/extensions" 
   xmlns:body="http://www.ibm.com/xmlns/prod/serviceregistry/HttpPostNotifierPluginMsgBody"
   xmlns:wsrradapter="http://ehealthontario.on.ca/wsrrnotificationadapter"
   
   extension-element-prefixes="dp"
   
   exclude-result-prefixes="xsl dp dpcp body" version="1.0">


   <xsl:import href="PolicyService.xsl"/>
   <xsl:import href="GroupIDRetrievalService.xsl"/>
   <xsl:import href="FMBLRetrievalService.xsl"/>
   <xsl:import href="SLAService.xsl"/>
   <xsl:import href="WSDLPolicyService.xsl"/>
   <xsl:import href="PolicyAttachmentEventAdapter.xsl"/>
   <xsl:import href="LoggingUtility.xsl"/>
   <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

   <!-- ********* Module External Templates ******************************************** -->

   <!-- Dispatches all Trigger messages to appropriate handler
        Implements: Flow 10
   -->
   <xsl:template match="/Trigger">
      <xsl:call-template name="updateAllSLACache2"/>
      <!-- update all policies -->
      <xsl:call-template name="updateAllPolicyCache"/>
      <!-- update all Group ID -->
      <xsl:call-template name="updateAllGroupCache"/>
      <!-- update all transient -->
      <xsl:call-template name="updateAllFMBLCache"/>
      <!-- Update WSDL and Policy Map -->
      <xsl:call-template name="updateAllWSDLMaps"/>
      <xsl:variable name="errors">
         <xsl:call-template name="checkForErrorsAndLog"/>
      </xsl:variable>
      <xsl:choose>
         <xsl:when test="count($errors/operationalstatus/errormessage) = 0">
       
            <dp:set-variable name="'var://system/RAID/status'" value="true()"/>
            <!-- remove this false() this was for testing, it's supposed to be true() -->
            <xsl:call-template name="doLog">
               <xsl:with-param name="Level" select="'INFO'"/>
               <xsl:with-param name="ErrorCode" select="'OK'"/>
               <xsl:with-param name="Message" select="'FULL SLA Update Successful'"/>
            </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
            <dp:set-variable name="'var://system/RAID/status'" value="false()"/>
            <xsl:call-template name="doLog">
               <xsl:with-param name="Level" select="'ERROR'"/>
               <xsl:with-param name="ErrorCode" select="'TBD'"/>
               <xsl:with-param name="Message" select="'FULL SLA Update Failed'"/>
            </xsl:call-template>
            <dp:reject/>
         </xsl:otherwise>
      </xsl:choose>


   </xsl:template>


   <!-- Matches on SLASubscription notifications based on correlationId 
        Implements: Flows 21, 31, 40 and 50
   -->
   <xsl:template match="/body:resources/body:resource[@correlationId = 'SLASubscription']">

      <!-- this is only called on attach, detach, activate -->
      <xsl:variable name="filelist">
         <FileList>
            <xsl:for-each
               select="./body:notificationResource[@event='ATTACH' or @event='DETACH' or (@event='TRANSITION' and @transition='http://www.ibm.com/xmlns/prod/serviceregistry/lifecycle/v6r3/LifecycleDefinition#ActivateSLA')]">
               <xsl:call-template name="updateSLACache2">
                  <xsl:with-param name="id" select="@subscribedBsrUri"/>
                  <xsl:with-param name="filename" select="@subscribedName"/>
               </xsl:call-template>

            </xsl:for-each>

            <xsl:for-each
               select="./body:notificationResource[@event='TRANSITION' and @transition='http://www.ibm.com/xmlns/prod/serviceregistry/lifecycle/v6r3/LifecycleDefinition#DeactivateSLA']">
               <xsl:call-template name="deleteResource">
                  <xsl:with-param name="filename" select="@subscribedName"/>
                  <xsl:with-param name="id" select="@subscribedBsrUri"/>
                  <xsl:with-param name="resourceType" select="'SLAAttachment'"/>
                  <xsl:with-param name="returnedResource" select="."/>
               </xsl:call-template>
            </xsl:for-each>
         </FileList>
      </xsl:variable>


      <xsl:if test="count($filelist/FileList/File) &gt; 0">
         <xsl:call-template name="refreshfiles">
            <xsl:with-param name="opname" select="'SLASubscription-notification'"/>
            <xsl:with-param name="filelist" select="$filelist"/>
         </xsl:call-template>
      </xsl:if>


      <xsl:call-template name="EmitSummaryLog">
         <xsl:with-param name="Operation" select="'SLASubscription Processing'"/>
      </xsl:call-template>

   </xsl:template>


   <!-- Matches on PolicySubscription notifications based on correlationId 
        Implements: Flows 80
   -->
   <xsl:template match="/body:resources/body:resource[@correlationId = 'PolicySubscription']">
      <xsl:variable name="filelist">
         <FileList>
            <xsl:for-each
               select="./body:notificationResource[@event='TRANSITION' and @transition='http://www.ibm.com/xmlns/prod/serviceregistry/lifecycle/v6r3/LifecycleDefinition#ApproveSpecification']">
               <xsl:call-template name="updatePolicyCache">
                  <xsl:with-param name="id" select="@subscribedBsrUri"/>
                  <xsl:with-param name="filename" select="@subscribedName"/>
               </xsl:call-template>
            </xsl:for-each>
         </FileList>
      </xsl:variable>


      <xsl:if test="count($filelist/FileList/File) &gt; 0">
         <xsl:call-template name="refreshfiles">
            <xsl:with-param name="opname" select="'PolicySubscription-notification'"/>
            <xsl:with-param name="filelist" select="$filelist"/>
         </xsl:call-template>
      </xsl:if>



      <xsl:call-template name="EmitSummaryLog">
         <xsl:with-param name="Operation" select="'PolicySubscription Processing'"/>
      </xsl:call-template>
   </xsl:template>

   <!-- Matches on GroupIDSubscription notifications based on correlationId 
        Implements: Flow 100
   -->
   <xsl:template match="/body:resources/body:resource[@correlationId = 'GroupIDSubscription']">
      <xsl:variable name="filelist">
         <FileList>
            <xsl:for-each
               select="./body:notificationResource[@event='TRANSITION' and @transition='http://www.ibm.com/xmlns/prod/serviceregistry/lifecycle/v6r3/LifecycleDefinition#ApproveXMLSpecification']">
               <xsl:call-template name="updateGroupCache">
                  <xsl:with-param name="id" select="@subscribedBsrUri"/>
                  <xsl:with-param name="filename" select="GroupIDRefData.xml"/>
               </xsl:call-template>
            </xsl:for-each>
         </FileList>
      </xsl:variable>

      <xsl:if test="count($filelist/FileList/File) &gt; 0">
         <xsl:call-template name="refreshfiles">
            <xsl:with-param name="opname" select="'GroupIDSubscription-notification'"/>
            <xsl:with-param name="filelist" select="$filelist"/>
         </xsl:call-template>
      </xsl:if>


      <xsl:call-template name="EmitSummaryLog">
         <xsl:with-param name="Operation" select="'GroupIDSubscription Processing'"/>
      </xsl:call-template>
   </xsl:template>

   <!-- Matches on FMBLSubscription notifications based on correlationId 
        Implements: Flow 110
   -->
   <xsl:template match="/body:resources/body:resource[@correlationId = 'TDMapSubscription']">

      <xsl:variable name="filelist">
         <FileList>
            <xsl:for-each
               select="./body:notificationResource[@event='TRANSITION' and @transition='http://www.ibm.com/xmlns/prod/serviceregistry/lifecycle/v6r3/LifecycleDefinition#ApproveXMLSpecification']">
               <xsl:call-template name="updateFMBLCache">
                  <xsl:with-param name="id" select="@subscribedBsrUri"/>
                  <xsl:with-param name="filename" select="@subscribedName"/>
               </xsl:call-template>
            </xsl:for-each>
         </FileList>
      </xsl:variable>

      <xsl:if test="count($filelist/FileList/File) &gt; 0">
         <xsl:call-template name="refreshfiles">
            <xsl:with-param name="opname" select="'TDMapSubscription-notification'"/>
            <xsl:with-param name="filelist" select="$filelist"/>
         </xsl:call-template>
      </xsl:if>

      <xsl:call-template name="EmitSummaryLog">
         <xsl:with-param name="Operation" select="'FMBLSubscription Processing'"/>
      </xsl:call-template>
   </xsl:template>
   
   <!-- Matches on PolicyAttachment notifications based on correlationId
      Implement: Flow 120 -special logic here, the initial PolicyAttachment notification
      gets converted into another PolicyAttachment prim
      -->
   <xsl:template match="/body:resources/body:resource[@correlationId= 'PolicyAttachmentSubscription']">
      <xsl:variable name="newEvent">
         <xsl:call-template name="convertToWSDLEvent">
            <xsl:with-param name="event" select="/"/>
         </xsl:call-template>
      </xsl:variable>
      <dp:set-variable name="'var://context/log/adapterEVENT'" value="$newEvent"/>
      <!-- apply templates into this dispatcher -->
      
      <xsl:apply-templates select="$newEvent"/>
   </xsl:template>
   
   <!-- Matches on PolicyAttachment notifications based on adapter namespace
      Implements: Flow 120 -special logic here, the initial PolicyAttachment notification
      gets converted into another PolicyAttachment prim
      -->
   <xsl:template match="/wsrradapter:resources/wsrradapter:resource">
      <!-- now delegate to the usual handler -->
      <xsl:variable name="filelist">
         <FileList>
            <xsl:for-each
               select="./wsrradapter:notificationResource">
               <xsl:call-template name="updateWSDLCache">
                  <xsl:with-param name="id" select="@subscribedBsrUri"/>
                  <xsl:with-param name="filename" select="@subscribedName"/>
               </xsl:call-template>
            </xsl:for-each>
         </FileList>
      </xsl:variable>
      
      <xsl:if test="count($filelist/FileList/File) &gt; 0">
         <xsl:call-template name="refreshfiles">
            <xsl:with-param name="opname" select="'PolicyAttachmentSubscription-notification'"/>
            <xsl:with-param name="filelist" select="$filelist"/>
         </xsl:call-template>
      </xsl:if>
      
      <xsl:call-template name="EmitSummaryLog">
         <xsl:with-param name="Operation" select="'WSDLPolicyAttachment Processing'"/>
      </xsl:call-template>
   </xsl:template>

   <!-- ********** Module Internal Templates *********************************************** -->


   <xsl:template name="EmitSummaryLog">
      <xsl:param name="Operation"/>

      <xsl:variable name="errors">
         <xsl:call-template name="checkForErrorsAndLog"/>
      </xsl:variable>
      <xsl:choose>
         <xsl:when test="count($errors/operationalstatus/errormessage) = 0">

            <xsl:call-template name="doLog">
               <xsl:with-param name="Level" select="'INFO'"/>
               <xsl:with-param name="ErrorCode" select="'OK'"/>
               <xsl:with-param name="Message" select="concat($Operation,' Successful')"/>
            </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>

            <xsl:call-template name="doLog">
               <xsl:with-param name="Level" select="'ERROR'"/>
               <xsl:with-param name="ErrorCode" select="'TBD'"/>
               <xsl:with-param name="Message" select="concat($Operation,' Failed')"/>
            </xsl:call-template>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>


   <xsl:template name="refreshfiles">
      <xsl:param name="opname"/>
      <xsl:param name="filelist"/>

      <xsl:variable name="results">
         <xsl:call-template name="dpcp:refreshFiles">
            <xsl:with-param name="filelist" select="$filelist"/>
         </xsl:call-template>
      </xsl:variable>
      <xsl:if test="count($results/Error) &gt; 0">

         <xsl:call-template name="AddErrorMessage">
            <xsl:with-param name="OperationName" select="$opname"/>
            <xsl:with-param name="Message"
               select="concat('Could not refresh files in cache ', dp:serialize($filelist))"/>
         </xsl:call-template>
         <dp:reject/>
      </xsl:if>
   </xsl:template>
</xsl:stylesheet>
