; ------------------------------------------------------
; Application settings for sydneyjabiru demo application
; ------------------------------------------------------

[settings]
description = Sydney Jabiru Flying School Website

; Installation root for this application
; appInstallRoot = /var/www/webapps/sydneyjabiru
appInstallRoot = c:\inetpub\webapps\sydneyjabiru

; Datasource for content database
codb = sydneyjabiru

; Database type access|sqlserver|oracle|postgresql|firebird|mysql|...
dbtype = access

; Template mapping to application's tags directory - only required if 
; appInstallRoot and Speck directory not within same parent directory
; mapping = /webapps/sydneyjabiru/tags

; Web root for this application. Enable this setting to run this speck app inside a virtual directory. 
; If necessary, replace "sydneyjabiru" with the name of your virtual directory
; appWebRoot = /sydneyjabiru

; What roles should be required to edit the label and keywords for content items?
labelRoles = spSuper
keywordsRoles = spSuper

; Version Control
; Combinations of these settings have the following effects:
; enableRevisions	enablePromotion	effect
; Yes				Yes				New revision created on every edit following a promotion (i.e once promoted to 
;									review a revision cannot be changed).  Change control allowed.
; Yes				No				New revision created every time content updated, takes effect instantly.
; No				Yes				NOT ALLOWED
; No				No				Only one revision, update replaces previous data, takes effect instantly.

enableRevisions = Yes
enablePromotion = Yes

; Debug?
Debug = No
