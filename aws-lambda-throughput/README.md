# aws-lambda-throughput

## lambda

- 128 MB
    -  1 para, 500 messages, 10154 ms
    -  2 para, 610 messages, 10230 ms
    -  4 para, 660 messages, 10373 ms
    -  8 para, 670 messages, 10599 ms
    - 16 para, 800 messages, 11261 ms
    - 32 para, 950 messages, 12532 ms
- 256 MB
    -  1 para, 1080 messages, 10043 ms
    -  2 para, 1250 messages, 10158 ms
    -  4 para, 1390 messages, 10153 ms
    -  8 para, 1530 messages, 10370 ms
    - 16 para, 1680 messages, 10471 ms
    - 32 para, 1650 messages, 11448 ms
- 512 MB
    -  1 para, 2180 messages, 10024 ms
    -  2 para, 2570 messages, 10108 ms
    -  4 para, 3070 messages, 10087 ms
    -  8 para, 3210 messages, 10176 ms
    - 16 para, 3480 messages, 10256 ms
    - 32 para, 3550 messages, 10632 ms
- 1024 MB
    -  1 para, 2560 messages, 10002 ms
    -  2 para, 4300 messages, 10021 ms
    -  4 para, 6530 messages, 10067 ms
    -  8 para, 7380 messages, 10825 ms
    - 16 para, 6900 messages, 10145 ms
    - 32 para, 7400 messages, 10177 ms
- 2048 MB
    -  1 para,  1790 messages, 10015 ms
    -  2 para,  4500 messages, 10019 ms
    -  4 para,  8310 messages, 10035 ms
    -  8 para, 11700 messages, 10073 ms
    - 16 para, 14100 messages, 10078 ms
    - 32 para, 13460 messages, 10116 ms
- 3008 MB
    -  1 para,  1940 messages, 10031 ms
    -  2 para,  5090 messages, 10025 ms
    -  4 para,  7130 messages, 10044 ms
    -  8 para, 12590 messages, 10038 ms
    - 16 para, 14490 messages, 10762 ms
    - 32 para, 15210 messages, 10153 ms

## local pc

```sh
node --version
# v14.4.0

cat /proc/cpuinfo | grep 'model name' | head -1
# model name      : Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz

nproc
# 4

ping sqs.ap-northeast-1.amazonaws.com -c 3 -q
# PING ap-northeast-1.queue.amazonaws.com (54.240.225.139) 56(84) bytes of data.
#
# --- ap-northeast-1.queue.amazonaws.com ping statistics ---
# 3 packets transmitted, 3 received, 0% packet loss, time 2001ms
# rtt min/avg/max/mdev = 13.298/17.416/20.984/3.161 ms
```

-  1 para,  930 messages, 10079 ms
-  2 para, 1590 messages, 10073 ms
-  4 para, 2820 messages, 10109 ms
-  8 para, 4050 messages, 10201 ms
- 16 para, 4740 messages, 10231 ms
- 32 para, 5650 messages, 11150 ms
