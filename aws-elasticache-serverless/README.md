# elasticache serverless のベンチ

```sh
dd if=/dev/urandom bs=30K count=1 | base64 | head -c 30000 > app/dummy.txt
make build
./run.sh 10 300
make logs
```

```sh
aws logs start-query \
--log-group-name /aws/ecs/r8api-dev-sls \
--start-time "$(date +%s -d '-15min')" \
--end-time "$(date +%s)" \
--query-string 'stats count(*), sum(rps), sum(reqs), sum(errs), sum(errs) / sum(reqs) * 100, avg(duration) by date'
# {
#     "queryId": "7e96ade7-7c53-4045-bfb8-fec4414709c3"
# }

aws logs get-query-results --query-id '7e96ade7-7c53-4045-bfb8-fec4414709c3'
