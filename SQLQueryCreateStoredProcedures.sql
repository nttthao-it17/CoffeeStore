USE QuanLyQuanCafe
GO 

-- Account

CREATE PROC USP_GetAccount
@userName NVARCHAR(100), @passWord NVARCHAR(100)
AS
BEGIN
	SELECT * FROM dbo.Account WHERE UserName = @userName AND PassWord = @passWord
END
GO

-- Get Food Table

CREATE PROC USP_GetFoodTable
AS
BEGIN
	SELECT * FROM dbo.FoodTable
END
GO

-- Bill

CREATE PROC USP_GetBill
@idTable INT
AS
BEGIN
	SELECT * FROM dbo.Bill WHERE idTable = @idTable
END
GO

-- BillInfo

CREATE PROC USP_GetBillInfo
@idBill INT
AS
BEGIN
	SELECT * FROM dbo.BillInfo WHERE idBill = @idBill
END
GO

-- Food - BillInfo - Bill

CREATE PROC USP_GetFood_Bill_InfoBill
@idTable INT
AS
BEGIN
	SELECT f.name, bi.count, f.price, f.price * bi.count AS intoMoney FROM dbo.Food AS f, dbo.BillInfo AS bi, dbo.Bill AS b
	WHERE f.id = bi.idFood AND bi.idBill = b.id AND b.idTable = @idTable AND b.status = 0
END
GO

-- Get Food Category

CREATE PROC USP_GetFoodCategory
AS
BEGIN
	SELECT * FROM dbo.FoodCategory
END
GO

-- Get Food Category By Name

CREATE PROC USP_Get_FoodCategory_By_Name
@name NVARCHAR(100)
AS
BEGIN
    SELECT * FROM dbo.FoodCategory WHERE name = @name
END
GO

-- Get Food By Food name

CREATE PROC USP_Get_Food_By_FoodName
@foodName NVARCHAR(100)
AS
BEGIN
	SELECT * FROM dbo.Food WHERE name = @foodName
END
GO

-- Get Table Food By name

CREATE PROC USP_Get_FoodTable_By_Name
@name NVARCHAR(100)
AS
BEGIN
    SELECT * FROM dbo.FoodTable WHERE name = @name
END
GO

-- Get Food by Category Id

CREATE PROC USP_Get_FoodByCategoryId
@categoryId INT
AS
BEGIN
	SELECT * FROM dbo.Food WHERE idCategory = @categoryId
END
GO

-- insert bill

CREATE PROC USP_Insert_Bill
@idTable INT
AS
BEGIN
	INSERT dbo.Bill
	(
	    DateCheckIn,
	    DateCheckOut,
	    idTable,
	    status,
	    totalPrice
	)
	VALUES
	(   GETDATE(), -- DateCheckIn - date
	    NULL, -- DateCheckOut - date
	    @idTable,         -- idTable - int
	    0,         -- status - int
	    0.0   -- totalPrice - float
	    )
END
GO

-- Insert_BillInfo

CREATE PROC USP_Insert_BillInfo
@idBill INT,
@idFood INT,
@count INT
AS
BEGIN
	DECLARE @isBillInfo INT = -1
	DECLARE @foodCount INT = 0

	SELECT @isBillInfo = id, @foodCount = count FROM dbo.BillInfo -- kiểm tra bill info có tồn tại chưa and lấy dữ liệu
	WHERE idBill = @idBill AND idFood = @idFood -- kiểm tra thông qua id bill và id food

	DECLARE @newCount INT = @foodCount + @count
	DECLARE @countCheck INT = 0

	IF (@isBillInfo > 0) -- bill info đã có
	BEGIN
		IF (@newCount > 0)
			UPDATE dbo.BillInfo SET count = @newCount -- cập nhập bill info
			WHERE idBill = @idBill AND idFood = @idFood
		ELSE
			DELETE dbo.BillInfo -- xóa bill info
			WHERE idBill = @idBill AND idFood = @idFood
			SELECT @countCheck = id FROM dbo.BillInfo -- kiểm tra bill info còn dữ liệu không, lưu dữ liệu vào @coutcheck
			IF (@countCheck = 0) -- khi bill info bị xóa trống sẽ cập nhập lại biến đếm
				DBCC CHECKIDENT(BillInfo, RESEED, 0)
	END 
	ELSE -- bill info chưa có
	BEGIN
	IF (@newCount > 0) -- đảm bảo số lượng thêm vào phải là số dương
		INSERT dbo.BillInfo -- thêm bill info mới
		(
			idBill,
			idFood,
			count
		)
		VALUES
		(  
			@idBill, -- idBill - int
			@idFood, -- idFood - int
			@count  -- count - int
		)
	END
END
GO

-- Insert Food Table

CREATE PROC USP_Insert_FoodTable
@name NVARCHAR(100)
AS
BEGIN
	DECLARE @idFoodTable INT = 0
	SELECT @idFoodTable = id FROM dbo.FoodTable WHERE name = @name

	IF (@idFoodTable = 0)
		INSERT dbo.FoodTable
		(
			name,
			status
		)
		VALUES
		(   @name, -- name - nvarchar(100)
			N'Trống'  -- status - nvarchar(100)
			)
END
GO

-- Update Food Table

CREATE PROC USP_Update_FoodTable
@id INT,
@name NVARCHAR(100)
AS
BEGIN
	DECLARE @idFoodTable INT = 0

	SELECT @idFoodTable = id FROM dbo.FoodTable WHERE name = @name

	IF (@idFoodTable = 0)
		UPDATE dbo.FoodTable SET name = @name WHERE id = @id
END
GO

-- Update bill

CREATE PROC USP_Update_Bill
@id INT,
@totalPrice FLOAT
AS
BEGIN
	UPDATE dbo.Bill SET status = 1, DateCheckOut = GETDATE(), totalPrice = @totalPrice WHERE id = @id
END
GO

-- Refresh table

CREATE PROC USP_Refresh_Table
@idTable INT 
AS
BEGIN
	UPDATE dbo.FoodTable SET status = N'Trống' WHERE id = @idTable AND status = N'Đã thanh toán'

	DECLARE @idBill INT
	DECLARE @dateCheckIn DATE
	DECLARE @dateCheckOut DATE
	DECLARE @totalPrice FLOAT
	DECLARE @count INT

	SELECT @idBill = id, @dateCheckIn = DateCheckIn, @dateCheckOut = DateCheckOut, @totalPrice = totalPrice FROM dbo.Bill WHERE status = 1 AND idTable = @idTable

	IF (@idBill > 0 AND @totalPrice > 0)
		INSERT dbo.BillSave
		(
			DateCheckIn,
			DateCheckOut,
			idTable,
			totalPrice
		)
		VALUES
		(   @dateCheckIn, -- DateCheckIn - date
			@dateCheckOut, -- DateCheckOut - date
			@idTable,         -- idTable - int
			@totalPrice        -- totalPrice - float
			)

	DELETE dbo.BillInfo WHERE idBill = @idBill
	DELETE dbo.Bill WHERE idTable = @idTable AND status = 1

	SELECT @count = COUNT(*) FROM dbo.BillInfo

	IF (@count = 0)
		DBCC CHECKIDENT(BillInfo, RESEED, 0)

	SELECT @count = COUNT(*) FROM dbo.Bill

	IF (@count = 0)
		DBCC CHECKIDENT(Bill, RESEED, 0)
END
GO

-- Get bill save

CREATE PROC USP_Get_BillSave
AS
BEGIN
	SELECT * FROM dbo.BillSave
END
GO

-- Get list bill by date

CREATE PROC USP_Get_List_Bill_By_Date
@dateCheckIn DATE,
@dateCheckOut DATE
AS
BEGIN
    SELECT IDENTITY(INT, 1, 1) AS [STT], b.DateCheckIn AS [Ngày vào], b.DateCheckOut AS [Ngày ra], t.name AS [Tên bàn], b.totalPrice AS [Tổng tiền]
	INTO #TableResult
	FROM dbo.BillSave AS b, dbo.FoodTable AS t
	WHERE b.DateCheckIn >= @dateCheckIn AND b.DateCheckOut <= @dateCheckOut AND b.idTable = t.id

	SELECT * FROM #TableResult
END
GO

-- Get Food Table Filter

CREATE PROC USP_Get_FoodTable_Filter
AS
BEGIN
	SELECT IDENTITY(INT, 1, 1) AS [STT], name AS [Tên bàn], status AS [Trạng thái]
	INTO #tableResult
	FROM dbo.FoodTable

	SELECT * FROM #tableResult
END
GO
 
-- Get Food Filter

CREATE PROC USP_Get_Food_Filter
AS
BEGIN
	SELECT IDENTITY(INT, 1, 1) AS [STT], f.name AS [Tên món], c.name AS [Danh mục], f.price AS [Giá]
	INTO #TableResult
	FROM dbo.Food AS f, dbo.FoodCategory AS c
	WHERE f.idCategory = c.id

	SELECT * FROM #TableResult
