/**
 * @description Traveller Repository Implementation
 * @author STARLUX Development Team
 * @date 2024
 */
public class TravellerRepository implements ITravellerRepository {
    
    /**
     * @description Find travellers based on query criteria
     * @param query Repository query parameters
     * @return List of traveller records
     */
    public List<TravellerInfo__c> findTravellers(RepositoryQuery query) {
        try {
            if (query == null || !query.isValid()) {
                return new List<TravellerInfo__c>();
            }
            
            // Build dynamic SOQL query
            String soqlQuery = buildSOQLQuery(query);
            System.debug('Executing SOQL: ' + soqlQuery);
            
            return Database.query(soqlQuery);
            
        } catch (Exception e) {
            System.debug('Error in findTravellers: ' + e.getMessage());
            return new List<TravellerInfo__c>();
        }
    }
    
    /**
     * @description Find travellers by seat assignment
     * @param seatCode Seat code
     * @return List of travellers assigned to seat
     */
    public List<TravellerInfo__c> findTravellersBySeat(String seatCode) {
        try {
            if (String.isBlank(seatCode)) {
                return new List<TravellerInfo__c>();
            }
            
            return [
                SELECT Id, PNR__c, 
                       LastName__c, FirstName__c, Title__c, Gender__c,
                       Country__c, DateOfBirth__c, PassengerType__c,
                       PassportNumber__c, PassportExpiryDate__c, PassportIssuingCountry__c,
                       DepartureLocation__c, US_Bound__c, Seat__c,
                       VisaNumber__c, VisaExpiryDate__c, VisaIssuingCountry__c,
                       USAStreet__c, USACity__c, USAState__c, USAZipCode__c,
                       USAEmergencyContactName__c, USAEmergencyContactNationality__c, USAEmergencyContactPhone__c
                FROM TravellerInfo__c 
                WHERE Seat__c = :seatCode
                ORDER BY PTOrderBy__c ASC, PassengerTypeOrderBy__c ASC
            ];
            
        } catch (Exception e) {
            System.debug('Error in findTravellersBySeat: ' + e.getMessage());
            return new List<TravellerInfo__c>();
        }
    }
    
