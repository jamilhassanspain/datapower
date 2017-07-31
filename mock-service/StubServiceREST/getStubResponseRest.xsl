<!-- 
	@author: Ozair Sheikh
	@version: 1.0
	@description: Using the incoming operation extracted from the URI, a lookup is performed in an XML file specified by the stylesheet parameter: responseStubDB.
	If the operation exists, information about how to extract the data objects is obtained using any lookup parameters. Another lookup is done in an XML file
	using any additional parameters. If a security token is specified in the token, then the result set is further filtered. The final data returned is an XML
	result set with a pre-configured latency.
	
	@note
	The supported service URI is of the following format:
	1. /getResource
	2. /getResource/Id
	Currently, there is no support for JSON or XML based input, only GET operations are supported	 
 -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:wst="http://docs.oasis-open.org/ws-sx/ws-trust/200512/"
	xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp"
	xmlns:dpconfig="http://www.datapower.com/param/config" 
	xmlns:dyn="http://exslt.org/dynamic"  xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns:func="http://exslt.org/functions" xmlns:stub="urn:stub" xmlns:str="http://exslt.org/strings"
	exclude-result-prefixes="dp func dpconfig dyn regexp str" version="1.0">
	
	<!-- file containing list of operations and how to extract data for each operation -->
	<xsl:param name="dpconfig:responseStubDB" />
	<dp:param name="dpconfig:responseStubDB" required="true">
		<display>Response Stub XML lookup table</display>
		<description>Enter the name of the Response Stub XML filename table</description>
		<default>responseStubDB.xml</default>
	</dp:param>
	
	<!-- security token if filtering by authenticated session is required
         Note: If this header is not passed than all elements are returned. This behaviour can be modified by checking this value and rejecting the execution.
        -->
	<xsl:param name="dpconfig:headerName" />
	<dp:param name="dpconfig:headerName" required="true">
		<display>HTTP Header name of security token</display>
		<description>Enter the name of the HTTP Header security token.</description>
		<default>userId</default>
	</dp:param>
	
	<!-- save stylesheet params in a variable -->
	<xsl:variable name="responseStubDB" select="document($dpconfig:responseStubDB)" />
	<xsl:variable name="securityToken" select="dp:http-request-header($dpconfig:headerName)"/>
	
	<!-- obtain service URI to parse -->
	<xsl:variable name="serviceURI" select="dp:variable('var://service/URI')" />
	
	<!-- main template -->   
	<xsl:template match="/">		 
	
		<xsl:message dp:priority="info">
			<xsl:value-of select="concat('security token:', $securityToken)" />
		</xsl:message>
		
		<!-- variable used to check if multiple operations are defined - only first one is returned -->
		<dp:set-local-variable name="'var://local/StubService/operation-found'" value="'f'" />
				
		
		<!--  -->
		<xsl:variable name="tokenized" select="str:tokenize(concat($serviceURI, '/'),'/')"/>
		
		<!-- extract parameters assuming convention: /openInsurance/OI_Vehicle/{id} -->
		<xsl:variable name="context-root" select="$tokenized[1]"/>
		<xsl:variable name="operation-name" select="$tokenized[2]"/>
		<xsl:variable name="operation-param" select="substring-after($serviceURI, concat($operation-name, '/'))"/>

		<!-- check if any operation parameters were passed and build xpath expression -->
		<xsl:variable name="xpath-param-value">
			<xsl:choose>
				<xsl:when test="string-length($operation-param) = 0">
					<xsl:value-of select="'.*'"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat('^', $operation-param, '$')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:message dp:priority="information">
			<xsl:value-of select="concat('context root:', $context-root)" />
		</xsl:message>
		
		<xsl:message dp:priority="information">
			<xsl:value-of select="concat('operation name:', $operation-name)" />
		</xsl:message>
		
		<xsl:message dp:priority="information">
			<xsl:value-of select="concat('operation param:', $operation-param)" />
		</xsl:message>
		
		<xsl:message dp:priority="information">
			<xsl:value-of select="concat('xpath-param-value:', $xpath-param-value)" />
		</xsl:message>
		
		<!-- try finding the exact operations -->
		<xsl:variable name="operation-set">
				<xsl:for-each select="$responseStubDB/services/service/operation">
					<xsl:variable name="cur-operation" select="./name/text()" />
					
					<!-- information for invoking call remotely -->
					<xsl:variable name="remote" select="@remote" />
					<xsl:variable name="remote-name" select="@name" />
					<xsl:variable name="url" select="@url" />
					
					<!-- if operation found, return the operation tag -->
					<xsl:if test="$cur-operation = $operation-name and string(dp:local-variable('var://local/StubService/operation-found')) = 'f'">
						<xsl:copy-of select="." />
						
						<xsl:message dp:priority="information">
							<xsl:value-of select="concat('Remote info name ', $remote, ' and url ',  $url)" />
						</xsl:message>
						
						<!-- create url element if remote is true -->
						<xsl:if test="$remote = 'true'">
							<xsl:element name="remote">
								<xsl:element name="name"><xsl:value-of select="$remote-name" /></xsl:element>
								<xsl:element name="url"><xsl:value-of select="$url" /></xsl:element>
							</xsl:element>
							<xsl:message dp:priority="information">
								<xsl:value-of select="concat('Found remote info with name ', $remote-name, ' and url ',  $url)" />
							</xsl:message>
							
						</xsl:if>
										
						 <dp:set-local-variable name="'var://local/StubService/operation-found'" value="'t'" />		
						 
						 <xsl:message dp:priority="information">
							<xsl:value-of select="concat('found operation:', $operation-name)" />
						</xsl:message>
					</xsl:if>
				</xsl:for-each>
		</xsl:variable>
		
		<!-- read the information for the found operation -->
		<xsl:variable name="xpath-str"  select="$operation-set/operation/xpath" />
		<xsl:variable name="xpath-param-str"  select="$operation-set/operation/xpath-param" />
		<xsl:variable name="filename-str"  select="$operation-set/operation/filename" />
		<xsl:variable name="latency-str"  select="$operation-set/operation/latency" />
		<xsl:variable name="remote-url-name"  select="$operation-set/remote/name" />
		<xsl:variable name="remote-url"  select="$operation-set/remote/url" />
		
		<xsl:message dp:priority="information">
			<xsl:value-of select="concat('XPath:', $xpath-str)" />
		</xsl:message>
		<xsl:message dp:priority="information">
			<xsl:value-of select="concat('XPath parameter:', $xpath-param-str)" />
		</xsl:message>
		<xsl:message dp:priority="information">
			<xsl:value-of select="concat('Filename:', $filename-str)" />
		</xsl:message>
		<xsl:message dp:priority="information">
			<xsl:value-of select="concat('Latency:', $latency-str)" />
		</xsl:message>			
				
		<!-- check if file is found as specified in the XML message -->
		<xsl:choose>	
			<xsl:when test="string-length($remote-url) > 0">
				<!-- 
				<xsl:value-of select="concat('{', $operation-name, 'Rs')"/>
				<xsl:value-of select="{$remote-url-name}"/>
				 -->
				<xsl:variable name="BinaryResp">
					<dp:url-open target="{$remote-url}" response="binaryNode" />
				</xsl:variable>
				<xsl:value-of select="dp:decode(dp:binary-encode($BinaryResp/result/binary/node()),'base-64')" />
				
				<xsl:message dp:priority="information">
					<xsl:value-of select="concat('Calling remote url ', $remote-url)" />
				</xsl:message>
				
			</xsl:when>
			<xsl:when test="string-length($filename-str) > 0">
				<xsl:variable name="database" select="document($filename-str)" />
				<!-- <xsl:variable name="xpath" select="document($filename-str)" /> -->
				
				<xsl:element name="{concat($operation-name, 'Rs')}">
					<!-- set the current context to apply the dyn:evaluate -->
					<xsl:variable name="payload">
						<xsl:for-each select="$database/*[$xpath-str]/*">					
							
							<xsl:message dp:priority="information">
								<xsl:value-of select="concat('current node:', .)" />
							</xsl:message>
										
							<!-- get the parameter value of the current node -->
							<xsl:variable name="param" select="dyn:evaluate($xpath-param-str)" />
							
							<xsl:message dp:priority="information">
								<xsl:value-of select="concat('param:', $param)" />
							</xsl:message>
							<xsl:message dp:priority="information">
								<xsl:value-of select="concat('xpath-param-value:', $xpath-param-value)" />
							</xsl:message>
							
							<!-- match the paramater passed in against the specified xpath -->
							<xsl:if test="regexp:match($param, $xpath-param-value)">
								<xsl:copy-of select="." />
							</xsl:if>
						</xsl:for-each>
					</xsl:variable>
				
					<!-- check if any data returned -->
					<xsl:choose>
						<xsl:when test="count($payload/*) = 0">
							<xsl:element name="fault">
								<xsl:value-of select="concat('Error: Unable to find information for parameter ', $operation-param)" />
							</xsl:element>
						</xsl:when>
						<!-- data is returned, but we will filter again based on security token  -->
						<xsl:when test="string-length($securityToken) > 0">
							
							<!-- check each returned element for the  -->
							<xsl:for-each select="$payload/*">
								
								<xsl:variable name="securityTokenFromFile" select="*[local-name() =string($dpconfig:headerName)]" />
								<xsl:message dp:priority="info">
									<xsl:value-of select="concat('securityTokenFromFile:', $securityTokenFromFile)" />
								</xsl:message>
								<!-- check if securitytoken matches -->
								<xsl:if test="$securityToken = $securityTokenFromFile">
									<xsl:copy-of select="." />
								</xsl:if>
							</xsl:for-each>
						</xsl:when>
						<!-- output the payload without any filter -->
						<xsl:otherwise>
							<xsl:copy-of select="$payload" />
						</xsl:otherwise>
					</xsl:choose>
				</xsl:element>
				
				<!-- inject latency into the request if required -->
				<xsl:variable name="URL" select="'http://2.3.4.5'"/>
				<xsl:variable name="latency" select="$latency-str"/>
    			
    			<!-- if the latency value is greater than 0, inject latency into the request -->
    			<xsl:if test="number($latency) > 0">
    				<dp:url-open target="{$URL}" response="ignore" timeout="{number($latency)}" />
    				
    				<xsl:message dp:priority="information">
						<xsl:value-of select="concat('Injecting latency of ', $latency, ' seconds.')" />
					</xsl:message>
    			</xsl:if>

<!-- return X-IBM headers in the response-->
    			<dp:set-response-header name="'X-IBM-User'" value="dp:http-request-header('X-IBM-User')"/>
    			<dp:set-response-header name="'X-IBM-Scope'" value="dp:http-request-header('X-IBM-Scope')"/>
    			<dp:set-response-header name="'X-IBM-Custom-Attributes'" value="dp:http-request-header('X-IBM-Custom-Attributes')"/>
    			
			</xsl:when>
			<xsl:otherwise>
				<dp:reject>
					<xsl:value-of select="concat('Response file not found for operation ', $operation-name)" />
				</dp:reject>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
</xsl:stylesheet>