END
GO

-- Get Food Category filter

CREATE PROC USP_Get_Food_Category_Filter
AS
BEGIN
    SELECT IDENTITY(INT, 1, 1) AS [STT], name AS [Danh mục] INTO #TableResult FROM dbo.FoodCategory
	SELECT * FROM #TableResult
END
GO

-- Get Account filter

CREATE PROC USP_Get_Account_Filter
AS
BEGIN
    SELECT IDENTITY(INT, 1, 1) AS [STT], a.UserName AS [Tên tài khoản], a.DisplayName AS [Tên hiển thị], t.name AS [Loại tài khoản]
	INTO #TableResult
	FROM dbo.Account AS a, dbo.AccountType AS t
	WHERE a.Type = t.id
	SELECT * FROM #TableResult
END
GO

-- Get Account Type

CREATE PROC USP_Get_AccountType
AS
BEGIN
    SELECT * FROM dbo.AccountType
END
GO

-- Insert Food

CREATE PROC USP_Insert_Food
@name NVARCHAR(100),
@idCategory INT,
@price FLOAT
AS
BEGIN
	DECLARE @idFood INT = 0
	SELECT @idFood = id FROM dbo.Food WHERE name = @name -- kiểm tra tên món có tồn tại trong bảng không

	IF (@idFood = 0) -- món không có trong bảng thì thực hiện thêm mới
		INSERT dbo.Food
		(
			name,
			idCategory,
			price
		)
		VALUES
		(   @name, -- name - nvarchar(100)
			@idCategory,   -- idCategory - int
			@price  -- price - float
			)
END
GO

-- Insert Food Category

CREATE PROC USP_Insert_FoodCategory
@name NVARCHAR(100)
AS
BEGIN
	DECLARE @idFood INT = 0
	SELECT @idFood = id FROM dbo.FoodCategory WHERE name = @name

	IF (@idFood = 0)
		INSERT dbo.FoodCategory
		(
			name
		)
		VALUES
		(@name -- name - nvarchar(100)
			)
END
GO

-- Insert Account

CREATE PROC USP_Insert_Account
@userName VARCHAR(100),
@displayName NVARCHAR(100),
@type INT
AS
BEGIN
	DECLARE @count INT = 0
	SELECT @count = COUNT(UserName) FROM dbo.Account WHERE UserName = @userName
	
	IF (@count = 0)
		INSERT dbo.Account
		(
			UserName,
			DisplayName,
			PassWord,
			Type
		)
		VALUES
		(   @userName,  -- UserName - varchar(100)
			@displayName, -- DisplayName - nvarchar(100)
			'1',  -- PassWord - varchar(1000)
			@type    -- Type - int
			)
END
GO

-- Update Account

CREATE PROC USP_Update_Account
@nameAccount VARCHAR(100),
@userName VARCHAR(100),
@displayName NVARCHAR(100),
@type INT
AS
BEGIN
	DECLARE @userNameAccount VARCHAR(100) = ''
	DECLARE @displayNameAccount NVARCHAR(100)
	DECLARE @typeAccount INT

	SELECT @userNameAccount = UserName, @displayNameAccount = DisplayName, @typeAccount = Type
	FROM dbo.Account
	WHERE UserName = @userName

	IF (@userNameAccount = '')
		UPDATE dbo.Account SET UserName = @userName, DisplayName = @displayName, Type = @type WHERE UserName = @nameAccount
	ELSE
	    IF (@nameAccount = @userName)
			IF (@displayNameAccount <> @displayName OR @typeAccount <> @type)
				UPDATE dbo.Account SET UserName = @userName, DisplayName = @displayName, Type = @type WHERE UserName = @nameAccount
END
GO

-- Update Food

CREATE PROC USP_Update_Food
@id INT,
@name NVARCHAR(100),
@idCategory INT,
@price FLOAT
AS
BEGIN
	DECLARE @idFood INT = 0
	DECLARE @foodIdCategory INT
	DECLARE @foodPrice FLOAT

	SELECT @idFood = id, @foodIdCategory = idCategory, @foodPrice = price FROM dbo.Food WHERE name = @name  -- kiểm tra xem tên món có tồn tại trong bảng hay chưa, nếu đã tồn tại thì lấy id, id category, price tại món đó

	IF (@idFood = 0)
		UPDATE dbo.Food SET name = @name, idCategory = @idCategory, price = @price WHERE id = @id
	ELSE
		IF (@idFood = @id)
			IF (@foodIdCategory <> @idCategory OR @foodPrice <> @price)
				UPDATE dbo.Food SET name = @name, idCategory = @idCategory, price = @price WHERE id = @id
