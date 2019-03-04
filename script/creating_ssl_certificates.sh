#/bin/bash
cat << EOF > ca-csr.json
{
    "CN": "Private Root CA",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "ca": {
        "expiry": "262800h"
    },
    "names": [
        {
            "C": "CN",
            "O": "Private issued",
            "OU": "Root CA"
        }
    ]
}
EOF
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
openssl x509  -noout -text -in ca.pem

# 如果CA证书过期，则可以使用下面方法重新生成CA证书
# 使用现有的CA私钥，重新生成： 
    cfssl gencert -initca -ca-key ca-key.pem ca-csr.json | cfssljson -bare ca
# 使用现有的CA私钥和CA证书，重新生成：
    cfssl gencert -renewca -ca-key ca-key.pem -ca ca.pem  | cfssljson -bare ca
#
#
#
cat << EOF > ca-config.json
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "www": {
        "expiry": "87600h",
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ]
      }
    }
  }
}
EOF



cat << EOF > www-csr.json
{
    "CN": "yonge.com",
    "hosts": [
        "127.0.0.1",
        "139.224.75.128",
        "10.10.10.1",
        "*.yonge.com"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "ZJ",            
            "ST": "HZ",
            "O": "yonge server",
            "OU": "IT"
        }
    ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=www www-csr.json | cfssljson -bare www

# 验证证书是否由 CA  签署
openssl verify -CAfile ca.pem www.pem

# 判断证书与私钥是否匹配,输出一样即为匹配
openssl x509 -noout -modulus -in www.pem | openssl md5
openssl rsa -noout -modulus -in www-key.pem | openssl md5

cat << EOF > harbor-csr.json
{
    "CN": "harbor.hub.com",
    "hosts": [
        "127.0.0.1",
        "10.10.10.53",
        "harbor.hub.com"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "ZJ",            
            "ST": "HZ",
            "O": "harbor",
            "OU": ""
        }
    ]
}
EOF
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=www harbor-csr.json | cfssljson -bare harbor


