@RestResource(urlMapping='/v1/ContactInfo/*')
global with sharing class ContactInfoRestResource {

    @HttpGet
    global static void getContactsInfo() {
        RestResponse res = RestContext.response;
        List<ContactInfoWrapper> contactWrappers = new List<ContactInfoWrapper>();
    
        Map<String,String> paramsMap = RestContext.request.params;
        List<String> uuids = paramsMap.containsKey(Constants.URL_PARAM_UUIDS)
            ?  String.escapeSingleQuotes(paramsMap.get(Constants.URL_PARAM_UUIDS)).split(',') // Escaping URL parameter to avoid XSS and converting it to list of ids
            : null;
        if (uuids != null && !uuids.isEmpty() && String.isNotBlank(uuids[0])) {
            List<Contact> contacts = [
                SELECT Id, UUID__c, FirstName, LastName, Home_Country__c, Product__c, Product__r.Name
                FROM Contact
                WHERE UUID__c IN :uuids
            ];

            if (!contacts.isEmpty()) {
                Map<String, Set<Card_Service__c>> cardServicesMap = getCardServicesByCountryAndProduct(contacts);
                for (Contact contact : contacts) {
                    contactWrappers.add(getContactInfoWrapper(contact, cardServicesMap));
                }
                res.statusCode = 200;
                res.responseBody = Blob.valueOf(JSON.serialize(contactWrappers));
            } else {
                res.statusCode = 500;
                res.responseBody = Blob.valueOf(Constants.CONTACT_REST_ERROR_NO_CONTACTS_FOUND);
            }
        } else {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(Constants.CONTACT_REST_ERROR_NO_UUIDS_PROVIDED);
        }
    }

    private static ContactInfoWrapper getContactInfoWrapper(Contact contact, Map<String, Set<Card_Service__c>> cardServicesMap) {
        ContactInfoWrapper wrapper = new ContactInfoWrapper();
        wrapper.uuid = contact.UUID__c;
        wrapper.firstName = contact.FirstName;
        wrapper.lastName = contact.LastName;
        wrapper.homeCountry = contact.Home_Country__c;
        wrapper.productId = contact.Product__c;
        wrapper.productName = contact.Product__r.Name;
        String cardServiceKey = contact.Home_Country__c + '-' + contact.Product__c;
        if (cardServicesMap.containsKey(cardServiceKey)) {
            Set<Card_Service__c> contactCardServices = cardServicesMap.get(cardServiceKey);
            if (!contactCardServices.isEmpty()) {
                List<ContactInfoCardServiceWrapper> cardServicesWrapper = new List<ContactInfoCardServiceWrapper>();
                for (Card_Service__c cardService : contactCardServices) {
                    ContactInfoCardServiceWrapper cardServiceWrapper = new ContactInfoCardServiceWrapper();
                    cardServiceWrapper.costPerCalendarMonth = cardService.Cost_per_Calendar_Month__c;
                    cardServiceWrapper.atmFeeInOtherCurrencies = cardService.ATM_Fee_in_other_currencies__c;
                    cardServiceWrapper.cardReplacementCost = cardService.Card_Replacement_Cost__c;
                    cardServicesWrapper.add(cardServiceWrapper);
                }
                wrapper.cardServices = cardServicesWrapper;
            }
        }

        return wrapper;
    }

    private static Map<String, Set<Card_Service__c>> getCardServicesByCountryAndProduct(List<Contact> contacts) {
        List<Card_Service__c> cardServices = getCardServices(contacts);
        Map<String, Set<Card_Service__c>> cardServicesMap = new Map<String, Set<Card_Service__c>>();
        for (Card_Service__c cardService : cardServices) {
            String key = cardService.Home_Country__c + '-' + cardService.Product__c;
            if (cardServicesMap.containsKey(key)) {
                cardServicesMap.get(key).add(cardService);
            } else {
                cardServicesMap.put(key, new Set<Card_Service__c>{cardService});
            }
        }
        return cardServicesMap;
    }

    private static List<Card_Service__c> getCardServices(List<Contact> contacts) {
        Set<String> homeCountries = getFieldValuesFromContacts(contacts, Constants.CONTACT_FIELD_API_NAME_HOME_COUNTRY);
        Set<String> productIds = getFieldValuesFromContacts(contacts, Constants.CONTACT_FIELD_API_NAME_PRODUCT);

        List<Card_Service__c> cardServices = [
            SELECT Id, Home_Country__c, Product__c, Cost_per_Calendar_Month__c,
                ATM_Fee_in_other_currencies__c, Card_Replacement_Cost__c
            FROM Card_Service__c
            WHERE Home_Country__c IN :homeCountries
                AND Product__c IN :productIds
        ];
        return cardServices;
    }

    private static Set<String> getFieldValuesFromContacts(List<Contact> contacts, String fieldApiName) {
        Set<String> fieldValues = new Set<String>();
        for (Contact cont : contacts) {
            fieldValues.add(String.valueOf(cont.get(fieldApiName)));
        }
        return fieldValues;
    }

    public class ContactInfoWrapper {
        public String uuid;
        public String firstName;
        public String lastName;
        public String homeCountry;
        public String productId;
        public String productName;
        public List<ContactInfoCardServiceWrapper> cardServices;
    }

    public class ContactInfoCardServiceWrapper {
        public Decimal costPerCalendarMonth;
        public Decimal atmFeeInOtherCurrencies;
        public Decimal cardReplacementCost;
    }
}