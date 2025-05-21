@isTest
public class CreateEVCQUotePDFControllerTest {
    
    @isTest
    public static void testConstructor() {
        List<Account> accounts = TestUtill.createAccount(1);
        insert accounts;
        
        List<Opportunity> opportunities = TestUtill.createOpportunity(1);
        for (Opportunity opp : opportunities) {
            opp.AccountId = accounts[0].Id;
            opp.StageName = 'Prospecting';
        }
        insert opportunities;
        
        // Create a Quote and assign it a Pricebook
        Id standardPricebookId = Test.getStandardPricebookId(); // Ensure you get the correct PricebookId
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opportunities[0].Id,
            BillingCountry = 'USA',
            BillingPostalCode = '12345',
            BillingState = 'CA',
            BillingCity = 'Los Angeles',
            BillingStreet = '123 Test St',
            Payment_Terms__c = 'Net 30',
            Additional_Request__c = 'None',
            Remarks__c = 'Test Remarks',
            Delivery__c = 'Standard',
            Warranty__c = '1 year',
           
            Pricebook2Id = standardPricebookId // Assign the Pricebook to the Quote
        );
        insert testQuote;
        
        // Create Quote Line Items
        Product2 testProduct = new Product2(Name = 'Test Product', PLSI_ItemId__c = '967980', IsActive = true);
        insert testProduct;
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId, // Use the same PricebookId as above
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testPricebookEntry;
        
        QuoteLineItem testQuoteLineItem = new QuoteLineItem(
            QuoteId = testQuote.Id,
            Quantity = 10,
            UnitPrice = 100,
            PricebookEntryId = testPricebookEntry.Id,
            Description = 'Test Line Item',
            GST__c = '5',
            Discount_Price__c = 50
        );
        insert testQuoteLineItem;
        
        String url = '/apex/EVCQuoteTemplatePdf';
        String parameters = 'id=' + testQuote.Id;
        PageReference pdfPage = new PageReference(url + '?' + parameters);
        
        Test.setCurrentPage(pdfPage);
        ApexPages.StandardController sc = new ApexPages.StandardController(testQuote);
        CreateEVCQuotePDFController pdfController = new CreateEVCQuotePDFController(sc);
        
        // Validate the controller's initial state
        System.assertNotEquals(null, pdfController.quote, 'Quote should not be null');
        System.assertNotEquals(null, pdfController.quoteItems, 'QuoteItems should not be null');
        System.assertEquals(1, pdfController.quoteItems.size(), 'There should be one QuoteLineItem'); 
        
        // Validate the version number logic
        System.assertEquals(1, pdfController.versionNumber, 'Initial versionNumber should be 1');
        
        // Insert a ContentVersion linked to the quote to simulate existing versions
        ContentVersion existingVersion = new ContentVersion(
            Title = 'Test Quote_V1', 
            PathOnClient = 'Test Quote_V1.pdf',
            VersionData = Blob.valueOf('Fake PDF Content'),
            IsMajorVersion = true
        );
        insert existingVersion;
        
        // Create a QuoteDocument linked to the existing version
        QuoteDocument existingQuoteDocument = new QuoteDocument(
            QuoteId = testQuote.Id,
            ContentVersionDocumentId = existingVersion.Id,
            Document = existingVersion.VersionData
        );
        insert existingQuoteDocument;
        
        // Reinstantiate the controller to simulate a new request
        pdfController = new CreateEVCQuotePDFController(sc);
        
        // Validate the version number increment logic
        System.assertEquals(2, pdfController.versionNumber, 'Version number should be incremented to 2');
        
    }
    
    @isTest
    public static void testSavePDFToQuoteSuccess() {
        List<Account> accounts = TestUtill.createAccount(1);
        insert accounts;
        
        List<Opportunity> opportunities = TestUtill.createOpportunity(1);
        for (Opportunity opp : opportunities) {
            opp.AccountId = accounts[0].Id;
            opp.StageName = 'Prospecting';
        }
        insert opportunities;
        
        // Create a Quote and assign it a Pricebook
        Id standardPricebookId = Test.getStandardPricebookId(); // Ensure you get the correct PricebookId
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opportunities[0].Id,
            BillingCountry = 'USA',
            BillingPostalCode = '12345',
            BillingState = 'CA',
            BillingCity = 'Los Angeles',
            BillingStreet = '123 Test St',
            Payment_Terms__c = 'Net 30',
            Additional_Request__c = 'None',
            Remarks__c = 'Test Remarks',
            Delivery__c = 'Standard',
            Warranty__c = '1 year',
            
            Pricebook2Id = standardPricebookId // Assign the Pricebook to the Quote
        );
        insert testQuote;
        
        // Create Quote Line Items
        Product2 testProduct = new Product2(Name = 'Test Product', PLSI_ItemId__c = '967980', IsActive = true);
        insert testProduct;
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId, // Use the same PricebookId as above
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testPricebookEntry;
        
        QuoteLineItem testQuoteLineItem = new QuoteLineItem(
            QuoteId = testQuote.Id,
            Quantity = 10,
            UnitPrice = 100,
            PricebookEntryId = testPricebookEntry.Id,
            Description = 'Test Line Item',
            GST__c = '5',
            Discount_Price__c = 50
        );
        insert testQuoteLineItem;
        
        // Create a fake previous ContentVersion and QuoteDocument
        ContentVersion existingVersion = new ContentVersion(
            Title = 'Test Quote_V1',
            PathOnClient = 'Test Quote_V1.pdf',
            VersionData = Blob.valueOf('Fake PDF Content'),
            IsMajorVersion = true
        );
        insert existingVersion;
        
        QuoteDocument quoteDoc = new QuoteDocument(
            QuoteId = testQuote.Id,
            ContentVersionDocumentId = existingVersion.Id,
            Document = Blob.valueOf('Fake PDF Content')
        );
        insert quoteDoc;
        
        
        Test.startTest();
        String result = CreateEVCQuotePDFController.savePDFToQuote(testQuote.Id);
        Test.stopTest();
        
        System.assertEquals('Success', result);        
        
        List<ContentVersion> contentVersions = [
            SELECT Id, Title 
            FROM ContentVersion 
            WHERE Title LIKE 'Test Quote_V%'
        ];
        System.assertEquals(4, contentVersions.size());
        
        
        List<QuoteDocument> quoteDocs = [
            SELECT Id, ContentVersionDocumentId 
            FROM QuoteDocument 
            WHERE QuoteId = :testQuote.Id
        ];
        System.assertEquals(2, quoteDocs.size());
        
        
    }
    
    @isTest
    public static void testSavePDFToQuoteFailure() {
        Test.startTest();
        String result = CreateEVCQuotePDFController.savePDFToQuote('invalidId');
        Test.stopTest();
        System.assert(result.startsWith('Failure'), 'Expected failure result');
    }
    
}