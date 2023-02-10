public with sharing class ProductInfoController {
	@AuraEnabled
	public static List<ProductInfoWrapper> getProductInfo(String caseId) {
		List<ProductInfoWrapper> wrappers = new List<ProductInfoWrapper>();
		try {
			Case case = [
				SELECT Contact, Contact.Product__c, Contact.Home_Country__c
				FROM Case
				WHERE Id = :caseId
			];

			if (case.Contact != null && case.Contact.Product__c != null && case.Contact.Home_Country__c != null) {
				List<Card_Service__c> cardServices = [
					SELECT
						Id, Product__r.Name, Home_Country__c, CurrencyIsoCode, Cost_per_Calendar_Month__c, ATM_Fee_in_other_currencies__c, Card_Replacement_Cost__c
					FROM Card_Service__c
					WHERE
						Product__c = :case.Contact.Product__c
						AND Home_Country__c = :case.Contact.Home_Country__c
				];

				if (!cardServices.isEmpty()) {
					for (Card_Service__c cardService : cardServices) {
						wrappers.add(new ProductInfoWrapper(cardService));
					}
				} else {
					wrappers.add(getErrorWrapper(Constants.PRODUCT_INFO_NO_PRODUCTS_FOR_CONTACT));
				}
			} else {
				wrappers.add(getErrorWrapper(Constants.PRODUCT_INFO_CONTACT_FIELDS_MISSING));
			}
		} catch (Exception e) {
			wrappers.add(getErrorWrapper(e.getMessage()));
		}
		return wrappers;
	}

	private ProductInfoWrapper getErrorWrapper(String errorMessage) {
		ProductInfoWrapper wrapper = new ProductInfoWrapper();
		wrapper.hasError = true;
		wrapper.errorMessage = errorMessage;
		return wrapper;
	}

	private List<Schema.FieldSetMember> getFieldsFromFieldSet(String objectName, String fieldSetName) {
		return Type.forName(objectName).newInstance().getDescribe().FieldSets.getMap().get(fieldSetName);
	}

	public class ProductInfoWrapper {
		public ProductInfoWrapper() {}
		public ProductInfoWrapper(Card_Service__c cardService) {
            this.productId = cardService.Id;
			this.productName = cardService.Product__r.Name;
			this.homeCountry = cardService.Home_Country__c;
			this.currencyIsoCode = cardService.CurrencyIsoCode;
			this.costPerMonth = cardService.Cost_per_Calendar_Month__c;
			this.atmFeeInOtherCurrencies = cardService.ATM_Fee_in_other_currencies__c;
			this.cardReplacementCost = cardService.Card_Replacement_Cost__c;
		}

        @AuraEnabled
        public Id productId {get; set;}
		@AuraEnabled
		public String productName {get; set;}
		@AuraEnabled
		public String homeCountry {get; set;}
		@AuraEnabled
		public String currencyIsoCode {get; set;}
		@AuraEnabled
		public Decimal costPerMonth {get; set;}
		@AuraEnabled
		public Decimal atmFeeInOtherCurrencies {get; set;}
		@AuraEnabled
		public Decimal cardReplacementCost {get; set;}
		@AuraEnabled
		public Boolean hasError {get; set;}
		@AuraEnabled
		public String errorMessage {get; set;}
	}
}
