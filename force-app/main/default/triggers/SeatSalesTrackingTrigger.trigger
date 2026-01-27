trigger SeatSalesTrackingTrigger on Seat_Sales_Tracking__c (before insert) {
	new SeatSalesTrackingTriggerHandler().run();
}