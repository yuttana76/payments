# EP01
Go Microservices Full Course: Build a Payments System From Scratch
https://www.youtube.com/watch?v=AVy0hy4qSnQ

github
https://github.com/dev-marker/payments/blob/ep03/cmd/wallet/main.go

Run on production env.
>APP_ENV=production make run-wallet

curl command 
>curl -i localhost:8081/healthz
>curl -s -H 'X-Request-ID: checkout-42' localhost:8081/wallets/123

** Before git **
>make test
>go vet ./...
>git status --short
>git diff -U2 cmd/wallet/main.go
>git add .
>git commit -m "feat(wallet): "

***************************

STEP:Build production-grade
>docker-compose up -d
>docker compose ps --format "table {{.Service}} \t{{.State}}\t{{.Status}}"

Check services
>docker compose exec postgres pg_isready -U payments
>docker compose exec redis redis-cli ping
>docker compose postgres pg_isready -U payments

>go run ./cmd/wallet

Test 
>curl -i localhost:8081/healthz
>curl -i -X POST localhost:8081/api/v1/healthz 
>curl -s localhost:8222/healthz
  
Build static binary 
>go build -o /tmp/wallet ./cmd/wallet  && du -h /tmp/wallet
>/tmp/wallet & sleep 1;curl -s localhost:8081/healthz; kill -TERM $!; wait

# EP02
>docker compose down -v
>docker compose up -d --wait
>docker compose exec -T postgres psql -U payments -c "SELECT datname FROM pg_database WHERE NOT datistemplate "
>docker compose exec -T postgres psql -U payments -d wallet -c '\dt'


Install migrate for postgres
>go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
>which migrate
>migrate -version
>migrate create -ext sql -dir db/wallet/migrations -seq init_ledger

## Make file
>make migrate-up
>make migrate-down
>make migrate-version
>make migrate-new

Check tables in wallet db
>docker compose exec -T postgres psql -U payments -d wallet -c '\dt'
>docker compose exec -T postgres psql -U payments -d wallet -c 'SELECT name,balance FROM account_balances ORDER BY name' 

#### For test query
Create file scratch.sql
> docker compose exec -T postgres psql -U payments -d wallet -q < scratch.sql

```
\set VERBOSITY terse

SELECT conname,contype
FROM pg_constraint
WHERE conrelid = 'entries'::regclass
ORDER BY conname;
```

- Scenario 1: perfect cast
scratch.sql
```
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


BEGIN;
INSERT INTO transactions (description)
VALUES('alice pays bob $20') RETURNING id AS tx \gset
INSERT INTO entries(transaction_id,account_id,direction,amount,currency)VALUES
(:'tx',:'alice','debit',2000,'USD'),
(:'tx',:'bob','credit',2000,'USD');
COMMIT;

SELECT name,balance
FROM account_balances
WHERE account_id IN (:'bank',:'alice',:'bob')
ORDER BY name;
```
>docker compose exec -T postgres psql -U payments -d wallet -c 'SELECT direction,sum(amount) FROM entries GROUP BY 1 ORDER BY 1' 
>docker compose exec -T postgres psql -U payments -d wallet -q < scratch.sql

- Scenario 2 credit and debit not equal

```
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


BEGIN;
INSERT INTO transactions (description)
VALUES('alice pays bob $20') RETURNING id AS tx \gset
INSERT INTO entries(transaction_id,account_id,direction,amount,currency)VALUES
(:'tx',:'alice','debit',2000,'USD'),
(:'tx',:'bob','credit',1500,'USD');
COMMIT;

SELECT name,balance
FROM account_balances
WHERE account_id IN (:'bank',:'alice',:'bob')
ORDER BY name;
```


- Scenario 3 construct check constraint

```
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
```

### Git
>git status --short
>git diff -U2 docker-compose.yml
>git add .
>git commit -m "feat(wallet): double-entry ledger schema and migration" 

# EP03
    Tell benefit for  sqlc and compare with another way
    start to sqlc

## install sqlc
>go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
>which sqlc
>sqlc --version

### Create SQL queries
- db/wallet/queries/accounts.sql
- db/wallet/queries/ledger.sql

### Generate Go code from SQL definitions
>sqlc generate

## install pgx driver
>go get github.com/jackc/pgx/v5
>go get github.com/google/uuid

>go build ./...

## Create connection pool
Wallet/internal/platform/postgres/postgres.go
>go mod tidy

create files
> Wallet/internal/wallet/store.go
> Wallet/internal/wallet/ledger.go

To check the error in your code.
>go vet ./...

Start service 
>go run ./cmd/wallet

curl -s localhost:8081/healthz
curl -i localhost:8081/readyz

Test db down
>docker stop payment-postgres
>docker compose up -d --wait postgres
>curl -i localhost:8081/readyz

## Go test files
create store_test.go

>go test ./...

## Make test
make test TESTFLAG='-v run Unbalanced'

>git status --short
>git diff -U2 cmd/wallet/main.go
>git add .
>git commit -m "feat(wallet): add DB store with SQLC-generated code" 

# EP04

## A middleware chain
>go test ./internal/platform/config

>go test ./internal/platform/...
>go test -v -run 'TestError$' ./internal/platform/httpx

>go vet ./...

### Run with env
>APP_ENV=prod LOG_LEVEL=loud WALLET_DB_MAM=ten  go run ./cmd/wallet

make run-wallet

!WATCH NEXT 45 mins.
In youtube is 2:50:41