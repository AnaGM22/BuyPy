/*
	DDL for the BuyPy Online Store

	(C) Ana Mendes & Diogo Ferreira, 2022
*/

USE BuyPy;

/*--------------------------------------------------------
> DESCRIBE
----------------------------------------------------------*/
DESCRIBE Book;
DESCRIBE Product;
DESCRIBE `Order`;
DESCRIBE Order_Item;
DESCRIBE Eletronic;
DESCRIBE `Client`;
/*--------------------------------------------------------
> SELECT | 
----------------------------------------------------------*/
SELECT * FROM `Client`;
SELECT * FROM Product;
SELECT * FROM Book; 
SELECT * FROM Eletronic;     
SELECT * FROM `Order`; 
SELECT * FROM Order_Item; 

/*--------------------------------------------------------
> INSERT | Data used to fill tables with content
----------------------------------------------------------*/
INSERT INTO `Client` (firstname, surname, email, `password`, address, zip_code, city, country,
        phone_number, birthdate, is_active)
VALUES    
	('Alberto', 'Antunes', 'alb@mail.com', '123abC!', 'Rua do Almada, n. 23', 9877, 'Lisboa', 'Portugal',
        '351213789123', '1981-05-23',1),
    ('Arnaldo', 'Avelar', 'arnaldo@coldmail.com', '456deF!', 'Av. América, n. 23', 2877, 'Porto', 'Portugal',
        '351213789123', '1981-05-23',1),
	('Fiona', 'Silva', 'fiona@mail.com', '456deF!', 'Av. da Liberdade, nº 1', 1800, 'Lisboa', 'Portugal',
        '351213789555', '1989-04-23'),
	('Fiona', 'Marquês', 'fionaM@mail.com', '456deF!', 'Av. do Osso, nº 2', 1900, 'Lisboa', 'Portugal',
        '351213789444', '1987-01-23',1),
	('Barkie', 'Mendes', 'barkie@mail.com', '123abC!', 'Rua Osso, nº 2', 1900, 'Lisboa', 'Portugal',
        '351213789444', '1987-01-23', 0);


INSERT INTO Product (id, quantity, price, vat, score, product_image)
VALUES
    ('ELE12P9817', 20, 800, 23, 5, 'file:://mnt/imgs/products/elec/ipad_xii.jpg'),
    ('BOK129922A', 50, 8, 6, 3, 'file:://mnt/imgs/products/book/prog_c++.jpg'),
	('ELE001943E', 100, 1000, 23, 5, 'file:://mnt/imgs/products/elec/ipad_xii.jpg'),
    ('BOK98128EE', 100, 16, 6, 3, 'file:://mnt/imgs/products/book/prog_c++.jpg');
    
INSERT INTO Product (id, quantity, price, vat, score, product_image)
VALUES
    ('BOK98133EE', 100, 16, 6, 3, 'file:://mnt/imgs/products/book/prog_c++.jpg');

INSERT INTO Book 
    (product_id, isbn13, title, genre, publisher, publication_date)
VALUES              
    ('BOK129922A', '978-0-32-1563842', 'The C++ Programming Language 4th Edition', 
    'Programming', 'Addison-Wesley', '2013-06-05'),
    ('BOK98128EE', '978-1-23-4567897', 'Guild Wars 2', 'Fantasy', 'Addison-Wesley', '2016-06-05');

INSERT INTO Eletronic (product_id, serial_num, brand, model, spec_tec, `type`)
VALUES              
    ('ELE12P9817', 0212379, 'MAC', 'OREO', '1.4 GHz quad-core 8th gen Intel core i5 | 256GB SSD', 'PC'),
	('ELE001943E', 88401231, 'ASUS', 'LIGHT', '2.3GHz dual-core i5 | 128GB SSD', 'PC');

INSERT INTO `Order`(payment_card_number, payment_card_name, payment_card_expiration, client_id)
VALUES
    (121, 'DR. ALBERTO ANTUNES', '2023-05-23', (SELECT id FROM `Client` WHERE firstname = 'alberto' LIMIT 1));

INSERT INTO Order_Item (order_id, product_id, quantity, price, vat_amount)
VALUES
    (1, 'BOK129922A', 5, 10, 6),
    (2, 'ELE12P9817', 10, 10, 23);

INSERT INTO `Operator` (firstname, surname, email, `password`)
VALUES
    ('Pedro', 'Pereira', 'pedro@mail.com', '123abC!'),
    ('Paulo', 'Pacheco', 'paulo@coldmail.com', '123abC!');
    
/*--------------------------------------------------------
> PROCEDURE | 
----------------------------------------------------------*/
-- TESTAR com BOK, ELE e ''
CALL ProdutoPorTipo('');

-- TESTAR com 2022-09-07
CALL EncomendasDiarias('2022-09-07');

-- TESTAR com ID Cliente 1 e 2022-09-07
CALL EncomendasAnuais(2,'2022-09-07');

-- TESTAR com  delivery_method, payment_card_number, payment_card_name, payment_card_expiration, client_id 
CALL CriarEncomenda('regular', 999, 'Fiona Silva', '2024-01-20', 3);

-- TESTAR com ID Order 1 ou 2
CALL CalcularTotal(2);

-- TESTAR com product_id, qantity, price, vat order_id | BOOK
CALL AdicionarProduto('BOK98222XX', 20, 5, 23, 1);

-- TESTAR com product_id, qantity, price, vat order_id | ELETRONIC
CALL AdicionarProduto('ELE001AA3E', 10, 5, 20, 1);

-- TESTAR com product_id, isbn13, title, genre, publisher, publication_date
-- NOTA: É necessário inserir primeiro o produto e depois criar o livro 
CALL CriarLivro('BOK98222XX', '979-03-73-410445', 'Metro 2034', 
'Fantasia', 'Dimitry', '2014-06-01');

-- TESTAR com product_id, serial_num, brand, model, spec_tec, `type`
-- É necessário inserir primeiro um produto e depois criar um Electronico 
CALL CriarConsumivelElec('ELE001AA3E', 66401321, 'SONY', 'OTHER', 'Tamanho do ecrã: 43” (42,5") polegadas / 108 cm,
Tipo de visor: LCD, Resolução: 3840 x 2160', 'TV');



