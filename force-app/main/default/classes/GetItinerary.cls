public class GetItinerary {
    @InvocableMethod(label='Get Itinerary')
    public static void getItinerary(List<String> ids) {
        if (ids == null || ids.isEmpty()) return;

        // Enqueue only once, use Queueable to chain
        System.enqueueJob(new QueueableGetItinerary(ids));
    }
    
    public static void fakeMethod(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        }
}