const Customer = require('./customer.model');

const generateCustomerCode = async (companyId) => {
  const count = await Customer.countDocuments({ companyId });
  return `CUS-${String(count + 1).padStart(4, '0')}`;
};

const createCustomer = async (companyId, data) => {
  const customerCode = await generateCustomerCode(companyId);
  return Customer.create({ ...data, companyId, customerCode });
};

const getCustomers = async (companyId, { page = 1, limit = 20, search, customerType, isActive = true }) => {
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
  const customer = await Customer.findOneAndUpdate({ _id: customerId, companyId }, { $set: data }, { new: true, runValidators: true });
  if (!customer) throw Object.assign(new Error('Customer not found'), { statusCode: 404 });
  return customer;
};

const deleteCustomer = async (companyId, customerId) => {
  return Customer.findOneAndUpdate({ _id: customerId, companyId }, { isActive: false }, { new: true });
};

module.exports = { createCustomer, getCustomers, getCustomerById, updateCustomer, deleteCustomer };
