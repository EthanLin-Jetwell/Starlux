public with sharing class SiteIPController {
    public String visitorIP { get; private set; }
    public Map<String,String> all { get; private set; }
    public String xff { get; private set; }

    public SiteIPController() {
        Map<String,String> hdr = ApexPages.currentPage().getHeaders();
        all = hdr;
        String v = hdr.get('True-Client-IP');
        if (v == null) v = hdr.get('CF-Connecting-IP');
        if (v == null) v = hdr.get('X-Forwarded-For');
        if (v == null) v = hdr.get('X-Client-IP');
        xff = hdr.get('X-Forwarded-For');

        if (v != null) {
            // 依序嘗試每個（若是逗號清單）
            for (String part : v.split(',')) {
                String ip = part.trim();
                if (!String.isBlank(ip)) { visitorIP = ip; break; }
            }
        } else {
            visitorIP = hdr.get('REMOTE_ADDR');
        }
    }
}