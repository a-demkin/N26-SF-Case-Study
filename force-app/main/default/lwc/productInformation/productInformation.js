import { LightningElement, api, track } from 'lwc';
import getProductInfo from '@salesforce/apex/ProductInfoController.getProductInfo';

const currencySignsByCodes = {
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
                product.productCardTitle = wrapper.productName + ' - ' + wrapper.homeCountry;
                product.featureFields.forEach(featureField => {
                    featureField.value = this.prepareField(featureField.dataType, featureField.value, product.currencyCode);
                });
                this.products.push(product);
            }
            console.log(this.products);
        })
        .catch(error => {
            console.log(error);
            this.error = error
        });
    }

    prepareField(dataType, value, currencyCode) {
        let fieldValue;
        switch (dataType) {
            case DATA_TYPE_PERCENT:
                fieldValue = value + '%';
                break;
            case DATA_TYPE_CURRENCY:
                fieldValue = value == null ? value : currencySignsByCodes[currencyCode] + ' ' + value;
                break;
            default:
                break;
        }
        return fieldValue;
    }
}