\set VERBOSITY terse

INSERT INTO accounts(name,currency,normal_balance)
VAlUES('bank','USD','debit') RETURNING id AS bank \gset
INSERT INTO accounts(name,currency,normal_balance)
VAlUES('alice','USD','credit') RETURNING id AS alice \gset
INSERT INTO accounts(name,currency,normal_balance)
VAlUES('bob','USD','credit') RETURNING id AS bob \gset

BEGIN;
INSERT INTO transactions (description)
VALUES('alice deposits $50') RETURNING id AS tx \gset
INSERT INTO entries(transaction_id,account_id,direction,amount,currency)VALUES
(:'tx',:'bank','debit',5000,'USD'),
(:'tx',:'alice','credit',5000,'USD');
COMMIT;

INSERT INTO transactions(description) VALUES('nothing to see here');

INSERT INTO entries(transaction_id,account_id,direction,amount,currency) 
VALUES(:'tx',:'alice','debit',-500,'USD');

INSERT INTO entries(transaction_id,account_id,direction,amount,currency) 
VALUES(:'tx',:'alice','debit',500,'EUR');

INSERT INTO accounts(name,currency,normal_balance)
VALUES ('carol','usd','credit');

UPDATE entries SET amount =500000 WHERE account_id=:'alice';

DELETE FROM transactions WHERE id=:'tx';