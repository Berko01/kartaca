# Kartaca - Çekirdekten Yetişenler Görevi

Bu depo, Ubuntu 24.04 ve Debian 12 sistemlerine uygulanmak üzere hazırlanan SaltStack state ve pillar dosyalarını içermektedir.

## 📌 İçerik

- **kartaca-wordpress.sls**: Salt state dosyası
- **kartaca-pillar.sls**: Kullanıcı bilgilerini içeren pillar dosyası
- **files/**:
  - `docker-compose.yml`: 3 WordPress replica + HAProxy + MariaDB servisi
  - `haproxy.cfg`: 443 üzerinden round-robin yönlendirme
  - `ssl/selfsigned.pem`: Self-signed SSL sertifikası
  - `sudoers_kartaca`: `kartaca` kullanıcısına şifresiz `sudo apt` yetkisi

## 🧪 Test Edilen Özellikler (Ubuntu 24.04)

- `kartaca` adlı kullanıcı oluşturuldu (UID/GID: 2025)
- Kullanıcıya sudo ve şifresiz `apt` yetkisi verildi
- Zaman dilimi ve hostname ayarlandı
- Gerekli paketler yüklendi
- IP forwarding etkinleştirildi
- `/etc/hosts` güncellendi
- Docker ortamında:
  - 3 WordPress replica
  - MariaDB
  - HTTPS erişimli HAProxy (443 portu)
- Salt uygulandığında tüm yapı otomatik kuruldu ve erişilebilir oldu

## 🔐 HTTPS erişimi

```bash
curl -k https://localhost
