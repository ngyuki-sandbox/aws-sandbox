# SSM Automation で EC2 を ALB からデタッチ・アタッチしながらローリングアップデート

```sh
ssh ec2-user@i-xxxxxxxxxxxxxxxxx
sudo dnf install -y dnf-plugin-versionlock
sudo dnf versionlock clear
sudo dnf versionlock add '*'
cat /etc/dnf/plugins/versionlock.list
exit

ssh ec2-user@i-xxxxxxxxxxxxxxxxx cat /etc/dnf/plugins/versionlock.list > versionlock.list
```

```sh
aws ssm start-automation-execution \
    --document-name os-update \
    --max-concurrency 1 \
    --max-errors 1 \
    --target-parameter-name InstanceId \
    --targets Key=ParameterValues,Values=i-xxxxxxxxxxxxxxxxx

aws ssm start-automation-execution \
    --document-name os-update \
    --max-concurrency 1 \
    --max-errors 1 \
    --target-parameter-name InstanceId \
    --targets Key=tag:Env,Values=dev
```
