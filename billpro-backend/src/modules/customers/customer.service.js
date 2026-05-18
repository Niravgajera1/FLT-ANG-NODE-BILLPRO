const mongoose = require('mongoose');
const Customer = require('./customer.model');

const generateCustomerCode = async (companyId) => {
  const lastCustomer = await Customer.findOne({ companyId, customerCode: { $regex: /^CUS-\d+$/ } })
    .sort({ customerCode: -1 })
    .select('customerCode')
    .lean();

  let lastNumber = 0;
  if (lastCustomer && lastCustomer.customerCode) {
    const match = lastCustomer.customerCode.match(/\d+/);
    if (match) {
      lastNumber = parseInt(match[0], 10);
    }
  }

  const nextNumber = lastNumber + 1;
  return `CUS-${String(nextNumber).padStart(4, '0')}`;
};

const createCustomer = async (companyId, data) => {
  if (data.email !== undefined) {
    const trimmedEmail = data.email ? data.email.trim().toLowerCase() : '';
    if (trimmedEmail) {
      data.email = trimmedEmail; // Sanitize in place
      const companyObjectId = new mongoose.Types.ObjectId(companyId);
      const existing = await Customer.findOne({
        companyId: companyObjectId,
        email: { $regex: new RegExp(`^${trimmedEmail}$`, 'i') }
      });
      if (existing) {
        throw Object.assign(new Error('Customer with this email already exists for this company'), { statusCode: 409 });
      }
    } else {
      delete data.email; // If empty string, delete key so it's not stored in Mongo
    }
  }

  const customerCode = await generateCustomerCode(companyId);
  const created = await Customer.create({ ...data, companyId, customerCode });
  return created;
};

const getCustomers = async (companyId, { page = 1, limit = 20, search, customerType, isActive }) => {
  const filter = { companyId };
  if (isActive !== undefined) filter.isActive = isActive === 'true' || isActive === true;
  if (customerType) filter.customerType = customerType;
  if (search) {
    filter.$or = [
      { name:         { $regex: search, $options: 'i' } },
      { gstin:        { $regex: search, $options: 'i' } },
      { mobile:       { $regex: search, $options: 'i' } },
      { customerCode: { $regex: search, $options: 'i' } },
    ];
  }
  const [customers, total] = await Promise.all([
    Customer.find(filter).sort({ name: 1 }).skip((page - 1) * limit).limit(parseInt(limit)).lean(),
    Customer.countDocuments(filter),
  ]);
  return { customers, total, page: parseInt(page), limit: parseInt(limit) };
};

const getCustomerById = async (companyId, customerId) => {
  const customer = await Customer.findOne({ _id: customerId, companyId });
  if (!customer) throw Object.assign(new Error('Customer not found'), { statusCode: 404 });
  return customer;
};

const updateCustomer = async (companyId, customerId, data) => {
  if (data.email !== undefined) {
    const trimmedEmail = data.email ? data.email.trim().toLowerCase() : '';
    if (trimmedEmail) {
      data.email = trimmedEmail; // Sanitize in place
      const companyObjectId = new mongoose.Types.ObjectId(companyId);
      const existing = await Customer.findOne({
        companyId: companyObjectId,
        email: { $regex: new RegExp(`^${trimmedEmail}$`, 'i') },
        _id: { $ne: new mongoose.Types.ObjectId(customerId) }
      });
      if (existing) {
        throw Object.assign(new Error('Customer with this email already exists for this company'), { statusCode: 409 });
      }
    } else {
      delete data.email; // If empty string, delete key so it's not stored in Mongo
    }
  }

  const customer = await Customer.findOneAndUpdate({ _id: customerId, companyId }, { $set: data }, { new: true, runValidators: true });
  if (!customer) throw Object.assign(new Error('Customer not found'), { statusCode: 404 });
  return customer;
};

const deleteCustomer = async (companyId, customerId) => {
  return Customer.findOneAndUpdate({ _id: customerId, companyId }, { isActive: false }, { new: true });
};

const toggleCustomerStatus = async (companyId, customerId) => {
  const customer = await Customer.findOne({ _id: customerId, companyId });
  if (!customer) throw Object.assign(new Error('Customer not found'), { statusCode: 404 });
  customer.isActive = !customer.isActive;
  await customer.save();
  return customer;
};

module.exports = { createCustomer, getCustomers, getCustomerById, updateCustomer, deleteCustomer, toggleCustomerStatus };
