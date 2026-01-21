import { LightningElement } from 'lwc';
import LOCALE from "@salesforce/i18n/locale";
import CURRENCY from "@salesforce/i18n/currency";

export default class TestComponent extends LightningElement {
    myLocale = LOCALE;
    myCurrency = CURRENCY;
    employee = {
        firstname : 'Ethan',
        lastname : 'Lin',
        age : 50,
    };
    employs=[
        {
            firstname : 'Ethan',
            lastname : 'Lin',
            age : 50
        },
        {
            firstname : 'Aaron',
            lastname : 'Lin',
            age : 60
        }
    ];

    i = 0;

    get getEmployeeRank() {
        const RANK = this.employee.age >= 50? 'ONE': 'TWO';
        return RANK;
    }

    changed = false;

    statusChanged(event) {
        this.changed = event.target.checked;
    }
}