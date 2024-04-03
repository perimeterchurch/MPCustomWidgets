SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[api_custom_GroupWidget]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[api_custom_GroupWidget] AS' 
END
GO

-- =============================================
-- Description:	This stored procedure returns details for a Mission Trip based on a selection from the Mission Trip Finder custom widget.
-- Create date: 2/19/2024
-- Author:		Dana Barry
-- =============================================
ALTER PROCEDURE [dbo].[api_custom_Mission_Trip_Detail_Widget]
	@DomainID INT,
	@Username NVARCHAR(75) = null,
	@TripID INT
	
AS
BEGIN
	/* DATASET 1 */
	SELECT PC.Pledge_Campaign_ID
			, Nickname
			, FORMAT(PC.Trip_Start_Date, 'MMMM dd, yyyy') AS Start_Date
			, FORMAT(PC.Trip_End_Date, 'MMMM dd, yyyy') AS End_Date
			, JD.Destination_Name
			, JD.Website_Banner AS Link
			, Long_Description
	FROM Pledge_Campaigns PC 
	INNER JOIN Journey_Destinations JD ON JD.Journey_Destination_ID = PC.Journey_Destination_ID
	WHERE Pledge_Campaign_Type_ID = 2
	AND YEAR(PC.End_Date) = YEAR(GETDATE())
	AND PC.Pledge_Campaign_ID = @TripID
	ORDER BY PC.Trip_Start_Date
	
	/* DATASET 2 */
	SELECT PC.Pledge_Campaign_ID
			, Pledge_ID
			, CASE WHEN P.Beneficiary IS NULL THEN First_Name + ' ' + Last_Name 
					ELSE P.Beneficiary
			  END AS Full_Name
			, 'https://ministryplatform.perimeter.org/ministryplatformapi/Api.svc/rst/getfile?dn=' + CONVERT(Varchar(40),D.Domain_GUID) + '&fn=' + Convert(Varchar(40), F.Unique_Name) AS Photo_URL
	FROM Pledges P
	INNER JOIN Pledge_Campaigns PC ON PC.Pledge_Campaign_ID = P.Pledge_Campaign_ID
	INNER JOIN Contacts C ON C.Donor_Record = P.Donor_ID
	LEFT JOIN dp_Files F ON F.Record_ID = C.Contact_ID AND F.Default_Image = 1
	INNER JOIN dp_Domains D ON D.Domain_ID = P.Domain_ID
	WHERE PC.Pledge_Campaign_Type_ID = 2
	AND C.Contact_ID <> 2
	AND PC.Pledge_Campaign_ID = @TripID
	AND P.Pledge_Status_ID <> 3
	ORDER BY Last_Name

END



-- ========================================================================================
-- SP MetaData Install
-- ========================================================================================
DECLARE @spName nvarchar(128) = 'api_custom_Mission_Trip_Detail_Widget'
DECLARE @spDescription nvarchar(500) = 'Custom Widget SP for returning details of a Mission Trips'

IF NOT EXISTS (SELECT API_Procedure_ID FROM dp_API_Procedures WHERE Procedure_Name = @spName)
BEGIN
	INSERT INTO dp_API_Procedures
	(Procedure_Name, Description)
	VALUES
	(@spName, @spDescription)	
END


DECLARE @AdminRoleID INT = (SELECT Role_ID FROM dp_Roles WHERE Role_Name='Administrators')
IF NOT EXISTS (SELECT * FROM dp_Role_API_Procedures RP INNER JOIN dp_API_Procedures AP ON AP.API_Procedure_ID = RP.API_Procedure_ID WHERE AP.Procedure_Name = @spName AND RP.Role_ID=@AdminRoleID)
BEGIN
	INSERT INTO dp_Role_API_Procedures
	(Domain_ID,  API_Procedure_ID, Role_ID)
	VALUES
	(1, (SELECT API_Procedure_ID FROM dp_API_Procedures WHERE Procedure_Name = @spName), @AdminRoleID)
END

