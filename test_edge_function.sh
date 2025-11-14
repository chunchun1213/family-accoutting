#!/bin/bash

# Supabase 本地環境測試腳本

BASE_URL="http://127.0.0.1:54321/functions/v1"

echo "========================================="
echo "測試 Edge Function - Auth"
echo "========================================="
echo ""

# 1. 測試根路徑
echo "1. 測試根路徑"
curl -s "$BASE_URL/auth"
echo ""
echo ""

# 2. Health Check
echo "2. Health Check"
curl -s "$BASE_URL/auth/health"
echo ""
echo ""

# 3. 註冊測試 (TODO: 實作後測試)
# echo "3. 會員註冊"
# curl -s -X POST \
#   -H "Content-Type: application/json" \
#   -d '{"email":"test@example.com","name":"測試用戶","password":"Test1234!"}' \
#   "$BASE_URL/auth/register"

echo ""
echo "========================================="
echo "測試完成"
echo "========================================"
