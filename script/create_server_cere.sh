#!/bin/bash
# 签发服务器证书
# 可在 man x509v3_config 中查看更多配置
cat << EOF > v3.ext
[ v3_ext ]
basicConstraints       = CA:FALSE
keyUsage               = digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment,keyAgreement,keyCertSign
extendedKeyUsage       = serverAuth,clientAuth
#certificatePolicies    = @polsect
subjectAltName         = @alt_names
authorityKeyIdentifier = keyid,issuer
subjectKeyIdentifier   = hash
#crlDistributionPoints  = crldp1_section

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
EOF

openssl req -out server.csr -newkey rsa:2048 -nodes -keyout server.key  -subj "/C=CN/CN=example.com"
openssl x509 -req -sha512 -days 3650 -extensions v3_ext -extfile v3.ext -CA middle_ca.crt \
    -CAkey middle_ca.key -CAcreateserial -in server.csr -out server.crt

openssl x509 -noout -text -in server.crt

#-------------------------------------------------------------------------
# 创建服务器证书证书链，服务器证书在上面，中间证书在下面
cat middle_ca.crt >> server.crt
openssl verify -CAfile middle_ca.crt server.crt
