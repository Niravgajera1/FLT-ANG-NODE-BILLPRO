# BillQube Backend API Documentation

Base URL: `http://localhost:8587`

This document contains dynamically extracted endpoints, grouped by modules, with expected cURL commands and standardized responses.

---

## Module: GENERAL

### GET `/health`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/health \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

## Module: AUTH

### POST `/api/v1/auth/register`

**Example cURL Request:**
```bash
curl -X POST http://localhost:8587/api/v1/auth/register \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### POST `/api/v1/auth/verify-otp`

**Example cURL Request:**
```bash
curl -X POST http://localhost:8587/api/v1/auth/verify-otp \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### POST `/api/v1/auth/login`

**Example cURL Request:**
```bash
curl -X POST http://localhost:8587/api/v1/auth/login \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### POST `/api/v1/auth/login/otp`

**Example cURL Request:**
```bash
curl -X POST http://localhost:8587/api/v1/auth/login/otp \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### POST `/api/v1/auth/login/otp/verify`

**Example cURL Request:**
```bash
curl -X POST http://localhost:8587/api/v1/auth/login/otp/verify \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### POST `/api/v1/auth/refresh`

**Example cURL Request:**
```bash
curl -X POST http://localhost:8587/api/v1/auth/refresh \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### POST `/api/v1/auth/forgot-password`

**Example cURL Request:**
```bash
curl -X POST http://localhost:8587/api/v1/auth/forgot-password \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### POST `/api/v1/auth/reset-password`

**Example cURL Request:**
```bash
curl -X POST http://localhost:8587/api/v1/auth/reset-password \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### GET `/api/v1/auth/me`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/auth/me \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### POST `/api/v1/auth/logout`

**Example cURL Request:**
```bash
curl -X POST http://localhost:8587/api/v1/auth/logout \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### POST `/api/v1/auth/change-password`

**Example cURL Request:**
```bash
curl -X POST http://localhost:8587/api/v1/auth/change-password \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

## Module: COMPANIES

### POST `/api/v1/companies`

**Example cURL Request:**
```bash
curl -X POST http://localhost:8587/api/v1/companies \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### GET `/api/v1/companies`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/companies \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### PUT `/api/v1/companies`

**Example cURL Request:**
```bash
curl -X PUT http://localhost:8587/api/v1/companies \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### GET `/api/v1/companies/validate/gstin/:gstin`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/companies/validate/gstin/:gstin \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### GET `/api/v1/companies/validate/ifsc/:ifsc`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/companies/validate/ifsc/:ifsc \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### POST `/api/v1/companies/branches`

**Example cURL Request:**
```bash
curl -X POST http://localhost:8587/api/v1/companies/branches \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### PUT `/api/v1/companies/branches/:branchId`

**Example cURL Request:**
```bash
curl -X PUT http://localhost:8587/api/v1/companies/branches/:branchId \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### POST `/api/v1/companies/bank-accounts`

**Example cURL Request:**
```bash
curl -X POST http://localhost:8587/api/v1/companies/bank-accounts \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

## Module: VENDORS

### GET `/api/v1/vendors`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/vendors \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### POST `/api/v1/vendors`

**Example cURL Request:**
```bash
curl -X POST http://localhost:8587/api/v1/vendors \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### GET `/api/v1/vendors/:id`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/vendors/:id \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### PUT `/api/v1/vendors/:id`

**Example cURL Request:**
```bash
curl -X PUT http://localhost:8587/api/v1/vendors/:id \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### DELETE `/api/v1/vendors/:id`

**Example cURL Request:**
```bash
curl -X DELETE http://localhost:8587/api/v1/vendors/:id \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

## Module: CUSTOMERS

### GET `/api/v1/customers`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/customers \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### POST `/api/v1/customers`

**Example cURL Request:**
```bash
curl -X POST http://localhost:8587/api/v1/customers \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### GET `/api/v1/customers/:id`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/customers/:id \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### PUT `/api/v1/customers/:id`

**Example cURL Request:**
```bash
curl -X PUT http://localhost:8587/api/v1/customers/:id \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### DELETE `/api/v1/customers/:id`

**Example cURL Request:**
```bash
curl -X DELETE http://localhost:8587/api/v1/customers/:id \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

## Module: ITEMS

### GET `/api/v1/items`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/items \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### POST `/api/v1/items`

**Example cURL Request:**
```bash
curl -X POST http://localhost:8587/api/v1/items \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### GET `/api/v1/items/:id`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/items/:id \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### PUT `/api/v1/items/:id`

**Example cURL Request:**
```bash
curl -X PUT http://localhost:8587/api/v1/items/:id \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### DELETE `/api/v1/items/:id`

**Example cURL Request:**
```bash
curl -X DELETE http://localhost:8587/api/v1/items/:id \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

## Module: PURCHASE

### GET `/api/v1/purchase`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/purchase \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### POST `/api/v1/purchase`

**Example cURL Request:**
```bash
curl -X POST http://localhost:8587/api/v1/purchase \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### GET `/api/v1/purchase/outstanding`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/purchase/outstanding \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### GET `/api/v1/purchase/:id`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/purchase/:id \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### PUT `/api/v1/purchase/:id`

**Example cURL Request:**
```bash
curl -X PUT http://localhost:8587/api/v1/purchase/:id \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### DELETE `/api/v1/purchase/:id`

**Example cURL Request:**
```bash
curl -X DELETE http://localhost:8587/api/v1/purchase/:id \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

## Module: SALES

### GET `/api/v1/sales`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/sales \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### POST `/api/v1/sales`

**Example cURL Request:**
```bash
curl -X POST http://localhost:8587/api/v1/sales \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### GET `/api/v1/sales/aging`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/sales/aging \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### GET `/api/v1/sales/:id`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/sales/:id \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### DELETE `/api/v1/sales/:id`

**Example cURL Request:**
```bash
curl -X DELETE http://localhost:8587/api/v1/sales/:id \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### POST `/api/v1/sales/:id/convert`

**Example cURL Request:**
```bash
curl -X POST http://localhost:8587/api/v1/sales/:id/convert \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

## Module: DASHBOARD

### GET `/api/v1/dashboard/kpis`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/dashboard/kpis \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### GET `/api/v1/dashboard/sales-trend`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/dashboard/sales-trend \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### GET `/api/v1/dashboard/sales-vs-purchase`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/dashboard/sales-vs-purchase \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### GET `/api/v1/dashboard/top-customers`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/dashboard/top-customers \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### GET `/api/v1/dashboard/invoice-status`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/dashboard/invoice-status \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### GET `/api/v1/dashboard/gst-summary`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/dashboard/gst-summary \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

## Module: REPORTS

### GET `/api/v1/reports/sales-register/excel`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/reports/sales-register/excel \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### GET `/api/v1/reports/purchase-register/excel`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/reports/purchase-register/excel \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

### GET `/api/v1/reports/gstr1/json`

**Example cURL Request:**
```bash
curl -X GET http://localhost:8587/api/v1/reports/gstr1/json \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  -H "Content-Type: application/json"
```

**Success Response (200 / 201):**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response (400 / 401 / 403 / 404 / 422 / 500):**
```json
{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}
```

---

