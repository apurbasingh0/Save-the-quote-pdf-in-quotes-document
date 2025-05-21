"# Save-the-quote-pdf-in-quotes-document" 
# Salesforce Quote PDF Generation for EVC

This Salesforce project automates the generation and versioning of PDF quotations using Apex, Visualforce, and LWC (Lightning Web Components). It dynamically compiles quote details and related line items into a multi-page, styled PDF, stores the file in Salesforce Content, and associates it with the corresponding Quote record.

## Features

- Generate quote PDFs rendered via Visualforce
- Dynamically version quote documents (e.g., `Quote123_V1`, `Quote123_V2`, etc.)
- Save PDFs as `ContentVersion` records
- Associate saved PDFs to Quotes via `QuoteDocument`
- Lightning Web Component to trigger PDF generation
- Includes custom formatting and multi-page layouts for professional presentation

## Technologies Used

- Apex
- Visualforce
- Lightning Web Components (LWC)
- Salesforce ContentVersion / QuoteDocument objects

---

## Components

### Apex: `CreateEVCQUotePDFController.cls`

Handles:

- Fetching Quote and Quote Line Items
- Determining latest version number of an existing Quote PDF
- Generating and saving the PDF file as `ContentVersion`
- Linking the PDF to the Quote using `QuoteDocument`

### Visualforce Page: `EVCQuoteTemplatePdf.page`

- Renders the PDF content
- Applies custom styles, headers, and multiple content sections
- Loads images from Static Resources
- Displays billing address, customer info, line items, terms, and remarks

### LWC: `evcQuotePdf.js`

- Displays PDF preview in an iframe
- Triggers Apex method to generate and save a new versioned PDF
- Uses `ShowToastEvent` to show success/error feedback
- Emits custom event on completion (`close`)

---

## How It Works

1. **User navigates to a Quote record.**
2. **LWC displays a button to generate PDF.**
3. **On click**, the LWC calls the Apex method `savePDFToQuote`.
4. **Apex queries for existing PDFs** for the Quote, determines the next version number, and renders the PDF using the Visualforce page.
5. **The rendered PDF is saved** to `ContentVersion` and linked via `QuoteDocument`.

---

## Installation & Setup

1. Deploy the following components to your Salesforce org:
   - `CreateEVCQUotePDFController.cls`
   - `EVCQuoteTemplatePdf.page`
   - `evcQuotePdf` LWC
2. Add necessary Static Resources for headers/images (`EVCHeader`, `EVCFirstPage`, etc.)
3. Add the LWC to your Quote Lightning record page
4. Ensure the user profile has access to the Apex class and Visualforce page

---

## Notes

- Replace static image references with your organization’s resources if needed.
- Ensure proper field-level security (FLS) on custom fields like `Quotation_No__c`, `Discount_Price__c`, etc.
- `Test.isRunningTest()` is used to bypass `PageReference.getContentAsPDF()` in tests.
- Adjust styles and content of the PDF layout according to branding or client preferences.

