#!/bin/bash

# Параметры
PROJECT_NAME="green_city_susak"
REGION="eu-central-1"
OUTPUT_FILE="inventory.ini"

# Переменные
BACKEND_DNS="" FRONTEND_DNS="" MONITORING_DNS=""
BACKEND_IP=""  FRONTEND_IP=""  MONITORING_IP=""

# Заголовок inventory.ini
cat > "$OUTPUT_FILE" << EOF
# Автогенерируемый inventory для Ansible
[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3

EOF

# Получаем инстансы
aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=instance-state-name,Values=running" \
  --output json | jq -r '
  .Reservations[].Instances[] |
  select(.PublicDnsName and .Tags) |
  .Tags |= from_entries |
  select(.Tags.Project == $PROJECT_NAME) |
  "\(.Tags.Role)|\(.PublicDnsName)|\(.PublicIpAddress)"' --arg PROJECT_NAME "$PROJECT_NAME" | while IFS='|' read ROLE DNS IP; do

    case "$ROLE" in
      "backend")
        BACKEND_DNS="$DNS"
        BACKEND_IP="$IP"
        echo "backend: $DNS (IP: $IP)"
        ;;
      "frontend")
        FRONTEND_DNS="$DNS"
        FRONTEND_IP="$IP"
        echo "frontend: $DNS (IP: $IP)"
        ;;
      "monitoring")
        MONITORING_DNS="$DNS"
        MONITORING_IP="$IP"
        echo "monitoring: $DNS (IP: $IP)"
        ;;
      *)
        echo "⚠️  Неизвестная роль: $ROLE — пропускаем"
        ;;
    esac

    # Сохраняем в tmp
    [[ "$ROLE" == "backend"    ]] && echo "$DNS" > /tmp/backend_dns.tmp    && echo "$IP" > /tmp/backend_ip.tmp
    [[ "$ROLE" == "frontend"   ]] && echo "$DNS" > /tmp/frontend_dns.tmp   && echo "$IP" > /tmp/frontend_ip.tmp
    [[ "$ROLE" == "monitoring" ]] && echo "$DNS" > /tmp/monitoring_dns.tmp && echo "$IP" > /tmp/monitoring_ip.tmp

done

# Читаем из tmp
BACKEND_DNS=$(cat /tmp/backend_dns.tmp 2>/dev/null || echo "")
BACKEND_IP=$(cat /tmp/backend_ip.tmp 2>/dev/null || echo "")
FRONTEND_DNS=$(cat /tmp/frontend_dns.tmp 2>/dev/null || echo "")
FRONTEND_IP=$(cat /tmp/frontend_ip.tmp 2>/dev/null || echo "")
MONITORING_DNS=$(cat /tmp/monitoring_dns.tmp 2>/dev/null || echo "")
MONITORING_IP=$(cat /tmp/monitoring_ip.tmp 2>/dev/null || echo "")

# Удаляем временные файлы
rm -f /tmp/*_dns.tmp /tmp/*_ip.tmp

# Добавляем в inventory.ini
if [[ -n "$BACKEND_DNS" ]]; then
  cat >> "$OUTPUT_FILE" << EOF
[backend]
$BACKEND_DNS

[backend:vars]
backend_ip=$BACKEND_IP

EOF
fi

if [[ -n "$FRONTEND_DNS" ]]; then
  cat >> "$OUTPUT_FILE" << EOF
[frontend]
$FRONTEND_DNS

[frontend:vars]
frontend_ip=$FRONTEND_IP

EOF
fi

if [[ -n "$MONITORING_DNS" ]]; then
  cat >> "$OUTPUT_FILE" << EOF
[monitoring]
$MONITORING_DNS

[monitoring:vars]
monitoring_ip=$MONITORING_IP

EOF
fi

echo "✅ inventory.ini сгенерирован: DNS для подключения, IP — для шаблонов"
echo ""
cat "$OUTPUT_FILE"
