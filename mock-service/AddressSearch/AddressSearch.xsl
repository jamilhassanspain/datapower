<?xml version="1.0" encoding="UTF-8"?>
<!-- 
	================================================================================
	file:			AddressSearch.xsl
	author:			Ozair Sheikh
	created:		2008 May 21
	
	description:	This stylesheet simluates a set of Web services. It will lookup address
	information from an XML file based on the input message. When no address information is
	available, a SOAP fault will be returned.
	
	external ref:	'local:///eastAddressDB.xml'
					'local:///westAddressDB.xml'
	
	includes:	N/A
	
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0" xmlns:xalan="http://xml.apache.org/xslt"
	xmlns:dp="http://www.datapower.com/extensions"
	extension-element-prefixes="dp"
	xmlns:dpconfig="http://www.datapower.com/param/config">

	<xsl:output indent="yes" method="xml" />

	<!-- This parameter determines the database to search (east or west) -->
	<xsl:param name="dpconfig:AddressType" select="'BY_PARAM'" />

	<!-- Build the name of the database file to search -->
	<xsl:variable name="AddressDBFile"
		select="concat($dpconfig:AddressType,'AddressDB.xml')" />
	<xsl:variable name="AddressDB" select="document($AddressDBFile)" />

	<!-- Build the name of the Address name space -->
	<xsl:variable name="AddressNSValue"
		select="concat('http://',$dpconfig:AddressType,'.address.training.ibm.com')" />
	<xsl:variable name="AddressNS" select="$AddressNSValue" />

	<!-- Invoke the template based on the request message -->
	<xsl:template match="/">
		<!-- Child tag of SOAP body is the operation name -->
		<xsl:variable name="opName"
			select="*[local-name()='Envelope']/*[local-name()='Body']/*" />

		<!-- Call the template for the respective operation -->
		<xsl:choose>
			<xsl:when test="local-name($opName)='findByLocation'">

				<xsl:call-template name="findByLocation">
					<xsl:with-param name="operation" select="$opName" />
				</xsl:call-template>
			</xsl:when>

			<xsl:when test="local-name($opName)='findByName'">

				<xsl:call-template name="findByName">
					<xsl:with-param name="operation" select="$opName" />
				</xsl:call-template>

			</xsl:when>

			<xsl:when test="local-name($opName)='retrieveAll'">

				<xsl:call-template name="retrieveAll">
					<xsl:with-param name="operation" select="$opName" />
				</xsl:call-template>
			</xsl:when>
		</xsl:choose>

		<!-- Flag to skip backend processing -->
		<dp:set-variable name="'var://service/mpgw/skip-backside'"	value="'1'" />
	</xsl:template>

	<!-- Search for address information based on either state, city or both -->
	<xsl:template name="findByLocation">
		<xsl:param name="operation" />
		
		<xsl:variable name="state" select="$operation/state" />
		<xsl:variable name="city" select="$operation/city" />

		<xsl:variable name="findByLocationResults">
			<xsl:choose>
				<!-- Search for address information based on state if city is blank -->
				<xsl:when test="$city = ''">
					<xsl:copy-of
						select="$AddressDB/AddressList/Address[contains(./details/state/text(),$state)]" />
				</xsl:when>
				<!-- Search for address information based on state if state is blank -->
				<xsl:otherwise>
					<xsl:copy-of
						select="$AddressDB/AddressList/Address[contains(./details/state/text(),$state) and contains(./details/city/text(),$city)]" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:choose>
			<!-- If address results found then build the response  -->
			<xsl:when
				test="string-length($findByLocationResults) > 0">
				<xsl:variable name="payload">
					<xsl:element name="findByLocationResponse"
						namespace="{$AddressNS}">
						<xsl:element name="findByLocationReturn">
							<!-- Output the results from searching the state information -->
							<xsl:copy-of
								select="$findByLocationResults" />
						</xsl:element>
					</xsl:element>
				</xsl:variable>

				<xsl:call-template name="buildResponse">
					<xsl:with-param name="payload" select="$payload" />
				</xsl:call-template>
			</xsl:when>
			<!-- If address results not found then build a fault message -->
			<xsl:otherwise>
				<xsl:call-template name="buildFault">
					<xsl:with-param name="soapFaultCode"
						select="'AddressNotFoundException'" />
					<xsl:with-param name="soapFaultString"
						select="concat('AddressNotFoundException: Cannot find any address entries located in ', $city, ' ', $state)" />
					<xsl:with-param name="soapFaultDetail">
						<AddressNotFoundException>
							<message>
								Cannot find any address entries located	in	<xsl:value-of
									select="concat($city, ' ', $state)" />
							</message>
						</AddressNotFoundException>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<!-- Search for address information based on name -->
	<xsl:template name="findByName">
		<xsl:param name="operation" />
		
		<xsl:variable name="firstName"
			select="$operation/name/firstName" />
		<xsl:variable name="lastName" select="$operation/name/lastName" />
		<xsl:variable name="title" select="$operation/name/title" />

		<!--  Check for address information in the Address database -->
		<xsl:variable name="searchResultsName"
			select="$AddressDB/AddressList/Address
   			[contains(./name/firstName/text(),$firstName) 
   			and contains(./name/lastName/text(),$lastName) 
   			and contains(./name/title/text(),$title)]" />

		<xsl:choose>
			<!-- If address results found then build response -->
			<xsl:when test="string-length($searchResultsName) > 0">
				<xsl:variable name="payload">
					<xsl:element name="findByNameResponse"
						namespace="{$AddressNS}">
						<xsl:element name="findByNameReturn">
							<!-- Output the results from searching the state information -->
							<xsl:copy-of select="$searchResultsName" />
						</xsl:element>
					</xsl:element>
				</xsl:variable>

				<xsl:call-template name="buildResponse">
					<xsl:with-param name="payload" select="$payload" />
				</xsl:call-template>
			</xsl:when>
			<!-- No address results then return fault message -->
			<xsl:otherwise>
				<xsl:call-template name="buildFault">
					<xsl:with-param name="soapFaultCode"
						select="'AddressNotFoundException'" />
					<xsl:with-param name="soapFaultString"
						select="concat('AddressNotFoundException: Cannot find any address entries belonging to ', $title, ' ', $firstName, ' ', $lastName)" />
					<xsl:with-param name="soapFaultDetail">
						<AddressNotFoundException>
							<message>
								Cannot find any address entries	belonging to <xsl:value-of
									select="concat(' ', $title, ' ', $firstName, ' ', $lastName)" />
							</message>
						</AddressNotFoundException>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<!-- Retrieve all address information from the Address database  -->
	<xsl:template name="retrieveAll">
		<xsl:param name="operation" />

		<xsl:variable name="searchResultsRetrieveAll"
			select="$AddressDB/AddressList/Address" />

		<xsl:choose>
			<!-- If address results found then return response message. -->
			<xsl:when test="string-length($searchResultsRetrieveAll) > 0">
				<xsl:variable name="payload">
					<xsl:element name="retrieveAllResponse"
						namespace="{$AddressNS}">
						<xsl:element name="retrieveAllReturn"
							namespace="{$AddressNS}">
							<!-- Output the results from searching the state information -->
							<xsl:copy-of
								select="$searchResultsRetrieveAll" />
						</xsl:element>
					</xsl:element>
				</xsl:variable>

				<xsl:call-template name="buildResponse">
					<xsl:with-param name="payload" select="$payload" />
				</xsl:call-template>
			</xsl:when>
			<!-- If no address results found then return fault message. -->
			<xsl:otherwise>
				<xsl:call-template name="buildFault">
					<xsl:with-param name="soapFaultCode"
						select="'AddressNotFoundException'" />
					<xsl:with-param name="soapFaultString"
						select="'AddressNotFoundException: The address book is empty.  No entries retrieved.'" />
					<xsl:with-param name="soapFaultDetail">
						<AddressNotFoundException>
							<message>
								AddressNotFoundException: The address book is empty.  No entries retrieved.
							</message>
						</AddressNotFoundException>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<!-- Build a SOAP formatted response message using the paramter payload  -->
	<xsl:template name="buildResponse">
		<xsl:param name="payload" />

		<soapenv:Envelope
			xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope"
			xmlns:xsd="http://www.w3.org/2001/XMLSchema"
			xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<soapenv:Header />

			<soapenv:Body>
				<xsl:copy-of select="$payload" />
			</soapenv:Body>
		</soapenv:Envelope>

	</xsl:template>

	<!-- Build a SOAP formated fault message using the passed parameters.  -->
	<xsl:template name="buildFault">
		<xsl:param name="soapFaultCode" />
		<xsl:param name="soapFaultString" />
		<xsl:param name="soapFaultDetail" />

		<soapenv:Envelope
			xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
			<soapenv:Body>
				<soapenv:Fault>
					<faultcode>
						<xsl:value-of select="$soapFaultCode" />
					</faultcode>
					<faultstring>
						<xsl:value-of select="$soapFaultString" />
					</faultstring>
					<xsl:if test="$soapFaultDetail != ''">
						<detail>
							<xsl:value-of select="$soapFaultDetail" />
						</detail>
					</xsl:if>
				</soapenv:Fault>
			</soapenv:Body>
		</soapenv:Envelope>
		
		<!-- Set the HTTP response code to 500 since a SOAP fault is returned -->
		<dp:set-http-response-header name="'x-dp-response-code'" value="'500'"/>  
	</xsl:template>
</xsl:stylesheet>