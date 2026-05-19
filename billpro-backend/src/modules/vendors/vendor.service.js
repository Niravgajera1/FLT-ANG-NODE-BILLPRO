// ─── vendor.service.js ───────────────────────────────────────────────────────
const Vendor = require('./vendor.model');

const generateVendorCode = async (companyId) => {
  const lastVendor = await Vendor.findOne({ companyId, vendorCode: { $regex: /^VND-\d+$/ } })
    .sort({ vendorCode: -1 })
    .select('vendorCode')
    .lean();

  let lastNumber = 0;
  if (lastVendor && lastVendor.vendorCode) {
    const match = lastVendor.vendorCode.match(/\d+/);
    if (match) {
      lastNumber = parseInt(match[0], 10);
    }
  }

  const nextNumber = lastNumber + 1;
  return `VND-${String(nextNumber).padStart(4, '0')}`;
};

const createVendor = async (companyId, data) => {
  const vendorCode = await generateVendorCode(companyId);
  return Vendor.create({ ...data, companyId, vendorCode });
};

const getVendors = async (companyId, { page = 1, limit = 20, search, isActive }) => {
  const filter = { companyId };
  if (isActive !== undefined) filter.isActive = isActive === 'true' || isActive === true;
  if (search) {
    filter.$or = [
      { name:       { $regex: search, $options: 'i' } },
      { gstin:      { $regex: search, $options: 'i' } },
      { vendorCode: { $regex: search, $options: 'i' } },
    ];
  }
  const [vendors, total] = await Promise.all([
    Vendor.find(filter).sort({ name: 1 }).skip((page - 1) * limit).limit(parseInt(limit)).lean(),
    Vendor.countDocuments(filter),
  ]);
  return { vendors, total, page: parseInt(page), limit: parseInt(limit) };
};

const getVendorById = async (companyId, vendorId) => {
  const vendor = await Vendor.findOne({ _id: vendorId, companyId });
  if (!vendor) throw Object.assign(new Error('Vendor not found'), { statusCode: 404 });
  return vendor;
};

const updateVendor = async (companyId, vendorId, data) => {
  const vendor = await Vendor.findOneAndUpdate({ _id: vendorId, companyId }, { $set: data }, { new: true, runValidators: true });
  if (!vendor) throw Object.assign(new Error('Vendor not found'), { statusCode: 404 });
  return vendor;
};

const deleteVendor = async (companyId, vendorId) => {
  const vendor = await Vendor.findOne({ _id: vendorId, companyId });
  if (!vendor) throw Object.assign(new Error('Vendor not found'), { statusCode: 404 });
  vendor.isActive = !vendor.isActive;
  await vendor.save();
  return vendor;
};

module.exports = { createVendor, getVendors, getVendorById, updateVendor, deleteVendor };
