import { LightningElement, api, track } from 'lwc';
import getProductInfo from '@salesforce/apex/ProductInfoController.getProductInfo';

const CURRENCY_SIGNS_BY_CODES = {
    'EUR' : '€',
    'GBP' : '£'
}
const DATA_TYPE_CURRENCY = 'CURRENCY';
const DATA_TYPE_PERCENT = 'PERCENT';

export default class ProductInformation extends LightningElement {
    @api recordId;
    error;
    @track products = [];

    connectedCallback() {
        getProductInfo({caseId: this.recordId})
        .then(productWrappers => {
            for (let wrapper of productWrappers) {
                if (wrapper.hasError) {
                    this.error = wrapper.errorMessage;
                    return;
                }
                let product = {};
                product = {...wrapper};
                product.productCardTitle = product.productName + ' - ' + product.homeCountry;
                product.featureFields.forEach(featureField => {
                    featureField.value = this.formatField(featureField.value, featureField.dataType, product.currencyCode);
                });
                this.products.push(product);
            }
        })
        .catch(error => {
            this.error = error
        });
    }

    formatField(value, dataType, currencyCode) {
        let fieldValue;
        switch (dataType) {
            case DATA_TYPE_PERCENT:
                fieldValue = value + '%';
                break;
            case DATA_TYPE_CURRENCY:
                fieldValue = value != null ? (CURRENCY_SIGNS_BY_CODES[currencyCode] + ' ' + value) : value;
                break;
            default:
                fieldValue = '' + value;
                break;
        }
        return fieldValue;
    }
}