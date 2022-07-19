/*

Cleaning Nashville (Tennessee) Housing data using SQL Queries

*/

USE SQL_DataClean_DB

SELECT *
FROM NashvilleHousing


-------------------------------------------------------------------------------------------------------

--Standardizing our Date Format 
--[Our 'SaleDate' column includes timestamps but no actual times are listed]


SELECT SaleDate, CONVERT(DATE,SaleDate)
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SaleDateNew DATE 

UPDATE NashvilleHousing
SET SaleDateNew = CONVERT(DATE,SaleDate)

SELECT *
FROM NashvilleHousing

--Remove old SaleDate column

ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate


---------------------------------------------------------------------------------------------------------

--Populate[Fill] Property Address data


SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL

SELECT *
FROM NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID


--I notice there are null values for certain property adresses, and these also correspond with the ParcelIDs
--Some addresses are listed MULTIPLE times, so I could populate parcelIDs with the PropertyAddress to fill in missing values

SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress
FROM NashvilleHousing as A
JOIN NashvilleHousing as B
	on A.ParcelID = B.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]  --SO ParcelID is the same but it's not the same row [UniqueID never repeats itself]
WHERE A.PropertyAddress IS NULL

--To populate data from the B.PropertyAddress 
--Data should be populated into a new column

SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress,B.PropertyAddress)
FROM NashvilleHousing as A
JOIN NashvilleHousing as B
	on A.ParcelID = B.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ] 
WHERE A.PropertyAddress IS NULL

--Populate data into A Table's column

UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress,B.PropertyAddress)
FROM NashvilleHousing as A
JOIN NashvilleHousing as B
	on A.ParcelID = B.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ] 
WHERE A.PropertyAddress IS NULL


----------------------------------------------------------------------------------------------------------

--Breaking Address into Individual Columns [Address, City, State)
--The PropertyAddress column contains the address along with the city and/or state, I want to put them in seperate columns 


SELECT PropertyAddress
FROM NashvilleHousing


--Use SUBSTRING to pull characters from the 1st value in our string until the comma(delimiter)

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) as Address 
FROM NashvilleHousing

--Getting rid of commas at the end of every address
--CHARINDEX is returning the 'position' of what it is you're looking for, so we can use -1 to subtract off final position which are commas

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address 
FROM NashvilleHousing

--To seperate City from Address[Notice there's +1 so it returns a space after delimiter and LEN because of diff string lengths]

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address 
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City 
FROM NashvilleHousing


--Can't seperate two values from one column without creating two more columns 

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255)

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)


ALTER TABLE NashvilleHousing
ADD PropertySPlitCity NVARCHAR(255) 

UPDATE NashvilleHousing
SET PropertySPlitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


SELECT *
FROM NashvilleHousing



--We could do the same for OwnerAddress Column using PARSENAME [returns specified part of an object name]

SELECT OwnerAddress
FROM NashvilleHousing


SELECT 
PARSENAME(OwnerAddress, 1)
FROM NashvilleHousing

--Doesn't work because PARSENAME works best with periods(we have commas) so we can REPLACE commas with periods

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousing

--Seperate into 3 seperate columns
--PARSENAME returns things backwards so instead of 1,2,3 do 3,2,1

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) as Address
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) as City
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) as State
FROM NashvilleHousing

--Add in new columns and values

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) 


ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) 


ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) 


SELECT * 
FROM NashvilleHousing


----------------------------------------------------------------------------------------------------------

--Change Y and N to Yes and No in "SoldAsVacant" column


--View all types of inputs in column

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) 
From NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

--Make changes to columns

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM NashvilleHousing


--Update SoldAsVacant column

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END

--Double-check if values updated

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) 
From NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


----------------------------------------------------------------------------------------------------------

--Remove Duplicates
--Have to find a way to find the duplicate rows [ROW_NUMBER and PARTITION BY] (PARTITION BY will divide the rows into smaller partitions)


--Create CTE so that we can filter data for 'row_num > 1' [Can't use where/order by function]

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDateNew,
				 LegalReference
				 ORDER BY
				 UniqueID
				 ) row_num
FROM NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

--Insert 'Delete' to Delete all values inside CTE

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDateNew,
				 LegalReference
				 ORDER BY
				 UniqueID
				 ) row_num
FROM NashvilleHousing
)
DELETE 
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress

--There should now be ZERO duplicate values


----------------------------------------------------------------------------------------------------------

--Delete Unused Columns


SELECT * 
FROM NashvilleHousing


ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress


/*

DATA SHOULD NOW BE CLEAN AND MORE USEABLE

*/