    /**
     * @description Update traveller records
     * @param travellers List of travellers to update
     * @return Success status
     */
    public Boolean updateTravellers(List<TravellerInfo__c> travellers) {
        try {
            if (travellers == null || travellers.isEmpty()) {
                return false;
            }
            
            update travellers;
            return true;
            
        } catch (Exception e) {
            System.debug('Error in updateTravellers: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Create new traveller records
     * @param travellers List of travellers to create
     * @return Success status
     */
    public Boolean createTravellers(List<TravellerInfo__c> travellers) {
        try {
            if (travellers == null || travellers.isEmpty()) {
                return false;
            }
            
            insert travellers;
            return true;
            
        } catch (Exception e) {
            System.debug('Error in createTravellers: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Delete traveller records
     * @param travellers List of travellers to delete
     * @return Success status
     */
    public Boolean deleteTravellers(List<TravellerInfo__c> travellers) {
        try {
            if (travellers == null || travellers.isEmpty()) {
                return false;
            }
            
            delete travellers;
            return true;
            
        } catch (Exception e) {
            System.debug('Error in deleteTravellers: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Build SOQL query from repository query parameters
     * @param query Repository query
     * @return SOQL query string
     */
    private String buildSOQLQuery(RepositoryQuery query) {
        // Base SELECT clause - using correct field names from SeatSelectionController
        String selectClause = 'SELECT Id, PNR__c, FlightNumber__c, ' +
                             'LastName__c, FirstName__c, Title__c, Gender__c, ' +
                             'Country__c, DateOfBirth__c, PassengerType__c, ' +
                             'PassportNumber__c, PassportExpiryDate__c, PassportIssuingCountry__c, ' +
                             'DepartureLocation__c, Destination__c, US_Bound__c, Seat__c, ' +
                             'VisaNumber__c, VisaExpiryDate__c, VisaIssuingCountry__c, ' +
                             'USAStreet__c, USACity__c, USAState__c, USAZipCode__c, ' +
                             'USAEmergencyContactName__c, USAEmergencyContactNationality__c, USAEmergencyContactPhone__c, ' +
                             'DepartureDate__c, DepartureLocationGMTLocal__c, BookingClass__c, External_ID__c';
        
        String fromClause = 'FROM TravellerInfo__c';
        
        // Build WHERE clause
        List<String> whereConditions = new List<String>();
        
        // Note: Active__c field is not used in SeatSelectionController, removing this condition
        
        // PNR codes condition
        if (query.hasPNRCriteria()) {
            List<String> quotedPNRs = new List<String>();
            for (String pnr : query.pnrCodes) {
                quotedPNRs.add('\'' + String.escapeSingleQuotes(pnr) + '\'');
            }
            whereConditions.add('PNR__c IN (' + String.join(quotedPNRs, ',') + ')');
        }
        
        // External IDs condition
        if (query.hasExternalIdCriteria()) {
            List<String> quotedIds = new List<String>();
            for (String extId : query.externalIds) {
                quotedIds.add('\'' + String.escapeSingleQuotes(extId) + '\'');
            }
            whereConditions.add('External_ID__c IN (' + String.join(quotedIds, ',') + ')');
        }
        
        // Flight criteria - Note: FlightNumber__c is not directly queried in controller's main query
        // Removing this condition as it's not used in the controller pattern
        
        // Date range condition using DepartureLocationGMTLocal__c (matches controller pattern)
        if (query.departureDate != null) {
            DateTime startOfDay = DateTime.newInstance(
                query.departureDate.year(),
                query.departureDate.month(),
                query.departureDate.day(),
                0, 0, 0
            );
            DateTime endOfDay = startOfDay.addDays(1).addSeconds(-1);
            
            whereConditions.add('DepartureLocationGMTLocal__c >= ' + startOfDay.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
            whereConditions.add('DepartureLocationGMTLocal__c <= ' + endOfDay.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
        }
        
        if (String.isNotBlank(query.departureLocation)) {
            whereConditions.add('DepartureLocation__c = \'' + String.escapeSingleQuotes(query.departureLocation) + '\'');
        }
        
        String whereClause = '';
        if (!whereConditions.isEmpty()) {
            whereClause = 'WHERE ' + String.join(whereConditions, ' AND ');
        }
        
        // Build ORDER BY clause - matching controller's ordering
        String orderByClause = '';
        if (String.isNotBlank(query.orderBy)) {
            orderByClause = 'ORDER BY ' + query.orderBy;
        } else {
            orderByClause = 'ORDER BY PTOrderBy__c ASC, PassengerTypeOrderBy__c ASC'; // Matches controller pattern
        }
        
        // Build LIMIT clause
        String limitClause = '';
        if (query.limitSize != null && query.limitSize > 0) {
            limitClause = 'LIMIT ' + query.limitSize;
        }
        
        // Combine all clauses
        List<String> queryParts = new List<String>{selectClause, fromClause};
        
        if (String.isNotBlank(whereClause)) {
            queryParts.add(whereClause);
        }
        
        if (String.isNotBlank(orderByClause)) {
            queryParts.add(orderByClause);
        }
        
        if (String.isNotBlank(limitClause)) {
            queryParts.add(limitClause);
        }
        
        return String.join(queryParts, ' ');
    }
    
    /**
     * @description Get traveller count for query (without LIMIT)
     * @param query Repository query parameters
     * @return Count of matching records
     */
    public Integer getTravellerCount(RepositoryQuery query) {
        try {
            if (query == null) {
                return 0;
            }
            
            // Build count query (similar to main query but with COUNT())
            String countQuery = buildCountQuery(query);
            System.debug('Executing count SOQL: ' + countQuery);
            
            return Database.countQuery(countQuery);
            
        } catch (Exception e) {
            System.debug('Error in getTravellerCount: ' + e.getMessage());
            return 0;
        }
    }
    
    /**
     * @description Build COUNT SOQL query
     * @param query Repository query
     * @return COUNT SOQL query string
     */
    private String buildCountQuery(RepositoryQuery query) {
        String selectClause = 'SELECT COUNT()';
        String fromClause = 'FROM TravellerInfo__c';
        
        // Build WHERE clause (same as main query)
        List<String> whereConditions = new List<String>();
        
        // Note: Active__c field is not used in SeatSelectionController, removing this condition
        
        if (query.hasPNRCriteria()) {
            List<String> quotedPNRs = new List<String>();
            for (String pnr : query.pnrCodes) {
                quotedPNRs.add('\'' + String.escapeSingleQuotes(pnr) + '\'');
            }
            whereConditions.add('PNR__c IN (' + String.join(quotedPNRs, ',') + ')');
        }
        
        if (query.hasExternalIdCriteria()) {
            List<String> quotedIds = new List<String>();
            for (String extId : query.externalIds) {
                quotedIds.add('\'' + String.escapeSingleQuotes(extId) + '\'');
            }
            whereConditions.add('External_ID__c IN (' + String.join(quotedIds, ',') + ')');
        }
        
        // Date range condition using DepartureLocationGMTLocal__c
        if (query.departureDate != null) {
            DateTime startOfDay = DateTime.newInstance(
                query.departureDate.year(),
                query.departureDate.month(),
                query.departureDate.day(),
                0, 0, 0
            );
            DateTime endOfDay = startOfDay.addDays(1).addSeconds(-1);
            
            whereConditions.add('DepartureLocationGMTLocal__c >= ' + startOfDay.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
            whereConditions.add('DepartureLocationGMTLocal__c <= ' + endOfDay.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
        }
        
        if (String.isNotBlank(query.departureLocation)) {
            whereConditions.add('DepartureLocation__c = \'' + String.escapeSingleQuotes(query.departureLocation) + '\'');
        }
        
        String whereClause = '';
        if (!whereConditions.isEmpty()) {
            whereClause = 'WHERE ' + String.join(whereConditions, ' AND ');
        }
        
        List<String> queryParts = new List<String>{selectClause, fromClause};
        if (String.isNotBlank(whereClause)) {
            queryParts.add(whereClause);
        }
        
        return String.join(queryParts, ' ');
    }
}