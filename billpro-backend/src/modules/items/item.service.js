const Item = require('./item.model');
const fs = require('fs');
const path = require('path');

const generateItemCode = async (companyId) => {
  const count = await Item.countDocuments({ companyId });
  return `ITM-${String(count + 1).padStart(4, '0')}`;
};

const createItem = async (companyId, data) => {
  const itemCode = await generateItemCode(companyId);
  const item = await Item.create({ ...data, companyId, itemCode });
  const itemObj = item.toObject();
  if (itemObj.image) {
    itemObj.image = `${process.env.SITE_URL || ''}${process.env.ITEM_IMAGE || ''}${itemObj.image}`;
  }
  return itemObj;
};

const getItems = async (companyId, { page = 1, limit = 20, search, itemType, isActive, lowStock, is_selling, categoryId }) => {
  const filter = { companyId };
  if (isActive !== undefined) filter.isActive = isActive === 'true' || isActive === true;
  if (is_selling !== undefined) filter.is_selling = is_selling === 'true' || is_selling === true;
  if (itemType) filter.itemType = itemType;
  if (categoryId) filter.categoryId = categoryId;
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
    Item.find(filter).populate('categoryId', 'name').sort({ name: 1 }).skip((page - 1) * limit).limit(parseInt(limit)).lean(),
    Item.countDocuments(filter),
  ]);
  const itemsWithImageUrl = items.map(item => {
    if (item.image) {
      item.image = `${process.env.SITE_URL || ''}${process.env.ITEM_IMAGE || ''}${item.image}`;
    }
    return item;
  });
  return { items: itemsWithImageUrl, total, page: parseInt(page), limit: parseInt(limit) };
};

const getItemById = async (companyId, itemId) => {
  const item = await Item.findOne({ _id: itemId, companyId }).populate('categoryId').lean();
  if (!item) throw Object.assign(new Error('Item not found'), { statusCode: 404 });
  if (item.image) {
    item.image = `${process.env.SITE_URL || ''}${process.env.ITEM_IMAGE || ''}${item.image}`;
  }
  return item;
};

const updateItem = async (companyId, itemId, data) => {
  if (data.image) {
    const oldItem = await Item.findOne({ _id: itemId, companyId });
    if (oldItem && oldItem.image && oldItem.image !== data.image) {
      const oldImagePath = path.join(__dirname, '../../..', 'uploads/Item', oldItem.image);
      fs.unlink(oldImagePath, (err) => {
        if (err) console.error('Failed to delete old image file:', err);
      });
    }
  }
  const item = await Item.findOneAndUpdate({ _id: itemId, companyId }, { $set: data }, { new: true, runValidators: true }).populate('categoryId').lean();
  if (!item) throw Object.assign(new Error('Item not found'), { statusCode: 404 });
  if (item.image) {
    item.image = `${process.env.SITE_URL || ''}${process.env.ITEM_IMAGE || ''}${item.image}`;
  }
  return item;
};

const deleteItem = async (companyId, itemId) => {
  const item = await Item.findOneAndUpdate({ _id: itemId, companyId }, { isActive: false }, { new: true }).populate('categoryId').lean();
  if (item && item.image) {
    item.image = `${process.env.SITE_URL || ''}${process.env.ITEM_IMAGE || ''}${item.image}`;
  }
  return item;
};

module.exports = { createItem, getItems, getItemById, updateItem, deleteItem };
