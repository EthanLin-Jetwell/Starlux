public class CreateFlightTimeInvoker {
    public class SatNoInput {
        @InvocableVariable(required=true)
        public String satNo;
    }

    @InvocableMethod(label='Create Flight Time by SAT No')
    public static void run(List<SatNoInput> inputs) {
        if (inputs == null || inputs.isEmpty()) return;

        List<String> satNos = new List<String>();
        for (SatNoInput i : inputs) {
            if (i != null && String.isNotBlank(i.satNo))
                satNos.add(i.satNo);
        }
        if (satNos.isEmpty()) return;

        System.enqueueJob(new CreateFlightTimeQueueable(satNos));
    }
}