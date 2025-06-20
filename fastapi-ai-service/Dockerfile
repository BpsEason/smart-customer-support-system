# 使用 Python 3.10 slim 鏡像作為基礎
FROM python:3.10-slim-buster

# 設定工作目錄
WORKDIR /app

# 複製 requirements.txt 並安裝依賴
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 複製應用代碼
COPY . /app

# 暴露 FastAPI 服務端口
EXPOSE 8001

# 運行 FastAPI 應用
# 使用 uvicorn 啟動 main.py 中的 app
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001"]
