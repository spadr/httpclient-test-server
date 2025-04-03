# HTTP Client Test Server

このリポジトリは、ESP32 HTTP クライアントライブラリ (`HttpClient_ESP32_Lib` など) のテストターゲットとして機能するように設計された HTTP/HTTPS テストサーバーを提供します。

Docker コンテナ内で動作する Nginx と、バックエンドとして Python (Flask) アプリケーションを使用し、一般的な HTTP クライアントの機能をテストするための様々なエンドポイントを提供します。

## ✨ 機能

*   HTTP (ポート 80) と HTTPS (ポート 443) の両方のエンドポイントを提供します。
*   HTTPS 用に自己署名証明書を使用します（初回実行時に自動生成）。
*   以下のテスト用エンドポイントを含みます：
    *   基本的な HTTP メソッド (GET, POST, PUT, DELETE, PATCH, OPTIONS)
    *   リダイレクト (301, 302, 相対パス, ループ)
    *   クッキーの設定と確認
    *   Basic 認証
    *   Bearer 認証ヘッダーの確認
    *   一般的な HTTP エラーコード (4xx, 5xx)
    *   大きなファイルの提供
    *   サーバー証明書の取得
    *   リクエスト情報の表示 (Echo)
    *   意図的な遅延応答
    *   チャンクエンコーディング応答
    *   Multipart/form-data の受付

## 🛠️ 前提条件

*   Docker と `docker compose` (Docker CLI プラグイン) がインストールされた Linux 環境 (Raspberry Pi OS, Ubuntu, Debian など)。
    *   `docker compose` がない場合は、お使いのディストリビューションの方法で `docker-compose-plugin` (または `docker-compose`) をインストールしてください (例: `sudo apt update && sudo apt install docker-compose-plugin`)。
*   ターミナルへのアクセス。

## 🚀 セットアップと実行

1.  **リポジトリのクローン:**
    ```bash
    git clone https://github.com/<your_username>/httpclient-test-server.git # あなたのリポジトリURLに置き換えてください
    cd httpclient-test-server
    ```

2.  **サーバーのビルドと起動:**
    ```bash
    docker compose up --build -d
    ```
    *   初回実行時には以下の処理が行われます：
        *   必要なツール (`openssl`, `apache2-utils`) を含むカスタム Nginx イメージと、Flask アプリケーションを実行する Python イメージをビルドします。
        *   自己署名証明書と鍵 (`nginx/ssl/nginx.crt`, `nginx/ssl/nginx.key`) を生成します。証明書の CN (Common Name) にはコンテナの IP アドレスが使用されます。
        *   Basic 認証用の `.htpasswd` ファイル (`nginx/ssl/.htpasswd`) をデフォルト認証情報 (`testuser`/`testpass`) で生成します。
        *   生成された証明書を ESP32 クライアントで使用するために `nginx/ssl/nginx_root_ca.pem` としてコピーします。
        *   Nginx と Flask のコンテナを起動します。

3.  **サーバーの IP アドレスを確認:**
    ESP32 からサーバーにアクセスするために、このサーバーが動作しているマシンの IP アドレスが必要です。以下のコマンドなどで確認します：
    ```bash
    hostname -I | awk '{print $1}'
    # または
    # ip addr show eth0 | grep "inet\b" # インターフェース名は環境に合わせて変更 (例: wlan0)
    ```

4.  **サーバーの利用:**
    以下の「テスト用エンドポイント」リストにあるエンドポイントに、確認したサーバーマシンの IP アドレスを使ってアクセスします。HTTPS の場合、自己署名証明書を信頼するか、ESP32 クライアントに `nginx/ssl/nginx_root_ca.pem` の内容をルート CA として設定する必要があります。

5.  **サーバーの停止:**
    ```bash
    docker compose down
    ```
    *   コンテナを停止し、削除します。作成された証明書やログファイルはホスト側に残ります。

## 🧪 テスト用エンドポイント

**( `<server_ip>` を実際のサーバーマシンの IP アドレスに置き換えてください)**

**共通:**

*   `https://<server_ip>/cert`: サーバーの公開証明書 (`nginx.crt`) をプレーンテキストで返します。クライアントの設定に役立ちます。

**HTTP (ポート 80):**

*   `http://<server_ip>/`: 基本的な "Hello" 応答。
*   `http://<server_ip>/cert`: 証明書を取得 (HTTPS と同じ)。
*   `http://<server_ip>/test/echo`: HTTP リクエスト情報を返します。

**HTTPS (ポート 443):**

*   `https://<server_ip>/`: 基本的な "Hello" 応答。
*   **メソッドテスト:**
    *   `GET https://<server_ip>/test/get`: GET リクエストに 200 OK を返します。
    *   `POST https://<server_ip>/test/post`: POST リクエストに 200 OK と受信ボディを返します。
    *   `PUT https://<server_ip>/test/put`: PUT リクエストに 200 OK と受信ボディを返します。
    *   `DELETE https://<server_ip>/test/delete`: DELETE リクエストに 200 OK を返します。
    *   `PATCH https://<server_ip>/test/patch`: PATCH リクエストに 200 OK と受信ボディを返します。
    *   `OPTIONS https://<server_ip>/test/options`: OPTIONS リクエストに許可メソッド (Allow ヘッダー) と 204 No Content を返します。
