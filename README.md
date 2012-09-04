sfdc-docusign-rest
==================

Docusign REST API Implementation with Force.com Sample Code:


Controllers:

ContractPDF.cls - PDF generation controller for Contract & Sending Document to Docusign

DocusignService2.cls - REST API implementation of Docusign APIs for sending PDF document using Apex/JSON


Custom Objects:

Docusign_Status__c - Docusign Status tracking custom object in SFDC configured through Docusign Connect console.

Custom Setting:

Docusign_Settings__c - Custom settings in Salesforce for storing docusign Username/Password/AccountId/Integerator Key.

Visualforce Page:

contractpdf.page - visualforce page for rendering contract as pdf file.

sendtodocusign.page - dummy controller to make Docusign API call from custom buttons.
