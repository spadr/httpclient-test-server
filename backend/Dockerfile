# Python の軽量イメージを選択 (Alpineベース)
FROM python:3.10-alpine

# 作業ディレクトリを設定
WORKDIR /app

# 依存関係ファイルをコピーしてインストール
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# アプリケーションコードをコピー
COPY . .

# Flask アプリケーションを実行するポートを公開 (コンテナ内部)
EXPOSE 5000

# アプリケーションの起動コマンド
# 環境変数で Gunicorn のワーカー数などを設定できるようにするのが一般的だが、
# 今回のテスト用途では Flask の開発サーバーで十分
CMD ["python", "app.py"]