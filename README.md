# BuyPy

Backoffice for an online shopping store.

## buypy.sql
Contains the structure of the Database having Triggers, Procedures, etc, but also including the Procedures from lines 3 and 5 (5.1, 5.2, 5.2.1, 5.2.2, 5.2.3, 5.3, 5.3.1, 5.3.2, 5.4 and 5.5)

## buypy.py
### Menu section
> **User:**
> - searchClient() function: List of all users, without parameters
> - searchClientID() function: Lists the details of a user ID, with Client ID parameter
> - searchClientBlock() function: List of users with blocked accounts, without parameters.

> **Product:** (Can't enter the menu for some reason)
> - searchProduct() function: List of products, with Product type parameter.
> - addProduct() function: Add product to the database, with the necessary parameters to introduce in the database.

> **Backoffice:** (Some doubts in the creation process)
> - BackupBD() function: Creates database backup

### Data to login, after running buypy.sql

**Username:** pedro@mail.com <br>
**Password:** 123abC!

#### FINAL NOTE:
The buypy.py program may not be fully working, but hopefully for anyone who analyze the code will understand what was intended.
