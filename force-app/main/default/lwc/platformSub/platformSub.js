import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';

export default class PlatformSub extends LightningElement {
    @track channelName = '/event/Test__e';
    @track notifications = [];

    subscription = {};

    connectedCallback() {
        // Configure default error handler
        onError((error) => {
            this.dispatchEvent(
                new ShowToastEvent({
                    variant: 'error',
                    title: 'EMP API Error',
                    message: "Check your browser's developer console for more details."
                })
            );
            console.error('EMP API error reported by server: ', JSON.stringify(error));
        });

        // Subscribe to platform events
        this.handleSubscribe();
    }

    handleSubscribe() {
        const messageCallback = (event) => {
            this.handleNotificationEvent(event);
        };

        subscribe(this.channelName, -1, messageCallback).then((response) => {
            this.subscription = response;
            this.dispatchEvent(
                new ShowToastEvent({
                    variant: 'success',
                    title: 'Ready to receive notifications'
                })
            );
            console.log('Subscribed to channel ', JSON.stringify(response));
        });
    }

    handleNotificationEvent(event) {
        // Show notification message as a toast
        this.dispatchEvent(
            new ShowToastEvent({
                variant: 'info',
                title: 'new account'
            })
        );
    }

    disconnectedCallback() {
        // Unsubscribe when component is destroyed
        unsubscribe(this.subscription, (response) => {
            console.log('Unsubscribed from channel ', JSON.stringify(response));
        });
    }
}