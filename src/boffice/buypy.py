"""
BuyPy
A command-line backoffice application. This is an interactive 
shell application
(c) Ana Mendes, 2022
"""

import sys
from subprocess import run
from getpass import getpass

import db


def main():
    user_info = exec_login()
    
    while True:
        cls()
        print(f"\nBem vindo {user_info['firstname']}\n")
        print("U - Menu 'Utilizador'")
        print("P - Menu 'Produto'")
        print("B - Menu 'Backup'")
        print("S - Sair do BackOffice")
        print("L - Logout do BackOffice")

        print()
        option = input(">> ")

        #MENU UTILIZADOR
        if option == 'U' or option == 'u':
            print("Menu UTILIZADOR")
            print()
            while True:
                cls()
                print()
                print("Menu UTILIZADOR")
                print()
                print ("1 - Listagem de todos os utilizadores")
                print ("2 - Listagem por Utilizador por ID")
                print ("3 - Listagem por utilizador bloqueados")
                print ("V - Voltar para Menu 'Menu UTILIZADOR'")

                print()
                option = input(">> ")

                if option == '1':
                    cls()
                    print()
                    print("Menu 'UTILIZADOR' | Listagem de todos os utilizadores")
                    print()
                    searchClient()

                elif option == '2':
                    cls()
                    print()
                    print("Menu 'UTILIZADOR' | Listagem por Utilizador por ID")
                    print()
                    searchClientID()

                elif option == '3':
                    cls()
                    print()
                    print("Menu 'UTILIZADOR' | Listagem por utilizador bloqueados")
                    print()
                    searchClientBlock()

                elif option == 'V' or option == 'v':
                    # NOTA: Como voltar ao menu principal sem sair do programa?
                    pass                    

                else:
                    print(f"Opção <{option}> inválida ")

        #MENU PRODUTO
        elif option == 'P' or option == 'P':
            print("Menu 'PRODUTO'")
            print()
            while True:
                cls()
                print()
                print("Menu 'PRODUTO'")
                print()
                print ("1 - Listagem de produtos")
                print ("2 - Adicionar produto")
                print ("V - Voltar para Menu 'Menu UTILIZADOR'")

                print()
                option = input(">> ")

                if option == '1':
                    cls()
                    print()
                    print("Menu 'PRODUTO' | Listagem de produtos")
                    print()
                    searchProduct()

                elif option == '2':
                    cls()
                    print()
                    print("Menu 'PRODUTO' | Adicionar produto")
                    print()
                    addProduct()

                elif option == 'V' or option == 'v':
                    # NOTA: Como voltar ao menu principal sem sair do programa?
                    pass                                        
                else:
                    print(f"Opção <{option}> inválida ")

        #MENU BACKUP
        elif option == 'B' or option == 'b':
            print("Menu 'BACKUP'")
            print()

            backOption = ''
            print("Deseja fazer backup à Base de Dados? (S/N)")
            if option == 'S' or option == 's':
                cls()
                BackupBD()
                print("Back Realizado!")
        
        #MENU TERMINAR BACKOFFICE
        elif option == 'S' or option == 's':
            print("O BackOffice vai terminar")
            sys.exit(0)
        else:
            print(f"Opção <{option}> inválida ")
#:

def exec_login():
    """
    Asks for user login info and then tries to authenticate the user in 
    the DB.
    Stores user data the data in the local config file 'config.ini'.
    """
    while True:
        username = input("Username      : ")
        passwd = getpass("Palavra-passe : ")
        user_info = db.login(username, passwd)
        if user_info:
            break
        print("Autenticação Inválida")
        print()
    return user_info
#:

def cls():
    # pylint: disable=subprocess-run-check
    if sys.platform in ('linux', 'darwin', 'freebsd'):
        run(['clear'])
    elif sys.platform == 'win32':
        run(['cls'], shell=True)
#:

'''
Function for USER MENU
'''

def searchClient():
    """
    Listagem de todos os utilizadores.
    """
    while True:
        print()
        client_info = db.querySearchClients()
        if client_info:
            break
        print()
    return client_info
#:

def searchClientID():
    """
    Lista os detalhes de um utilizador ID.
    """
    while True:
        print()
        clientID = input("Cliente ID: ")
        print()
        client_info = db.querySearchClientsID(clientID)
        if client_info:
            break
        print()
    return client_info
#:


def searchClientBlock():
    """
    Listagem de utilizadores com contas bloqueadas. 
    """
    while True:

        client_info = db.querySearchClientsBlock()
        if client_info:
            break
        print()
    return client_info
#:

'''
Function for PRODUCT MENU
'''

def searchProduct():
    """
    Listagem dos produtos por tipo de Produto.
    """
    while True:
        print()
        productType = input("Indique o Tipo de produto ('BOK', 'ELE' ou ''): ")
        print()
        product_info = db.querySearchProduct(productType)
        if product_info:
            break
        print()
    return product_info
#:

def addProduct():
    """
    Listagem dos produtos por tipo de Produto.
    """
    while True:
        print()
        productType = input("Indique o Tipo de produto ('BOKXXXXXXX' ou 'ELEXXXXXXX'): ")
        qt = input("Indique a Quantidade: ")
        price = input("Indique o Preço: ")
        vat = input("Indique o IVA: ")
        print()
        product_info = db.queryAddProduct(productType, qt, price, vat)

        findBOK = 'BOK'
        if findBOK in productType:
            print()
            print("Adicionar novo Livro")
            print()
            bookID = input("Indique o Cód do Livro (ex: BOKXXXXXXX): ")
            codIsbn13 = input("Indique o ISBN13: ")
            title  = input("Indique o Titulo: ")
            genre  = input("Indique o Género: ")
            publisher = input("Indique o Publicador: ")
            publication_date = input("Indique a Data da Publicação (YYYY-MM-DD): ")
            print()
            info = db.queryAddBook(bookID, codIsbn13, title, genre, publisher, publication_date)

        else:
            print()
            print("Adicionar novo Eletrico")
            print()
            elecID = input("Indique o Cód do Eletrico (ex: ELEXXXXXXX): ")
            serialNum = input("Indique o Nº de Serie: ")
            brand  = input("Indique a Marca: ")
            model  = input("Indique o Modelo: ")
            spec_tec = input("Indique as Especificações: ")
            elecType = input("Indique o Tipo (ex: TV, PC...): ")
            print()
            info = db.queryAddElec(elecID, serialNum, brand, model, spec_tec, elecType)

        if product_info and info:
            break
        print()
    return product_info, info
#:

'''
Function for BACKUP MENU
'''
def BackupBD():
    """
    Backup DB
    """
    while True:
        print()
        backup_info = db.queryBackupBD()
        if backup_info:
            break
        print()
    return backup_info
#:

if __name__ == '__main__':
    main()
#:
