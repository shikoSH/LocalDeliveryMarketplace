/* 4.2 c 
Average rating and number of feedbacks of every business (NULL and 0 if none).
Type: View
Name: BusinessRatingsSummary
Input: Nothing
Output: Table (business_id, business_name, avg_rating, ratings_count)
*/ 

CREATE VIEW BusinessRatingsSummary
AS 
SELECT B.business_id, B.name AS business_name, AVG(rating) AS avg_rating, COUNT(rating) AS ratings_count
FROM Feedback F
INNER JOIN SubOrder S ON S.suborder_id = F.suborder_id
INNER JOIN Business B ON S.business_id = B.business_id

/* 4.2 f 
Every rider with the number of Delivered deliveries (0 if none) and the average rider rating (NULL if
none).
Type: View
Name: RiderPerformanceSummary
Input: Nothing
Output: Table (rider_id, rider_name, zone_name, completed_deliveries, avg_rating)
*/

SELECT R.rider_id
FROM Delivery D