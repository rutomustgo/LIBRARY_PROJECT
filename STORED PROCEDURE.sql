--Task 19: Stored Procedure Objective:
--Create a stored procedure to manage the status of books in a library system.
--Description: Write a stored procedure that updates the status of a book in the library 
--based on its issuance.
--The procedure should function as follows: 
--The stored procedure should take the book_id as an input parameter. 
--The procedure should first check if the book is available (status = 'yes').
--If the book is available, it should be issued,
--and the status in the books table should be updated to 'no'.
--If the book is not available (status = 'no'), 
--the procedure should return an error message indicating that the book is currently not available.



SELECT* FROM BOOKS

SELECT* FROM ISSUED_STATUS

CREATE OR REPLACE PROCEDURE ISSUE_BOOK(
P_ISSUE_ID varchar(10),
P_ISSUED_MEMBER_ID varchar(30),
P_ISSUED_BOOK_ISBN varchar(50),
P_ISSUED_emp_ID varchar(10))
LANGUAGE plpgsql
as $$

declare
v_status varchar(10);
begin

-- checking if book is available

select status
into
v_status
from books
where isbn=p_issued_book_isbn;

if v_status='yes' then

		insert into issued_status(issued_id,issued_member_id,issued_date,issued_book_isbn,issued_emp_id)
		values
		(P_ISSUE_ID,p_issued_member_id,current_date,p_issued_book_isbn,p_issued_emp_id);

		UPDATE BOOKS
		 SET STATUS='NO'
		WHERE ISBN=P_ISSUED_BOOK_ISBN;

		raise notice 'book record added successfully for book isbn : %',p_ISSUED_BOOK_ISBN;

ELSE

	raise notice 'SORRY TO INFORM YOU THE BOOK IS UNAVAILABLE BOOK ISBN : %',p_ISSUED_BOOK_ISBN;
END IF;
		
end;
$$

SELECT*FROM BOOKS
978-0-553-29698-2 -- YES
978-0-7432-7357-1 ---NO

SELECT*FROM ISSUED_STATUS

CALL ISSUE_BOOK('IS155','C108','978-0-553-29698-2','E104');


CALL ISSUE_BOOK('IS156','C108','978-0-7432-7357-1','E104');


SELECT*FROM BOOKS
WHERE ISBN='978-0-553-29698-2'






































