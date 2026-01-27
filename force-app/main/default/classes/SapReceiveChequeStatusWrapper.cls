/********************************************************************************************************
NAME:			SapReceiveChequeStatusWrapper
AUTHOR:			Chris Hsu (chrishsu@starlux-airlines.com)
PURPOSE:		This is a input Class for SapReceiveChequeStatusApi.
UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
2021/12/27      Chris Hsu		First version
********************************************************************************************************/
public class SapReceiveChequeStatusWrapper {
    public String businessNumber;
    public String chequeNo;
    public String chequeStatus;
    public Double amount;

    public static List<SapReceiveChequeStatusWrapper> deserializeJson(String json) {
        return (List<SapReceiveChequeStatusWrapper>) System.JSON.deserialize(json, List<SapReceiveChequeStatusWrapper>.class);
    }

    public Boolean isMissingRequiredFields() {
        if (this.businessNumber == '' || this.chequeNo == '' || this.chequeStatus == '' || this.businessNumber == null || this.chequeNo == null || this.chequeStatus == null) {
            return true;
        }
        return false;
    }
}