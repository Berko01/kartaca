❗ Not: wp-config.php içinde kullanılan DB_HOST değeri 'kartaca1.local' olarak tanımlanmıştır.
Debian sunucusunun /etc/hosts dosyasına Ubuntu sunucusunun IP'si bu hostname ile eklenmektedir.

Salt-master testlerinde Ubuntu makinesi 'kartaca1.local' olarak çözümlendiği sürece bağlantı sorunsuz çalışacaktır.

# Kartaca - Çekirdekten Yetişenler Görevi

Bu depo, Ubuntu 24.04 ve Debian 12 sistemlerine uygulanmak üzere hazırlanan SaltStack state ve pillar dosyalarını içermektedir. Tüm işlemler **tek bir Salt state (`kartaca-wordpress.sls`)** ve **tek bir pillar (`kartaca-pillar.sls`)** dosyası içinde organize edilmiştir.

---

## 📌 İçerik

- **kartaca-wordpress.sls**: Salt state dosyası
- **kartaca-pillar.sls**: Kullanıcı ve sistem parametrelerini içeren pillar dosyası
- **top.sls**: Salt state mapping dosyası
- **pillar/top.sls**: Pillar mapping dosyası
- **files/**:
  - `docker-compose.yml`: 3 WordPress replica + HAProxy + MariaDB servisi (Ubuntu için)
  - `haproxy.cfg`: 443 üzerinden round-robin yönlendirme (Ubuntu için)
  - `ssl/cert.pem` & `ssl/key.pem`: Self-signed SSL sertifikası ve özel anahtarı (Debian için)
  - `sudoers_kartaca`: `kartaca` kullanıcısına şifresiz `sudo apt` yetkisi
  - `nginx.conf`: Debian için Nginx yapılandırma dosyası
  - `wp-config.php.j2`: WordPress yapılandırması için Jinja şablonu
  - `logrotate_nginx`: Saatlik log döngüsü için yapılandırma

---

## 🧪 Test Edilen Özellikler

### ✅ Ubuntu 24.04 (Docker Tabanlı Kurulum)

- `kartaca` adlı kullanıcı oluşturuldu (UID/GID: 2025)
- Kullanıcıya sudo ve şifresiz `apt` yetkisi verildi
- Zaman dilimi ve hostname ayarlandı
- Gerekli sistem paketleri kuruldu
- IP forwarding etkinleştirildi
- `/etc/hosts` güncellendi
- Docker ortamında:
  - 3 WordPress replica
  - MariaDB
  - HTTPS erişimli HAProxy (443 portu)
- Tüm yapı `salt state` ile tam otomatik kuruldu
- Test: `curl -k https://localhost` ile başarıyla erişildi

### ✅ Debian 12 (Native Kurulum - Nginx & PHP-FPM)

- `kartaca` adlı kullanıcı oluşturuldu (UID/GID: 2025)
- Kullanıcıya sudo ve şifresiz `apt` yetkisi tanımlandı
- Hostname ve timezone (`Europe/Istanbul`) ayarlandı
- Yardımcı sistem paketleri kuruldu (`htop`, `ping`, `mtr` vs.)
- **Nginx + PHP-FPM** yapılandırıldı
- MariaDB kurulumu tamamlandı ve `wordpress` veritabanı oluşturuldu
- `wp-config.php` dosyası, salt üzerinden secrets ile birlikte yerleştirildi
- Günlük döngüsü için `logrotate` ve `cron` yapılandırıldı
- `cert.pem` ile HTTPS kurulumu yapıldı
- Test: `curl -k https://localhost` başarılı şekilde WordPress sayfasını döndürdü

---

## 📁 Dizin Yapısı

```bash
.
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
├── kartaca-wordpress.sls
├── kartaca-pillar.sls
├── top.sls
├── pillar/
│   └── top.sls
└── README.md
