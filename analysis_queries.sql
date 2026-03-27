SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM members;
SELECT * FROM return_status;

-- Project Task
-- CRUD operation (CREATE, READ, UPDATE, DELETE)
-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')

-- Task 2: Update an Existing Member's Address
UPDATE members
SET member_address = '125 Main St'
WHERE member_id = 'C101';

-- Task 3: Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
DELETE FROM issued_status
WHERE issued_id = 'IS121'

-- Task 4: Retrieve All Books Issued by a Specific Employee 
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101'

-- Task 5: List Members Who Have Issued More Than One Book 
-- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT 
	issued_emp_id,
	COUNT (*) AS total_book_issued
FROM issued_status
GROUP BY issued_emp_id
HAVING COUNT (*) > 1;

-- CTAS (CREATE TABLE AS SELECT)
-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
CREATE TABLE book_issued_count AS
SELECT 
	b.isbn,
	b.book_title,
	COUNT (i.issued_id) AS issued_count
FROM books AS b
JOIN issued_status AS i 
ON b.isbn = i.issued_book_isbn
GROUP BY 1,2;

SELECT * FROM book_issued_count;

-- Data Analysis & Findings
-- Task 7. Retrieve All Books in a Specific Category:
SELECT category FROM books GROUP BY 1;

SELECT * FROM books
WHERE category = 'Fantasy';

-- Task 8: Find Total Rental Income by Category:
SELECT
	b.category,
	SUM(b.rental_price)
FROM books AS b
JOIN issued_status AS i
ON b.isbn = i.issued_book_isbn
GROUP BY b.category;

-- Task 9: List Members Who Registered in the Last 180 Days
SELECT * FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days'

INSERT INTO members (member_id, member_name, member_address, reg_date)
VALUES 
	('C111', 'Adam Husein', '791 Oak St', '2026-01-24'),
	('C124', 'Emily Pattinson', '273 Pine St', '2026-03-01');

-- Task 10: List Employees with Their Branch Manager's Name and their branch details
SELECT 
	e1.emp_id,
	e1.emp_name,
	e1.position,
	e1.salary,
	b.*,
	e2.emp_name  AS manager
FROM employees AS e1
JOIN branch AS b
ON e1.branch_id = b.branch_id
JOIN employees AS e2
ON b.manager_id = e2.emp_id;

-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold:
CREATE TABLE expensive_books AS
SELECT * FROM books
WHERE rental_price >= 7.00;

SELECT * FROM expensive_books;

-- Task 12: Retrieve the List of Books Not Yet Returned
SELECT * 
FROM issued_status AS i
LEFT JOIN return_status AS r
ON i.issued_id = r.issued_id
WHERE r.issued_id IS NULL;

-- ADVANCED SQL
/** Task 13: Identify Members with Overdue Books.
Write a query to identify members who have overdue books (assume a 30-day return period). 
Display the member's_id, member's name, book title, issue date, and days overdue.**/
SELECT 
	m.member_id,
	m.member_name,
	i.issued_book_name,
	i.issued_date,
	CURRENT_DATE - i.issued_date AS days_overdue
FROM members AS m
JOIN issued_status AS i
ON m.member_id = i.issued_member_id
LEFT JOIN return_status AS r
ON r.issued_id = i.issued_id
WHERE 
	r.return_date IS NULL
	AND
	CURRENT_DATE - i.issued_date > 30
ORDER BY m.member_id
;

/** Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the 
number of books issued, the number of books returned, and the total revenue 
generated from book rentals.**/
CREATE TABLE branch_performance AS
SELECT 
	b.branch_id,
	b.manager_id,
	COUNT(i.issued_id) AS num_books_issued,
 	COUNT(r.return_id) AS num_books_return,
	SUM(bk.rental_price) AS total_revenue 
FROM issued_status AS i
JOIN employees AS e
ON e.emp_id = i.issued_emp_id
JOIN branch AS b
ON b.branch_id = e.branch_id
LEFT JOIN return_status AS r
ON r.issued_id = i.issued_id
JOIN books AS bk
ON bk.isbn = i.issued_book_isbn
GROUP BY 1,2
ORDER BY 5 DESC;

SELECT * FROM branch_performance;

/** Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members 
containing members who have issued at least one book in the last 2 months.**/
-- join
SELECT 
	m.*,
	COUNT (i.issued_id) AS sum_issued_book
FROM members AS m
JOIN issued_status AS i
ON m.member_id = i.issued_member_id
WHERE i.issued_date >= CURRENT_DATE - INTERVAL '24 month'
GROUP BY m.member_id;

SELECT * FROM issued_status

-- subquery
SELECT * FROM members
WHERE member_id IN
				(SELECT DISTINCT issued_member_id FROM issued_status
				WHERE issued_date >= CURRENT_DATE - INTERVAL '24 month')

/** Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. 
Display the employee name, number of books processed, and their branch.**/
-- TOP 3 GLOBAL
SELECT
	b.branch_id,
	e.emp_id,
	e.emp_name,
	COUNT(i.issued_id) AS total_book_issued
FROM branch AS b
JOIN employees AS e
ON b.branch_id = e.branch_id
JOIN issued_status AS i
ON e.emp_id = i.issued_emp_id
GROUP BY 1,2
ORDER BY 4 DESC
LIMIT 3;

-- TOP 3 TIAP CABANG
SELECT * FROM (
	SELECT
		b.branch_id,
		e.emp_id,
		e.emp_name,
		COUNT(i.issued_id) AS total_book_issued,
		ROW_NUMBER() OVER (
			PARTITION BY b.branch_id
			ORDER BY COUNT(i.issued_id) DESC) AS ranking
		FROM branch AS b
		JOIN employees AS e
		ON b.branch_id = e.branch_id
		JOIN issued_status AS i
		ON e.emp_id = i.issued_emp_id
		GROUP BY 1,2
		) AS rank_branch
WHERE ranking<=3
ORDER BY branch_id

/** Task 18: Identify Members Issuing High-Risk Books
Write a query to identify members who have issued books more than twice with the 
status "damaged" in the books table. Display the member name, book title, and 
the number of times they've issued damaged books.**/
SELECT * FROM return_status