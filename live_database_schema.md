# Complete Production Database Schema

Below is the exhaustive list of every single table (model), its columns, and relational mappings currently operating within the live **Supabase PostgreSQL Database** (driven by Prisma).

---

## 👥 Core Identity & Profiles

### 1. User (`users`)
| Column Name | Data Type | Modifiers / Notes |
| :--- | :--- | :--- |
| `id` | String | Primary Key (UUID) |
| `email` | String | Unique |
| `password` | String | Nullable (Omitted for Google OAuth) |
| `name` | String | |
| `regNo` | String | Nullable |
| `department` | String | Nullable |
| `year` | String | Nullable |
| `mobile` | String | Nullable |
| `cgpa` | Float | Nullable |
| `rewardPoints` | Int | Default: 0 |
| `activityPoints` | Int | Default: 0 |
| `profileImageUrl` | String | Nullable |
| `role` | Enum `UserRole` | Default: `MEMBER` *(ADMIN, CAPTAIN, VICE_CAPTAIN, STRATEGIST, MANAGER, MEMBER)* |
| `fcmToken` | String | Nullable (For push notifications) |
| `primarySkills` | String[] | Array, Default: `[]` |
| `secondarySkills` | String[] | Array, Default: `[]` |
| `specialSkills` | String[] | Array, Default: `[]` |
| `programmingLangs`| String[] | Array, Default: `[]` |
| `linkedinUrl` | String | Nullable |
| `githubUrl` | String | Nullable |
| `leetcodeUrl` | String | Nullable |
| `twitterUrl` | String | Nullable |
| `createdAt` | DateTime | Default: `now()` |
| `updatedAt` | DateTime | Auto-updates |
| `lastActive` | DateTime | Tracks real-time presence |

---

## 🚀 Projects & Operations

### 2. Personal Project (`personal_projects`)
| Column Name | Data Type | Modifiers / Notes |
| :--- | :--- | :--- |
| `id` | String | Primary Key (UUID) |
| `userId` | String | Foreign Key -> `User.id` (Cascades on delete) |
| `name` | String | |
| `description` | String | Nullable |
| `contribution` | String | Nullable |
| `githubLink` | String | Nullable |
| `liveLink` | String | Nullable |
| `skillsUsed` | String[] | Array, Default: `[]` |
| `createdAt` | DateTime | Default: `now()` |
| `updatedAt` | DateTime | |

### 3. Team Project (`team_projects`)
| Column Name | Data Type | Modifiers / Notes |
| :--- | :--- | :--- |
| `id` | String | Primary Key (UUID) |
| `projectName` | String | |
| `createdById` | String | Foreign Key -> `User.id` |
| `assignedCaptainId`| String | Foreign Key -> `User.id` (Nullable) |
| `domain` | String | Nullable |
| `subDomain` | String | Nullable |
| `problemStatement`| String | Nullable |
| `solution` | String | Nullable |
| `startDate` | DateTime | Nullable |
| `status` | Enum `ProjectStatus`| Default: `NOT_STARTED` *(IN_PROGRESS, COMPLETED, ON_HOLD)* |
| `createdAt` | DateTime | Default: `now()` |
| `updatedAt` | DateTime | |

### 4. Team Project Member (`team_project_members`) - *Relational Mapping*
| Column Name | Data Type | Modifiers / Notes |
| :--- | :--- | :--- |
| `id` | String | Primary Key (UUID) |
| `teamProjectId` | String | Foreign Key -> `TeamProject.id` |
| `userId` | String | Foreign Key -> `User.id` |
| `joinedAt` | DateTime | Default: `now()` |
> *Note: Enforces `@unique([teamProjectId, userId])` to prevent duplicate assignments.*

### 5. Project Milestone (`project_milestones`)
| Column Name | Data Type | Modifiers / Notes |
| :--- | :--- | :--- |
| `id` | String | Primary Key (UUID) |
| `projectId` | String | Foreign Key -> `TeamProject.id` |
| `title` | String | |
| `description` | String | Nullable |
| `dueDate` | DateTime | Nullable |
| `status` | String | Default: `"PENDING"` |
| `order` | Int | Default: `0` (For timeline sorting) |
| `createdAt` | DateTime | |
| `updatedAt` | DateTime | |

### 6. Project Update (`project_updates`)
| Column Name | Data Type | Modifiers / Notes |
| :--- | :--- | :--- |
| `id` | String | Primary Key (UUID) |
| `projectId` | String | Foreign Key -> `TeamProject.id` |
| `userId` | String | Foreign Key -> `User.id` |
| `title` | String | |
| `description` | String | Nullable |
| `date` | DateTime | Default: `now()` |
| `createdAt` | DateTime | Default: `now()` |

---

## 🧠 Continuous Learning & Advancement

### 7. Hackathon (`hackathons`)
| Column Name | Data Type | Modifiers / Notes |
| :--- | :--- | :--- |
| `id` | String | Primary Key (UUID) |
| `userId` | String | Foreign Key -> `User.id` |
| `hackName` | String | |
| `projectName` | String | Nullable |
| `description` | String | Nullable |
| `contribution` | String | Nullable |
| `skillsUsed` | String[] | Array, Default: `[]` |
| `date` | DateTime | Nullable |
| `isTeam` | Boolean | Default: `false` |
| `teamMembers` | String[] | Array, Default: `[]` |
| `status` | Enum `HackathonStatus`| Default: `UPCOMING` *(COMPLETED)*|
| `createdAt` | DateTime | |
| `updatedAt` | DateTime | |

### 8. Hackathon Round (`hackathon_rounds`) - *Relational Detail*
| Column Name | Data Type | Modifiers / Notes |
| :--- | :--- | :--- |
| `id` | String | Primary Key (UUID) |
| `hackathonId` | String | Foreign Key -> `Hackathon.id` |
| `roundName` | String | |
| `description` | String | Nullable |

