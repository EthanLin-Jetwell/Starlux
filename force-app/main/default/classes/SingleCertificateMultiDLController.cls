public with sharing class SingleCertificateMultiDLController {
    public String bpmAppNo { get; private set; }
    public List<Ticket_Certificate__c> certs { get; private set; }

    public SingleCertificateMultiDLController() {
        bpmAppNo = ApexPages.currentPage().getParameters().get('bpmAppNo');
        certs = String.isBlank(bpmAppNo) ? new List<Ticket_Certificate__c>() : [
            SELECT Id, Name
            FROM Ticket_Certificate__c
            WHERE External_Tickets__r.SerialID__c = :bpmAppNo
            ORDER BY CreatedDate ASC
            LIMIT 1000
        ];
    }

    public String getItemsJson() {
        List<Map<String,String>> rows = new List<Map<String,String>>();
        for (Ticket_Certificate__c c : certs) {
            rows.add(new Map<String,String>{
                'name' => sanitize(c.Name) + '.pdf',
                'url'  => pdfUrl(c.Id)
            });
        }
        return JSON.serialize(rows);
    }

    private String pdfUrl(Id certId){
        PageReference p = Page.SingleCertificateCN_PDF; // 你的 PDF VF 頁
        p.getParameters().put('certId', (String)certId);
        String url = p.getUrl();              // /apex/SingleCertificateCN_PDF?certId=...
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
}