END
GO

-- Update Food Category

CREATE PROC USP_Update_FoodCategory
@id INT,
@name NVARCHAR(100)
AS
BEGIN
	DECLARE @idFoodCategory INT = 0
	SELECT @idFoodCategory = id FROM dbo.FoodCategory WHERE name = @name

	IF (@idFoodCategory = 0)
		UPDATE dbo.FoodCategory SET name = @name WHERE id = @id
END
GO

-- Delete Food by Id

CREATE PROC USP_Delete_Food_By_Id
@id INT
AS
BEGIN
	DELETE dbo.BillInfo WHERE idFood = @id
    DELETE dbo.Food WHERE id = @id

	DECLARE @count INT = 0

	SELECT @count = COUNT(id) FROM dbo.Food

	IF (@count = 0)
		DBCC CHECKIDENT(Food, RESEED, 0)

	SET @count = 0

	SELECT @count = COUNT(id) FROM dbo.BillInfo

	IF (@count = 0)
		DBCC CHECKIDENT(BillInfo, RESEED, 0)
END
GO

-- Delete Food Category By Id

CREATE PROC USP_Delete_FoodCategory_By_Id
@id INT
AS
BEGIN
	DECLARE @idFood INT = 0
	DECLARE @idBillInfo INT = 0

	SELECT @idFood = id FROM dbo.Food WHERE idCategory = @id
	SELECT @idBillInfo = id FROM dbo.BillInfo WHERE idFood = @idFood

	IF (@idFood = 0)
		DELETE dbo.FoodCategory WHERE id = @id
	ELSE
	BEGIN
		IF (@idBillInfo = 0)
		BEGIN
		    DELETE dbo.Food WHERE idCategory = @id
			DELETE dbo.FoodCategory WHERE id = @id
		END
		ELSE
		BEGIN
		    DELETE dbo.BillInfo WHERE idFood = @idFood
			DELETE dbo.Food WHERE idCategory = @id
			DELETE dbo.FoodCategory WHERE id = @id
		END
	END
	
	DECLARE @count INT = 0

	SELECT @count = COUNT(id) FROM dbo.FoodCategory

	IF (@count = 0)
		DBCC CHECKIDENT(FoodCategory, RESEED, 0)

	SELECT @count = COUNT(id) FROM dbo.Food

	IF (@count = 0)
		DBCC CHECKIDENT(Food, RESEED, 0)

	SELECT @count = COUNT(id) FROM dbo.BillInfo

	IF (@count = 0)
		DBCC CHECKIDENT(BillInfo, RESEED, 0)
END
GO

-- Delete Food Table

CREATE PROC USP_Delete_FoodTable_By_Id
@id INT
AS
BEGIN
	DECLARE @idBill INT = 0
	SELECT @idBill = id FROM dbo.Bill WHERE idTable = @id

	IF (@idBill = 0)
		DELETE dbo.FoodTable WHERE id = @id
	ELSE
	BEGIN
		DELETE dbo.BillInfo WHERE idBill = @idBill
		DELETE dbo.Bill WHERE idTable = @id
		DELETE dbo.FoodTable WHERE id = @id
	END 

	DECLARE @count INT = 0

	SELECT @count = COUNT(id) FROM dbo.FoodTable

	IF (@count = 0)
		DBCC CHECKIDENT(FoodTable, RESEED, 0)

	SET @count = 0
	SELECT @count = COUNT(id) FROM dbo.Bill

	IF (@count = 0)
		DBCC CHECKIDENT(Bill, RESEED, 0)

	SET @count = 0

	SELECT @count = COUNT(id) FROM dbo.BillInfo

	IF (@count = 0)
		DBCC CHECKIDENT(BillInfo, RESEED, 0)
END
GO

-- Delete Account

CREATE PROC USP_Delete_Account
@userName VARCHAR(100)
AS
BEGIN
	DECLARE @count INT = 0
	DECLARE @type INT

	SELECT @type = Type FROM dbo.Account WHERE UserName = @userName

	IF (@type = 2)
		DELETE dbo.Account WHERE UserName = @userName
	ELSE
	BEGIN
		SELECT @count = COUNT(*) FROM dbo.Account WHERE Type = 1
		IF (@count > 1)
			DELETE dbo.Account WHERE UserName = @userName
	END
END
GO