### 9. Learning (`learnings`)
| Column Name | Data Type | Modifiers / Notes |
| :--- | :--- | :--- |
| `id` | String | Primary Key (UUID) |
| `userId` | String | Foreign Key -> `User.id` |
| `skillName` | String | |
| `topics` | String[] | Array, Default: `[]` |
| `startDate` | DateTime | Nullable |
| `endDate` | DateTime | Nullable |
| `level` | Enum `LearningLevel` | Default: `BEGINNER` *(INTERMEDIATE, EXPERT)* |
| `status` | Enum `LearningStatus`| Default: `ONGOING` *(COMPLETED)* |
| `createdAt` | DateTime | |
| `updatedAt` | DateTime | |

### 10. Certification (`certifications`)
| Column Name | Data Type | Modifiers / Notes |
| :--- | :--- | :--- |
| `id` | String | Primary Key (UUID) |
| `userId` | String | Foreign Key -> `User.id` |
| `skill` | String | |
| `provider` | String | Nullable |
| `description` | String | Nullable |
| `issuedDate` | DateTime | Nullable |
| `createdAt` | DateTime | |

### 11. PS Skill (`ps_skills`)
| Column Name | Data Type | Modifiers / Notes |
| :--- | :--- | :--- |
| `id` | String | Primary Key (UUID) |
| `userId` | String | Foreign Key -> `User.id` |
| `type` | Enum `SkillType` | `TECHNICAL` or `NON_TECHNICAL` |
| `skillName` | String | |
| `completed` | Boolean | Default: `false` |
| `createdAt` | DateTime | |
| `updatedAt` | DateTime | |

---

## 🎯 Task Delegation

### 12. Task Assignment (`task_assignments`)
| Column Name | Data Type | Modifiers / Notes |
| :--- | :--- | :--- |
| `id` | String | Primary Key (UUID) |
| `title` | String | |
| `description` | String | Nullable |
| `assignedById`| String | Foreign Key -> `User.id` (Delegator) |
| `assignedToId`| String | Foreign Key -> `User.id` (Executor) |
| `deadline` | DateTime | Nullable |
| `priority` | Enum `TaskPriority`| Default: `MEDIUM` *(LOW, HIGH)* |
| `status` | Enum `TaskStatus` | Default: `PENDING` *(IN_PROGRESS, COMPLETED, OVERDUE)* |
| `createdAt` | DateTime | |
| `updatedAt` | DateTime | |

### 13. Task Report (`task_reports`) 
| Column Name | Data Type | Modifiers / Notes |
| :--- | :--- | :--- |
| `id` | String | Primary Key (UUID) |
| `taskId` | String | Foreign Key -> `TaskAssignment.id` |
| `userId` | String | Foreign Key -> `User.id` |
| `reportText` | String | |
| `createdAt` | DateTime | |

---

## 📊 Analytics & Communications

### 14. Daily Activity (`daily_activities`)
| Column Name | Data Type | Modifiers / Notes |
| :--- | :--- | :--- |
| `id` | String | Primary Key (UUID) |
| `userId` | String | Foreign Key -> `User.id` |
| `type` | Enum `ActivityType` | `LEARNING`, `PROJECT`, `OTHERS` |
| `customType` | String | Nullable |
| `description` | String | Nullable |
| `startTime` | DateTime | |
| `endTime` | DateTime | |
| `date` | DateTime | |
| `createdAt` | DateTime | |

### 15. System Activity (`system_activities`) - *Admin Telemetry*
| Column Name | Data Type | Modifiers / Notes |
| :--- | :--- | :--- |
| `id` | String | Primary Key (UUID) |
| `userId` | String | Foreign Key -> `User.id` |
| `title` | String | |
| `content` | String | |
| `type` | String | Logs nature of event (Auth, Delete, Demotion) |
| `metadata` | Json | Nullable. Deep payload inspection object. |
| `createdAt` | DateTime | |

### 16. Team Message (`team_messages`) - *Global Chat*
| Column Name | Data Type | Modifiers / Notes |
| :--- | :--- | :--- |
| `id` | String | Primary Key (UUID) |
| `senderId` | String | Foreign Key -> `User.id` |
| `message` | String | Nullable |
| `imageUrl` | String | Nullable |
| `isPinned` | Boolean | Default: `false` |
| `timestamp` | DateTime | Default: `now()` |

### 17. Chat Conversation (`chat_conversations`) - *Private 1v1 / Group Container*
| Column Name | Data Type | Modifiers / Notes |
| :--- | :--- | :--- |
| `id` | String | Primary Key (UUID) |
| `createdAt` | DateTime | |
| `updatedAt` | DateTime | |

### 18. Chat Participant (`chat_participants`)
| Column Name | Data Type | Modifiers / Notes |
| :--- | :--- | :--- |
| `id` | String | Primary Key (UUID) |
| `conversationId`| String | Foreign Key -> `ChatConversation.id` |
| `userId` | String | Foreign Key -> `User.id` |
> *Note: `@unique([conversationId, userId])` prevents duplicate room bindings.*

### 19. Chat Message (`chat_messages`) - *Private Message Nodes*
| Column Name | Data Type | Modifiers / Notes |
| :--- | :--- | :--- |
| `id` | String | Primary Key (UUID) |
| `conversationId`| String | Foreign Key -> `ChatConversation.id` |
| `senderId` | String | Foreign Key -> `User.id` |
| `message` | String | Nullable |
| `imageUrl` | String | Nullable |
| `timestamp` | DateTime | Default: `now()` |
| `isPinned` | Boolean | Default: `false` |
