import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FileUploaderCompLwc extends LightningElement {
    @api recordId;
    fileData;
    isDisabled = false;

    // You may need to pass this from outside or fetch it based on recordId
    customerNo = '202506-012725'; 
    fileType = 'warranty'; // could also be network or bd

    openfileUpload(event) {
        const file = event.target.files[0];
        if (!file) return;

        this.fileData = {
            file,
            fileName: file.name
        };
    }

    async handleClick() {
        if (!this.fileData) {
            this.showToast('Error', '請選擇一個檔案上傳', 'error');
            return;
        }

        this.showToast('上傳中...', '正在上傳檔案，請稍候', 'info');
        this.isDisabled = true;

        try {
            const { file, fileName } = this.fileData;

            const formData = new FormData();
            formData.append('customer_no', this.customerNo);

            // Determine the field name based on fileType
            const fieldMap = {
                'warranty': 'warranty_image',
                'network': 'network_image',
                'bd': 'bd_image'
            };

            const fieldName = fieldMap[this.fileType];
            if (!fieldName) throw new Error('Invalid file type');

            formData.append(fieldName, file, fileName);

            const response = await fetch('https://napoleon-rd1.ichefpos.com/api/opera/post_contract_execution/', {
                method: 'POST',
                headers: {
                    'Authorization': 'Bearer NVHkmYpf61OzdMEfH8ORkufE'
                    // Note: Do NOT set Content-Type manually with FormData
                },
                body: formData
            });

            if (!response.ok) {
                const errorText = await response.text();
                throw new Error(`上傳失敗: ${response.status} - ${errorText}`);
            }

            const result = await response.json();
            console.log('Upload success:', result);

            this.showToast('成功', `${fileName} 上傳成功`, 'success');
            this.fileData = null;

        } catch (error) {
            console.error('Upload error:', error);
            this.showToast('Error', error.message || '檔案上傳失敗', 'error');
        } finally {
            this.isDisabled = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}