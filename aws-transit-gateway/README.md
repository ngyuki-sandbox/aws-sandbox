# AWS Transit Gateway 素振り

VPC の構成。

- us-west-2 (Oregon)
  - VPC 10.100.0.0/16
- ap-northeast-1 (Tokyo)
  - VPC 10.101.0.0/16
  - VPC 10.102.0.0/16

Transit Gateway と Oregon と Tokyo にそれぞれ作成し、リージョン内の VPC をアタッチする。
さらに Transit Gateway 同士をピアリング接続してリージョン間の VPC でも通信可能にする。

各 VPC に EC2 インスタンスが」 1 つずつ起動する。
SSM session manager が有効なのでインスタンス ID で ssh 接続できる。
