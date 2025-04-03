import time
import os
from flask import Flask, request, jsonify, Response

app = Flask(__name__)

# 環境変数からデバッグモードを読み込む（Docker Composeで設定可能）
app.debug = os.environ.get('FLASK_DEBUG', 'false').lower() == 'true'

@app.route('/')
def index():
    """基本的なルート"""
    return "Hello from Flask Backend!\n"

@app.route('/api/echo', methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH'])
def echo():
    """リクエスト情報をそのまま返す"""
    echo_data = {
        "method": request.method,
        "path": request.path,
        "args": request.args.to_dict(),
        "headers": dict(request.headers),
        "body": request.get_data(as_text=True),
        "form": request.form.to_dict(), # form-urlencoded や multipart の場合
        # multipart のファイル情報は request.files で取得可能
    }
    return jsonify(echo_data), 200

@app.route('/api/delay/<int:seconds>')
def delay(seconds):
    """指定された秒数だけ処理を遅延させる"""
    if seconds < 0:
        return "Delay seconds must be non-negative.\n", 400
    if seconds > 60: # 過度な遅延を防ぐ制限（任意）
        return f"Delay cannot exceed 60 seconds.\n", 400

    app.logger.info(f"Delaying response by {seconds} seconds...")
    time.sleep(seconds)
    app.logger.info("Delay finished.")
    return f"Response delayed by {seconds} seconds.\n", 200

@app.route('/api/chunked')
def chunked_response():
    """チャンク形式のレスポンスを返すジェネレータ"""
    def generate():
        yield "Chunk 1\n"
        time.sleep(1)
        yield "Chunk 2\n"
        time.sleep(1)
        yield "Chunk 3\n"
    # Flask はジェネレータを返すと自動的に chunked encoding を使う
    return Response(generate(), mimetype='text/plain')

@app.route('/api/multipart', methods=['POST'])
def handle_multipart():
    """multipart/form-data を受け付け、情報を返す"""
    if 'file' not in request.files:
        return "No file part in the request\n", 400

    file = request.files['file']
    form_data = request.form.to_dict()

    if file.filename == '':
        return 'No selected file\n', 400

    file_info = {
        "filename": file.filename,
        "content_type": file.content_type,
        # "content": file.read().decode('utf-8', errors='ignore') # ファイル内容読み込み (大きいファイル注意)
    }

    response_data = {
        "message": "Multipart data received successfully.",
        "form_data": form_data,
        "file_info": file_info,
    }
    return jsonify(response_data), 200

# 他にも必要なエンドポイントがあればここに追加

if __name__ == '__main__':
    # Dockerから実行される場合は 0.0.0.0 でリッスンする必要がある
    app.run(host='0.0.0.0', port=5000)