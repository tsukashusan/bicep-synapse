SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[仕入先]
( 
	[仕入先コード] [int]  NOT NULL,
	[フリガナ] [nvarchar](80)  NULL,
	[仕入先名] [nvarchar](40)  NOT NULL,
	[担当者名] [nvarchar](30)  NULL,
	[部署] [nvarchar](30)  NULL,
	[郵便番号] [nvarchar](10)  NULL,
	[トドウフケン] [nvarchar](30)  NULL,
	[都道府県] [nvarchar](15)  NULL,
	[住所1] [nvarchar](60)  NULL,
	[住所2] [nvarchar](60)  NULL,
	[電話番号] [nvarchar](24)  NULL,
	[ファクシミリ] [nvarchar](24)  NULL,
	[ホームページ] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	CLUSTERED COLUMNSTORE INDEX
)
GO

CREATE TABLE [dbo].[受注]
( 
	[受注コード] [int]  NOT NULL,
	[得意先コード] [int]  NULL,
	[社員コード] [int]  NULL,
	[出荷先名] [nvarchar](40)  NULL,
	[出荷先郵便番号] [nvarchar](10)  NULL,
	[出荷先都道府県] [nvarchar](20)  NULL,
	[出荷先住所1] [nvarchar](60)  NULL,
	[出荷先住所2] [nvarchar](60)  NULL,
	[運送区分] [nvarchar](40)  NULL,
	[受注日] [datetime]  NULL,
	[締切日] [datetime]  NULL,
	[出荷日] [datetime]  NULL,
	[運送料] [decimal](10,4)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

CREATE TABLE [dbo].[受注明細]
( 
	[受注コード] [int]  NOT NULL,
	[商品コード] [int]  NOT NULL,
	[単価] [decimal](10,4)  NOT NULL,
	[数量] [int]  NOT NULL,
	[割引] [decimal](10,4)  NOT NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO


CREATE TABLE [dbo].[商品]
( 
	[商品コード] [int]  NOT NULL,
	[フリガナ] [nvarchar](80)  NULL,
	[商品名] [nvarchar](200)  NOT NULL,
	[仕入先コード] [int]  NULL,
	[区分コード] [int]  NULL,
	[梱包単位] [nvarchar](20)  NULL,
	[単価] [decimal](10,4)  NULL,
	[在庫] [int]  NULL,
	[発注済] [nvarchar](20)  NULL,
	[発注点] [nvarchar](20)  NULL,
	[生産中止] [nvarchar](1)  NOT NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	CLUSTERED COLUMNSTORE INDEX
)
GO


CREATE TABLE [dbo].[商品区分]
( 
	[区分コード] [int]  NOT NULL,
	[区分名] [nvarchar](30)  NOT NULL,
	[説明] [nvarchar](4000)  NULL,
	[図] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	CLUSTERED COLUMNSTORE INDEX
)
GO

CREATE TABLE [dbo].[得意先]
( 
	[得意先コード] [int]  NOT NULL,
	[フリガナ] [nvarchar](40)  NULL,
	[得意先名] [nvarchar](40)  NOT NULL,
	[担当者名] [nvarchar](30)  NULL,
	[部署] [nvarchar](30)  NULL,
	[郵便番号] [nvarchar](10)  NULL,
	[トドウフケン] [nvarchar](30)  NULL,
	[都道府県] [nvarchar](15)  NULL,
	[住所1] [nvarchar](60)  NULL,
	[住所2] [nvarchar](60)  NULL,
	[電話番号] [nvarchar](24)  NULL,
	[ファクシミリ] [nvarchar](24)  NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	CLUSTERED COLUMNSTORE INDEX
)
GO


CREATE TABLE [dbo].[社員]
( 
	[社員コード] [int]  NOT NULL,
	[フリガナ] [nvarchar](80)  NULL,
	[氏名] [nvarchar](40)  NOT NULL,
	[在籍支社] [nvarchar](20)  NULL,
	[部署名] [nvarchar](30)  NULL,
	[誕生日] [datetime]  NULL,
	[入社日] [datetime]  NULL,
	[自宅郵便番号] [nvarchar](10)  NULL,
	[自宅都道府県] [nvarchar](40)  NULL,
	[自宅住所1] [nvarchar](60)  NULL,
	[自宅住所2] [nvarchar](60)  NULL,
	[自宅電話番号] [nvarchar](24)  NULL,
	[内線] [nvarchar](4)  NULL,
	[写真] [nvarchar](255)  NULL,
	[プロフィール] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	CLUSTERED COLUMNSTORE INDEX
)
GO

CREATE TABLE [dbo].[運送]
( 
	[運送コード] [int]  NOT NULL,
	[運送会社] [nvarchar](40)  NOT NULL,
	[電話番号] [nvarchar](24)  NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	CLUSTERED COLUMNSTORE INDEX
)
GO

CREATE TABLE [dbo].[都道府県]
( 
	[トドウフケン] [nvarchar](30)  NULL,
	[都道府県] [nvarchar](15)  NULL,
	[ローマ字] [nvarchar](200)  NULL,
	[地域名ローマ字] [nvarchar](200)  NULL,
	[地域] [nvarchar](10)  NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	CLUSTERED COLUMNSTORE INDEX
)
GO