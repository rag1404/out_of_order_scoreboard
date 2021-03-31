# out_of_order_scoreboard

// out of order transactions checking 

// We have two components comp_a,comp_b sending transactions to comp_c

// comp_a sends in order transactions to comp_c

// comp_b sends out of order transactions to comp_c

// comp_c stores both the transactions in separate associative array indexed through ID field in transaction

// comp_c checks if the ID exists in another Associative array, if yes then call the compare function of the transaction to see if it is a equal match !!
