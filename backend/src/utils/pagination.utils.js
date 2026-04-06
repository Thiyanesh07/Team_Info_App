/**
 * Standardized Pagination Helper
 * @param {Object} query - Express request query object
 * @returns {Object} - Object containing skip, take, and metadata factors
 */
const getPagination = (query) => {
  const page = Math.max(1, parseInt(query.page) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit) || 20));
  const skip = (page - 1) * limit;

  return {
    skip,
    take: limit,
    page,
    limit
  };
};

/**
 * Format Pagination Metadata for Response
 * @param {number} totalCount - Total records in DB
 * @param {number} page - Current page
 * @param {number} limit - Items per page
 * @returns {Object} - Metadata object
 */
const getPaginationMetadata = (totalCount, page, limit) => {
  return {
    total: totalCount,
    page,
    limit,
    totalPages: Math.ceil(totalCount / limit)
  };
};

module.exports = {
  getPagination,
  getPaginationMetadata
};
