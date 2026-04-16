import { track, api, LightningElement } from "lwc";
//import queueFull from '@salesforce/label/c.queueFull';
import validateQueue from '@salesforce/apex/PrechatController.validateQueue';
import validateEmail from '@salesforce/apex/PrechatController.validateEmail';
import getMessage from '@salesforce/apex/PrechatController.getMessage';

export default class PrechatTest extends LightningElement {
    /**
    * Deployment configuration data.
    * @type {Object}
    */
    @api configuration = {};

    startConversationLabel;
    showStartButton = true;
    showEmailError = false;
    
    /*label = {
        queueFull: queueFull
    };*/

    errorMessage = '';

    isSubmitButtonDisabled = false;
    get prechatForm() {
        const forms = this.configuration.forms || [];
        return forms.find(form => form.formType === "PreChat") || {};
    }

    get prechatFormFields() {
        return this.prechatForm.formFields || [];
    }

    /**
    * Returns pre-chat form fields sorted by their display order.
    * @type {Object[]}
    */
    get fields() {
        let fields =  JSON.parse(JSON.stringify(this.prechatFormFields));
        this.addChoiceListValues(fields);
        return fields.sort((fieldA, fieldB) => fieldA.order - fieldB.order);
    }

    connectedCallback() {
        this.startConversationLabel = "Start Conversation";
    }

    /**
    * Adds values to choiceList (dropdown) fields.
    */
    addChoiceListValues(fields) {
        for (let field of fields) {
            if (field.type === "ChoiceList") {
                const valueList = this.configuration.choiceListConfig.choiceList.find(list => list.choiceListId === field.choiceListId) || {};
                field.choiceListValues = valueList.choiceListValues || [];
            }
        }
    }

    /**
    * Iterates over and validates each form field. Returns true if all the fields are valid.
    * @type {boolean}
    */
    isValid() {
        let isFormValid = true;
        this.template.querySelectorAll("c-custom-pre-chat-form-field").forEach(formField => {
            if (!formField.reportValidity()) {
                isFormValid = false;
            }

            /*const emailPattern = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\\.[a-zA-Z0-9-]+)*$";
            if (formField.name == "Email" && !emailPattern.test(formField.value)) {
                console.error("No");
                isFormValid = false;
            }
            console.error(emailPattern.test(formField.value));*/
        });
        return isFormValid;
    }

    /**
    * Gathers and submits pre-chat data to the app on start-conversation-button click.
    * @type {boolean}
    */
    async onStartConversationClick() {
        const prechatData = {};
        if (!this.isValid()) return;

        let languageValue;
        let emailValue;
        this.template.querySelectorAll('c-custom-pre-chat-form-field')
            .forEach(formField => {
                const value = String(formField.value);
                prechatData[formField.name] = value;
                if (formField.name === 'Language') languageValue = value;
                if (formField.name === 'Email') emailValue = value;
            });

        this.isSubmitButtonDisabled = true;
        this.queueErrorMessage = '';

        try {
            await validateQueue({ language: languageValue });
            await validateEmail({ language: languageValue, email:  emailValue});
            // No error thrown — safe to start
            this.dispatchEvent(new CustomEvent('prechatsubmit', { detail: { value: prechatData } }));

        } catch (error) {
            const errorCode = error?.body?.message;
            console.log(errorCode);
            if (errorCode === 'QUEUE_FULL' || errorCode === 'NOT_WORKING_HOURS' || errorCode === 'EMAIL_ERROR') {
                console.log(errorCode);
                this.errorMessage = await getMessage({ language: languageValue, type: errorCode });
                console.log(this.errorMessage);
            } else {
                this.errorMessage = 'Something went wrong. Please try again.';
            }

            this.showStartButton = false;
            if (errorCode === 'EMAIL_ERROR') {
                this.showStartButton = true;
                this.showEmailError = true;
            }
            
            this.isSubmitButtonDisabled = false;
        }
    }

    /*get inputType() {

        return this.fieldInfo.name === 'Email' ? 'email' : 'text';

    }

    get emailPattern() {

        return this.fieldInfo.name === 'Email'

            ? "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\\.[a-zA-Z0-9-]+)*$"

            : null;

    }
 

    handleStartChat() {
        const inputs = this.template.querySelectorAll('lightning-input');
    
        let isValid = true;
        inputs.forEach(input => {
            if (!input.checkValidity()) {
                input.reportValidity();
                isValid = false;
            }
        });
    
        if (!isValid) {
            return;
        }
    
        // Continue with pre-chat submission
        this.startChat();
    }*/
}