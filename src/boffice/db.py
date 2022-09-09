"""
This module defines functions and classes related to DB access.

(c) Ana Mendes, 2022
"""

from hashlib import sha256 as default_hashalgo
from time import sleep
from PySide2 import sys
from mysql.connector import connect, Error as MySQLError

DB_CONN_PARAMS = {
	'host': '192.168.3.2', # IP da Maquina onde esta a Base de dados
	'user': 'operator', # User criado
	'password': 'Passw0rd', # Password que se pôs ao user operador
	'database': 'BuyPy',
}

def login(username: str, passwd: str) -> dict:
    hash_obj = default_hashalgo()
    hash_obj.update(passwd.encode())
    hash_passwd = hash_obj.hexdigest()
    with connect(**DB_CONN_PARAMS) as connection:
        with connection.cursor() as cursor:
            # Chamar procedure criado na DB
            cursor.callproc('AuthenticateOperator', [username, hash_passwd])
            user_info = next(cursor.stored_results())
            if user_info.rowcount != 1:
                return None
            user_row = user_info.fetchall()[0]
            return dict(zip(user_info.column_names, user_row))
            #Devolve um dicionario com nom firstname e lastname
#:

'''
Querys for USER MENU
'''

# Search all Client
def querySearchClients ():
    with connect(**DB_CONN_PARAMS) as connection:
        with connection.cursor() as cursor:
            # Chamar procedure criado na DB
            cursor.callproc('searchClients')
            client_info = next(cursor.stored_results())
            print("Total de Nº linhas na Tabela: ", cursor.rowcount)
            print()
            for row in client_info:
                print("ID          ",row[0])
                print("Nome        ",row[1])
                print("Apelido     ",row[2])
                print("Cidade      ",row[3])
                print("Cód. Postal ",row[4])
                print("Data Nasc.  ",row[5])
                print("Email       ",row[6])
                print()           
#:

# Search a Client by ID
def querySearchClientsID (clientID: int):
    with connect(**DB_CONN_PARAMS) as connection:
        with connection.cursor() as cursor:
            # Chamar procedure criado na DB
            cursor.callproc('searchClientID',[clientID])
            client_info = next(cursor.stored_results())
            print("Total de Nº linhas na Tabela: ", cursor.rowcount)
            print()
            for row in client_info:
                print("ID          ",row[0])
                print("Nome        ",row[1])
                print("Apelido     ",row[2])
                print("Cidade      ",row[3])
                print("Cód. Postal ",row[4])
                print("Data Nasc.  ",row[5])
                print("Email       ",row[6])
                print()           
#:

# Search a Client have the acount Block
def querySearchClientsBlock ():
    with connect(**DB_CONN_PARAMS) as connection:
        with connection.cursor() as cursor:
            # Chamar procedure criado na DB
            cursor.callproc('searchClientBlock')
            client_info = next(cursor.stored_results())
            print("Total de Nº linhas na Tabela: ", cursor.rowcount)
            print()
            for row in client_info:
                print("ID          ",row[0])
                print("Nome        ",row[1])
                print("Apelido     ",row[2])
                print("Cidade      ",row[3])
                print("Cód. Postal ",row[4])
                print("Data Nasc.  ",row[5])
                print("Email       ",row[6])
                print()           
#:

'''
Querys for PRODUCT MENU
'''
# Search All Product
def querySearchProduct (ProductType: str):
    with connect(**DB_CONN_PARAMS) as connection:
        with connection.cursor() as cursor:
            # Chamar procedure criado na DB
            cursor.callproc('searchProduct',[ProductType])
            client_info = next(cursor.stored_results())
            print("Total de Nº linhas na Tabela: ", cursor.rowcount)
            print()
            for row in client_info:
                print("Cód. do Produto ",row[0])
                print("Preço           ",row[1])
                print("Avaliação       ",row[2])
                print("Recomendação    ",row[3])
                print("Activo          ",row[4])
                print("Ficheiro        ",row[5])
                print("Tipo de Produto ",row[6])
                print()           
#:

# ADD a Product 
def queryAddProduct (ProductType: str, qt: int, price: float, vat: float):
    with connect(**DB_CONN_PARAMS) as connection:
        with connection.cursor() as cursor:
            # Chamar procedure criado na DB
            # cursor.callproc('AddProduct',[ProductType, qt, price, vat])
            cursor.execute('AddProduct',[ProductType, qt, price, vat])
            print("Dados Inseridos")
            DB_CONN_PARAMS.commit()
            print()         
#:

# ADD a Book
def queryAddBook (bookID: str, isbn13: str, title: str, genre: str, publisher: str, publication_date: str):
    with connect(**DB_CONN_PARAMS) as connection:
        with connection.cursor() as cursor:
            # Chamar procedure criado na DB
            cursor.callproc('addBook',[bookID, isbn13, title, genre, publisher, publication_date])
            print("Dados Inseridos")
            print()        
#:

# ADD a Eletronic
def queryAddElec (elecID: str, serialNum: str, brand: str, model: str, spec_tec: str, elecType: str):
    with connect(**DB_CONN_PARAMS) as connection:
        with connection.cursor() as cursor:
            # Chamar procedure criado na DB
            cursor.callproc('addElec',[elecID, serialNum, brand, model, spec_tec, elecType])
            print("Dados Inseridos")
            print()         
#:

'''
Querys for BACKUP MENU
'''
# Search All TABLES + Backup
def queryBackupBD():
    with connect(**DB_CONN_PARAMS) as connection:
        with connection.cursor() as cursor:
            # Chamar procedure criado na DB
            cursor.callproc('allTables')
            table_names = []
            for record in cursor.fetchall():
                table_names.append(record[0])
            
            backup_dbname = 'BuyPy' + '_backup'
            try:
                cursor.execute(f'CREATE DATABASE {backup_dbname}')
            except:
                pass

            for table_name in table_names:
                cursor.execute(f'CREATE TABLE {table_name} SELECT * FROM BuyPy.{table_name}')
          
#: