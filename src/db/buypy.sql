DELIMITER //

-- DROP DATABASE IF EXISTS BuyPy
//

DELIMITER //
CREATE DATABASE IF NOT EXISTS BuyPy
//

DELIMITER //
USE BuyPy
//
/*--------------------------------------------------------
> CLIENT
---------------------------------------------------------*/
DROP TABLE IF EXISTS Client
//

DELIMITER //
CREATE TABLE `Client`(
	ID 			INT PRIMARY KEY AUTO_INCREMENT,
	firstname	VARCHAR(250) NOT NULL,
	surname		VARCHAR(250) NOT NULL,
	email		VARCHAR(250) NOT NULL UNIQUE,
	`password`	CHAR(64) NOT NULL, 
	address		 VARCHAR(100) NOT NULL,
	zip_code	 SMALLINT UNSIGNED NOT NULL,
	city		 VARCHAR(30) NOT NULL,
	country		 VARCHAR(30) NOT NULL DEFAULT 'Portugal',
	last_login	 TIMESTAMP NOT NULL DEFAULT(NOW()),
	phone_number VARCHAR(15) NOT NULL CHECK(phone_number RLIKE '^[0-9]{6,}$'),
	birthdate	 DATE NOT NULL,
	is_active	 BOOLEAN DEFAULT TRUE,

CONSTRAINT ClientEmailChk CHECK(email RLIKE "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
)//

/*TRIGGER > Associado a uma tabela que faz uma acção antes ou depois de qualquer coisa. */

/*--------------------------------------------------------
> TRIGGER BeforeNewClient
---------------------------------------------------------*/
DROP TRIGGER IF EXISTS BeforeNewClient
//

DELIMITER //
CREATE TRIGGER `BeforeNewClient`
	BEFORE INSERT ON `Client`
	FOR EACH ROW
	BEGIN
		CALL ValidateClient (NEW.phone_number, NEW.country, NEW.`password`);
	END//

/*--------------------------------------------------------
> TRIGGER BeforeUpdatingClient
---------------------------------------------------------*/
DROP TRIGGER IF EXISTS BeforeUpdatingClient
//

DELIMITER //
CREATE TRIGGER BeforeUpdatingClient BEFORE UPDATE ON `Client`
FOR EACH ROW
BEGIN
    CALL ValidateClient(NEW.phone_number, NEW.country, NEW.`password`);
END//

/*--------------------------------------------------------
> TRIGGER ValidateClient
---------------------------------------------------------*/
DROP PROCEDURE IF EXISTS ValidateClient
//

DELIMITER //
CREATE PROCEDURE `ValidateClient`(
    IN phone_number   VARCHAR(15),
    IN country        VARCHAR(30),
    INOUT `password`  CHAR(64)
)
BEGIN
    DECLARE INVALID_PHONE_NUMBER CONDITION FOR SQLSTATE '45000';
    DECLARE INVALID_PASSWORD CONDITION FOR SQLSTATE '45001';
    
    IF country = 'Portugal' AND LEFT(phone_number, 3) <> '351' THEN
        SIGNAL INVALID_PHONE_NUMBER
            SET MESSAGE_TEXT = 'Invalid phone number for Portugal';
    END IF;

    -- We have to this, and not with CHECK CONSTRAINT because
    -- by that time, the password is already hashed (see below)
    -- The password can only be hashed here, in this trigger.
    IF `password` NOT RLIKE "(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!$#?%]).{6,}" THEN
        SIGNAL INVALID_PASSWORD
            SET MESSAGE_TEXT = 'Invalid password';
    END IF;

    SET `password` := SHA2(`password`, 256);
END//

/*--------------------------------------------------------
> ORDER
---------------------------------------------------------*/
DELIMITER //
DROP TABLE IF EXISTS `Order`
//

DELIMITER //
CREATE TABLE `Order`(
	ID 							INT PRIMARY KEY AUTO_INCREMENT,
	date_time					DATETIME NOT NULL DEFAULT(NOW()),
	delivery_method				ENUM('regular', 'urgent') DEFAULT 'regular',
	`status`					ENUM('open', 'processing', 'pending', 'closed', 'cancelled') DEFAULT 'open',
	payment_card_number			BIGINT NOT NULL,
	payment_card_name			VARCHAR(20) NOT NULL,
	payment_card_expiration		DATE NOT NULL,
	client_id					INT NOT NULL,

	-- CONSTRAINT ExpirationDate CHECK(payment_card_expiration >= CURDATE()),
	FOREIGN KEY ClientFK (client_id) REFERENCES `Client`(id)
)//

/*--------------------------------------------------------
> TRIGGER ValidateOrder
---------------------------------------------------------*/
DROP TRIGGER IF EXISTS ValidateOrder
//

DELIMITER //
CREATE TRIGGER ValidadeteOrder BEFORE INSERT ON `Order`
FOR EACH ROW
BEGIN
	DECLARE INVALID_EXPIRATION_DATE CONDITION FOR SQLSTATE '45020';
	IF NEW.payment_card_expiration < CURDATE() THEN
			SIGNAL INVALID_EXPIRATION_DATE
				SET MESSAGE_TEXT = 'Invalid date card expiration';
	END IF;
END//

/*--------------------------------------------------------
> PRODUCT
---------------------------------------------------------*/
DELIMITER //
DROP TABLE IF EXISTS Product
//

DELIMITER //
CREATE TABLE Product(
	ID 				CHAR(10) PRIMARY KEY,
	quantity		INT UNSIGNED NOT NULL,
	price 			DECIMAL(10,2) NOT NULL,
	vat				DECIMAL(4,2) NOT NULL,
	score			TINYINT,
	product_image	VARCHAR(1000) COMMENT 'URL for the image',
	active			BOOL NOT NULL DEFAULT TRUE,
	reason			VARCHAR(500),

	CONSTRAINT pricePositive CHECK(price >= 0),
	CONSTRAINT VatPercentage CHECK(vat BETWEEN 0 AND 101),
	CONSTRAINT scoreNumber CHECK(score BETWEEN 1 AND 6)
)//

/*
# TRIGGER COLLECT VAT_AMOUNT FROM VAT IN PRODUCT TABLE
# INCOMPLET 
CREATE TRIGGER BeforeNewOrderedItem BEFORE INSERT ON `Ordered_Item`
FOR EACH ROW 
BEGIN
    DECLARE prod_price      DECIMAL(10,2);
    DECLARE prod_quantity   INT UNSIGNED;
    DECLARE vat             DECIMAL(4,2)

    SELECT  price, quantity, vat 
    INTO    prod_price, prod_quantity, vat
    FROM    Product
    WHERE   id = NEW.product_id;

    NEW.vat_amount = ...;
END//
*/

/*--------------------------------------------------------
> ORDER ITEM
---------------------------------------------------------*/
DROP TABLE IF EXISTS Order_Item
//

DELIMITER //
CREATE TABLE Order_Item(
	ID 					INT PRIMARY KEY AUTO_INCREMENT,
	order_id 			INT NOT NULL,
	product_id			CHAR(10) NOT NULL,
	quantity			INT NOT NULL,
	price 				DECIMAL(10,2) NOT NULL,
	vat_amount			DECIMAL(4,2) NOT NULL,

	CONSTRAINT Qta CHECK(quantity > 0),
	CONSTRAINT orderPricePositive CHECK(price > 0),
	CONSTRAINT VatAmountPositive CHECK(vat_amount > 0),

	FOREIGN KEY ProductFK (product_id) REFERENCES Product(ID),
	FOREIGN KEY OrderFK (order_id) REFERENCES `Order`(ID)
)//

/*--------------------------------------------------------
> BOOK
---------------------------------------------------------*/
DROP TABLE IF EXISTS Book
//

DELIMITER //
CREATE TABLE Book(
	product_id 			CHAR(10) PRIMARY KEY,
	isbn13				VARCHAR(20) NOT NULL UNIQUE,
	title 				VARCHAR(50) NOT NULL,
	genre				VARCHAR(50) NOT NULL,
	publisher			VARCHAR(100) NOT NULL,
	publication_date	DATE NOT NULL,

	FOREIGN KEY ProductFK (product_id) REFERENCES Product(ID)
		ON UPDATE CASCADE ON DELETE CASCADE,

	CONSTRAINT ISBN13Chk CHECK(isbn13 RLIKE '^[0-9\-]+$')
)//

/*--------------------------------------------------------
> TRIGGER ValidBook
----------------------------------------------------------*/
DROP TRIGGER IF EXISTS ValidateBook
//

DELIMITER //
CREATE TRIGGER ValidateBook BEFORE INSERT ON Book
FOR EACH ROW
BEGIN
    DECLARE INVALID_ISBN13 CONDITION FOR SQLSTATE '45023';
    IF NOT ValidISBN13(NEW.isbn13) THEN
        SIGNAL INVALID_ISBN13 
            SET MESSAGE_TEXT = 'Invalid ISBN-13';
    END IF;
END//

/*--------------------------------------------------------
> TRIGGER ValidISBN13
----------------------------------------------------------*/
DROP FUNCTION IF EXISTS ValidISBN13
//

DELIMITER //
CREATE FUNCTION ValidISBN13(isbn13 VARCHAR(20))
RETURNS BOOL
DETERMINISTIC
BEGIN
	DECLARE i TINYINT UNSIGNED DEFAULT 1;
    DECLARE s SMALLINT UNSIGNED DEFAULT 0;

    SET isbn13 = REPLACE(isbn13, '-', '');
    -- SET isbn13 = REPLACE(isbn13, ' ', '');
    -- SET isbn13 = REPLACE(isbn13, '_', '');

    IF isbn13 NOT RLIKE '^[0-9]{13}$' THEN    
    	RETURN FALSE;
    END IF;

    WHILE i < 14 DO
        SET s = s + SUBSTRING(isbn13, i, 1) * IF(i % 2 = 1, 1, 3);
        SET i = i + 1;
    END WHILE;

    RETURN s % 10 = 0;
END//

/*--------------------------------------------------------
####### TRIGGER CRIADO POR MIM #######
> TRIGGER validar se campo titulo não é vazio
---------------------------------------------------------*/
/*DROP TRIGGER IF EXISTS titleChck
//

DELIMITER //
CREATE TRIGGER titleChck 
BEFORE INSERT ON Book
FOR EACH ROW
BEGIN
	DECLARE INVALID_TITLE CONDITION FOR SQLSTATE '45021';
	IF NEW.title IS NULL or title = '' THEN
		SIGNAL INVALID_TITLE
			SET MESSAGE_TEXT = 'Invalid title entray';
	END IF;
END//
*/
/*--------------------------------------------------------
####### TRIGGER CRIADO POR MIM #######
> TRIGGER validar se campo genero não é vazio
---------------------------------------------------------*/
/*
DROP TRIGGER IF EXISTS genreChck
//

DELIMITER //
CREATE TRIGGER genreChck BEFORE INSERT ON Book
FOR EACH ROW
BEGIN
	DECLARE INVALID_GENRE CONDITION FOR SQLSTATE '45022';
	IF NEW.genre IS NULL or genre = '' THEN
		SIGNAL INVALID_GENRE
			SET MESSAGE_TEXT = 'Invalid genre entray';
	END IF;
END//
*/
/*--------------------------------------------------------
####### TRIGGER CRIADO POR MIM #######
> TRIGGER validar se campo publisher não é vazio
---------------------------------------------------------*/
/*
DROP TRIGGER IF EXISTS publisherChck
//

DELIMITER //
CREATE TRIGGER publisherChck BEFORE INSERT ON Book
FOR EACH ROW
BEGIN
	DECLARE INVALID_PUBLISHER CONDITION FOR SQLSTATE '45023';
	IF NEW.publisher IS NULL or publisher = '' THEN
		SIGNAL INVALID_PUBLISHER
			SET MESSAGE_TEXT = 'Invalid genre entray';
	END IF;
END//
*/

/*--------------------------------------------------------
> AUTHOR
---------------------------------------------------------*/
DROP TABLE IF EXISTS Author
//

DELIMITER //
CREATE TABLE Author(
	ID 				INT PRIMARY KEY AUTO_INCREMENT,
	`name` 			VARCHAR(100),
	fullname		VARCHAR(100),
	birthdate		DATE NOT NULL

)//

/*--------------------------------------------------------
> BOOK AUTHOR 
---------------------------------------------------------*/
DROP TABLE IF EXISTS BookAuthor
//

DELIMITER //
CREATE TABLE BookAuthor(
	ID 					INT PRIMARY KEY AUTO_INCREMENT,
	product_id 			CHAR(10) NOT NULL,
	author_id			INT NOT NULL,

	FOREIGN KEY ProductFK (product_id) REFERENCES Product(ID),
	FOREIGN KEY AuthorFK (author_id) REFERENCES Author(ID)
)//

/*--------------------------------------------------------
> ELETRONIC
---------------------------------------------------------*/
DROP TABLE IF EXISTS Eletronic
//

DELIMITER //
CREATE TABLE Eletronic(
	product_id 		CHAR(10) NOT NULL,
	serial_num		INT NOT NULL UNIQUE,
	brand 			VARCHAR(20) NOT NULL,
	model			VARCHAR(20) NOT NULL,
	spec_tec		LONGTEXT,
	`type`			VARCHAR(10) NOT NULL,

	FOREIGN KEY productFK (product_id) REFERENCES Product(ID)
)//

/*--------------------------------------------------------
> RECOMMENDATION
----------------------------------------------------------*/

DROP TABLE IF EXISTS Recommendation
//

DELIMITER //
CREATE TABLE Recommendation(
	ID 			INT PRIMARY KEY AUTO_INCREMENT,
	product_id 	CHAR(10) NOT NULL,
	client_id	INT NOT NULL,
	reason		VARCHAR(500),
	start_date 	DATE,

	FOREIGN KEY ProductFK (product_id) REFERENCES Product(ID),
	FOREIGN KEY ClientFK (client_id) REFERENCES `Client`(ID)
)//

/*--------------------------------------------------------
####### TRIGGER CRIADO POR MIM #######
> TRIGGER validar que a data não seja inferior que a data actual
----------------------------------------------------------*/
DROP TRIGGER IF EXISTS startDateChck
//

DELIMITER //
CREATE TRIGGER startDateChck BEFORE INSERT ON Recommendation
FOR EACH ROW
BEGIN
	DECLARE INVALID_CURRENT_DATE CONDITION FOR SQLSTATE '45020';
	IF NEW.start_date < CURDATE() THEN
		SIGNAL INVALID_CURRENT_DATE
			SET MESSAGE_TEXT = 'Invalid date for recommendation';
	END IF;
END//

/*--------------------------------------------------------
> OPERATOR 
---------------------------------------------------------*/
DROP TABLE IF EXISTS `Operator`
//

DELIMITER //
CREATE TABLE `Operator`(
    id              INT PRIMARY KEY AUTO_INCREMENT,
    firstname       VARCHAR(250) NOT NULL,
    surname         VARCHAR(250) NOT NULL,
    email           VARCHAR(50) NOT NULL UNIQUE,
    `password`      CHAR(64) NOT NULL COMMENT 'Holds the hashed password',

    CONSTRAINT OperatorEmailChk CHECK(email RLIKE "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
)//

/*--------------------------------------------------------
> TRIGGER BeforeNewOperator
----------------------------------------------------------*/
DROP TRIGGER IF EXISTS BeforeNewOperator
//

DELIMITER //
CREATE TRIGGER BeforeNewOperator BEFORE INSERT ON `Operator`
FOR EACH ROW
BEGIN
    CALL ValidateOperator(NEW.`password`);
END//

/*--------------------------------------------------------
> TRIGGER BeforeUpdatingOperator
---------------------------------------------------------*/
DROP TRIGGER IF EXISTS BeforeUpdatingOperator
//

DELIMITER //
CREATE TRIGGER BeforeUpdatingOperator BEFORE UPDATE ON `Operator`
FOR EACH ROW
BEGIN
    CALL ValidateOperator(NEW.`password`);
END//

/*--------------------------------------------------------
> PROCEDURE ValidateOperator
---------------------------------------------------------*/
DROP PROCEDURE IF EXISTS ValidateOperator
//

DELIMITER //
CREATE PROCEDURE ValidateOperator(
    INOUT `password`  CHAR(64)
)
BEGIN
    DECLARE INVALID_PASSWORD CONDITION FOR SQLSTATE '45001';

    -- We have to this, and not with CHECK CONSTRAINT because
    -- by that time, the password is already hashed (see below)
    -- The password can only be hashed here, in this trigger.
    IF `password` NOT RLIKE "(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!$#?%]).{6,}" THEN
        SIGNAL INVALID_PASSWORD
            SET MESSAGE_TEXT = 'Invalid password';
    END IF;
    SET `password` := SHA2(`password`, 256);
END//

/*--------------------------------------------------------
> PROCEDURE AuthenticateOperator
--------------------------------------------------------*/
DROP PROCEDURE IF EXISTS AuthenticateOperator
//

DELIMITER //
CREATE PROCEDURE AuthenticateOperator(
	IN operator_email 	VARCHAR(50),
	IN operator_passwd  CHAR(64)
)
BEGIN
	SELECT firstname, surname 
	FROM `Operator`
	WHERE email = operator_email 
	AND `password` = operator_passwd;
END//

/*--------------------------------------------------------
> DATABASE USERS AND ACCOUNTS
----------------------------------------------------------*/
DROP USER IF EXISTS 'web_client'@'10.10.10.%'
//

DELIMITER //
CREATE USER 'web_client'@'10.10.10.%' IDENTIFIED BY 'Passw0rd'
//

DROP USER IF EXISTS 'web_client'@'%'
//

DELIMITER //
CREATE USER 'web_client'@'%' IDENTIFIED BY 'Passw0rd'
//

DELIMITER //
DROP USER IF EXISTS 'operator'@'localhost'
//

DELIMITER //
CREATE USER 'operator'@'localhost' IDENTIFIED BY 'Passw0rd'
//

DROP USER IF EXISTS 'operator'@'%'
//

DELIMITER //
CREATE USER 'operator'@'%' IDENTIFIED BY 'Passw0rd'
//


/* NOTA TEMOS DE DAR PERVILEGOS AO ADMIN DO ServerDebian
Entrar como ssh com o "linux Mint" e aceder ao ServerDebian

> Correr o comando mysql -u root -p

Depois correr este privilegios
> GRANT ALL PRIVILLAGEs ON *.* 'admin'@'localhost' WITH GRANT OPTION;
> GRANT ALL PRIVILLAGEs ON *.* 'admin'@'%' WITH GRANT OPTION;

> É necessário dar pervilegios ao utilizador de modo que possa leitura e pode executar eventuais
> procedimentos guardados defnidos na BD
*/

DELIMITER //
GRANT SELECT, INSERT, DELETE ON BuyPy.* TO 'web_client'@'10.10.10.%' WITH GRANT OPTION
//

DELIMITER //
GRANT SELECT, INSERT, DELETE ON BuyPy.* TO 'web_client'@'%' WITH GRANT OPTION
//

DELIMITER //
GRANT ALL ON BuyPy.* TO 'operator'@'localhost' WITH GRANT OPTION
//

DELIMITER //
GRANT ALL ON BuyPy.* TO 'operator'@'%' WITH GRANT OPTION
//

/*--------------------------------------------------------
> 3. A equipa de desenvolvimento chegou à conclusão que necessita 
de determinadas operaçoes implementadas na BD. A tabela em baixo 
lista, para algumas das funcionalidades identifcadas durante a 
Análise de Requisitos, parte das consultas e procedimentos 
necessários para as concretizar essas funcionalidades. 
Deve implementar estas consultas e procedimentos utilizando 
procedimentos e/ou vistas.
----------------------------------------------------------*/

/*--------------------------------------------------------
> ProdutoPorTipo
----------------------------------------------------------*/
/*--------------------------------------------------------
Devolve código de produto, preço, pontuação, 
recomendação, activo/inactivo, fcheiro e coluna 
com tipo de produto.

PARÂMETROS: Tipo de produto (se NULL devolve todos)
----------------------------------------------------------*/
DROP PROCEDURE IF EXISTS ProdutoPorTipo
//

DELIMITER //
CREATE PROCEDURE ProdutoPorTipo(
	IN produtoTipo VARCHAR(50)
)
BEGIN
	IF SUBSTRING(produtoTipo, 1, 3) LIKE 'BOK%' THEN
		SELECT ID as 'Cód. do Produto', 
        price as 'Preço', 
        score as 'Avaliação', 
        reason as 'Recomendação', 
        `active` as 'Activo', 
        product_image as 'Ficheiro',
        'Livro' as 'Tipo de Produto'
		FROM Product
        WHERE ID  LIKE 'BOK%';

	ELSEIF SUBSTRING(produtoTipo, 1, 3) LIKE 'ELE%' THEN 
		SELECT ID as 'Cód. do Produto', 
        price as 'Preço', 
        score as 'Avaliação', 
        reason as 'Recomendação', 
        `active` as 'Activo', 
        product_image as 'Ficheiro',
        'Eletronic' as 'Product Type'
		FROM Product
		WHERE ID LIKE 'ELE%';
	ELSE
		SELECT ID as 'Cód. do Produto', 
        price as 'Preço', 
        score as 'Avaliação', 
        reason as 'Recomendação', 
        `active` as 'Activo',
        product_image as 'Ficheiro'
		FROM Product;
	END IF;
END
//
-- TESTAR com BOK, ELE e ''
CALL ProdutoPorTipo('');

/*--------------------------------------------------------
> EncomendasDiarias
----------------------------------------------------------*/
/*--------------------------------------------------------
Devolve todas as encomendas para um dado dia

PARÂMETROS: Data
----------------------------------------------------------*/
DROP PROCEDURE IF EXISTS EncomendasDiarias
//

DELIMITER //
CREATE PROCEDURE EncomendasDiarias(
	IN encomendaData date
)
BEGIN
	SELECT DATE(date_time) as 'Data',  
    CONCAT(`Client`.firstname,' ', `Client`.surname) as 'Cliente', 
	`Order`.ID as 'ID da Encomenda',
    delivery_method as 'Tipo de Entrega', 
    status as 'Estado'
	FROM `Order`, `Client`
    WHERE DATE(date_time) = encomendaData;
END
//
-- TESTAR com 2022-09-07
CALL EncomendasDiarias('2022-09-07');

/*--------------------------------------------------------
> EncomendasAnuais
----------------------------------------------------------*/
/*--------------------------------------------------------
Devolve todas as encomendas colocadas por um 
determinado cliente durante um determinado 
ano.

PARÂMETROS: ID do Cliente, Ano
----------------------------------------------------------*/
DROP PROCEDURE IF EXISTS EncomendasAnuais
//

DELIMITER //
CREATE PROCEDURE EncomendasAnuais(
	IN clienteID INT,
    IN ano DATE
)
BEGIN
	SELECT DATE(date_time) as 'Ano', 
    CONCAT(`Client`.firstname,' ', `Client`.surname) as 'Cliente', 
	`Order`.ID as 'ID da Encomenda', 
    delivery_method as 'Tipo de Entrega', 
    status as 'Estado'
	FROM `Order`, `Client`
	WHERE `Client`.ID = clienteID AND DATE(date_time) = ano;	
END
//
-- TESTAR com 1 e 2022-09-07
CALL EncomendasAnuais(2,'2022-09-07');

/*--------------------------------------------------------
> CriarEncomenda
----------------------------------------------------------*/
/*--------------------------------------------------------
Cria uma encomenda. Dados: cliente, método de 
expedição, número de cartão, nome do titular do 
cartão e data de validade do cartão.

PARÂMETROS: ID de Cliente, Método, Número do Cartão, 
Nome no Cartão, Data de Validade
----------------------------------------------------------*/
DROP PROCEDURE IF EXISTS CriarEncomenda
//

DELIMITER //
CREATE PROCEDURE CriarEncomenda(
	IN metodo VARCHAR(30),
	IN nCartao BIGINT,
	IN nomeCartao VARCHAR(20),
	IN dateValidade DATE,
    IN clienteID INT
)
BEGIN
	INSERT INTO `Order`(
    delivery_method, 
    payment_card_number, 
    payment_card_name,
    payment_card_expiration, 
    client_id
    )
	VALUES (metodo, nCartao, nomeCartao, dateValidade, clienteID);	
END
//
-- TESTAR com 'regular', 999, 'Fiona Silva', '2024-01-20', 3 
CALL CriarEncomenda('regular', 999, 'Fiona Silva', '2024-01-20', 3);

/*--------------------------------------------------------
> CalcularTotal
----------------------------------------------------------*/
/*--------------------------------------------------------
Calcula o montante total de uma encomenda. 

PARÂMETROS: ID da Encomenda
----------------------------------------------------------*/
DROP PROCEDURE IF EXISTS CalcularTotal
//

DELIMITER //
CREATE PROCEDURE CalcularTotal(
	IN orderID INT
)
BEGIN
	SELECT SUM(price * quantity) as 'Montante Total'
	FROM Order_Item
	WHERE Order_Item.ID = orderID;
END
//
-- TESTAR com ID 1 ou 2
CALL CalcularTotal(2);

/*--------------------------------------------------------
> AdicionarProduto | INCOMPLETO
----------------------------------------------------------*/
/*--------------------------------------------------------
Adiciona um produto a uma encomenda, 
registando quantos produtos são encomendados.

PARÂMETROS: ID da Encomenda, ID do Produto, Quantidade
----------------------------------------------------------*/
DROP PROCEDURE IF EXISTS AdicionarProduto
//

DELIMITER //
CREATE PROCEDURE AdicionarProduto(
	IN produtoID CHAR(10),
	IN quantidade INT,
	IN preco DECIMAL(10,2),
	IN vat DECIMAL(4,2),
    IN orderID INT
)
BEGIN
	INSERT INTO Product(id, quantity, price, vat)
	VALUES (produtoID, quantidade, preco, vat);	
END
//
-- TESTAR com product_id, qantity, price, vat | BOOK
CALL AdicionarProduto('BOK98222XX', 20, 5, 23);

-- TESTAR com product_id, qantity, price, vat | ELETRONIC
CALL AdicionarProduto('ELE001AA3E', 10, 5, 20);

/*--------------------------------------------------------
> CriarLivro
----------------------------------------------------------*/
/*--------------------------------------------------------
Adiciona um produto do tipo livro à BD

PARÂMETROS: ID Produto, ISBN13, Titulo, Genero, Publicação, 
Data da Publicação
----------------------------------------------------------*/
DROP PROCEDURE IF EXISTS CriarLivro
//

DELIMITER //
CREATE PROCEDURE CriarLivro(
	IN bookID CHAR(10),
	IN isbn13 VARCHAR(20),
	IN title VARCHAR(50),
	IN genre VARCHAR(50),
	IN publisher VARCHAR(50),
	IN publication_date DATE
)
BEGIN
	INSERT INTO Book (product_id, isbn13, title, genre, publisher, publication_date)
	VALUES (bookID, isbn13, title, genre, publisher, publication_date);	
END
//
-- TESTAR com product_id, isbn13, title, genre, publisher, publication_date
-- É necessário inserir primeiro um produto e depois criar um livro 

CALL CriarLivro('BOK98222XX', '979-03-73-410445', 'Metro 2034', 
'Fantasia', 'Dimitry', '2014-06-01');

/*--------------------------------------------------------
> CriarConsumivelElec
----------------------------------------------------------*/
/*--------------------------------------------------------
Adiciona um produto do tipo consumível de 
electrónica à BD

PARÂMETROS: ID Produto, Nº de Serie, Marca, Modelo, Especificações, Tipo
----------------------------------------------------------*/
DROP PROCEDURE IF EXISTS CriarConsumivelElec
//

DELIMITER //
CREATE PROCEDURE CriarConsumivelElec(
	IN elecID CHAR(10),
	IN serialNum VARCHAR(20),
    IN brand VARCHAR(20),
	IN model VARCHAR(20),
	IN spec_tec LONGTEXT,
	IN elecType VARCHAR(10)
)
BEGIN
	INSERT INTO Eletronic (product_id, serial_num, brand, model, spec_tec, `type`)
	VALUES (elecID, serialNum, brand, model, spec_tec, elecType);	
END
//
-- TESTAR com product_id, serial_num, brand, model, spec_tec, `type`
-- É necessário inserir primeiro um produto e depois criar um Electronico 
CALL CriarConsumivelElec('ELE001AA3E', 66401321, 'SONY', 'OTHER', 'Tamanho do ecrã: 43” (42,5") polegadas / 108 cm,
Tipo de visor: LCD, Resolução: 3840 x 2160', 'TV');

/*--------------------------------------------------------
>  Menu "Utilizador"
----------------------------------------------------------*/
/*-------------------------------------------------------
5.2.1 Pesquisar por ID ou por username de um utilizador.
Fornece a possibilidade de desbloquear ou bloquear a conta do utilizador
----------------------------------------------------------*/
/*--------------------------------------------------------
>  searchClients
----------------------------------------------------------*/
DROP PROCEDURE IF EXISTS searchClients
//

DELIMITER //
CREATE PROCEDURE searchClients()
BEGIN
	SELECT ID as 'ID', 
    firstname as 'Nome', 
    surname as 'Apelido', 
    city as 'Cidade', 
    zip_code as 'Código Postal', 
    birthdate as 'Data Nasc.', 
    email as 'Email',
    is_active as 'Estado da Conta'
	FROM Client;
END
//
-- TESTAR sem parametros, ao qual vai buscar toda as informações 
-- da tabela de clientes
CALL searchClients();
/*--------------------------------------------------------
>  unlockClients | Incompleto
----------------------------------------------------------*/


/*-------------------------------------------------------
5.2.2 (extra) Listar os detalhes de um utilizador por ID
----------------------------------------------------------*/
DROP PROCEDURE IF EXISTS searchClientID
//

DELIMITER //
CREATE PROCEDURE searchClientID(
	IN clientID INT
)
BEGIN
	SELECT ID as 'ID', 
    firstname as 'Nome',
    surname as 'Apelido', 
    city as 'Cidade', 
    zip_code as 'Código Postal', 
    birthdate as 'Data Nasc.', 
    email as 'Email'
	FROM Client
	WHERE ID = clientID;
END
//
-- TESTAR com client ID 
CALL searchClientID(1);

/*-------------------------------------------------------
 5.2.3 (extra) Listagem de utilizadores com contas bloqueadas.
----------------------------------------------------------*/
DROP PROCEDURE IF EXISTS searchClientBlock
//

DELIMITER //
CREATE PROCEDURE searchClientBlock(
)
BEGIN
	SELECT ID as 'ID', 
    firstname as 'Nome',
    surname as 'Apelido', 
    city as 'Cidade', 
    zip_code as 'Código Postal', 
    birthdate as 'Data Nasc.', 
    email as 'Email'
	FROM Client
	WHERE is_active = 0;
END
//
-- TESTAR com product_id, serial_num, brand, model, spec_tec, `type`
-- É necessário inserir primeiro um produto e depois criar um Electronico 
CALL searchClientBlock();

/*--------------------------------------------------------
>  Menu "PRODUTOS":
----------------------------------------------------------*/
/*-------------------------------------------------------
5.3.1 Listagem de produtos 
----------------------------------------------------------*/
DROP PROCEDURE IF EXISTS searchProduct
//

DELIMITER //
CREATE PROCEDURE searchProduct(
	IN produtoTipo VARCHAR(50)
)
BEGIN
	IF SUBSTRING(produtoTipo, 1, 3) LIKE 'BOK%' THEN
		SELECT ID as 'Cód. do Produto', 
        price as 'Preço', 
        score as 'Avaliação', 
        reason as 'Recomendação', 
        `active` as 'Activo', 
        product_image as 'Ficheiro',
        'Livro' as 'Tipo de Produto'
		FROM Product
        WHERE ID  LIKE 'BOK%';

	ELSEIF SUBSTRING(produtoTipo, 1, 3) LIKE 'ELE%' THEN 
		SELECT ID as 'Cód. do Produto', 
        price as 'Preço', 
        score as 'Avaliação', 
        reason as 'Recomendação', 
        `active` as 'Activo', 
        product_image as 'Ficheiro',
        'Eletronic' as 'Tipo de Produto'
		FROM Product
		WHERE ID LIKE 'ELE%';
	ELSE
		SELECT ID as 'Cód. do Produto', 
        price as 'Preço', 
        score as 'Avaliação', 
        reason as 'Recomendação', 
        `active` as 'Activo',
        product_image as 'Ficheiro'
		FROM Product;
	END IF;
END
//
-- TESTAR com BOK, ELE e ''
CALL searchProduct('');

/*-------------------------------------------------------
 5.3.2 Adicionar um produto à BD. | Add Product Type
----------------------------------------------------------*/
DROP PROCEDURE IF EXISTS AddProduct
//

DELIMITER //
CREATE PROCEDURE AddProduct(
	IN produtoID CHAR(10),
	IN quantidade INT,
	IN preco DECIMAL(10,2),
	IN vat DECIMAL(4,2)
)
BEGIN
	INSERT INTO Product(id, quantity, price, vat)
	VALUES (produtoID, quantidade, preco, vat);	
END
//
-- TESTAR com product_id, qantity, price, vat | BOOK
CALL AddProduct('BOK98222XX', 20, 5, 23);

-- TESTAR com product_id, qantity, price, vat | ELETRONIC
CALL AddProduct('ELE001AA3E', 10, 5, 20);

/*--------------------------------------------------------
 5.3.2 Adicionar um produto à BD. | Add Book
----------------------------------------------------------*/
DROP PROCEDURE IF EXISTS addBook
//

DELIMITER //
CREATE PROCEDURE addBook(
	IN bookID CHAR(10),
	IN isbn13 VARCHAR(20),
	IN title VARCHAR(50),
	IN genre VARCHAR(50),
	IN publisher VARCHAR(50),
	IN publication_date DATE
)
BEGIN
	INSERT INTO Book (product_id, isbn13, title, genre, publisher, publication_date)
	VALUES (bookID, isbn13, title, genre, publisher, publication_date);	
END
//
-- TESTAR com product_id, isbn13, title, genre, publisher, publication_date
-- É necessário inserir primeiro um produto e depois criar um livro 

CALL addBook('BOK98222XX', '979-03-73-410445', 'Metro 2034', 
'Fantasia', 'Dimitry', '2014-06-01');

/*--------------------------------------------------------
 5.3.2 Adicionar um produto à BD. | Add Eletronic
----------------------------------------------------------*/
DROP PROCEDURE IF EXISTS addElec
//

DELIMITER //
CREATE PROCEDURE addElec(
	IN elecID CHAR(10),
	IN serialNum VARCHAR(20),
    IN brand VARCHAR(20),
	IN model VARCHAR(20),
	IN spec_tec LONGTEXT,
	IN elecType VARCHAR(10)
)
BEGIN
	INSERT INTO Eletronic (product_id, serial_num, brand, model, spec_tec, `type`)
	VALUES (elecID, serialNum, brand, model, spec_tec, elecType);	
END
//
-- TESTAR com product_id, serial_num, brand, model, spec_tec, `type`
-- É necessário inserir primeiro um produto e depois criar um Electronico 
CALL addElec('ELE001AA3E', 66401321, 'SONY', 'OTHER', 'Tamanho do ecrã: 43” (42,5") polegadas / 108 cm,
Tipo de visor: LCD, Resolução: 3840 x 2160', 'TV');

/*--------------------------------------------------------
>  Menu "BACKUP":
----------------------------------------------------------*/
DROP PROCEDURE IF EXISTS allTables
//

DELIMITER //
CREATE PROCEDURE allTables()
BEGIN
	SHOW TABLES;	
END
//
-- TESTAR sem parametros, mostra todas as tabelas da BD BuyPy
CALL allTables();