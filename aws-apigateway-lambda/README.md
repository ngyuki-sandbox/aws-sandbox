# aws-apigateway-lambda

## CF 経由の API Gateway 側 WAF の ipset

なぜか CF 経由でも API Gateway 側の WAF の ipset がエンドの IP で通っているような？
逆に CF の ipset を WAF に設定しても通らない・・？
CF -> API Gateway で Proxy Protocol みたいなのでクライアントの IP アドレスが渡っている？

API Gateway のリソースポリシーでIP制限したときも同様？
なぜか CF の ipset で許可してもダメで、エンドの IP で許可しないと通らない。

## CF のオリジンリクエストポリシー

オリジンに API Gateway を使う場合はオリジンリクエストポリシーで AllViewerExceptHostHeader などで
host ヘッダーを除外してやらないと、API Gateway の素の host ヘッダーが渡らないために通らない。
また、API Gateway はパスにステージ名を含むが、CF 経由でもステージ名のパスを付与するか、
もしくは、CF のオリジンの設定でステージ名をパスとして設定する必要がある。

CF のドメインと同じ名前で API Gateway でカスタムドメインとして登録してやれば大丈夫。
API Gateway のカスタムドメインはステージに紐付くので、この場合は CF 経由でもステージ名のパスは不要。
