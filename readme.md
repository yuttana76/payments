Go Microservices Full Course: Build a Payments System From Scratch
https://www.youtube.com/watch?v=AVy0hy4qSnQ

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
  
>go build -o /tmp/wallet ./cmd/wallet  && du -h /tmp/wallet

>/tmp/wallet & sleep 1;curl -s localhost:8081/healthz; kill -TERM $!; wait