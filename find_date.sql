USE [db]
GO
/****** Object:  UserDefinedFunction [dbo].[find_date]    Script Date: 2022/9/10 下午 10:42:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER FUNCTION [dbo].[find_date](@NumberOfDay int, @Date date, @include int, @forward int) 

RETURNS @result TABLE 
(
	date date NOT NULL,
	day_of_stock int NOT NULL,
	other nvarchar(255)
)
AS
BEGIN

DECLARE @remaining_day int;
DECLARE @current_day int;
DECLARE @current_year INT
DECLARE @current_total_day INT

SELECT @current_day = day_of_stock FROM [dbo].[calendar] WHERE date = @Date AND day_of_stock != -1;
if(@current_day is NULL) RETURN

IF(@forward = 0) BEGIN
	SET @remaining_day = @current_day - @NumberOfDay + 1;

	IF(@remaining_day > 0)
		IF(@include = 1)
			INSERT @result
			SELECT * FROM [dbo].[calendar] WHERE day_of_stock BETWEEN @remaining_day AND @current_day AND year(date) = year(@Date);
		ELSE
			INSERT @result
			SELECT * FROM [dbo].[calendar] WHERE day_of_stock BETWEEN @remaining_day-1 AND @current_day-1 AND year(date) = year(@Date);
	ELSE 
		BEGIN
			IF(@include = 1)
				INSERT @result
				SELECT * FROM [dbo].[calendar] WHERE day_of_stock BETWEEN 0 AND @current_day AND year(date) = year(@Date);
			ELSE
				INSERT @result
				SELECT * FROM [dbo].[calendar] WHERE day_of_stock BETWEEN 0 AND @current_day-1 AND year(date) = year(@Date);



			DECLARE cur CURSOR LOCAL for
			SELECT year, total_day FROM [dbo].[year_calendar] order by year DESC
			open cur

			FETCH next from cur into @current_year, @current_total_day
			FETCH next from cur into @current_year, @current_total_day

			WHILE @@FETCH_STATUS = 0 BEGIN
				IF(@include = 0)
					SET @remaining_day = @remaining_day + @current_total_day - 1;
				ELSE
					SET @remaining_day = @remaining_day + @current_total_day;

				IF @remaining_day > 0 
					BEGIN
						INSERT @result
						SELECT * FROM [dbo].[calendar] WHERE day_of_stock BETWEEN @remaining_day AND @current_total_day AND year(date) = @current_year;
						BREAK
					END
				ELSE
					INSERT @result
					SELECT * FROM [dbo].[calendar] WHERE day_of_stock BETWEEN 0 AND @current_total_day AND year(date) = @current_year;

				FETCH next from cur into @current_year, @current_total_day
			END
		END
	END

ELSE BEGIN
	SET @remaining_day = @current_day + @NumberOfDay - 1;

	IF(@include = 1)
		INSERT @result
		SELECT * FROM [dbo].[calendar] WHERE day_of_stock BETWEEN @current_day AND @remaining_day AND year(date) = year(@Date);
	ELSE
		INSERT @result
		SELECT * FROM [dbo].[calendar] WHERE day_of_stock BETWEEN @current_day+1 AND @remaining_day+1 AND year(date) = year(@Date);

	
	DECLARE cur CURSOR LOCAL for
			SELECT year, total_day FROM [dbo].[year_calendar] order by year ASC
			open cur

			FETCH next from cur into @current_year, @current_total_day

			WHILE @@FETCH_STATUS = 0 BEGIN

				IF @current_year < year(@Date)-1 BEGIN
					FETCH next from cur into @current_year, @current_total_day
					CONTINUE 
				END

				
				IF(@include = 0)
					SET @remaining_day = @remaining_day - @current_total_day + 1;
				ELSE
					SET @remaining_day = @remaining_day - @current_total_day;

				IF @remaining_day > 0
					INSERT @result
					SELECT * FROM [dbo].[calendar] WHERE day_of_stock BETWEEN 0 AND @remaining_day AND year(date) = @current_year+1;
				ElSE
					BREAK

				FETCH next from cur into @current_year, @current_total_day
			END
	
	END

	RETURN

END