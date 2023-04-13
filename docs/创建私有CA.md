# 创建私有CA



```
openssl genrsa -out ca.key 2048
openssl req -config openssl.conf -new -x509 -days 3650 -sha256 -key ca.key -extensions v3_ca -out ca.crt -subj /CN=ca.pki

--------------------------------------------------------------------
openssl x509 -in ca.crt -noout -text
openssl x509 -in ca.crt -noout -serial
openssl x509 -in ca.crt -noout -subject
openssl x509 -in ca.crt -noout -issuer
openssl x509 -in ca.crt -noout -fingerprint
openssl x509 -in ca.crt -noout -issuer_hash
openssl x509 -in ca.crt -noout -startdate -enddate
--------------------------------------------------------------------
openssl x509 -noout -modulus -in ca.crt | openssl md5
openssl rsa -noout -modulus -in ca.key | openssl md5
```

```
【信息输出选项：】
-text：以text格式输出证书内容，即以最全格式输出，
     ：包括public key,signature algorithms,issuer和subject names,serial number以及any trust settings.
-certopt option：自定义要输出的项
-noout         ：禁止输出证书请求文件中的编码部分
-pubkey        ：输出证书中的公钥
-modulus       ：输出证书中公钥模块部分
-serial        ：输出证书的序列号
-subject       ：输出证书中的subject
-issuer        ：输出证书中的issuer，即颁发者的subject
-subject_hash  ：输出证书中subject的hash码
-issuer_hash   ：输出证书中issuer(即颁发者的subject)的hash码
-hash          ：等价于"-subject_hash"，但此项是为了向后兼容才提供的选项
-email         ：输出证书中的email地址，如果有email的话
-startdate     ：输出证书有效期的起始日期
-enddate       ：输出证书有效期的终止日期
-dates         ：输出证书有效期，等价于"startdate+enddate"
-fingerprint   ：输出指纹摘要信息
```

```
【签署选项：】
*****************************************************************************************
*  伪命令x509可以像openssl ca一样对证书或请求执行签名动作。注意，openssl x509         *
*  不读取配置文件，所有的一切配置都由x509自行提供，所以openssl x509像是一个"mini CA"  *
*****************************************************************************************
-signkey filename：该选项用于提供自签署时的私钥文件，自签署的输入文件"-in file"的file可以是证书请求文件，也可以是已签署过的证书。-days arg：指定证书有效期限，默认30天。
-x509toreq：将已签署的证书转换回证书请求文件。需要使用"-signkey"选项来传递需要的私钥。
-req：x509工具默认以证书文件做为inputfile(-in file)，指定该选项将使得input file的file为证书请求文件。
-set_serial n：指定证书序列号。该选项可以和"-singkey"或"-CA"选项一起使用。
             ：如果和"-CA"一起使用，则"-CAserial"或"-CAcreateserial"选项指定的serial值将失效。
             ：序列号可以使用数值或16进制值(0x开头)。也接受负值，但是不建议。
-CA filename      ：指定签署时所使用的CA证书。该选项一般和"-req"选项一起使用，用于为证书请求文件签署。
-CAkey filename   ：设置CA签署时使用的私钥文件。如果该选项没有指定，将假定CA私钥已经存在于CA自签名的证书文件中。
-CAserial filename：设置CA使用的序列号文件。当使用"-CA"选项来签名时，它将会使用某个文件中指定的序列号来唯一标识此次签名后的证书文件。
                  ：这个序列号文件的内容仅只有一行，这一行的值为16进制的数字。当某个序列号被使用后，该文件中的序列号将自动增加。
                  ：默认序列号文件以CA证书文件基名加".srl"为后缀命名。如CA证书为"mycert.pem"，则默认寻找的序列号文件为"mycert.srl"
-CAcreateserial   ：当使用该选项时，如果CA使用的序列号文件不存在将自动创建：该文件将包含序列号值"02"并且此次签名后证书文件序列号为1。
                  ：一般如果使用了"-CA"选项而序列号文件不存在将会产生错误"找不到srl文件"。
-extfile filename ：指定签名时包含要添加到证书中的扩展项的文件。

```

```
【CERTIFICATE EXTENSIONS】
-purpose：选项检查证书的扩展项并决定该证书允许用于哪些方面，即证书使用目的范围。
basicConstraints：该扩展项用于决定证书是否可以当作CA证书。格式为basicConstraints=CA:true | false
                ：1.如果CA的flag设置为true，那么该证书允许作为一个CA证书，即可以颁发下级证书或进行签名；
                ：2.如果CA的flag设置为false，那么该证书就不能作为CA，不能为下级颁发证书或签名；
                ：3.所有CA的证书中都必须设置CA的flag为true。
                ：4.如果basicConstraints扩展项未设置，那么证书被认为可疑的CA，即"possible CA"。
keyUsage：该扩展项用于指定证书额外的使用限制，即也是使用目的的一种表现方式。
        ：1.如果keyUsage扩展项被指定，那么该证书将又有额外的使用限制。
        ：2.CA证书文件中必须至少设置keyUsage=keyCertSign。
        ：3.如果设置了keyUsage扩展项，那么不论是否使用了critical，都将被限制在指定的使用目的purpose上。
        
```

例如，使用x509工具自建CA。由于x509无法建立证书请求文件，所以只能使用openssl req来生成请求文件，然后使用x509来自签署。自签署时，使用"-req"选项明确表示输入文件为证书请求文件，否则将默认以为是证书文件，再使用"-signkey"提供自签署时使用的私钥。
