<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx" version="1.0">
  <xsl:output indent="yes" encoding="UTF-8" omit-xml-declaration="yes"/>
  <xsl:strip-space elements="*"/>

<xsl:template match="*[local-name()='Envelope']">
        <xsl:apply-templates/>
</xsl:template>
<xsl:template match="*[local-name()='Body']">
        <xsl:apply-templates/>
</xsl:template>
  <!-- Array -->
  <xsl:template match="*[*[2]][name(*[1])=name(*[2])]">
    <json:object name="{local-name()}">
      <json:array name="{local-name(*[1])}">
        <xsl:apply-templates/>
      </json:array>
    </json:object>
  </xsl:template>
  <!-- Array member -->
  <xsl:template match="*[parent::*[ name(*[1])=name(*[2]) ]] | /">
    <json:object>
      <xsl:apply-templates/>
    </json:object>
  </xsl:template>
  <!-- Object -->
  <xsl:template match="*">
    <json:object name="{local-name()}">
      <xsl:apply-templates/>
    </json:object>
  </xsl:template>
  <!-- String -->
  <xsl:template match="*[not(*)]">
    <json:string name="{local-name()}">
      <xsl:value-of select="."/>
    </json:string>
  </xsl:template>
</xsl:stylesheet>