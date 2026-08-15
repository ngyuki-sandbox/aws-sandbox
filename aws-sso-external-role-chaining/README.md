# IAM Identity Center から組織外アカウントへの AssumeRole をユーザー属性で制御

## SSO -> 組織外アカウントの Role へ直接 AssumeRole

IAM Identity Center の SSO のセッションでは、許可セット（Permission Set）を割り当てたときにメンバーアカウントに自動で作成されている、次のような IAM Role が使用される。

```
AWSReservedSSO_<PermissionSet名>_<ランダムなサフィックス>
```

サフィックス部分は許可セットを解除→再割り当てなどで変わることがあるようで、これを固定的なモノとして使うのは危うい。
よって、組織外のアカウントの IAM Role の信頼ポリシーは次のようにワイルドカート付きで設定してもらうことになる。

```jsonc
// 組織外の IAM Role の信頼ポリシー
{
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Principal": {
        "AWS": "arn:aws:iam::0123456789:root"
    },
    "Condition": {
        "ArnLike": {
            "aws:PrincipalArn": "arn:aws:iam::0123456789:role/aws-reserved/sso.amazonaws.com/ap-northeast-1/AWSReservedSSO_ExternalAccountAccess_*"
        }
    }
}
```

## ブリッジアカウント

組織外の IAM Role へ AssumeRole する元となる AWS アカウントは Org の管理アカウントとは別に設ける。

というのも、Org のメンバーアカウントの作成時に次のような管理アカウント全体に対する信頼ポリシーが付与された、AdministratorAccess ポリシーを持つ IAM Role が自動作成される。

```jsonc
// OrganizationAccountAccessRole
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::9999999999:root" // 管理アカウント
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

これは管理アカウント内の任意のプリンシパルからの AssumeRole を可能にしてしまうので、組織外の IAM Role へ AssumeRole するために管理アカウント内でセッションを開始可能にしてしまうと、実質 Org 内の全メンバーアカウントへの無制限のアクセスを許可してしまうことになる。それは意図したものではない。

管理アカウントとは別に、専用のメンバーアカウントを用意しておけば問題無し（これを今後ブリッジアカウントと呼ぶ）。

### ユーザー属性で識別

前述の組織外 IAM Role の信頼ポリシーだと、許可セット ExternalAccountAccess を割り当てられた任意のユーザーからの AssumeRole が許可される。ただ、特定の誰それだけを許可したい、ということはありがち。ユーザーごとに許可セットを作る、ということも考えられるが、組織の規模によっては現実的ではない。

そこで、IAM Identity Center のアクセスコントロールの属性の設定で次のように設定しておくと、

```
email: ${path:emails[primary eq true].value}
```

信頼ポリシー側で `aws:PrincipalTag/email` のような条件キーでメールアドレスで制限できる。

```jsonc
// 組織外の IAM Role の信頼ポリシーで oreore@example.com だけを許可する
{
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Principal": {
        "AWS": "arn:aws:iam::0123456789:root"
    },
    "Condition": {
        "ArnLike": {
            "aws:PrincipalArn": "arn:aws:iam::0123456789:role/aws-reserved/sso.amazonaws.com/ap-northeast-1/AWSReservedSSO_ExternalAccountAccess_*"
        },
        "StringEquals": {
            "aws:PrincipalTag/email": "oreore@example.com"
        }
    }
}
```

## SSO -> ブリッジ Role -> 組織外 Role

組織外 Role へ直接 AssumeRole するパターンの問題点は、組織外の IAM Role の信頼ポリシーがやや複雑になること。
IAM Identity Center を利用しておらず、基本的に IAM User からの AssumeRole を前提としている組織であれば、Principal に IAM User の arn を 1 行追加するだけで済むので、それと比べると難解で、知らない人ではギョッとするかもしれない。

そこで、前述のユーザー属性での制御を組織内で完結させ、組織外への AssumeRole する元のプリンシパルは固定的なものになるように、ブリッジアカウントに IAM Role を用意する。

```jsonc
// ブリッジアカウントでユーザーごとに設ける IAM Role の信頼ポリシー
{
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Principal": {
        "AWS": "arn:aws:iam::0123456789:root"
    },
    "Condition": {
        "ArnLike": {
            "aws:PrincipalArn": "arn:aws:iam::0123456789:role/aws-reserved/sso.amazonaws.com/ap-northeast-1/AWSReservedSSO_ExternalAccountAccess_*"
        },
        "StringEquals": {
            "aws:PrincipalTag/email": "oreore@example.com"
        }
    }
}
```

ブリッジアカウントの IAM Role の信頼ポリシーの内容は最初のパターンでの組織外の IAM Role の信頼ポリシーと変わらない。
ただ、組織外の IAM Role の信頼ポリシーは次のように固定的な IAM Role の ARN の許可だけで収めることができる。

```jsonc
// 組織外の IAM Role の信頼ポリシーで oreore だけを許可する
{
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Principal": {
        "AWS": "arn:aws:iam::0123456789:role/oreore"
    }
}
```

### aws-vault の設定

`aws-vault` では、通常の SSO 用に設定したプロファイルを `source_profile` で指定すれば SSO のセッションから AssumeRole できる。

```ini
[profile bridge-sso]
sso_start_url = https://d-1234567890.awsapps.com/start/
sso_region = ap-northeast-1
sso_role_name = ExternalAccountAccess
sso_account_id = 0123456789

[profile external]
source_profile = bridge-sso
role_arn = arn:aws:iam::9876543210:role/external
```

ブリッジアカウントの IAM Role を挟む場合も、次のように `source_profile` を多段にすれば良い。

```ini
[profile bridge-sso]
sso_start_url = https://d-1234567890.awsapps.com/start/
sso_region = ap-northeast-1
sso_role_name = ExternalAccountAccess
sso_account_id = 0123456789

[profile bridge-role]
source_profile = bridge-sso
role_arn = arn:aws:iam::0123456789:role/oreore

[profile external]
source_profile = bridge-role
role_arn = arn:aws:iam::9876543210:role/external
```
