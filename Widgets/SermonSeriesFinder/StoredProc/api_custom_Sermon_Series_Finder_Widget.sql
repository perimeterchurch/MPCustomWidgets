SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[api_custom_Sermon_Series_Finder_Widget]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[api_custom_Sermon_Series_Finder_Widget] AS' 
END
GO

-- =============================================
-- Description:	This stored procedure returns sermons series data for the sermon series finder custom widget.
-- Create date: 4/2/2024
-- Author:		Dana Barry
-- =============================================
ALTER PROCEDURE [dbo].[api_custom_Sermon_Series_Finder_Widget]
	@DomainID INT,
	@Username NVARCHAR(75) = null,
	@keyword NVARCHAR(50) = null,
	@Sermon_Series_Type INT = null

	
AS
BEGIN
	
	/* DATASET 1 */
	SELECT S.Title AS Sermon_Title
		, SS.Sermon_Series_ID
		, SS.Title AS Series_Title
		, CONVERT(nvarchar, S.Sermon_Date, 107) AS Sermon_Date
		, C.First_Name + ' ' + C.Last_Name AS Full_Name
		, S.Description
		, (SELECT SL.Link_URL 
			FROM Pocket_Platform_Sermon_Links SL 
			WHERE SL.Sermon_ID = S.Sermon_ID
			AND SL.Link_Type_ID = 1) AS Video_Link
		, (SELECT SL.Link_URL 
			FROM Pocket_Platform_Sermon_Links SL 
			WHERE SL.Sermon_ID = S.Sermon_ID
			AND SL.Link_Type_ID = 2) AS Audio_Link
	FROM Pocket_Platform_Sermons S
	INNER JOIN Pocket_Platform_Sermon_Series SS ON SS.Sermon_Series_ID = S.Series_ID
	INNER JOIN Pocket_Platform_Speakers SP ON SP.Speaker_ID = S.Speaker_ID
	INNER JOIN Contacts C ON C.Contact_ID = SP.Contact_ID
	WHERE S.Sermon_ID = (SELECT MAX(Sermon_ID) FROM Pocket_Platform_Sermons)
	AND SS.Sermon_Series_Type_ID = @Sermon_Series_Type
	;

	/* DATASET 2*/
	SELECT SS.Sermon_Series_ID
		, SS.Title AS Series_Title
		, CONVERT(nvarchar, MIN(S.sermon_date),107) AS [Start_Date]
		, CONVERT(nvarchar, MAX(S.sermon_date),107) AS [End_Date]
		, 'https://www.perimeter.org/images/thumbs/23452' AS Photo_URL
	FROM Pocket_Platform_Sermons S
	INNER JOIN Pocket_Platform_Sermon_Series SS ON S.Series_ID = SS.Sermon_Series_ID
	WHERE (@Sermon_Series_Type IS NULL OR @Sermon_Series_Type = SS.Sermon_Series_Type_ID)
	GROUP BY SS.Sermon_Series_ID, SS.Title
	ORDER BY MAX(S.Sermon_Date) DESC

END



-- ========================================================================================
-- SP MetaData Install
-- ========================================================================================
DECLARE @spName nvarchar(128) = 'api_custom_Sermon_Series_Finder_Widget'
DECLARE @spDescription nvarchar(500) = 'Custom Widget SP for returning sermon data served to the Sermon Finder'

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
