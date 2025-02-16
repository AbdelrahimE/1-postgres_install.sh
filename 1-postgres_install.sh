#!/bin/bash

# التحقق من تشغيل السكربت بصلاحيات Root
if [[ $EUID -ne 0 ]]; then
   echo "يجب تشغيل هذا السكربت بصلاحيات Root" 
   exit 1
fi

# تحديث النظام
echo "تحديث قائمة الحزم..."
sudo apt-get update -y
sudo apt-get upgrade -y

# تثبيت PostgreSQL
echo "تثبيت PostgreSQL..."
sudo apt-get install -y postgresql postgresql-contrib

# تشغيل PostgreSQL والتأكد من عمله تلقائيًا بعد إعادة التشغيل
echo "تفعيل وتشغيل PostgreSQL..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

# فتح منفذ PostgreSQL في الجدار الناري
echo "فتح المنفذ 5432 في الجدار الناري..."
sudo ufw allow 5432/tcp

# إنشاء مستخدم وقاعدة بيانات
echo "إعداد قاعدة البيانات والمستخدم..."

sudo -i -u postgres psql <<EOF
-- إنشاء قاعدة البيانات
CREATE DATABASE evolution_api;

-- إنشاء مستخدم جديد
CREATE USER api_user WITH ENCRYPTED PASSWORD 'ApiPassw0rd!2024';

-- منح الصلاحيات للمستخدم على قاعدة البيانات
GRANT ALL PRIVILEGES ON DATABASE evolution_api TO api_user;
EOF

# تعديل إعدادات PostgreSQL للسماح بالاتصال الخارجي (اختياري)
echo "تعديل إعدادات PostgreSQL للسماح بالاتصال الخارجي..."
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf

# السماح بالاتصال من أي IP (للاتصال عن بعد - اختياري)
echo "السماح بالاتصال من أي IP..."
echo "host all all 0.0.0.0/0 md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf

# إعادة تشغيل PostgreSQL لتطبيق التغييرات
echo "إعادة تشغيل PostgreSQL..."
sudo systemctl restart postgresql

echo "تم التثبيت بنجاح! يمكنك الآن الاتصال بقاعدة البيانات عبر:"
echo "psql -U api_user -d evolution_api -h localhost -W"