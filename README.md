# sp_what
The sp_what is a stored procedure that when executed gives you detailed information about what processes are executing and requesting memory grants.I am exposing the pre-calculated memory counters, as well as DOP and QueryCost.

This shows us exactly what is requesting how much memory, further allowing us to focus on the problem queries with large memory grants but low actual usage. 

