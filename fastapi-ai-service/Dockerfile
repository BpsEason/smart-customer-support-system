FROM python:3.10-slim-buster

# 設置環境變量，確保 Python stdout/stderr 不被緩衝
ENV PYTHONUNBUFFERED 1

WORKDIR /app

# 複製 requirements.txt 並安裝依賴
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 創建用於存放模型的目錄 (映射到 Docker volume)
RUN mkdir -p /app/models
# 創建用於存放知識庫的數據目錄 (映射到 Docker volume)
RUN mkdir -p /app/data

# 複製應用程式代碼
COPY . .

EXPOSE 8001

# 運行 Uvicorn 服務
# --reload 在生產環境中通常不建議使用，只用於開發
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001"]
