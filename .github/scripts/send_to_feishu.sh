#!/bin/bash
set -e

# 飞书通知脚本 - 上传构建产物到飞书群
# 支持两种模式：
# 1. Webhook 模式（仅发送通知消息）: ./send_to_feishu.sh webhook <webhook_url> <file_path> <environment> <build_type>
# 2. OpenAPI 模式（上传文件）: ./send_to_feishu.sh openapi <app_id> <app_secret> <chat_id> <file_path> <environment> <build_type>

MODE="$1"

if [ "$MODE" == "webhook" ]; then
  WEBHOOK_URL="$2"
  FILE_PATH="$3"
  ENVIRONMENT="$4"
  BUILD_TYPE="$5"
  BUILD_ACTOR="${6:-Unknown}"
  BUILD_START_TIME="${7:-N/A}"
  BUILD_END_TIME="${8:-N/A}"

  if [ -z "$WEBHOOK_URL" ] || [ -z "$FILE_PATH" ]; then
    echo "Usage: $0 webhook <webhook_url> <file_path> <environment> <build_type> [actor] [start_time] [end_time]"
    exit 1
  fi

  if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File not found: $FILE_PATH"
    exit 1
  fi

  FILE_NAME=$(basename "$FILE_PATH")
  FILE_SIZE=$(ls -lh "$FILE_PATH" | awk '{print $5}')
  TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')

  if [ "$BUILD_TYPE" == "APK" ]; then
    EMOJI="🤖"
    PLATFORM="Android"
  elif [ "$BUILD_TYPE" == "IPA" ]; then
    EMOJI="🍎"
    PLATFORM="iOS"
  else
    EMOJI="📦"
    PLATFORM="Unknown"
  fi

  MESSAGE=$(cat <<EOF
{
  "msg_type": "interactive",
  "card": {
    "header": {
      "title": {
        "tag": "plain_text",
        "content": "${EMOJI} Story App 构建完成 - ${PLATFORM}"
      },
      "template": "blue"
    },
    "elements": [
      {
        "tag": "div",
        "fields": [
          {
            "is_short": true,
            "text": {
              "tag": "lark_md",
              "content": "**环境**\\n${ENVIRONMENT}"
            }
          },
          {
            "is_short": true,
            "text": {
              "tag": "lark_md",
              "content": "**平台**\\n${PLATFORM}"
            }
          },
          {
            "is_short": true,
            "text": {
              "tag": "lark_md",
              "content": "**构建人**\\n${BUILD_ACTOR}"
            }
          },
          {
            "is_short": true,
            "text": {
              "tag": "lark_md",
              "content": "**文件大小**\\n${FILE_SIZE}"
            }
          },
          {
            "is_short": true,
            "text": {
              "tag": "lark_md",
              "content": "**开始时间**\\n${BUILD_START_TIME}"
            }
          },
          {
            "is_short": true,
            "text": {
              "tag": "lark_md",
              "content": "**结束时间**\\n${BUILD_END_TIME}"
            }
          },
          {
            "is_short": false,
            "text": {
              "tag": "lark_md",
              "content": "**文件名**\\n${FILE_NAME}"
            }
          }
        ]
      },
      {
        "tag": "note",
        "elements": [
          {
            "tag": "plain_text",
            "content": "点击下方按钮前往 GitHub Actions 下载构建产物"
          }
        ]
      },
      {
        "tag": "action",
        "actions": [
          {
            "tag": "button",
            "text": {
              "tag": "plain_text",
              "content": "下载构建产物"
            },
            "type": "primary",
            "url": "${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
          }
        ]
      }
    ]
  }
}
EOF
)

  echo "📤 Sending notification to Feishu (Webhook mode)..."
  RESPONSE=$(curl -s -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$MESSAGE")

  if echo "$RESPONSE" | grep -q '"code":0'; then
    echo "✅ Successfully sent notification to Feishu"
    exit 0
  else
    echo "❌ Failed to send notification to Feishu"
    echo "Response: $RESPONSE"
    exit 1
  fi

elif [ "$MODE" == "openapi" ]; then
  APP_ID="$2"
  APP_SECRET="$3"
  CHAT_ID="$4"
  FILE_PATH="$5"
  ENVIRONMENT="$6"
  BUILD_TYPE="$7"
  BUILD_ACTOR="${8:-Unknown}"
  BUILD_START_TIME="${9:-N/A}"
  BUILD_END_TIME="${10:-N/A}"

  if [ -z "$APP_ID" ] || [ -z "$APP_SECRET" ] || [ -z "$CHAT_ID" ] || [ -z "$FILE_PATH" ]; then
    echo "Usage: $0 openapi <app_id> <app_secret> <chat_id> <file_path> <environment> <build_type> [actor] [start_time] [end_time]"
    exit 1
  fi

  if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File not found: $FILE_PATH"
    exit 1
  fi

  FILE_NAME=$(basename "$FILE_PATH")

  echo "📤 Uploading to Feishu (OpenAPI mode)..."

  # 1. 获取 tenant_access_token
  echo "🔑 Getting access token..."
  TOKEN_RESPONSE=$(curl -s -X POST "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" \
    -H "Content-Type: application/json" \
    -d "{\"app_id\":\"$APP_ID\",\"app_secret\":\"$APP_SECRET\"}")

  ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"tenant_access_token":"[^"]*' | cut -d'"' -f4)

  if [ -z "$ACCESS_TOKEN" ]; then
    echo "❌ Failed to get access token"
    echo "Response: $TOKEN_RESPONSE"
    exit 1
  fi

  echo "✅ Got access token"

  # 2. 上传文件
  echo "📁 Uploading file: $FILE_NAME"
  UPLOAD_RESPONSE=$(curl -s -X POST "https://open.feishu.cn/open-apis/im/v1/files" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -F "file_type=stream" \
    -F "file_name=$FILE_NAME" \
    -F "file=@$FILE_PATH")

  FILE_KEY=$(echo "$UPLOAD_RESPONSE" | grep -o '"file_key":"[^"]*' | cut -d'"' -f4)

  if [ -z "$FILE_KEY" ]; then
    echo "❌ Failed to upload file"
    echo "Response: $UPLOAD_RESPONSE"
    exit 1
  fi

  echo "✅ File uploaded, file_key: $FILE_KEY"

  # 3. 发送消息到群聊
  FILE_SIZE=$(ls -lh "$FILE_PATH" | awk '{print $5}')
  TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')

  if [ "$BUILD_TYPE" == "APK" ]; then
    EMOJI="🤖"
    PLATFORM="Android"
  elif [ "$BUILD_TYPE" == "IPA" ]; then
    EMOJI="🍎"
    PLATFORM="iOS"
  else
    EMOJI="📦"
    PLATFORM="Unknown"
  fi

  echo "💬 Sending message with file..."
  MESSAGE_PAYLOAD=$(cat <<EOF
{
  "receive_id": "$CHAT_ID",
  "msg_type": "file",
  "content": "{\"file_key\":\"$FILE_KEY\"}"
}
EOF
)

  MESSAGE_RESPONSE=$(curl -s -X POST "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=chat_id" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$MESSAGE_PAYLOAD")

  if echo "$MESSAGE_RESPONSE" | grep -q '"code":0'; then
    echo "✅ File sent to Feishu chat"

    # 发送额外的信息卡片
    CARD_PAYLOAD=$(cat <<EOF
{
  "receive_id": "$CHAT_ID",
  "msg_type": "interactive",
  "content": "{\"config\":{\"wide_screen_mode\":true},\"header\":{\"title\":{\"tag\":\"plain_text\",\"content\":\"${EMOJI} Story App 构建完成 - ${PLATFORM}\"},\"template\":\"blue\"},\"elements\":[{\"tag\":\"div\",\"fields\":[{\"is_short\":true,\"text\":{\"tag\":\"lark_md\",\"content\":\"**环境**\\\\n${ENVIRONMENT}\"}},{\"is_short\":true,\"text\":{\"tag\":\"lark_md\",\"content\":\"**平台**\\\\n${PLATFORM}\"}},{\"is_short\":true,\"text\":{\"tag\":\"lark_md\",\"content\":\"**构建人**\\\\n${BUILD_ACTOR}\"}},{\"is_short\":true,\"text\":{\"tag\":\"lark_md\",\"content\":\"**文件大小**\\\\n${FILE_SIZE}\"}},{\"is_short\":true,\"text\":{\"tag\":\"lark_md\",\"content\":\"**开始时间**\\\\n${BUILD_START_TIME}\"}},{\"is_short\":true,\"text\":{\"tag\":\"lark_md\",\"content\":\"**结束时间**\\\\n${BUILD_END_TIME}\"}}]},{\"tag\":\"note\",\"elements\":[{\"tag\":\"plain_text\",\"content\":\"文件已上传，请下载安装\"}]}]}"
}
EOF
)

    curl -s -X POST "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=chat_id" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$CARD_PAYLOAD" > /dev/null

    exit 0
  else
    echo "❌ Failed to send message"
    echo "Response: $MESSAGE_RESPONSE"
    exit 1
  fi

else
  echo "Usage:"
  echo "  Webhook mode: $0 webhook <webhook_url> <file_path> <environment> <build_type>"
  echo "  OpenAPI mode: $0 openapi <app_id> <app_secret> <chat_id> <file_path> <environment> <build_type>"
  exit 1
fi
