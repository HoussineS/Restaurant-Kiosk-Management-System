Restaurant Kiosk Management System - Flutter Desktop

I want to build a professional Restaurant Kiosk Management System using Flutter Desktop (Windows) with a modern, clean, production-ready architecture.

Project Overview

The application will be a self-service restaurant kiosk that allows customers to browse the menu, place orders, receive a printed ticket, and track their order status. The system must work completely offline using a local database and be designed for touch-screen kiosk devices.

The application should be suitable for real restaurant usage and follow industry best practices.

Technical Stack
Flutter Desktop (Windows)
Dart
Riverpod for state management
SQLite (sqflite_common_ffi) for local storage
Go Router for navigation
ESC/POS thermal printer integration
Material 3 UI
Clean Architecture
Repository Pattern
Core Modules
1. Customer Kiosk

Customers can:

Browse product categories
View products with images
Add products to cart
Modify quantities
View total price
Confirm order
Receive printed ticket

The kiosk must be optimized for touch screens.

2. Product Management

Admin can:

Add products
Edit products
Delete products
Upload product images
Create categories
Set prices
Enable or disable products

Product fields:

id
name
description
category
image
price
available
3. Order Management

Orders must contain:

orderId
orderNumber
orderDate
orderTime
orderItems
totalPrice
status

Statuses:

Pending
Preparing
Ready
Completed
Cancelled
4. Kitchen Screen

Kitchen staff can:

View incoming orders
Change order status
Mark orders as ready
View preparation queue

Orders should automatically update.

5. Ticket Printing

Generate professional thermal receipts.

Receipt contains:

Restaurant Name

Order Number

Items

Quantities

Total Price

Date

Time

QR Code

Thank You Message

Support ESC/POS printers.

Provide a printer abstraction layer for future printer models.

6. Order History

Store all orders locally.

Features:

Search by order number
Search by date
Search by product
Reprint ticket
View completed orders
7. Analytics Dashboard

Show:

Daily sales
Weekly sales
Monthly sales
Revenue statistics
Most sold products
Number of orders
Average order value

Include charts and KPIs.

Database Design

Create SQLite schema for:

Categories
id
name
Products
id
categoryId
name
description
imagePath
price
available
Orders
id
orderNumber
totalPrice
status
createdAt
OrderItems
id
orderId
productId
quantity
unitPrice
Application Requirements
Fully offline
Responsive desktop UI
Full-screen kiosk mode
Dark and light theme
Error handling
Logging system
Clean code
SOLID principles
Dependency injection
Unit testing support
Expected Output

Generate:

Complete project architecture.
Folder structure.
Database schema.
Models.
Repositories.
Services.
Riverpod providers.
UI screens.
Navigation flow.
Thermal printer integration layer.
Sample code for each module.
Step-by-step implementation plan.