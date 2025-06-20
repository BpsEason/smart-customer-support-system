FROM python:3.10-slim-buster

WORKDIR /app

# 安裝系統依賴
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# 複製 requirements.txt 並安裝 Python 依賴
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 複製應用程式代碼
COPY . .

# 創建用於模型和數據的持久化目錄
RUN mkdir -p /app/models /app/data

# 設定環境變數
ENV PYTHONUNBUFFERED=1 \
    MODEL_DIR=/app/models \
    DATA_DIR=/app/data

# 暴露 FastAPI 端口
EXPOSE 8001

# 啟動 Gunicorn 服務，綁定到所有網絡接口的 8001 端口
# 使用 --reload 進行開發，生產環境請移除
CMD ["gunicorn", "main:app", "--workers", "2", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8001"]
