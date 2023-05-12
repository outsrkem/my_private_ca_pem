#!/bin/bash
# 先签发ca证书
# 中间证书
cat << EOF > middle_ca_v3.ext
basicConstraints       = critical, CA:true, pathlen:0
keyUsage               = critical, digitalSignature, cRLSign, keyCertSign
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer
EOF

openssl req -out middle_ca.csr -newkey rsa:2048 -nodes -keyout middle_ca.key  -subj "/CN=Middle CA"
# 使用ca签名
openssl x509 -req -sha512 -days 3650 -extfile middle_ca_v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial -in middle_ca.csr -out middle_ca.crt

openssl x509 -noout -text -in middle_ca.crt
openssl verify -CAfile ca.crt middle_ca.crt

#-------------------------------------------------------------------------
# 创建中间ca证书链，中间证书在上面，根证书在下面
cat ca.crt >> middle_ca.crt
# 测试证书
openssl verify -CAfile ca.crt middle_ca.crt
