# 📚 Library Management System (SQL)

## 🧭 Overview
This SQL-based project simulates a real-world library management system — covering everything from database design to advanced analytical queries. Unlike simple data retrieval, this project focuses on building the schema from scratch, performing CRUD operations, and using advanced SQL techniques to answer operational and performance questions across branches, employees, members, and books.

▶️ **erd_schemas.sql** — includes all table definitions, `ALTER TABLE` refinements, and foreign key constraints that build the full database schema.

▶️ **analysis_queries.sql** — includes all CRUD operations, data analysis queries, CTAS statements, and advanced SQL used to answer the business questions.

---

## 📚 Research Questions
This project tackles four main areas through 18 specific tasks:

- **Data Management:** How do we create, update, and maintain clean library records?
- **Member & Book Insights:** Which members are most active? Which books are most issued?
- **Operational Performance:** Which branches generate the most revenue? Which employees process the most books?
- **Risk & Overdue Tracking:** Which members have overdue books or have handled damaged items?

---

## 📄 Dataset Description
The database is built from scratch with **6 interrelated tables**:

- 📋 **Transaction Records** (`issued_status`, `return_status`) — book issue and return logs
- 📖 **Book Catalog** (`books`) — ISBN, title, category, rental price, and availability
- 👤 **Member Data** (`members`) — member ID, name, address, and registration date
- 👨‍💼 **Employee Records** (`employees`) — staff details, position, salary, and branch assignment
- 🏢 **Branch Info** (`branch`) — branch address, contact, and manager assignment

---

## 🛠️ SQL Skills Used
This project applies a full set of modern SQL techniques across database design and analysis:

- 🏗️ **DDL & Schema Design:** Using `CREATE TABLE`, `ALTER TABLE`, and `ADD CONSTRAINT` for a normalized schema with proper foreign keys.
- ✏️ **CRUD Operations:** `INSERT`, `UPDATE`, `DELETE`, and `SELECT` for data management.
- 🔗 **Joins:** `INNER JOIN`, `LEFT JOIN`, and Self Join for multi-table queries.
- 💪 **Aggregations:** Using `SUM`, `COUNT`, `GROUP BY`, and `HAVING` for summary metrics.
- 📊 **Window Functions:** Using `ROW_NUMBER() OVER (PARTITION BY)` for per-branch rankings.
- 🧮 **CTAS:** `CREATE TABLE AS SELECT` to persist analytical results as new tables.
- ⚡ **Conditional Filtering:** Date arithmetic with `INTERVAL` and `CURRENT_DATE` for overdue detection.
- 🔍 **Subqueries:** Using `IN` with subqueries as an alternative to joins for active member detection.

---

## 1️⃣ How is the database structured?
🧮 **Method:** DDL — Schema Design & Foreign Keys

The database was built from scratch with 6 tables, each with appropriate data types. Several `ALTER TABLE` statements were applied after creation to refine column types and rename columns, reflecting real iterative development.

```sql
-- Sample: Create and refine the employees table
CREATE TABLE employees (
    emp_id    VARCHAR(10),
    emp_name  VARCHAR(30),
    position  VARCHAR(30),
    salary    FLOAT,
    branch_id VARCHAR(25)
);

-- Foreign keys linking all tables together
ALTER TABLE issued_status ADD CONSTRAINT fk_members
    FOREIGN KEY (issued_member_id) REFERENCES members(member_id);

ALTER TABLE issued_status ADD CONSTRAINT fk_books
    FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn);

ALTER TABLE employees ADD CONSTRAINT fk_branch
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id);

ALTER TABLE return_status ADD CONSTRAINT fk_issued_status
    FOREIGN KEY (issued_id) REFERENCES issued_status(issued_id);
```

### 📊 Key Findings
- 🏗️ **Normalized Design:** All 6 tables are linked through well-defined foreign key constraints, ensuring referential integrity across the entire system.
- 🔄 **Iterative Refinement:** Real-world schema adjustments (type changes, renames) were applied using `ALTER TABLE`, mirroring actual development workflows.

---

## 2️⃣ How do we manage library records?
🧮 **Method:** CRUD Operations

Core data management tasks were performed to keep the library's records accurate and up to date.

**Task 1 — Add a new book:**
```sql
INSERT INTO books (isbn, book_title, category, rental_price, status, author, publisher)
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes',
        'Harper Lee', 'J.B. Lippincott & Co.');
```

**Task 2 — Update a member's address:**
```sql
UPDATE members
SET member_address = '125 Main St'
WHERE member_id = 'C101';
```

**Task 3 — Delete a specific issued record:**
```sql
DELETE FROM issued_status
WHERE issued_id = 'IS121';
```

**Task 5 — Find members who issued more than one book:**
```sql
SELECT 
    issued_emp_id,
    COUNT(*) AS total_book_issued
FROM issued_status
GROUP BY issued_emp_id
HAVING COUNT(*) > 1;
```

### 📊 Key Findings
- 📖 **Catalog Growth:** New book records can be inserted cleanly and linked immediately through the books table.
- 🧹 **Data Integrity:** Removing specific records (like `IS121`) demonstrates targeted deletion without affecting unrelated data.
- 👥 **Repeat Issuers:** Identifying members who issue multiple books is key for library engagement tracking.

---

## 3️⃣ What are the key operational performance metrics?
🧮 **Method:** Aggregations, CTAS & Joins

I used aggregations and summary tables (via CTAS) to measure rental income, book popularity, and branch performance.

