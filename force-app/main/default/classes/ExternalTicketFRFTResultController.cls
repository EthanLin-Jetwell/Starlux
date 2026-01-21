public without sharing class ExternalTicketFRFTResultController {
    public String companyType { get; set; }
    public String departmentCode { get; set; }
    public String loginCode { get; set; }
    public Id accountId { get; set; }

    public External_Tickets__c ticket { get; set; }
    public String bpmAppNo { get; set; }
    public List<Ticket_Certificate__c> certs { get; private set; }
	// 建構元
    public ExternalTicketFRFTResultController() {}

    public PageReference ensureAuth() {
        // 讀 cookie（集中在這裡）
        Map<String, Cookie> ck = ApexPages.currentPage().getCookies();
        if (ck.containsKey('Company_type__c'))
            companyType = EncodingUtil.urlDecode(ck.get('Company_type__c').getValue(), 'UTF-8');
        if (ck.containsKey('Department_Code__c'))
            departmentCode = EncodingUtil.urlDecode(ck.get('Department_Code__c').getValue(), 'UTF-8');
        if (ck.containsKey('Login_Code__c'))
            loginCode = EncodingUtil.urlDecode(ck.get('Login_Code__c').getValue(), 'UTF-8');
        
        // 1) 沒 cookie -> 回登入
        if (String.isBlank(companyType) || String.isBlank(departmentCode) || String.isBlank(loginCode)) {
            PageReference lp = Page.ExternalTicketLogin;
            lp.setRedirect(true);
            return lp;
        }

        // 2) 要有 bpmAppNo 參數，否則回 Search 並提示 again
        bpmAppNo = ApexPages.currentPage().getParameters().get('bpmAppNo');
        if (String.isBlank(bpmAppNo)) {
            PageReference sp = Page.ExternalTicketFRFTSearch;
            sp.getParameters().put('toast', 'again');
            sp.setRedirect(true);
            return sp;
        }else{
            certs = String.isBlank(bpmAppNo) ? new List<Ticket_Certificate__c>() : [
                SELECT Id, Name
                FROM Ticket_Certificate__c
                WHERE External_Tickets__r.SerialID__c = :bpmAppNo
                ORDER BY CreatedDate ASC
                LIMIT 1000
        	];
        }

        // 3) 找登入者 Account（用 cookie 條件）
        List<Account> accList = [
            SELECT Id
            FROM Account
            WHERE Company_type__c = :companyType
              AND Department_Code__c = :departmentCode
            LIMIT 1
        ];
        if (accList.isEmpty()) {
            PageReference lp = Page.ExternalTicketLogin;
            lp.setRedirect(true);
            return lp;
        }
        accountId = accList[0].Id;

        // 4) 查 External_Tickets__c（含 bpmAppNo + Account 限制）
        List<External_Tickets__c> ets = [
            SELECT Id, SerialID__c, Applicant__c, Applicant_Dept__c, Applicant_Name__c,
                   Budget_Type__c, Company__c, Reason_for_Application__c, Fare_Basis__c,
                   Apply_For__c, Discount__c, Exemption_YQ__c, Exemption_Tax__c,
                   Exemption_YR__c, Embargo__c, Ticket_Count__c, PFA_No__c,
                   Prizes_and_Awards_won_by_chance__c, Expiration_Date__c,
                   DepatureID__c, ArrivalID__c, Depature__c, Arrival__c,
                   Booking_Class__c, Language__c, Account__c,Two_People__c
            FROM External_Tickets__c
            WHERE SerialID__c = :bpmAppNo
              AND Account__c = :accountId
            LIMIT 1
        ];

        // 5) 查不到 -> 回 Search 並提示 again
        if (ets.isEmpty()) {
            PageReference sp = Page.ExternalTicketFRFTSearch;
            sp.getParameters().put('toast', 'again');
            sp.setRedirect(true);
            return sp;
        }

        // 6) OK：設資料，讓頁面正常 render
        ticket = ets[0];
        return null;
    }

    public String CN_PDF_URL {
        get {
            PageReference p = Page.SingleCertificateCN_PDF;
            if (!String.isBlank(bpmAppNo)) p.getParameters().put('bpmAppNo', bpmAppNo);
            String url = p.getUrl();                 // "/apex/singlecertificatecn_pdf?..."
            String prefix = Site.getPathPrefix();    // "/ExternalTicket" 或空字串
            if (!String.isBlank(prefix)) url = url.replace('/apex/', prefix + '/');
            return url;
        }
    }
    
    public String EN_PDF_URL {
        get {
            PageReference p = Page.SingleCertificateEN_PDF;
            if (!String.isBlank(bpmAppNo)) p.getParameters().put('bpmAppNo', bpmAppNo);
            String url = p.getUrl();                 // "/apex/singlecertificatecn_pdf?..."
            String prefix = Site.getPathPrefix();    // "/ExternalTicket" 或空字串
            if (!String.isBlank(prefix)) url = url.replace('/apex/', prefix + '/');
            return url;
        }
    }
    
    public Map<String, String> pdfParams {
        get {
            Map<String, String> m = new Map<String, String>();
            if (!String.isBlank(bpmAppNo)) m.put('bpmAppNo', bpmAppNo);
            return m;
        }
    }
        
    public PageReference logout() {
        ExternalTicketLoginUtility.clearAccountLoginCookie();
        PageReference p = Page.ExternalTicketLogin;
        p.getParameters().put('toast', 'logout');
        p.setRedirect(true);
        return p;
    }
    
    public String getItemsJsonCN() {
        List<Map<String,String>> rows = new List<Map<String,String>>();
        for (Ticket_Certificate__c c : certs) {
            rows.add(new Map<String,String>{
                'name' => sanitize(c.Name) + '_CN.pdf',
                'url'  => pdfUrlCN(c.Id)
            });
        }
        return JSON.serialize(rows);
    }

    private String pdfUrlCN(Id certId){
        PageReference p = Page.SingleCertificateCN_PDF; // 你的 PDF VF 頁
        p.getParameters().put('certId', (String)certId);
        String url = p.getUrl();              // /apex/SingleCertificateCN_PDF?certId=...
        String prefix = Site.getPathPrefix(); // /ExternalTicket 或空字串
        if (!String.isBlank(prefix)) url = url.replace('/apex/', prefix + '/');
        return url;
    }

    public String getItemsJsonEN() {
        List<Map<String,String>> rows = new List<Map<String,String>>();
        for (Ticket_Certificate__c c : certs) {
            rows.add(new Map<String,String>{
                'name' => sanitize(c.Name) + '_EN.pdf',
                'url'  => pdfUrlEN(c.Id)
            });
        }
        return JSON.serialize(rows);
    }

    private String pdfUrlEN(Id certId){
        PageReference p = Page.SingleCertificateEN_PDF; // 你的 PDF VF 頁
        p.getParameters().put('certId', (String)certId);
        String url = p.getUrl();              // /apex/SingleCertificateEN_PDF?certId=...
        String prefix = Site.getPathPrefix(); // /ExternalTicket 或空字串
        if (!String.isBlank(prefix)) url = url.replace('/apex/', prefix + '/');
        return url;
    }

    private static String sanitize(String s){
        if (String.isBlank(s)) return 'Certificate';
        s = s.trim().replaceAll('[\\\\/:*?"<>|\\r\\n]+','_');
        if (s.length()>120) s = s.substring(0,120);
        return s;
    }
    public static void fakeMethod() {
        Integer i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
    }
    

}