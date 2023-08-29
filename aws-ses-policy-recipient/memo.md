# [AWS]SESでIAMポリシーや承認ポリシーで宛先を制限
```sh
eval $(
    terraform output --json |\
        jq '[
            "export iam_role=\(.iam_role.value)",
            "export ses_identity=\(.ses_identity.value)"
        ] | join("\n")' -r
)
eval $(
    aws sts assume-role --role-arn "$iam_role" --role-session-name ses |\
        jq '.Credentials | [
            "export AWS_ACCESS_KEY_ID=\(.AccessKeyId)",
            "export AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey)",
            "export AWS_SESSION_TOKEN=\(.SessionToken)"
        ] | join("\n")' -r
)
aws sts get-caller-identity

aws ses send-email --from notify@hj1.work --to gotou@headjapan.com --subject OK1 --text "this is test"
aws ses send-email --from notify@hj1.work --to gotou.headjapan.com@gmail.com --subject OK2 --text "this is test"
aws ses send-email --from notify@hj1.work --to gotou@headjapan.com --cc gotou.headjapan.com@gmail.com --subject OK3 --text "this is test"
#=> ok

aws ses send-email --from notify@hj1.work --to ngyuki.jp@gmail.com --subject NG --text "this is test"
aws ses send-email --from notify@hj1.work --to ngyuki.jp@gmail.com --cc gotou.headjapan.com@gmail.com --subject NG --text "this is test"
aws ses send-email --from notify@hj1.work --to gotou.headjapan.com@gmail.com --cc ngyuki.jp@gmail.com --subject NG --text "this is test"
#=> ng
```
