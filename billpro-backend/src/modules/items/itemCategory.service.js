const ItemCategory = require('./itemCategory.model');
const Item = require('./item.model');

const createCategory = async (companyId, data) => {
  const existing = await ItemCategory.findOne({ 
    companyId, 
    name: { $regex: new RegExp(`^${data.name.trim()}$`, 'i') } 
  });
  if (existing) {
    throw Object.assign(new Error('Category with this name already exists'), { statusCode: 400 });
  }

  return ItemCategory.create({ ...data, companyId });
};

const getCategories = async (companyId, { page = 1, limit = 20, search, isActive }) => {
  const filter = { companyId };
  if (isActive !== undefined) filter.isActive = isActive === 'true' || isActive === true;
  if (search) {
    filter.$or = [
      { name: { $regex: search, $options: 'i' } },
      { description: { $regex: search, $options: 'i' } }
    ];
  }

  const [categories, total] = await Promise.all([
    ItemCategory.find(filter).sort({ name: -1 }).select('-createdAt -updatedAt -__v').skip((page - 1) * limit).limit(parseInt(limit)).lean(),
    ItemCategory.countDocuments(filter)
  ]);

  return { categories, total, page: parseInt(page), limit: parseInt(limit) };
};

const getCategoryById = async (companyId, categoryId) => {
  const category = await ItemCategory.findOne({ _id: categoryId, companyId }).select('-createdAt -updatedAt -__v').lean();
  if (!category) throw Object.assign(new Error('Item Category not found'), { statusCode: 404 });
  return category;
};

const updateCategory = async (companyId, categoryId, data) => {
  if (data.name) {
    const existing = await ItemCategory.findOne({
      companyId,
      _id: { $ne: categoryId },
      name: { $regex: new RegExp(`^${data.name.trim()}$`, 'i') }
    });
    if (existing) {
      throw Object.assign(new Error('Category with this name already exists'), { statusCode: 400 });
    }
  }

  const category = await ItemCategory.findOneAndUpdate(
    { _id: categoryId, companyId },
    { $set: data },
    { new: true, runValidators: true }
  ).lean();
  if (!category) throw Object.assign(new Error('Item Category not found'), { statusCode: 404 });
  return category;
};

const deleteCategory = async (companyId, categoryId) => {
  // Check if any items are currently using this category
  const itemInUse = await Item.findOne({ categoryId, companyId });
  if (itemInUse) {
    throw Object.assign(new Error('Cannot delete category as it is currently linked to items'), { statusCode: 400 });
  }

  const category = await ItemCategory.findOneAndUpdate(
    { _id: categoryId, companyId },
    { isActive: false },
    { new: true }
  ).lean();
  if (!category) throw Object.assign(new Error('Item Category not found'), { statusCode: 404 });
  return category;
};

module.exports = {
  createCategory,
  getCategories,
  getCategoryById,
  updateCategory,
  deleteCategory
};
