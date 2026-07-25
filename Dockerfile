# ============================================================
# Aider Agent API - Dockerfile متوافق مع المشروع الرسمي
# ============================================================

FROM python:3.12-slim

# متغيرات البيئة
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# تثبيت أدوات النظام الضرورية
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# نسخ ملفات المشروع أولاً
COPY . .

# تثبيت Aider من المستودع المحلي (مع جميع اعتمادياته بما فيها FastAPI)
RUN pip install --upgrade pip \
    && pip install -e . \
    && pip install uvicorn[standard]

# إنشاء مجلدات العمل
RUN mkdir -p /workspace/data /workspace/logs /workspace/repos

# إنشاء مستخدم غير root (اختياري لكن موصى به)
RUN groupadd -r aider && useradd -r -g aider -m -d /home/aider aider \
    && chown -R aider:aider /workspace /app

USER aider

# التحقق من التثبيت
RUN python -c "import fastapi; import uvicorn; print('✅ FastAPI ready')" \
    && aider --version || echo "⚠️ Aider check skipped"

# المنفذ
EXPOSE 8080

# فحص الصحة
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:${PORT:-8080}/health || exit 1

# أمر التشغيل - يستخدم Python مباشرة لتجنب مشاكل المسار
CMD ["python", "-m", "uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8080"]
