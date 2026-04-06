/**
 * Service to interact with the BIT Sathy Portal API
 */
class PortalService {
  /**
   * Fetches the detailed activity points breakdown for a user.
   * @param {string} psToken - User's session cookie
   * @param {string} enrollmentNo - The portal-specific enrollment number (e.g., 2024UAD1139)
   * @returns {Promise<{total: number, breakdown: Array}>}
   */
  async fetchActivityPointsBreakdown(psToken, enrollmentNo) {
    if (!psToken || !enrollmentNo) {
      throw new Error('psToken and enrollmentNo are required for sync');
    }

    const url = `https://ps.bitsathy.ac.in/api/ps_v2/activity/rewards/breakdown?id=1&user_id=${enrollmentNo}`;

    try {
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Accept': 'application/json, text/plain, */*',
          'Cookie': `PS=${psToken}`,
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        }
      });

      if (!response.ok) {
        throw new Error(`Portal API responded with status ${response.status}`);
      }

      const json = await response.json();

      if (!json.success || !json.data) {
        throw new Error(json.message || 'Failed to fetch breakdown from portal');
      }

      const breakdown = json.data;
      const total = breakdown.reduce((sum, cat) => sum + (cat.total_earned || 0), 0);

      return {
        total,
        breakdown
      };
    } catch (error) {
      console.error(`[PortalService] Error for ${enrollmentNo}:`, error.message);
      throw error;
    }
  }

  /**
   * (Optional) Extracts profile info to discover enrollment number automatically.
   */
  async getProfileInfo(psToken) {
    const url = 'https://ps.bitsathy.ac.in/api/ps_v2/dashboard/user-points?filter=overall';
    
    try {
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Cookie': `PS=${psToken}`,
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        }
      });

      if (!response.ok) return null;

      const json = await response.json();
      // The enrollment ID is often in the user object of these responses
      return json.data?.user || null;
    } catch (error) {
      return null;
    }
  }
}

module.exports = new PortalService();
