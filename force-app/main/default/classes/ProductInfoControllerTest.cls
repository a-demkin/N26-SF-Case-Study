@isTest
public with sharing class ProductInfoControllerTest {
    private static Decimal COST_PER_MONTH = 1;
    private static Double ATM_FEE = 1;
    private static Decimal REPLACEMENT_COST = 1;
    @TestSetup
    static void setup(){
        Product2 stdProd = new Product2(
            Name = 'Standard Test',
            IsActive = true
        );
        insert stdProd;

        Contact contactSuccess = new Contact(
            LastName = 'Test Success Contact',
            Product__c = stdProd.Id,
            Home_Country__c = Constants.HOME_COUNTRY_DE
        );
        Contact contactWithoutMatchingCountry = new Contact(
            LastName = 'Test Contact Without Matching Card Service Country',
            Product__c = stdProd.Id,
            Home_Country__c = Constants.HOME_COUNTRY_FR
        );
        Contact contactWithMissingFields = new Contact(
            LastName = 'Test Contact Without Product'
        );
        insert new List<Contact>{
            contactSuccess, contactWithoutMatchingCountry, contactWithMissingFields
        };

        Case caseSuccess = new Case(
            Origin = 'Email',
            ContactId = contactSuccess.Id
        );
        Case casecontactWithMissingFields = new Case(
            Origin = 'Email',
            ContactId = contactWithMissingFields.Id
        );
        Case caseContactWithoutMatchingCountry = new Case(
            Origin = 'Email',
            ContactId = contactWithoutMatchingCountry.Id
        );
        Case caseWithoutContact = new Case(
            Origin = 'Email'
        );
        insert new List<Case>{
            caseSuccess, casecontactWithMissingFields,
            caseContactWithoutMatchingCountry, caseWithoutContact
        };

        Card_Service__c cardServiceSuccess = new Card_Service__c(
            Product__c = stdProd.Id,
            Home_Country__c = Constants.HOME_COUNTRY_DE,
            Cost_per_Calendar_Month__c = COST_PER_MONTH,
            ATM_Fee_in_other_currencies__c = ATM_FEE,
            Card_Replacement_Cost__c = REPLACEMENT_COST
        );
        insert cardServiceSuccess;
    }

    @isTest
    static void testGetProductInfoPositive() {
        Id productId = [SELECT Id FROM Product2 LIMIT 1].Id;
        Id successfulCaseId = [
            SELECT Id
            FROM Case
            WHERE Contact.Home_Country__c = :Constants.HOME_COUNTRY_DE
                AND Contact.Product__c = :productId
            LIMIT 1
        ].Id;

        Map<Id, Card_Service__c> cardServices = new Map<Id, Card_Service__c>([
            SELECT Id, Home_Country__c, Product__r.Name, Cost_per_Calendar_Month__c,
                ATM_Fee_in_other_currencies__c, Card_Replacement_Cost__c
            FROM Card_Service__c
            WHERE Product__c = :productId
                AND Home_Country__c = :Constants.HOME_COUNTRY_DE
        ]);

        Test.startTest();
        List<ProductInfoController.ProductInfoWrapper> result =
            ProductInfoController.getProductInfo(successfulCaseId);

        for (ProductInfoController.ProductInfoWrapper resultWrapper : result) {
            Card_Service__c cardService = cardServices.get(resultWrapper.cardServiceId);
            System.assertEquals(resultWrapper.productName, cardService.Product__r.Name, 'Product Name should be the same');
            System.assertEquals(resultWrapper.homeCountry, cardService.Home_Country__c, 'Home Country should be the same');
            for (ProductInfoController.ProductInfoFeatureField featureField : resultWrapper.featureFields) {
                System.assertEquals(featureField.value, cardService.get(featureField.apiName),
                    featureField.label + ' should be the same');
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testGetProductInfoContactWithoutMatchingCardService() {
        Id productId = [SELECT Id FROM Product2 LIMIT 1].Id;
        Id caseId = [
            SELECT Id
            FROM Case
            WHERE Contact.Home_Country__c = :Constants.HOME_COUNTRY_FR
                AND Contact.Product__c = :productId
            LIMIT 1
        ].Id;

        Test.startTest();
        List<ProductInfoController.ProductInfoWrapper> result =
            ProductInfoController.getProductInfo(caseId);
        assertErrorWrapper(result, Constants.PRODUCT_INFO_ERROR_NO_PRODUCTS_FOR_CONTACT);
        Test.stopTest();
    }

    @isTest
    static void testGetProductInfoContactWithMissingFields() {
        Id contactId = [
            SELECT Id
            FROM Contact
            WHERE Home_Country__c = NULL
                AND Product__c = NULL
            LIMIT 1].Id;
        Id caseId = [
            SELECT Id
            FROM Case
            WHERE ContactId = :contactId
            LIMIT 1
        ].Id;

        Test.startTest();
        List<ProductInfoController.ProductInfoWrapper> result =
            ProductInfoController.getProductInfo(caseId);
        assertErrorWrapper(result, Constants.PRODUCT_INFO_ERROR_CONTACT_FIELDS_MISSING);
        Test.stopTest();
    }

    @isTest
    static void testGetProductInfoCaseWithoutContact() {
        Id caseId = [
            SELECT Id
            FROM Case
            WHERE ContactId = NULL
            LIMIT 1
        ].Id;

        Test.startTest();
        List<ProductInfoController.ProductInfoWrapper> result =
            ProductInfoController.getProductInfo(caseId);
        assertErrorWrapper(result, Constants.PRODUCT_INFO_ERROR_CONTACT_MISSING);
        Test.stopTest();
    }

    private static void assertErrorWrapper(List<ProductInfoController.ProductInfoWrapper> wrappers, String errorMessage) {
        System.assertEquals(wrappers.size(), 1, 'Should be only 1 wrapper (with error)');
        System.assert(wrappers[0].hasError, 'Shoud be error wrapper');
        System.assertEquals(wrappers[0].errorMessage, errorMessage,
            'Error messages should be the same');
    }
}