*   **リダイレクトテスト:**
    *   `GET https://<server_ip>/test/redirect/permanent`: `/test/redirect/target` へ 301 リダイレクトします。
    *   `GET https://<server_ip>/test/redirect/temporary`: `/test/redirect/target` へ 302 リダイレクトします。
    *   `GET https://<server_ip>/test/redirect/relative`: 相対パス (`../redirect/target`) で 302 リダイレクトします。
    *   `GET https://<server_ip>/test/redirect/loop1`: `/test/redirect/loop2` へ 302 リダイレクトし、ループを発生させます。
    *   `GET https://<server_ip>/test/redirect/target`: リダイレクトの最終到達点です。
*   **クッキーテスト:**
    *   `GET https://<server_ip>/test/cookie/set`: `sessionid` と `userdata` の2つのクッキーを設定する `Set-Cookie` ヘッダーを返します。
    *   `GET https://<server_ip>/test/cookie/check`: 受信した `Cookie` ヘッダーに `sessionid=s_abc123` が含まれているか確認します。
*   **認証テスト:**
    *   `GET https://<server_ip>/test/auth/basic`: Basic 認証 (ユーザー: `testuser`, パスワード: `testpass`) を要求します。
    *   `GET https://<server_ip>/test/auth/bearer`: `Authorization: Bearer <token>` ヘッダーが存在するか確認し、存在すればその内容を返します。認証自体は行いません。
*   **エラー応答テスト:**
    *   `GET https://<server_ip>/test/error/400`: 400 Bad Request を返します。
    *   `GET https://<server_ip>/test/error/401`: 401 Unauthorized を返します。
    *   `GET https://<server_ip>/test/error/403`: 403 Forbidden を返します。
    *   `GET https://<server_ip>/test/error/404`: 404 Not Found を返します。
    *   `GET https://<server_ip>/test/error/405`: 405 Method Not Allowed を返します。
    *   `GET https://<server_ip>/test/error/500`: 500 Internal Server Error を返します。
    *   `GET https://<server_ip>/test/error/503`: 503 Service Unavailable を返します。
*   **データテスト:**
    *   `GET https://<server_ip>/test/large-response`: `test-data/large_file.bin` ファイルの内容を提供します（ファイルが存在する場合）。大きなダウンロードのテストに使用します（例: `dd if=/dev/zero of=test-data/large_file.bin bs=1M count=5` で作成）。
*   **デバッグ支援:**
    *   `GET/POST/... https://<server_ip>/test/echo`: 受信した HTTPS リクエストの詳細（メソッド、URI、ヘッダー、ボディ等）をレスポンスとして返します。
*   **バックエンド機能テスト (Nginx 経由):**
    *   `GET https://<server_ip>/test/delay`: 5秒後に応答を返します (実際には `/api/delay/5` に転送)。
    *   `GET https://<server_ip>/test/chunked`: チャンクエンコーディングされた応答を返します (実際には `/api/chunked` に転送)。
    *   `POST https://<server_ip>/test/multipart`: `multipart/form-data` 形式のデータ（ファイル含む）を受け付け、受信情報を JSON で返します (実際には `/api/multipart` に転送)。

## 🔧 カスタマイズ

*   **Basic 認証情報:** デフォルトのユーザー名 (`testuser`) とパスワード (`testpass`) を変更するには、`docker-compose.yml` ファイル内の `backend` サービスの `environment` セクションにある `BASIC_AUTH_USER` と `BASIC_AUTH_PASS` の値を変更し、`docker compose down && docker compose up --build -d` を実行してください。`.htpasswd` ファイルが再生成されます。
*   **証明書の CN (Common Name):** `nginx/entrypoint.sh` スクリプトはコンテナの IP アドレスを自動検出しようとしますが、特定のホスト名を使いたい場合はスクリプト内の `HOST_IP=...` の行を変更してください。変更後はコンテナの再ビルドが必要です。
*   **テストデータ:** 大きなファイルなどをテストするには、`test-data/` ディレクトリにファイルを配置してください。`/test/large-response` エンドポイントなどがこれを利用します。
*   **Flask バックエンドの拡張:** より複雑なテストシナリオが必要な場合は、`backend/app.py` に新しいルートやロジックを追加してください。`docker compose restart backend` または、コード変更を即時反映させるために `docker-compose.yml` でソースをマウントしている場合は変更が自動で反映されるはずです（Flask のデバッグモードが有効な場合）。

## ⚠️ 注意事項

*   このサーバーは **テスト目的** であり、自己署名証明書を使用し、セキュリティは考慮されていません。公開環境での使用は避けてください。
*   HTTPS アクセス時、クライアント側で証明書の検証を無効にするか、生成されたルート CA (`nginx/ssl/nginx_root_ca.pem`) を信頼するように設定する必要があります。