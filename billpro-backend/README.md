# BillQube Backend API

**Billing & Accounting Software for Indian SMEs**
Node.js + Express + MongoDB — GST-compliant REST API

---

## 📁 Project Structure

```
billqube-backend/
├── src/
│   ├── server.js                     # Entry point
│   ├── app.js                        # Express setup, middleware registration
│   ├── routes/
│   │   └── index.js                  # Master router — all module routes
│   │
│   ├── config/
│   │   ├── database.js               # MongoDB connection
│   │   ├── redis.js                  # Redis connection + helpers (OTP, cache, blacklist)
│   │   └── constants.js              # Roles, permissions, GST rates, states, enums
│   │
│   ├── middleware/
│   │   ├── auth.middleware.js        # JWT verification, company context
│   │   ├── rbac.middleware.js        # Role-based access control
│   │   ├── auditLog.js               # Immutable audit trail (auto-logs CRUD)
│   │   ├── errorHandler.js           # Global error handler
│   │   ├── rateLimiter.js            # express-rate-limit config
│   │   └── upload.js                 # Multer file upload config
│   │
│   ├── utils/
│   │   ├── gstCalculator.js          # ⭐ Core GST engine (intra/inter/export/RCM)
│   │   ├── billNumberGenerator.js    # Sequential bill numbers per FY
│   │   ├── otpService.js             # OTP generation, storage, verification
│   │   ├── responseHelper.js         # Standardized API response helpers
│   │   └── logger.js                 # Winston logging
│   │
│   ├── jobs/
│   │   └── queues.js                 # BullMQ — PDF, email, GST retry queues
│   │
│   └── modules/
│       ├── auth/
│       │   ├── auth.service.js       # register, login, OTP, JWT, password mgmt
│       │   ├── auth.controller.js
│       │   ├── auth.routes.js
│       │   └── auth.validation.js    # Joi schemas
│       │
│       ├── users/
│       │   └── user.model.js         # User schema, bcrypt, sessions, RBAC
│       │
│       ├── company/
│       │   ├── company.model.js      # Company, branches, bank accounts
│       │   ├── company.service.js    # GSTIN/IFSC validation, branch mgmt
│       │   ├── company.controller.js
│       │   └── company.routes.js
│       │
│       ├── vendors/
│       │   ├── vendor.model.js
│       │   ├── vendor.service.js
│       │   ├── vendor.controller.js
│       │   └── vendor.routes.js
│       │
│       ├── customers/
│       │   ├── customer.model.js
│       │   ├── customer.service.js
│       │   ├── customer.controller.js
│       │   └── customer.routes.js
│       │
│       ├── items/
│       │   ├── item.model.js         # Product/service master, HSN/SAC, inventory
│       │   ├── item.service.js
│       │   └── item.routes.js
│       │
│       ├── purchase/
│       │   ├── purchaseBill.model.js # Line items, GST, ITC, attachments
│       │   ├── purchaseBill.service.js # WAC inventory update, void, outstanding
│       │   ├── purchaseBill.controller.js
│       │   └── purchaseBill.routes.js
│       │
│       ├── sales/
│       │   ├── salesInvoice.model.js  # Tax invoice, proforma, e-invoice, EWB
│       │   ├── salesInvoice.service.js # Proforma→Invoice, aging report
│       │   ├── salesInvoice.controller.js
│       │   ├── salesInvoice.routes.js
│       │   └── creditNote.model.js    # CreditNote + DebitNote schemas
│       │
│       ├── inventory/
│       │   └── inventory.model.js    # Stock levels + StockMovement log
│       │
│       ├── dashboard/
│       │   ├── dashboard.service.js  # KPI cards, charts, analytics aggregations
│       │   └── dashboard.routes.js
│       │
│       └── reports/
│           ├── report.service.js     # Excel reports, GSTR-1 JSON export
│           └── report.routes.js
│
├── tests/
│   ├── unit/
│   │   └── gstCalculator.test.js    # GST engine unit tests
│   └── integration/
│       └── auth.test.js             # Auth API integration tests
│
├── logs/                             # Winston log files (gitignored)
├── .env.example                      # Environment variable template
├── .gitignore
├── package.json
└── README.md
```

---

## 🚀 Quick Start

```bash
# 1. Install dependencies
npm install

# 2. Set up environment
cp .env.example .env
# Edit .env with your MongoDB URI, Redis, JWT secrets, etc.

# 3. Start development server
npm run dev

# 4. Run tests
npm test
```

---

## 🔌 API Endpoints

