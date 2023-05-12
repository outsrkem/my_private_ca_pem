## 生成一个 2048 位的 ca.key 文件
```bash
openssl genrsa -out ca.key 2048
```
在 ca.key 文件的基础上，生成 ca.crt 文件（用参数 -days 设置证书有效期）
```bash
openssl req -x509 -new -nodes -key ca.key -subj "/CN=${MASTER_IP}" -days 10000 -out ca.crt
```
生成一个 2048 位的 server.key 文件：
```bash
openssl genrsa -out server.key 2048
```
创建一个用于生成证书签名请求（CSR）的配置文件。 保存文件（例如：csr.conf）前，记得用真实值替换掉尖括号中的值（例如：<MASTER_IP>）。 注意：MASTER_CLUSTER_IP 就像前一小节所述，它的值是 API 服务器的服务集群 IP。 下面的例子假定你的默认 DNS 域名为 cluster.local。
```bash
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = <country>
ST = <state>
L = <city>
O = <organization>
OU = <organization unit>
CN = <MASTER_IP>

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
IP.1 = <MASTER_IP>
IP.2 = <MASTER_CLUSTER_IP>

[ v3_ext ]
authorityKeyIdentifier=keyid,issuer:always
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names
```
基于上面的配置文件生成证书签名请求：
```bash
openssl req -new -key server.key -out server.csr -config csr.conf
```
基于 ca.key、ca.crt 和 server.csr 等三个文件生成服务端证书：
```bash
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out server.crt -days 10000 \
    -extensions v3_ext -extfile csr.conf -sha256
```
查看证书签名请求：
```bash
openssl req  -noout -text -in ./server.csr
```
查看证书：
```bash
openssl x509  -noout -text -in ./server.crt
```