**Task 8 — Total rental income by category:**
```sql
SELECT
    b.category,
    SUM(b.rental_price) AS total_income
FROM books AS b
JOIN issued_status AS i ON b.isbn = i.issued_book_isbn
GROUP BY b.category;
```

**Task 6 — Summary table: issued count per book:**
```sql
CREATE TABLE book_issued_count AS
SELECT 
    b.isbn,
    b.book_title,
    COUNT(i.issued_id) AS issued_count
FROM books AS b
JOIN issued_status AS i ON b.isbn = i.issued_book_isbn
GROUP BY 1, 2;
```

**Task 15 — Branch performance report:**
```sql
CREATE TABLE branch_performance AS
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(i.issued_id)   AS num_books_issued,
    COUNT(r.return_id)   AS num_books_returned,
    SUM(bk.rental_price) AS total_revenue
FROM issued_status AS i
JOIN employees AS e  ON e.emp_id = i.issued_emp_id
JOIN branch AS b     ON b.branch_id = e.branch_id
LEFT JOIN return_status AS r ON r.issued_id = i.issued_id
JOIN books AS bk     ON bk.isbn = i.issued_book_isbn
GROUP BY 1, 2
ORDER BY total_revenue DESC;
```

### 📊 Key Findings
- 💰 **Revenue Drivers:** Category-level revenue totals reveal which genres generate the most income for the library.
- 📈 **Book Popularity:** The `book_issued_count` table instantly shows which titles are most in demand.
- 🏢 **Branch Comparison:** The `branch_performance` table ranks all branches by revenue, giving management a clear snapshot of top performers.

---

## 4️⃣ Who are the most active members and employees?
🧮 **Method:** CTAS, Subquery, Window Functions

I identified active members and top-performing employees using multiple approaches for comparison.

**Task 16 — Active members in the last 2 months (two approaches):**
```sql
-- Using JOIN
SELECT m.*, COUNT(i.issued_id) AS sum_issued_book
FROM members AS m
JOIN issued_status AS i ON m.member_id = i.issued_member_id
WHERE i.issued_date >= CURRENT_DATE - INTERVAL '2 month'
GROUP BY m.member_id;

-- Using Subquery
SELECT * FROM members
WHERE member_id IN (
    SELECT DISTINCT issued_member_id FROM issued_status
    WHERE issued_date >= CURRENT_DATE - INTERVAL '2 month'
);
```

**Task 17 — Top 3 employees per branch (Window Function):**
```sql
SELECT * FROM (
    SELECT
        b.branch_id,
        e.emp_id,
        e.emp_name,
        COUNT(i.issued_id) AS total_book_issued,
        ROW_NUMBER() OVER (
            PARTITION BY b.branch_id
            ORDER BY COUNT(i.issued_id) DESC
        ) AS ranking
    FROM branch AS b
    JOIN employees AS e ON b.branch_id = e.branch_id
    JOIN issued_status AS i ON e.emp_id = i.issued_emp_id
    GROUP BY 1, 2
) AS rank_branch
WHERE ranking <= 3
ORDER BY branch_id;
```

### 📊 Key Findings
- 🏆 **Top Employees:** `ROW_NUMBER() OVER (PARTITION BY branch_id)` cleanly ranks the top 3 performers within each branch independently.
- 👥 **Engagement Tracking:** Active member queries can be reused as a `CTAS` to feed retention or outreach workflows.
- 🔄 **Method Comparison:** Both JOIN and subquery approaches return equivalent results — demonstrating query flexibility.

---

## 5️⃣ What are the overdue and risk patterns?
🧮 **Method:** Multi-table JOIN & Date Arithmetic

I flagged books that were never returned and members who have exceeded the 30-day return period.

**Task 12 — Books not yet returned:**
```sql
SELECT * 
FROM issued_status AS i
LEFT JOIN return_status AS r ON i.issued_id = r.issued_id
WHERE r.issued_id IS NULL;
```

**Task 13 — Members with overdue books (30-day threshold):**
```sql
SELECT 
    m.member_id,
    m.member_name,
    i.issued_book_name,
    i.issued_date,
    CURRENT_DATE - i.issued_date AS days_overdue
FROM members AS m
JOIN issued_status AS i ON m.member_id = i.issued_member_id
LEFT JOIN return_status AS r ON r.issued_id = i.issued_id
WHERE r.return_date IS NULL
  AND CURRENT_DATE - i.issued_date > 30
ORDER BY m.member_id;
```

### 📊 Key Findings
- 🔴 **Overdue Detection:** The 30-day threshold query gives staff an actionable list of members to follow up with immediately.
- 📋 **Unreturned Books:** `LEFT JOIN` with a `NULL` check on `return_status` reliably surfaces all outstanding loans without losing any issued records.

---

## ✅ Conclusion
As someone passionate about data, this project gave me a structured way to explore database design and library operations end-to-end. Starting from a blank schema, I built all 6 tables with proper constraints, populated them with real data, and used SQL — including window functions, CTAS, and date arithmetic — to answer meaningful operational questions.

🔍 I hope this project offers helpful insights — whether you're into database design, data analysis, or exploring what SQL can do.

---

## 📩 Contact & Connect
If you have any questions or would like to collaborate, feel free to reach out!

- **LinkedIn:** [Hanifah Arrasyidah](https://linkedin.com/in/your-profile)
- **GitHub:** [Hanifah Arrasyidah](https://github.com/your-username)
- **Email:** hanifaharrasyidah@email.com
