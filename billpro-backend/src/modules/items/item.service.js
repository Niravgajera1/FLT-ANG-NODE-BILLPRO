const Item = require('./item.model');
const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');

const generateItemCode = async (companyId) => {
  const count = await Item.countDocuments({ companyId });
  return `ITM-${String(count + 1).padStart(4, '0')}`;
};

const createItem = async (companyId, data) => {
  if (data.category && !data.categoryId) {
    data.categoryId = data.category;
  }
  const itemCode = await generateItemCode(companyId);
  const item = await Item.create({ ...data, companyId, itemCode });
  const itemObj = item.toObject();
  if (itemObj.image) {
    itemObj.image = `${process.env.SITE_URL || ''}${process.env.ITEM_IMAGE || ''}${itemObj.image}`;
  }
  return itemObj;
};

const getItems = async (companyId, { page = 1, limit = 20, search, itemType, isActive, lowStock, is_selling, categoryId, category }) => {
  const matchFilter = { companyId: new mongoose.Types.ObjectId(companyId) };
  if (isActive !== undefined) {
    matchFilter.isActive = isActive === 'true' || isActive === true;
  }
  if (is_selling !== undefined) {
    matchFilter.is_selling = is_selling === 'true' || is_selling === true;
  }
  if (itemType) {
    matchFilter.itemType = itemType;
  }
  const targetCategoryId = categoryId || category;
  if (targetCategoryId) {
    matchFilter.categoryId = new mongoose.Types.ObjectId(targetCategoryId);
  }
  if (lowStock === 'true') {
    matchFilter.$expr = { $lte: ['$currentStock', '$reorderLevel'] };
  }
  if (search) {
    matchFilter.$or = [
      { name: { $regex: search, $options: 'i' } },
      { hsnCode: { $regex: search, $options: 'i' } },
      { sacCode: { $regex: search, $options: 'i' } },
      { itemCode: { $regex: search, $options: 'i' } },
    ];
  }

  const pipeline = [
    { $match: matchFilter },
    {
      $lookup: {
        from: 'itemcategories',
        localField: 'categoryId',
        foreignField: '_id',
        as: 'categoryInfo'
      }
    },
    {
      $unwind: {
        path: '$categoryInfo',
        preserveNullAndEmptyArrays: true
      }
    },
    {
      $addFields: {
        categoryName: { $ifNull: ['$categoryInfo.name', ''] },
        category_id: { $ifNull: ['$categoryInfo._id', null] },
        categoryId: {
          $cond: {
            if: { $gt: [{ $type: '$categoryInfo' }, 'missing'] },
            then: {
              _id: '$categoryInfo._id',
              name: '$categoryInfo.name'
            },
            else: null
          }
        }
      }
    },
    { $sort: { name: 1 } },
    { $skip: (page - 1) * limit },
    { $limit: parseInt(limit) }
  ];

  const [items, total] = await Promise.all([
    Item.aggregate(pipeline),
    Item.countDocuments(matchFilter),
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
  if (data.category && !data.categoryId) {
    data.categoryId = data.category;
  }
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
