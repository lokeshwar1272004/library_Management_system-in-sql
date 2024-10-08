select * from books;
select * from branch;
select * from employees;
select * from issued_status;
select * from members;
select * from return_status;

--Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
insert into books(isbn,book_title,category,rental_price,status,author,publisher)
values ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co');

--Task 2: Update an Existing Member's Address
update members
set member_address = '125 main St'
where member_id = 'C103'

--Task 3: Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
delete from issued_status
where issued_id ='IS121'

--Task 4: Retrieve All Books Issued by a Specific Employee 
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
select * from issued_status
where issued_emp_id='E101'

--Task 5: List Members Who Have Issued More Than One Book 
-- Objective: Use GROUP BY to find members who have issued more than one book.
select issued_emp_id,count(issued_emp_id)as total_issued_book from issued_status 
group by issued_emp_id having count(issued_emp_id)>1;

--Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results
-- each book and total book_issued_cnt**
create table book_cont_issue as
select b.isbn,b.book_title,
count(ist.issued_id)from books as b
join  
issued_status as ist
on ist.issued_book_isbn = b.isbn
group by 1,2

--Task 7. Retrieve All Books in a Specific Category:
select * from books where category = 'Classic'

--Task 8: Find Total Rental Income by Category:
select b.category,sum(b.rental_price),count(*)
from books as b
join issued_status as ist
on ist.issued_book_isbn = b.isbn
group by 1

--List Members Who Registered in the Last 180 Days
select * from members
where reg_date > current_date - interval '180 days'

--List Employees with Their Branch Manager's Name and their branch details:
select * from employees;
select * from branch;

select e.*,
b.manager_id,
e2.emp_name as manager
from employees as e
join  branch as b
on e.branch_id = b.branch_id join 
employees as e2
on e2.emp_id = b.manager_id

--Create a Table of Books with Rental Price Above a Certain Threshold > 7:
create table book_price_greater_7
as
select * from books
where rental_price > 7;
select * from book_price_greater_7

-- Retrieve the List of Books Not Yet Returned
select * from return_status;
select * from issued_status;
select distinct ist.issued_book_name  from issued_status as ist
left join return_status  as rs
on ist.issued_id = rs.issued_id 
where rs.return_id is null

/*Advanced SQL Operations
--Task 13: Identify Members with Overdue Books
--Write a query to identify members who have overdue books (assume a 30-day return period).
--Display the member's_id, member's name, book title, issue date, and days overdue

--issued_status == member == books == return_status
--books return over due >180 */
select * from books;
select * from issued_status;
select * from members;
select * from return_status;

select  ist.issued_member_id,
m.member_name,
bk.book_title,
ist.issued_date,
rs.return_date,
current_date - ist.issued_date as over_due_days

from issued_status as ist
join members as m
on m.member_id=ist.issued_member_id
join 
books as bk
on bk.isbn = ist.issued_book_isbn
left join 
return_status as rs 
on rs.issued_id = ist.issued_id
where rs.return_date is null and
(current_date - ist.issued_date) >180
order by 1

/*Task 14: Update Book Status on Return
Write a query to update the status of books in the books table 
to "Yes" when they are returned (based on entries in the return_status table)
*/
select * from issued_status
where issued_book_isbn ='978-0-451-52994-2'
update books
set status = 'yes'
where isbn = '978-0-451-52994-2';

select * from return_status
where issued_id='Is130';

alter table return_status
add column book_quality varchar(15);
update return_status
set book_quality='GOOD'
select * from return_status;
 
insert into return_status(return_id,issued_id,retturn_book_namereturn_date,return_book_isbn)
values
('RS125','IS130','Moby Dick',current_date,'978-0-451-52994-2');
Select * from return_status where issued_id='IS130'

---store procedurces
create or replace procedure add_return_records(p_return_id varchar(10),p_issued_id varchar(10),p_book_quality varchar(10))
language plpgsql
as $$
declare
    v_isbn varchar(50);
    v_book_name varchar(80);

begin
     insert into return_status(return_id,issued_id,return_date,book_quality)
     values
     (p_return_id,p_issued_id,current_date,p_book_quality);

	  select issued_book_isbn,issued_book_name
	  into
	  v_isbn,
	  v_book_name
	  from issued_status where issued_id = p_issued_id;

	  update books
	  set status ='YES'
	  where isbn =v_isbn;

	  RAISE NOTICE 'THANK YOU for returning the book: %',v_book_name;
END;
$$

/*Branch Performance Report
Create a query that generates a performance report for each branch, 
showing the number of books issued, 
the number of books returned, and 
the total revenue generated from book rentals.*/
select * from books;
select * from branch;
select * from employees;
select * from issued_status;
select * from members;
select * from return_status;

create table branch_report as 
select br.branch_id,br.manager_id,count(ist.issued_id)as issued_count,
count(rs.return_id) as return_count,sum(b.rental_price) as reneval
from employees as e 
join issued_status as ist on
e.emp_id = ist.issued_emp_id
join books as b on
ist.issued_book_isbn = b.isbn
join branch as br on
br.branch_id = e.branch_id
left join 
return_status as rs on
ist.issued_id = rs.issued_id
group by 1,2 order by branch_id 
select  * from branch_report

--CTAS: Create a Table of Active Members
--Use the CREATE TABLE AS (CTAS) statement to create a new table active_members 
--containing members who have issued at least one book in the last 2 months.
create table active_members as
select * from members where member_id in 
(select distinct issued_member_id from issued_status 
where issued_date >=current_date - interval '6 month');
select * from active_members

--Write a query to find the top 3 employees who have processed the most book issues.
--Display the employee name, number of books processed, and their branch
select * from employees;
select * from issued_status;

select e.emp_name,b.*,count(ist.issued_emp_id)from issued_status as ist
join employees as e on
ist.issued_emp_id = e.emp_id
join branch as b on
b.branch_id = e.branch_id
group by 1,2 	order by 6

/*Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. 
Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 
The procedure should first check if the book is available (status = 'yes'). 
If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.*/
select * from books;
select * from issued_status;
select * from return_status;

create or replace procedure add_status(p_issued_id varchar(10),p_issued_member_id varchar(10),p_issued_book_isbn varchar(25),p_issued_emp_id varchar(10))
language plpgsql as $$
declare 

	 p_status varchar(15);

begin 

	 select status 
	 into
	 p_status from books where isbn = p_issued_book_isbn;

	 if p_status ='No' then

		insert into issued_status(issued_id,issued_member_id,issued_date,issued_book_isbn,issued_emp_id)
	    values (p_issued_id,p_issued_member_id,current_date,p_issued_book_isbn,p_issued_emp_id);

	    update books
	    set status ='Yes'
	    where isbn = p_issued_book_isbn;
		
	    raise notice 'book record was change successfully from isbn: %',p_issued_book_isbn;

	 
	 else 
	     raise notice 'sorry book was unavaliable %',p_issued_book_isbn;

	end if;
	     
end;
$$

call add_status('is141','C108','978-0-7432-7357-1','E107')
update books
	    set status ='No'
	    where isbn = '978-0-7432-7357-1';