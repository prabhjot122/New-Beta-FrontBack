// Mock data for the admin panel and leaderboard

export interface User {
  id: number;
  name: string;
  email: string;
  points: number;
  rank: number;
  sharesCount: number;
  registrationDate: string;
  status: 'active' | 'inactive';
  lastActivity: string;
  isAdmin: boolean;
}

export interface LeaderboardEntry {
  rank: number;
  name: string;
  points: number;
  sharesCount: number;
}

export interface AnalyticsData {
  totalUsers: number;
  activeUsers24h: number;
  totalSharesToday: number;
  pointsDistributedToday: number;
  platformBreakdown: {
    [platform: string]: {
      shares: number;
      percentage: number;
    };
  };
  growthMetrics: {
    newUsers7d: number;
    userRetentionRate: number;
    averageSessionDuration: number;
  };
}

// Generate mock users with legal professional names
const generateMockUsers = (): User[] => {
  const legalNames = [
    'Advocate Rajesh Kumar', 'Dr. Priya Sharma', 'Justice Anil Verma', 'Advocate Meera Gupta',
    'Senior Counsel Vikram Singh', 'Advocate Sunita Rao', 'Justice Ramesh Patel', 'Dr. Kavita Joshi',
    'Advocate Suresh Reddy', 'Justice Neha Agarwal', 'Senior Advocate Amit Khanna', 'Dr. Ravi Mehta',
    'Advocate Pooja Malhotra', 'Justice Deepak Sinha', 'Advocate Sanjay Tiwari', 'Dr. Anita Desai',
    'Senior Counsel Manoj Jain', 'Advocate Rekha Nair', 'Justice Ashok Pandey', 'Dr. Shweta Bansal',
    'Advocate Rohit Saxena', 'Justice Preeti Chopra', 'Senior Advocate Vinod Kumar', 'Dr. Nisha Arora',
    'Advocate Kiran Bhatia', 'Justice Sunil Kapoor', 'Advocate Geeta Srivastava', 'Dr. Ajay Mishra',
    'Senior Counsel Ritu Agarwal', 'Advocate Manish Gupta', 'Justice Seema Yadav', 'Dr. Rahul Joshi',
    'Advocate Divya Sharma', 'Justice Arun Kumar', 'Senior Advocate Neeraj Patel', 'Dr. Swati Verma',
    'Advocate Harsh Vardhan', 'Justice Madhuri Singh', 'Advocate Sachin Reddy', 'Dr. Pallavi Jain',
    'Senior Counsel Arjun Malhotra', 'Advocate Shruti Nair', 'Justice Vikas Pandey', 'Dr. Ruchi Desai',
    'Advocate Nitin Bansal', 'Justice Smita Saxena', 'Senior Advocate Gaurav Chopra', 'Dr. Monika Arora',
    'Advocate Tarun Bhatia', 'Justice Alok Kapoor', 'Advocate Shilpa Srivastava', 'Dr. Vivek Mishra'
  ];

  const domains = ['lawfirm.com', 'legalcorp.in', 'advocates.org', 'judiciary.gov.in', 'lawchambers.com'];
  
  return legalNames.map((name, index) => {
    const basePoints = Math.floor(Math.random() * 5000) + 100;
    const sharesCount = Math.floor(basePoints / 50) + Math.floor(Math.random() * 10);
    const email = name.toLowerCase()
      .replace(/[^a-z\s]/g, '')
      .replace(/\s+/g, '.')
      .replace(/^(dr|justice|advocate|senior|counsel)\./, '') + 
      '@' + domains[Math.floor(Math.random() * domains.length)];
    
    const registrationDate = new Date(
      Date.now() - Math.floor(Math.random() * 365 * 24 * 60 * 60 * 1000)
    ).toISOString().split('T')[0];
    
    const lastActivity = new Date(
      Date.now() - Math.floor(Math.random() * 30 * 24 * 60 * 60 * 1000)
    ).toISOString().split('T')[0];

    return {
      id: index + 1,
      name,
      email,
      points: basePoints,
      rank: 0, // Will be calculated after sorting
      sharesCount,
      registrationDate,
      status: Math.random() > 0.1 ? 'active' : 'inactive' as 'active' | 'inactive',
      lastActivity,
      isAdmin: index === 0 // First user is admin
    };
  }).sort((a, b) => b.points - a.points)
    .map((user, index) => ({ ...user, rank: index + 1 }));
};

// Generate mock analytics data
const generateAnalyticsData = (): AnalyticsData => {
  return {
    totalUsers: 1247,
    activeUsers24h: 89,
    totalSharesToday: 156,
    pointsDistributedToday: 2340,
    platformBreakdown: {
      linkedin: { shares: 45, percentage: 28.8 },
      twitter: { shares: 38, percentage: 24.4 },
      facebook: { shares: 35, percentage: 22.4 },
      whatsapp: { shares: 25, percentage: 16.0 },
      instagram: { shares: 13, percentage: 8.3 }
    },
    growthMetrics: {
      newUsers7d: 23,
      userRetentionRate: 78.5,
      averageSessionDuration: 12.4
    }
  };
};

export const mockUsers = generateMockUsers();
export const mockAnalytics = generateAnalyticsData();

// Get top leaderboard entries
export const getTopLeaderboard = (limit: number = 10): LeaderboardEntry[] => {
  return mockUsers.slice(0, limit).map(user => ({
    rank: user.rank,
    name: user.name,
    points: user.points,
    sharesCount: user.sharesCount
  }));
};

// Search and filter users
export const searchUsers = (query: string, users: User[] = mockUsers): User[] => {
  if (!query.trim()) return users;
  
  const searchTerm = query.toLowerCase();
  return users.filter(user => 
    user.name.toLowerCase().includes(searchTerm) ||
    user.email.toLowerCase().includes(searchTerm)
  );
};

// Sort users by different criteria
export const sortUsers = (users: User[], sortBy: string): User[] => {
  const sorted = [...users];
  
  switch (sortBy) {
    case 'points':
      return sorted.sort((a, b) => b.points - a.points);
    case 'name':
      return sorted.sort((a, b) => a.name.localeCompare(b.name));
    case 'email':
      return sorted.sort((a, b) => a.email.localeCompare(b.email));
    case 'date':
      return sorted.sort((a, b) => new Date(b.registrationDate).getTime() - new Date(a.registrationDate).getTime());
    default:
      return sorted;
  }
};

// Export user data
export const exportUsers = (users: User[], format: 'csv' | 'json'): string => {
  if (format === 'json') {
    return JSON.stringify(users, null, 2);
  }
  
  // CSV format
  const headers = ['ID', 'Name', 'Email', 'Points', 'Rank', 'Shares', 'Registration Date', 'Status', 'Last Activity'];
  const csvRows = [
    headers.join(','),
    ...users.map(user => [
      user.id,
      `"${user.name}"`,
      user.email,
      user.points,
      user.rank,
      user.sharesCount,
      user.registrationDate,
      user.status,
      user.lastActivity
    ].join(','))
  ];
  
  return csvRows.join('\n');
};
