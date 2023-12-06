# Database Indexes 101

Database indexing is a detailed topic evident by the many online whitepapers covering every aspect of the subject.  The following provides some high level insight into frequently asked questions.

## FAQ

**Q:** What is a database index?

**A:** Much like an index in a book, a database index increases data searches by logging a row identifier (RID) against a searchable argument, for example an searchable argument may be <vehicle registration>.

**Q:** What is index maintenance?

**A:** Unlike a book the data within a database changes when data is inserted, updated or deleted.  When this happens the row identifier in the index becomes stale and searches against these records take longer.

**Q:** How often must index maintenance occur?

**A:** This depends on the data change within the table, best practices state that an index should be reorganised at 5% and rebuilt at 30% fragmentation.  At organisation standard jobs are deployed to monitor table fragmentation and take the necessary action, unless the business has opted to maintain this themselves.

**Q:** How long will index maintenance take?

**A:** Index maintenance is dependent on a number of factors:

- Size of the table.
- Size of the index (for non-clustered covering indexes).
- Size of the Server: CPU's, Memory, and disk latency/capacity.
- Online activity, for offline indexes maintenance performance will be hampered by user activity.
- Index level of fragmentation and location of fragmentation.

**Q:** Can the duration of index maintenance be projected?

**A:** In a perfect environment where the percentage data change is set.  However this is seldom the case as the percentage data change is based on the workload of the system.

> As an example consider a book where the last 2 pages needed to be switched, in this case there would be 2 updates to the index.  Now consider the same scenario where it was the last and first pages that needed to be switched, in this case every index row identifier needs updating.  You may as well throw away the book and start again, this is not unlike how a database engine would look at the problem.  See following table taken from a live system.

| Job duration | No. of indexes rebuilt |
|--------------|------------------------|
|    02:55     |  2                     |
|    02:06     |  1                     |
|    03:37     |  9                     |
|    05:09     | 24                     |

In summary it is not possible to pin down the exact duration of index maintenance, but a rough trend can be calculated from historical data, however considering the next question what would the appropriate action to this event?

**Q:** Can index maintenance be cancelled?

**A:** Short answer NO. Index maintenance is a logged transaction to maintain database consistency.  Terminating index maintenance results in the task being rolled back.

> Consider if an index maintenance task took 2 hours to get to 90% complete it is likely to take a further 2 hour to rollback the transaction.

Passed experiences with index maintenance has taught us to let the task complete, but ultimately this is a business call and they need to accept the consequences.

**Q:** Can we monitor the progress of index maintenance?

**A:** There are functions within the database engine that provide feedback on executing requests, but the output is an estimate only and not reliable.  

> Consider the maintenance for an index of LastName, lets approximate the key is segregated into 26 unique values for demonstration purposes. At the letter 'R' the engine would estimate  69% completion, but we understanding that there are more 'Smiths' within the data-set than any other LastName.  Hence actual progress is likely to be 50%.

In summary the progress is not linear as it is dependent distribution of data.

**Q:** Can I as an application DBA do anything to improve my indexes and index maintenance?

**A:** Yes, as an application DBA there are many tasks you must take weekly to keep your indexes tuned:

- Monitor index fragmentation and if maintenance is not automated take necessary action.
- Review index usage, unused indexes are an overhead on the system and unnecessary degrade response times.
- Review missing index statistics, most advance database engines such as MSSQL, oracle and db2 maintain statistics on how data was queried and will recommend appropriate indexes to improve response times.  This data must be regularly reviewed and data changes to tune indexes appropriately  .
- Don't collect unnecessary data.  Collecting data for the sake of it will indeed the application over time as the data-set grows searches and index maintenance will take longer.  Keep over the data necessary for the task.
- Don't keep old unused data.  As above archive or delete data that is not used day to day.
- Inform you supplier of changes to you data pattern.  Advertisement campaigns or additional features will undoubtedly effect the pattern of data change within the system. Advanced warning of this and appropriate NFT will allow time to increase capacity and avoid any potential service outages
