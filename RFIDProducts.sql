USE [BMS]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[RFIDProducts]') AND type in (N'P', N'PC'))
      DROP PROCEDURE [dbo].[RFIDProducts]

GO

CREATE PROCEDURE [dbo].[RFIDProducts]
      @LastRunDate SMALLDATETIME, @FullFile BIT
AS
-- ==========================================================================================
-- Author:        David Hostler
-- Create date:   3/13/2014
-- Description:   This proc returns the dataset that RFID uses to refresh its product data daily.
-- ==========================================================================================
-- Modifications
-- Date			WO Num	Author			Description
-- ==========================================================================================
-- ==========================================================================================

BEGIN
SET NOCOUNT ON

	IF @FullFile = 1
	BEGIN
		SET @LastRunDate = '1900-01-01' --This is intended to improve performance when producing the entire file.
	END

	SELECT CASE
             WHEN pm.ShortDescription <> ''
                   OR pm.ShortDescription <> NULL THEN pm.ShortDescription
             ELSE pm.[Description]
           END                                        AS [ProductName]
           , ucr.Prefix + ucr.Number + ucr.CheckDigit AS [SKU]
           , pm.SKU                                   AS [ItemSKU]
           , ucr.SizeColumn                           AS [Size]
           , pm.FullColor                             AS [Color]
           , pd.[Description]                         AS [Department]
           , pc2.[Description]                        AS [Category]
           , ps3.[Description]                        AS [Silhouette]
           , pt.[Description]                         AS [Team]
           , vm.ShortName                             AS [Manufacturer]
           , CASE
               WHEN pp.Markdown = 1 THEN pp.MarkdownPrice
               ELSE pp.RetailPrice
             END                                      AS [RetailPrice]
    FROM   dbo.ProductMaster AS pm WITH (NOLOCK)
           INNER JOIN dbo.UPCCrossReference AS ucr WITH (NOLOCK)
                   ON pm.SKU = ucr.SKU
                      AND Len(ucr.CheckDigit) = 1
                      AND Len(ucr.Number) = 10
                      AND ISNUMERIC(ucr.Prefix) = 1
                      AND ISNUMERIC(ucr.Number) = 1
                      AND ISNUMERIC(ucr.CheckDigit) = 1
           INNER JOIN dbo.ProductDepartments AS pd WITH (NOLOCK)
                   ON pm.DepartmentId = pd.DepartmentID
           INNER JOIN dbo.ProductCategories AS pc2 WITH (NOLOCK)
                   ON pm.CategoryId = pc2.CategoryID
           INNER JOIN dbo.ProductStyles AS ps2 WITH (NOLOCK)
                   ON pm.StyleId = ps2.StyleID
           INNER JOIN dbo.ProductSilhouettes AS ps3 WITH (NOLOCK)
                   ON ps2.SilhouetteID = ps3.SilhouetteID
           INNER JOIN dbo.ProductTeams AS pt WITH (NOLOCK)
                   ON pm.TeamId = pt.TeamID
           INNER JOIN dbo.VendorMaster AS vm WITH (NOLOCK)
                   ON pm.Vendor = vm.Code
           INNER JOIN dbo.ProductPrices AS pp WITH (NOLOCK)
                   ON pm.SKU = pp.SKU
                      AND PriceZone = 1
    WHERE  pm.[Status] = 'A'
           AND pm.DateLastChanged > @LastRunDate 
    
END

GO
--if using BMS, use BMSWebUser as the user group
GRANT EXECUTE ON [RFIDProducts] TO BMSWebUser 
GO
