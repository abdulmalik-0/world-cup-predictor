FROM nginx:alpine

# نسخ ملفات موقع التوقعات المبنية إلى مسار nginx داخل الحاوية
COPY build/web /usr/share/nginx/html

# إعداد الـ Routing لتجنب خطأ 404 عند تحديث صفحات الموقع
RUN echo 'server { \
    listen 80; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80