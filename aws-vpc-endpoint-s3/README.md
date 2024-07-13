
```sh
terraform apply

ssh "ec2-user@$(terraform output -raw instance_id)"

curl https://<BUCKET>.s3.ap-northeast-1.amazonaws.com/a.txt
curl https://<BUCKET>.s3.ap-northeast-1.amazonaws.com/b.txt
```
