A high level understanding of the root cause for the application issue, is that an Intrasession Parallelism Deadlock within the applications database prevented the completion of client inputs.  Thus resulting in the blocking of all application inputs.

What is the cause of Intrasession Parallelism Deadlock, simply put, it is bad design, however a good design can become bad if the data profile changes in such a way that the events were never considered within the initial design requirements. 

The following is a simplified explanation of the events that caused the deadlock, and witnessed within the test environment where the issue was replicated. 

	- Query 1 starts its execution and is assigned 8 threads.
	- While waiting on IO operation query 2 starts its execution and is assigned 8 threads.
	- Query 2 also needs data and enters a waiting state for the IO operation to complete.
	- Query 3 starts execution, and enters a waiting state for IO operations to complete.
	- On query 1 thread 2 results are completed and is assigned for the task
	- On query 2 threads 2, and 6 results are completed and are assigned for the task, however as thread 2 is currently being used by query 1 thread 2 becomes blocked, thus the query cannot complete.
	- On query 3 threads 4, and 6 results are completed and are assigned for the task, however as thread 6 is currently being used by query 2 thread 6 becomes blocked, thus the query cannot complete.
	- On query 1 thread 4 results are completed and is assigned for the task, however as thread 4 is currently being used by query 3 thread 4 becomes blocked.
	- As all three queries are effectively blocking each other none of the queries can complete their operation and the system enters deadlock.

Changing the maximum degree of parallelism (MAXDOP) from 0 to 1 forced the server to assign only 1 thread to any executing query, thus preventing the above events.  This may have little to no impact to small queries however resource intensive queries such as reports would now take longer to run.

Ideally a system should be tuned using both the MAXDOP and Cost Threshold for Parallelism options at the server or database level.

The Cost Threshold for Parallelism option is used to determine at what cost a query will be split across multiple threads.  The default value is 5, however existing recommendations suggest a setting of between 25 to 50.

The MAXDOP option is a hard-line setting.  At 0 it is left to the system to decide the number of threads a query uses, where as a setting of 1, 2, or 4 will enforce the number of execution threads.

In test initially try
	- Cost Threshold for Parallelism = 50
	- MAXDOP = 2
Test both normal activity and reports and tweak the Cost Threshold for Parallelism down and the MAXDOP up until you are happy with the report execution time, if normal activity suffers from these change then tweak the Cost Threshold for Parallelism up and the MAXDOP down until the results are better.

Note changes to the MAXDOP and Cost Threshold for Parallelism options are like switches and the effects are immediate, thus if when rolling out to production the changes has a negative effect you can simply switch back to MAXDOP = 1 and once blocked transactions are killed service will return.
