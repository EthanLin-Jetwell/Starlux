/**
 * @description Interface for TravellerInfo__c database operations
 * @author STARLUX Development Team
 * @date 2024
 */
public interface ITravellerRepository {
    
    /**
     * @description Find travellers based on query criteria
     * @param query Repository query parameters
     * @return List of traveller records
     */
    List<TravellerInfo__c> findTravellers(RepositoryQuery query);
    
    /**
     * @description Find travellers by seat assignment
     * @param seatCode Seat code
     * @return List of travellers assigned to seat
     */
    List<TravellerInfo__c> findTravellersBySeat(String seatCode);
    
    /**
     * @description Update traveller records
     * @param travellers List of travellers to update
     * @return Success status
     */
    Boolean updateTravellers(List<TravellerInfo__c> travellers);
    
    /**
     * @description Create new traveller records
     * @param travellers List of travellers to create
     * @return Success status
     */
    Boolean createTravellers(List<TravellerInfo__c> travellers);
    
    /**
     * @description Delete traveller records
     * @param travellers List of travellers to delete
     * @return Success status
     */
    Boolean deleteTravellers(List<TravellerInfo__c> travellers);
    
    /**
     * @description Get traveller count for query (without LIMIT)
     * @param query Repository query parameters
     * @return Count of matching records
     */
    Integer getTravellerCount(RepositoryQuery query);
}