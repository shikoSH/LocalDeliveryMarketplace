/* 4.2 c 
Average rating and number of feedbacks of every business (NULL and 0 if none).
Type: View
Name: BusinessRatingsSummary
Input: Nothing
Output: Table (business_id, business_name, avg_rating, ratings_count)
*/ 
GO
CREATE VIEW BusinessRatingsSummary
AS 
SELECT B.business_id, B.name AS business_name, AVG(rating) AS avg_rating, COUNT(rating) AS ratings_count
FROM Feedback F
INNER JOIN SubOrder S ON S.suborder_id = F.suborder_id
INNER JOIN Business B ON S.business_id = B.business_id
GO

/* 4.2 f 
Every rider with the number of Delivered deliveries (0 if none) and the average rider rating (NULL if
none).
Type: View
Name: RiderPerformanceSummary
Input: Nothing
Output: Table (rider_id, rider_name, zone_name, completed_deliveries, avg_rating)
*/

CREATE VIEW RiderPerformanceSummary
SELECT R.rider_id, U.first_name, U.middle_name, U.last_name, Z.zone_name, COUNT(delivered_at) AS completed_deliveries, AVG(rider_rating) AS avg_rating 
FROM Delivery D
INNER JOIN Rider R ON R.rider_id = D.rider_id
INNER JOIN Users U ON U.user_id = R.rider_id
INNER JOIN Zone Z ON Z.zone_id = R.zone_id
GO