@isTest
public with sharing class ContactInfoRestResourceTest {
    private static String UUID_NON_EXISTING_CONTACT = '0';
    private static String UUID_EXISTING_CONTACT = '1';
    private static String UUID_EXISTING_CONTACT_NO_CARD_SERVICES = '2';
    @TestSetup
    static void setup(){
        Product2 stdProd = new Product2(
            Name = 'Standard Test',
            IsActive = true
        );
        insert stdProd;

        Contact contWithUuidAndCardServices = new Contact(
            LastName = 'Success Contact',
            Home_Country__c = Constants.HOME_COUNTRY_DE,
            Product__c = stdProd.Id,
            UUID__c = UUID_EXISTING_CONTACT
        );
        Contact contWithUuidNoCardServices = new Contact(
            LastName = 'Contact No Card Services',
            Home_Country__c = Constants.HOME_COUNTRY_FR,
            UUID__c = UUID_EXISTING_CONTACT_NO_CARD_SERVICES
        );
        insert new List<Contact>{
            contWithUuidAndCardServices, contWithUuidNoCardServices
        };

        Card_Service__c cardServiceSuccess = new Card_Service__c(
            Product__c = stdProd.Id,
            Home_Country__c = Constants.HOME_COUNTRY_DE,
            Cost_per_Calendar_Month__c = 1,
            ATM_Fee_in_other_currencies__c = 1,
            Card_Replacement_Cost__c = 1
        );
        insert cardServiceSuccess;
    }

    @isTest
    static void testGetContactsInfoSuccess() {
        Contact cont = [
            SELECT Id, LastName, Home_Country__c, Product__c
            FROM Contact
            WHERE UUID__c = :UUID_EXISTING_CONTACT
        ];
        Test.startTest();
        RestContext.response = new RestResponse();
        RestContext.request = getTestRequest(new List<String>{UUID_EXISTING_CONTACT});
        ContactInfoRestResource.getContactsInfo();
        Test.stopTest();

        List<ContactInfoRestResource.ContactInfoWrapper> result = (List<ContactInfoRestResource.ContactInfoWrapper>)JSON.deserializeStrict(
            RestContext.response.responseBody.toString(), List<ContactInfoRestResource.ContactInfoWrapper>.class
        );

        System.assertEquals(RestContext.response.statusCode, 200, 'Status Code should be 200');
        System.assertEquals(result[0].lastName, cont.LastName, 'Last Name sould be the same');
        System.assertEquals(result[0].homeCountry, cont.Home_Country__c, 'Home Country should be the same');
        System.assertEquals(result[0].productId, cont.Product__c, 'Product Id should be the same');
        System.assert(!result[0].cardServices.isEmpty(), 'Should have card services');
    }

    @isTest
    static void testGetContactsInfoNoCardServices() {
        Contact cont = [
            SELECT Id, LastName, Home_Country__c, Product__c
            FROM Contact
            WHERE UUID__c = :UUID_EXISTING_CONTACT_NO_CARD_SERVICES
        ];
        Test.startTest();
        RestContext.response = new RestResponse();
        RestContext.request = getTestRequest(new List<String>{UUID_EXISTING_CONTACT_NO_CARD_SERVICES});
        ContactInfoRestResource.getContactsInfo();
        Test.stopTest();

        List<ContactInfoRestResource.ContactInfoWrapper> result = (List<ContactInfoRestResource.ContactInfoWrapper>)JSON.deserializeStrict(
            RestContext.response.responseBody.toString(), List<ContactInfoRestResource.ContactInfoWrapper>.class
        );

        System.assert(result[0].cardServices == null, 'Shouldn\'t have any card services');
    }

    @isTest
    static void testGetContactsInfoNoUuids() {
        Test.startTest();
        RestContext.response = new RestResponse();
        RestContext.request = getTestRequest(new List<String>());
        ContactInfoRestResource.getContactsInfo();
        Test.stopTest();

        assertErrorResponse(RestContext.response, Constants.CONTACT_REST_ERROR_NO_UUIDS_PROVIDED);
    }

    @isTest
    static void testGetContactsInfoNoContacts() {
        Test.startTest();
        RestContext.response = new RestResponse();
        RestContext.request = getTestRequest(new List<String>{UUID_NON_EXISTING_CONTACT});
        ContactInfoRestResource.getContactsInfo();
        Test.stopTest();

        assertErrorResponse(RestContext.response, Constants.CONTACT_REST_ERROR_NO_CONTACTS_FOUND);
    }

    private static RestRequest getTestRequest(List<String> uuids) {
        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        req.requestURI = '/services/apexrest/v1/ContactInfo';
        req.addHeader('Content-Type', 'application/json');
        if (!uuids.isEmpty() && String.isNotBlank(uuids[0])) {
            req.params.put(Constants.URL_PARAM_UUIDS, String.join(uuids, ','));
        }
        return req;
    }

    private static void assertErrorResponse(RestResponse res, String errorMessage) {
        System.assertEquals(res.statusCode, 500, 'Status code should be 500');
        System.assertEquals(res.responseBody.toString(), errorMessage, 'Error mesages should be the same');
    }
}