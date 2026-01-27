/********************************************************************************************************
NAME:			SapResponseChequeStatusWrapper
AUTHOR:			Chris Hsu (chrishsu@starlux-airlines.com)
PURPOSE:		This is a output Class for SapReceiveChequeStatusApi.
UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
2022/1/17      Chris Hsu		First version
********************************************************************************************************/
public class SapResponseChequeStatusWrapper {
    public String status;
    public String message;
    public List<chequeList> chequeList;
    public class chequeList{
        public String businessNumber;
        public String chequeNo;
        public String processStatus;
        public String remark;
    }

    public static List<SapResponseChequeStatusWrapper> deserializeJson(String json) {
        return (List<SapResponseChequeStatusWrapper>) System.JSON.deserialize(json, List<SapResponseChequeStatusWrapper>.class);
    }
}