# ============================================================
# المرحلة الأولى: البناء
# ============================================================
FROM python:3.12-slim AS builder

# إعدادات Python
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# تثبيت أدوات البناء الأساسية
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    gcc \
    g++ \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# نسخ ملفات المشروع
COPY . .

# تثبيت Aider والمتطلبات
RUN pip install --upgrade pip setuptools wheel
RUN pip install -e .
RUN pip install fastapi==0.109.0 uvicorn==0.27.0 pydantic==2.5.3

# ============================================================
# المرحلة الثانية: الإنتاج
# ============================================================
FROM python:3.12-slim

# إعدادات Python
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# تثبيت متطلبات التشغيل فقط
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    git-lfs \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# نسخ الحزم المثبتة من مرحلة البناء
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# نسخ كود المشروع
COPY . .

# إنشاء مجلد workspace
RUN mkdir -p /workspace/data /workspace/logs /workspace/repos

# التأكد من صلاحيات المجلدات
RUN chmod -R 755 /workspace

# تعيين متغيرات البيئة الافتراضية
ENV WORKSPACE_DIR=/workspace \
    PORT=8080 \
    HOST=0.0.0.0 \
    LOG_LEVEL=INFO \
    PYTHONPATH=/app

# فتح المنفذ
EXPOSE 8080

# فحص الصحة
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# تشغيل الخدمة
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "1"]
