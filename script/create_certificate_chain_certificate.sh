#!/bin/bash
# 先签发ca证书
[ -d .openssl ] || mkdir .openssl || exit 1
# 中间证书
cat << EOF > .openssl/middle_ca_v3.ext
basicConstraints       = critical, CA:true, pathlen:0
keyUsage               = critical, digitalSignature, cRLSign, keyCertSign
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer
EOF

openssl req -out middle_ca.csr -newkey rsa:2048 -nodes -keyout middle_ca.key  -subj "/CN=Middle CA"
# 也可以使用已有的ca签名
openssl x509 -req -sha512 -days 3650 -extfile .openssl/middle_ca_v3.ext \
	-CA ca.crt -CAkey ca.key -CAcreateserial -in middle_ca.csr -out middle_ca.crt

openssl x509 -in middle_ca.crt -noout -text
openssl verify -CAfile ca.crt middle_ca.crt


# 签发服务器证书
# 可在 man x509v3_config 中查看更多配置
cat << EOF > .openssl/v3.ext
basicConstraints       = CA:FALSE
keyUsage               = digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment,keyAgreement,keyCertSign
extendedKeyUsage       = serverAuth,clientAuth
subjectAltName         = @alt_names
nsCertType             = server
# certificatePolicies    = @polsect
authorityKeyIdentifier = keyid,issuer
# crlDistributionPoints  = crldp1_section


[ crldp1_section ]
fullname = URI:http://myhost.com/myca.crlaa

[ polsect ]
policyIdentifier = 1.3.5.1.4
CPS.1            = http://my.host.name

[ alt_names ]
DNS.1  = localhost
DNS.2  = www.example.com
DNS.2  = *.example.com
IP.1   = 127.0.0.1
IP.2   = 192.168.14.37
IP.3   = 10.10.10.10
IP.4   = 10.10.10.11
EOF

openssl req -out nginx.csr -newkey rsa:2048 -nodes -keyout nginx.key  -subj "/C=CN/CN=example.com"
openssl x509 -req -sha512 -days 3650 -extfile .openssl/v3.ext -CA middle_ca.crt \
	-CAkey middle_ca.key -CAcreateserial -in nginx.csr -out nginx.crt

openssl x509 -in nginx.crt -noout -text

#-------------------------------------------------------------------------
# 创建服务器证书证书链，服务器证书在上面，中间证书在下面
cat middle_ca.crt >> nginx.crt
# 创建中间ca证书链，中间证书在上面，根证书在下面
cat ca.crt >> middle_ca.crt
# 测试证书
openssl verify -CAfile ca.crt middle_ca.crt
openssl verify -CAfile middle_ca.crt nginx.crt
