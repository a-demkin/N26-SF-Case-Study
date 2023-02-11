public with sharing class ProductInfoController {
	private static List<String> CARD_SERVICE_QUERY_COMMON_FIELDS = new List<String>{
		'Id',
		'CurrencyIsoCode',
		'Product__r.Name',
		'Home_Country__c'
	};

	@AuraEnabled
	public static List<ProductInfoWrapper> getProductInfo(String caseId) {
		List<ProductInfoWrapper> wrappers = new List<ProductInfoWrapper>();
		try {
			Case caseRecord = [
				SELECT ContactId, Contact.Product__c, Contact.Home_Country__c
				FROM Case
				WHERE Id = :caseId
			];

			if (caseRecord.ContactId != null) {
				if (caseRecord.Contact.Product__c != null && caseRecord.Contact.Home_Country__c != null) {
					List<Schema.FieldSetMember> fsFields = getFieldsFromFieldSet(Constants.CARD_SERVICE_API_NAME, Constants.PRODUCT_INFO_FIELD_SET_NAME);

					String query = 'SELECT ' + String.join(CARD_SERVICE_QUERY_COMMON_FIELDS, ', ');
					query += ', ' + String.join(
						getFieldApiNames(fsFields),
						', ');
					query += ' FROM ' + Constants.CARD_SERVICE_API_NAME;
					query += ' WHERE Product__c = \'' + caseRecord.Contact.Product__c + '\'' +
						' AND Home_Country__c = \'' + caseRecord.Contact.Home_Country__c + '\'';
					List<Card_Service__c> cardServices = Database.query(query);

					if (!cardServices.isEmpty()) {
						for (Card_Service__c cardService : cardServices) {
							wrappers.add(getProductInfoWrapper(cardService, fsFields));
						}
					} else {
						wrappers.add(getErrorWrapper(Constants.PRODUCT_INFO_ERROR_NO_PRODUCTS_FOR_CONTACT));
					}
				} else {
					wrappers.add(getErrorWrapper(Constants.PRODUCT_INFO_ERROR_CONTACT_FIELDS_MISSING));
				}
			} else {
				wrappers.add(getErrorWrapper(Constants.PRODUCT_INFO_ERROR_CONTACT_MISSING));
			}
		} catch (Exception e) {
			wrappers.add(getErrorWrapper(e.getMessage()));
		}
		return wrappers;
	}

	private static ProductInfoWrapper getProductInfoWrapper(Card_Service__c cardService, List<Schema.FieldSetMember> featureFields) {
		ProductInfoWrapper wrapper = new ProductInfoWrapper();
		wrapper.cardServiceId = cardService.Id;
		wrapper.currencyCode = cardService.CurrencyIsoCode;
		wrapper.productName = cardService.Product__r.Name;
		wrapper.homeCountry = cardService.Home_Country__c;
		List<ProductInfoFeatureField> wrapperFeatureFields = new List<ProductInfoFeatureField>();
		for (Schema.FieldSetMember fsField : featureFields) {
			ProductInfoFeatureField featureField = new ProductInfoFeatureField();
			featureField.label = fsField.getLabel();
			featureField.apiName = fsField.getFieldPath();
			featureField.value = cardService.get(fsField.getFieldPath());
			featureField.dataType = String.valueOf(fsField.getType());
			wrapperFeatureFields.add(featureField);
		}
		wrapper.featureFields = wrapperFeatureFields;
		return wrapper;
	}

	private static ProductInfoWrapper getErrorWrapper(String errorMessage) {
		ProductInfoWrapper wrapper = new ProductInfoWrapper();
		wrapper.hasError = true;
		wrapper.errorMessage = errorMessage;
		return wrapper;
	}

	private static List<Schema.FieldSetMember> getFieldsFromFieldSet(String objectName, String fieldSetName) {
		return ((SObject)Type.forName(objectName).newInstance()).getSObjectType().getDescribe()
			.FieldSets.getMap().get(fieldSetName).getFields();
	}

	private static List<String> getFieldApiNames(List<Schema.FieldSetMember> fsFields) {
		List<String> fieldApiNames = new List<String>();
		for (Schema.FieldSetMember fsField : fsFields) {
			fieldApiNames.add(fsField.getFieldPath());
		}
		return fieldApiNames;
	}

	public class ProductInfoWrapper {
        @AuraEnabled
        public List<ProductInfoFeatureField> featureFields {get; set;}
		@AuraEnabled
		public String cardServiceId {get; set;}
		@AuraEnabled
		public String currencyCode {get; set;}
		@AuraEnabled
		public String productName {get; set;}
		@AuraEnabled
		public String homeCountry {get; set;}
		@AuraEnabled
		public Boolean hasError {get; set;}
		@AuraEnabled
		public String errorMessage {get; set;}
	}

	public class ProductInfoFeatureField {
		@AuraEnabled
		public String label {get; set;}
		@AuraEnabled
		public String apiName {get; set;}
		@AuraEnabled
		public Object value {get; set;}
		@AuraEnabled
		public String dataType {get; set;}
	}
}
