FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# أدوات النظام
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# نسخ ملفات المشروع
COPY . .

# ⚠️ هذا هو الإصلاح: تحديد الإصدار يدوياً
# لأن Railway لا ينسخ مجلد .git
ENV SETUPTOOLS_SCM_PRETEND_VERSION_FOR_AIDER_CHAT=0.75.0

# تثبيت Aider والاعتماديات
RUN pip install --upgrade pip \
    && pip install -e . \
    && pip install uvicorn[standard]

# مجلدات العمل
RUN mkdir -p /workspace/data /workspace/logs /workspace/repos

# فحص الصحة
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:${PORT:-8080}/health || exit 1

EXPOSE 8080

CMD ["python", "-m", "uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8080"]
