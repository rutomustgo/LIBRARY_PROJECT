-- CREATING LIBRARY PROJECT

-- CREATING BRANCH TABLE

DROP TABLE IF EXISTS BRANCH;
CREATE TABLE BRANCH(
branch_id VARCHAR(10)PRIMARY KEY,
manager_id VARCHAR(10),
branch_address VARCHAR(55),
contact_no VARCHAR(10)
);

ALTER TABLE BRANCH
ALTER COLUMN contact_no type varchar(20);


DROP TABLE IF EXISTS EMPLOYEES;
CREATE TABLE EMPLOYEES(
emp_id VARCHAR(20) PRIMARY KEY,
emp_name VARCHAR(25),
position VARCHAR(25),
salary	INT,
branch_id VARCHAR(30)-- FK
);

DROP TABLE IF EXISTS BOOKS;
CREATE TABLE BOOKS(
isbn VARCHAR(20) PRIMARY KEY,
book_title VARCHAR(75),
category VARCHAR(20),
rental_price FLOAT,
status VARCHAR (40),
author VARCHAR (40),
publisher VARCHAR(60)
);


DROP TABLE IF EXISTS MEMBERS;
CREATE TABLE MEMBERS(
member_id VARCHAR(30) PRIMARY KEY,
member_name VARCHAR(30),
member_address VARCHAR(75),
reg_date DATE
);


DROP TABLE IF EXISTS ISSUED_STATUS;
CREATE TABLE ISSUED_STATUS(
issued_id VARCHAR(30) PRIMARY KEY,
issued_member_id VARCHAR(30), -- FK
issued_book_name VARCHAR(75),
issued_date DATE,
issued_book_isbn VARCHAR(55), -- FK
issued_emp_id VARCHAR(35)  -- FK
);


DROP TABLE IF EXISTS RETURN_STATUS;
CREATE TABLE RETURN_STATUS(
return_id VARCHAR(20) PRIMARY KEY,
issued_id VARCHAR(20),
return_book_name VARCHAR(75),
return_date	DATE,
return_book_isbn VARCHAR(60)
);


SELECT * FROM information_schema.tables WHERE table_schema = 'public';





-- FOREIGN KEY CONCEPT

ALTER TABLE ISSUED_STATUS
ADD CONSTRAINT FK_MEMBERS
FOREIGN KEY (ISSUED_MEMBER_ID)
REFERENCES MEMBERS(MEMBER_ID);


ALTER TABLE ISSUED_STATUS
ADD CONSTRAINT FK_BOOKS
FOREIGN KEY (ISSUED_BOOK_ISBN)
REFERENCES BOOKS(ISBN);


ALTER TABLE ISSUED_STATUS
ADD CONSTRAINT FK_EMPLOYEES
FOREIGN KEY (ISSUED_EMP_ID)
REFERENCES EMPLOYEES(EMP_ID);


ALTER TABLE EMPLOYEES
ADD CONSTRAINT FK_BRANCH
FOREIGN KEY (BRANCH_ID)
REFERENCES  BRANCH(BRANCH_ID);

ALTER TABLE RETURN_STATUS
ADD CONSTRAINT FK_ISSUED_STATUS
FOREIGN KEY (ISSUED_ID)
REFERENCES  ISSUED_STATUS(ISSUED_ID);


-- creating a new book record 

INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;


-- updating an existing member's adress

UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';

-- delete a record from the issue status table

DELETE FROM issued_status
WHERE   issued_id =   'IS121';


-- retrieve all books issued by a specific employee

SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';

-- list members that have issued more than one book

SELECT
    issued_emp_id,
    COUNT(*)
FROM issued_status
GROUP BY 1
HAVING COUNT(*) > 1;

-- CTAs create summary tables to generate new tables based on query results each book and total book issued count


CREATE TABLE book_issued_cnt AS
SELECT b.isbn, b.book_title, COUNT(ist.issued_id) AS issue_count
FROM issued_status as ist
JOIN books as b
ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title;


-- books in a specific category

SELECT * FROM books
WHERE category = 'Classic';


-- find total rental income by category


SELECT 
    b.category,
    SUM(b.rental_price),
    COUNT(*)
FROM 
issued_status as ist
JOIN
books as b
ON b.isbn = ist.issued_book_isbn
GROUP BY 1;

-- list members who registerd in the last 180 days

SELECT * FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days'



-- list members with their branch manager's name and branch details

SELECT 
    e1.emp_id,
    e1.emp_name,
    e1.position,
    e1.salary,
    b.*,
    e2.emp_name as manager
FROM employees as e1
JOIN 
branch as b
ON e1.branch_id = b.branch_id    
JOIN
employees as e2
ON e2.emp_id = b.manager_id


-- create a table of books with rental price above a certain threshhold 

CREATE TABLE expensive_books AS
SELECT * FROM books
WHERE rental_price > 7.00;


-- retrieve list of books not yet returned


SELECT * FROM issued_status as ist
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL;


-- identify members with overdue books

SELECT 
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    -- rs.return_date,
    CURRENT_DATE - ist.issued_date as over_dues_days
FROM issued_status as ist
JOIN 
members as m
    ON m.member_id = ist.issued_member_id
JOIN 
books as bk
ON bk.isbn = ist.issued_book_isbn
LEFT JOIN 
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE 
    rs.return_date IS NULL
    AND
    (CURRENT_DATE - ist.issued_date) > 30
ORDER BY 1;


-- update book status on return


CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10), p_book_quality VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
    v_isbn VARCHAR(50);
    v_book_name VARCHAR(80);
    
BEGIN
    -- all your logic and code
    -- inserting into returns based on users input
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES
    (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

    SELECT 
        issued_book_isbn,
        issued_book_name
        INTO
        v_isbn,
        v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    RAISE NOTICE 'Thank you for returning the book: %', v_book_name;
    
END;
$$


-- Testing FUNCTION add_return_records

issued_id = IS135
ISBN = WHERE isbn = '978-0-307-58837-1'

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

-- calling function 
CALL add_return_records('RS138', 'IS135', 'Good');

-- calling function 
CALL add_return_records('RS148', 'IS140', 'Good');



--branch performance report

CREATE TABLE branch_reports
AS
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) as number_book_issued,
    COUNT(rs.return_id) as number_of_book_return,
    SUM(bk.rental_price) as total_revenue
FROM issued_status as ist
JOIN 
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
JOIN 
books as bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY 1, 2;

SELECT * FROM branch_reports;



-- creating a table of active members



CREATE TABLE active_members
AS
SELECT * FROM members
WHERE member_id IN (SELECT 
                        DISTINCT issued_member_id   
                    FROM issued_status
                    WHERE 
                        issued_date >= CURRENT_DATE - INTERVAL '2 month'
                    )
;

SELECT * FROM active_members;



-- employees with the most books issued processed


SELECT 
    e.emp_name,
    b.*,
    COUNT(ist.issued_id) as no_book_issued
FROM issued_status as ist
JOIN
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
GROUP BY 1, 2;


-- 



SELECT 
    e.emp_name,
    b.*,
    COUNT(ist.issued_id) as no_book_issued
FROM issued_status as ist
JOIN
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
GROUP BY 1, 2


































































