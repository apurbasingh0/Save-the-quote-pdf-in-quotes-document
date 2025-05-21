/**
     * @description       : used in "EvcQuotePdf" LWC to create and save the quote pdf in quotes document
     * @authorName        : Apurba Singh
     * @group             : Appstrail
     * @last modified on  : 19-08-2024
     * @last modified by  : Apurba Singh
**/
public with sharing class CreateEVCQUotePDFController {
    public Integer versionNumber { get; set; }
    public Quote quote { get; set; }
    public List<QuoteLineItem> quoteItems { get; set; }
    public CreateEVCQUotePDFController(ApexPages.StandardController controller) {
        //this.quote = (Quote)controller.getRecord();
        this.quote = [SELECT Id, Name, Account.Name, BillingCountry, BillingPostalCode, BillingState, BillingCity, BillingStreet, CreatedDate,
        SPA_Number__c, Payment_Terms__c, Additional_Request__c, Remarks__c, Delivery__c,Warranty__c, Quotation_No__c  FROM Quote WHERE Id = :controller.getId()];
        String quoteName = this.quote.Name;
        quote.Remarks__c = quote.Remarks__c.replace('\n', '<br/>').replace('&BR()', '<br/>');
        // Query for ContentDocumentLink records related to the Quote
        List<ContentDocumentLink> contentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :quote.Id];
        
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink link : contentLinks) {
            contentDocumentIds.add(link.ContentDocumentId);
        }

        // Query for existing ContentVersions related to the ContentDocumentIds
        versionNumber = 1; // Default to version 1
        if (!contentDocumentIds.isEmpty()) {
            List<ContentVersion> existingVersions = [
                SELECT Id, Title 
                FROM ContentVersion 
                WHERE ContentDocumentId IN :contentDocumentIds
                AND Title LIKE :quoteName + '_V%'
                ORDER BY CreatedDate DESC
            ];

            if (!existingVersions.isEmpty()) {
                // Extract the last version number and increment it
                String lastVersionTitle = existingVersions[0].Title;
                String lastVersionNumberStr = lastVersionTitle.substringAfter('_V');
                Integer lastVersionNumber = Integer.valueOf(lastVersionNumberStr);
                versionNumber = lastVersionNumber + 1;
            }
        }
        quoteItems = [SELECT Description, Quantity, ListPrice, TotalPrice, Total_Price__c,Total_Sales_Discount_Price__c, GST__c,Discount_Price__c,Total_Price_EVC__c, Unit_Rate__c,
        Quote.BillingStreet, Quote.BillingCity, Quote.BillingState, Quote.BillingCountry, Quote.BillingPostalCode,
        Quote.Account.Name, CreatedDate, Quote.SPA_Number__c , Product2.Name
                      FROM QuoteLineItem
                      WHERE QuoteId = :quote.Id];

        
    }

    @AuraEnabled
    public static String savePDFToQuote(String recordId) {
        String returnType;
        try {
            System.debug('recordId ' + recordId);
        
            // Retrieve the Quote Name
            Quote quote = [SELECT Name FROM Quote WHERE Id = :recordId LIMIT 1];
            if (quote == null) {
                System.debug('Quote not found: ');
            }
            String quoteName = quote.Name;
        
            // Step 1: Query for ContentDocumentLink records related to the Quote
            List<ContentDocumentLink> contentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
            
            Set<Id> contentDocumentIds = new Set<Id>();
            for(ContentDocumentLink link : contentLinks) {
                contentDocumentIds.add(link.ContentDocumentId);
            }
        
            // Step 2: Query for existing ContentVersions related to the ContentDocumentIds
            Integer versionNumber = 1; // Default to version 1
            if (!contentDocumentIds.isEmpty()) {
                List<ContentVersion> existingVersions = [
                    SELECT Id, Title 
                    FROM ContentVersion 
                    WHERE ContentDocumentId IN :contentDocumentIds
                    AND Title LIKE :quoteName + '_V%'
                    ORDER BY CreatedDate DESC
                ];
        
                if (!existingVersions.isEmpty()) {
                    // Extract the last version number and increment it
                    String lastVersionTitle = existingVersions[0].Title;
                    String lastVersionNumberStr = lastVersionTitle.substringAfter('_V');
                    Integer lastVersionNumber = Integer.valueOf(lastVersionNumberStr);
                    versionNumber = lastVersionNumber + 1;
                }
            }
        
            String newTitle = quoteName + '_V' + versionNumber;
        
            // Generate the PDF content
            String url = '/apex/EVCQuoteTemplatePdf?core.apexpages.request.devconsole=1&id=' + recordId;
            PageReference pdfPage = new PageReference(url);
            Blob pdfContent;

            if (!Test.isRunningTest()) {
                pdfContent = pdfPage.getContentAsPDF();
            } else {
                pdfContent = Blob.valueOf('Test Case Content'); // Simulate PDF content in test
            }
            
            // Create the ContentVersion record
            if (pdfContent != null && pdfContent.size() > 0) {
                ContentVersion cversion = new ContentVersion();
                cversion.ContentLocation = 'S'; // Origin of the document
                cversion.Title = newTitle;
                cversion.PathOnClient = newTitle + '.pdf'; // Save with title and extension as PDF
                cversion.VersionData = pdfContent;
                insert cversion;
                System.debug('cversion ' + cversion);
        
                // Create the QuoteDocument record
                QuoteDocument quoteDocument = new QuoteDocument();
                quoteDocument.QuoteId = recordId; // Link the document to the Quote
                quoteDocument.ContentVersionDocumentId = cversion.Id; // Store the ContentVersionId
                quoteDocument.Document = pdfContent; // Store the binary data of the document
                insert quoteDocument;
                System.debug('quoteDocument ' + quoteDocument);
            } else {
                system.debug('PDF content is empty or null: ');
            }
        
            returnType = 'Success';
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage()); 
            returnType = 'Failure: ' + e.getMessage();
        }
        
        return returnType;

  }

}