### Auth
| Method | Endpoint                         | Description                |
|--------|----------------------------------|----------------------------|
| POST   | /api/v1/auth/register            | User registration          |
| POST   | /api/v1/auth/verify-otp          | Verify email/mobile OTP    |
| POST   | /api/v1/auth/login               | Login with password        |
| POST   | /api/v1/auth/login/otp           | Request login OTP          |
| POST   | /api/v1/auth/refresh             | Refresh access token       |
| POST   | /api/v1/auth/logout              | Logout (blacklist token)   |
| POST   | /api/v1/auth/forgot-password     | Request password reset     |
| POST   | /api/v1/auth/reset-password      | Reset with token           |
| POST   | /api/v1/auth/change-password     | Change password            |
| GET    | /api/v1/auth/me                  | Get logged-in user         |

### Companies
| Method | Endpoint                                 | Description              |
|--------|------------------------------------------|--------------------------|
| POST   | /api/v1/companies                        | Create company           |
| GET    | /api/v1/companies                        | Get active company       |
| PUT    | /api/v1/companies                        | Update company           |
| GET    | /api/v1/companies/validate/gstin/:gstin  | Validate GSTIN           |
| GET    | /api/v1/companies/validate/ifsc/:ifsc    | Validate IFSC code       |
| POST   | /api/v1/companies/branches               | Add branch               |
| POST   | /api/v1/companies/bank-accounts          | Add bank account         |

### Vendors / Customers / Items
| Method | Endpoint                    | Description        |
|--------|-----------------------------|--------------------|
| GET    | /api/v1/vendors             | List vendors       |
| POST   | /api/v1/vendors             | Create vendor      |
| GET    | /api/v1/vendors/:id         | Get vendor         |
| PUT    | /api/v1/vendors/:id         | Update vendor      |
| DELETE | /api/v1/vendors/:id         | Deactivate vendor  |
| (same pattern for /customers and /items)          |

### Purchase Bills
| Method | Endpoint                         | Description             |
|--------|----------------------------------|-------------------------|
| GET    | /api/v1/purchase                 | List purchase bills     |
| POST   | /api/v1/purchase                 | Create purchase bill    |
| GET    | /api/v1/purchase/:id             | Get bill by ID          |
| PUT    | /api/v1/purchase/:id             | Update bill             |
| DELETE | /api/v1/purchase/:id             | Void bill               |
| GET    | /api/v1/purchase/outstanding     | Vendor outstanding      |

### Sales Invoices
| Method | Endpoint                         | Description                   |
|--------|----------------------------------|-------------------------------|
| GET    | /api/v1/sales                    | List invoices                 |
| POST   | /api/v1/sales                    | Create invoice                |
| GET    | /api/v1/sales/:id                | Get invoice by ID             |
| DELETE | /api/v1/sales/:id                | Void invoice                  |
| POST   | /api/v1/sales/:id/convert        | Proforma → Tax Invoice        |
| GET    | /api/v1/sales/aging              | Receivables aging report      |

### Dashboard
| Method | Endpoint                            | Description              |
|--------|-------------------------------------|--------------------------|
| GET    | /api/v1/dashboard/kpis              | 12 KPI cards             |
| GET    | /api/v1/dashboard/sales-trend       | Monthly sales trend      |
| GET    | /api/v1/dashboard/sales-vs-purchase | Grouped bar chart data   |
| GET    | /api/v1/dashboard/top-customers     | Top 10 customers         |
| GET    | /api/v1/dashboard/invoice-status    | Donut chart data         |
| GET    | /api/v1/dashboard/gst-summary       | GST monthly summary      |

### Reports
| Method | Endpoint                                | Description           |
|--------|-----------------------------------------|-----------------------|
| GET    | /api/v1/reports/sales-register/excel    | Sales register XLSX   |
| GET    | /api/v1/reports/purchase-register/excel | Purchase register XLSX|
| GET    | /api/v1/reports/gstr1/json              | GSTR-1 JSON export    |

---

## 🔐 Authentication

All protected routes require:
```
Authorization: Bearer <access_token>
X-Company-Id: <company_id>
```

---

## 🗺️ Planned Future Modules (Phase 2)
- `modules/stock/`      — Full WMS: stock adjustments, batch tracking, warehouses
- `modules/employees/`  — Employee management, attendance
- `modules/payroll/`    — Payroll processing
- `modules/eInvoice/`   — Full IRP e-invoice generation service
- `modules/eWayBill/`   — NIC e-way bill API integration
