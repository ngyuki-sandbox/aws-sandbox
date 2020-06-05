# AWS NLB(Network Load Balancer) で TLS/TLS で ALPN で HTTP/2 する

Terraform で環境作ってからサーバにログインして作業。

```sh
sudo amazon-linux-extras install -y nginx1.12

sudo openssl req -batch -new -x509 -newkey rsa:2048 -nodes -sha256 \
  -subj /CN=localhost/O=oreore -days 3650 \
  -keyout /etc/nginx/localhost.key \
  -out /etc/nginx/localhost.crt

cat <<'EOS' | sudo tee /etc/nginx/conf.d/ssl.conf
server {
    listen       443 ssl http2 default_server;
    server_name  _;
    root         /usr/share/nginx/html;

    ssl_certificate "/etc/nginx/localhost.crt";
    ssl_certificate_key "/etc/nginx/localhost.key";
    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout  10m;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
    }

    error_page 404 /404.html;
        location = /40x.html {
    }

    error_page 500 502 503 504 /50x.html;
        location = /50x.html {
    }
}
EOS

sudo systemctl start nginx.service
sudo systemctl status nginx.service

curl -I -k https://localhost/
```

マネジメントコンソールで NLB のリスナーで ALPN を適当に切り替えて HTTP/2 になるか試してみる。
（Terraform ではいまのところまだリスナーの ALPN の設定はいじれないもよう）

これが実現可能ということは NLB の TLS/TLS は「クライアント～NLB」のネゴシエーションと並行して「NLB～ターゲット」のネゴシエーションが行われているということだろうか。

それならまさかサーバにクライアント認証を設定していればそれも通るとか・・試した感じ流石にそんなことはなかった。
