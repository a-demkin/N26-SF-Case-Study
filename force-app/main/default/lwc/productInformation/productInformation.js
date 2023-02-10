import { LightningElement, api, track } from 'lwc';
import getProductInfo from '@salesforce/apex/ProductInfoController.getProductInfo';

export default class ProductInformation extends LightningElement {
    @api recordId;
    error;
    @track products = [];

    connectedCallback() {
        getProductInfo({caseId: this.recordId})
        .then(productWrappers => {
            console.log(productWrappers);
            for (let wrapper of productWrappers) {
                if (wrapper.hasError) {
                    this.error = wrapper.errorMessage;
                    return;
                }
                let product = {};
                product = {...wrapper};
                product.productCardTitle = wrapper.productName + ' - ' + wrapper.homeCountry;
                this.products.push(product);
            }
            console.log(this.products);
        })
        .catch(error => {
            console.log(error);
            this.error = error
        });
    }

    // @wire(getProductInfo, {caseId: '$recordId'})
    // wiredProducts({ error, data }) {
    //     if (data) {
    //         let productWrappers = data;
    //         for (let wrapper of productWrappers) {
    //             if (wrapper.errorMessage) {
    //                 this.error = wrapper.errorMessage;
    //                 return;
    //             }
    //             this.products.push(wrapper);
    //         }
    //     }
    //     if (error) {
    //         this.error = error;
    //     }
    // }
}