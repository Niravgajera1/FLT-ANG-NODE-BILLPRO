const Item = require('./item.model');

const generateItemCode = async (companyId) => {
  const count = await Item.countDocuments({ companyId });
  return `ITM-${String(count + 1).padStart(4, '0')}`;
};

const createItem = async (companyId, data) => {
  const itemCode = await generateItemCode(companyId);
  return Item.create({ ...data, companyId, itemCode });
};

const getItems = async (companyId, { page = 1, limit = 20, search, itemType, isActive = true, lowStock }) => {
  const filter = { companyId };
  if (isActive !== undefined) filter.isActive = isActive === 'true' || isActive === true;
  if (itemType) filter.itemType = itemType;
  if (lowStock === 'true') filter.isLowStock = true;
  if (search) {
    filter.$or = [
      { name: { $regex: search, $options: 'i' } },
      { hsnCode: { $regex: search, $options: 'i' } },
      { sacCode: { $regex: search, $options: 'i' } },
      { itemCode: { $regex: search, $options: 'i' } },
    ];
  }
  const [items, total] = await Promise.all([
    Item.find(filter).sort({ name: 1 }).skip((page - 1) * limit).limit(parseInt(limit)).lean(),
    Item.countDocuments(filter),
  ]);
  return { items, total, page: parseInt(page), limit: parseInt(limit) };
};

const getItemById = async (companyId, itemId) => {
  const item = await Item.findOne({ _id: itemId, companyId });
  if (!item) throw Object.assign(new Error('Item not found'), { statusCode: 404 });
  return item;
};

const updateItem = async (companyId, itemId, data) => {
  const item = await Item.findOneAndUpdate({ _id: itemId, companyId }, { $set: data }, { new: true, runValidators: true });
  if (!item) throw Object.assign(new Error('Item not found'), { statusCode: 404 });
  return item;
};

const deleteItem = async (companyId, itemId) => {
  return Item.findOneAndUpdate({ _id: itemId, companyId }, { isActive: false }, { new: true });
};

module.exports = { createItem, getItems, getItemById, updateItem, deleteItem };
