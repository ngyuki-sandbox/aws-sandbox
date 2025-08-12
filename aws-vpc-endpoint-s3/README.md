
```sh
terraform apply

curl http://$(terraform output -raw domain)/index.html
curl http://$(terraform output -raw domain)/a.txt
curl http://$(terraform output -raw domain)/b.txt
```
