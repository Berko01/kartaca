📦 Kartaca - Çekirdekten Yetişenler Görevi

Bu depo, Ubuntu 24.04 ve Debian 12 sistemlerine uygulanmak üzere hazırlanmış tam otomatik bir SaltStack altyapısı içerir. Tüm yapılandırmalar tek bir Salt state dosyası (kartaca-wordpress.sls) ve bir pillar dosyası (kartaca-pillar.sls) aracılığıyla yönetilir.

📁 İçerik

kartaca-wordpress.sls: Ana Salt state dosyası (OS tipi bazlı tüm işlemleri içerir)
kartaca-pillar.sls: Kullanıcı bilgileri ve sistem yapılandırmalarını içeren pillar verisi
top.sls: State dosyası eşlemesini tanımlar
pillar/top.sls: Pillar eşlemesini tanımlar
files/: Yardımcı dosyalar dizini:
docker-compose.yml: 3 WordPress replikası + MariaDB + HAProxy (Ubuntu için)
haproxy.cfg: HAProxy konfigürasyonu (443 portu, round-robin)
nginx.conf: Nginx yapılandırma dosyası (Debian için)
sudoers_kartaca: kartaca kullanıcısına şifresiz apt izni
wp-config.php.j2: WordPress yapılandırması için Jinja şablonu
logrotate_nginx: Saatlik log döngüsü yapılandırması
ssl/cert.pem ve ssl/key.pem: Self-signed SSL sertifikası ve özel anahtarı (Debian için)
🧪 Test Edilen Platformlar

✅ Ubuntu 24.04 (Docker Tabanlı WordPress Kurulumu)
kartaca kullanıcısı oluşturuldu (UID/GID: 2025)
Şifresiz sudo apt izni tanımlandı
Hostname & timezone (Europe/Istanbul) ayarlandı
Sistem paketleri kuruldu (htop, mtr, dnsutils vb.)
IP forwarding etkinleştirildi
/etc/hosts yapılandırıldı
Docker üzerinden:
3 adet WordPress container'ı
1 adet MariaDB container
HAProxy üzerinden SSL destekli reverse proxy
Test: curl -k https://localhost komutu başarıyla WordPress sayfasını döndürdü
✅ Debian 12 (Nginx + PHP-FPM Tabanlı WordPress Kurulumu)
kartaca kullanıcısı oluşturuldu (UID/GID: 2025)
Şifresiz sudo apt yetkisi verildi
Hostname & timezone ayarlandı
Gerekli yardımcı paketler kuruldu
Nginx + PHP-FPM yapılandırıldı
wp-config.php Salt üzerinden secrets ile oluşturuldu
SSL sertifikası /etc/ssl/certs/selfsigned.pem yoluna yerleştirildi
Logrotate & cron ile günlük döngü yapılandırıldı
Test: curl -k https://localhost komutu WordPress arayüzünü başarıyla döndürdü
📂 Dizin Yapısı

kartaca-sistem-administrator-task/
├── kartaca-wordpress.sls
├── kartaca-pillar.sls
├── top.sls
├── pillar/
│   └── top.sls
├── files/
│   ├── docker-compose.yml
│   ├── haproxy.cfg
│   ├── nginx.conf
│   ├── sudoers_kartaca
│   ├── wp-config.php.j2
│   ├── logrotate_nginx
│   └── ssl/
│       ├── cert.pem
│       └── key.pem
└── README.md
