import 'package:collection/collection.dart';

import '../../models/announcement.dart';
import '../../models/employee.dart';
import '../../models/message.dart';
import '../../models/project.dart';
import '../../models/support_ticket.dart';
import '../../../core/constants/roles.dart';

final List<Employee> mockEmployees = [
  const Employee(
    id: 'emp-001',
    firstName: 'C.K',
    lastName: 'Reddy',
    email: 'ck.reddy@artihcus.com',
    role: EmployeeRole.admin,
    department: 'Executive Leadership',
  ),
  const Employee(
    id: 'emp-002',
    firstName: 'Nara',
    lastName: 'Reddy',
    email: 'nara.reddy@artihcus.com',
    role: EmployeeRole.manager,
    department: 'Technology',
  ),
  const Employee(
    id: 'emp-003',
    firstName: 'Hari',
    lastName: 'Andluru',
    email: 'hari.andluru@artihcus.com',
    role: EmployeeRole.lead,
    department: 'Operations',
  ),
  const Employee(
    id: 'emp-004',
    firstName: 'Surendra',
    lastName: 'Gondipalli',
    email: 'surendra.g@artihcus.com',
    role: EmployeeRole.lead,
    department: 'Global Delivery',
  ),
  const Employee(
    id: 'emp-005',
    firstName: 'Aaradhya',
    lastName: 'Patel',
    email: 'aaradhya.patel@artihcus.com',
    role: EmployeeRole.employee,
    department: 'SAP EWM',
  ),
  const Employee(
    id: 'emp-006',
    firstName: 'Manish',
    lastName: 'Mathi',
    email: 'Goutham.Mathi@artihcus.com',
    role: EmployeeRole.employee,
    department: 'AI Solutions',
  ),
  const Employee(
    id: 'emp-007',
    firstName: 'Goutham',
    lastName: 'Mathi',
    email: 'goutham@artihcus.com',
    role: EmployeeRole.employee,
    department: 'People Operations',
  ),
];

final Map<String, String> mockCredentials = {
  for (final employee in mockEmployees) employee.email: 'Welcome@2025',
};

final now = DateTime.now();

final Map<String, List<Message>> mockMessagesByChannel = {
  'general': [
    Message(
      id: 'msg-001',
      channelId: 'general',
      senderId: 'emp-002',
      senderName: 'Nara Reddy',
      content:
          'Welcome to the Artihcus workspace! Let us know if you need onboarding support.',
      sentAt: now.subtract(const Duration(minutes: 45)),
      readBy: mockEmployees.map((e) => e.id).toList(),
    ),
    Message(
      id: 'msg-002',
      channelId: 'general',
      senderId: 'emp-005',
      senderName: 'Aaradhya Patel',
      content:
          'SAP EWM rollout at the Dubai warehouse completed. Great job team!',
      sentAt: now.subtract(const Duration(minutes: 18)),
      readBy: const ['emp-001', 'emp-002', 'emp-003'],
    ),
  ],
  'support': [
    Message(
      id: 'msg-003',
      channelId: 'support',
      senderId: 'emp-006',
      senderName: 'Manish Kumar',
      content:
          'Created ticket SUP-2025-031 on integration delays with SAP TM. Need infra input.',
      sentAt: now.subtract(const Duration(hours: 2)),
      readBy: const ['emp-003'],
    ),
  ],
};

final List<Announcement> mockAnnouncements = [
  Announcement(
    id: 'ann-001',
    title: 'Artihcus Q4 All-Hands',
    body:
        'Join the leadership team on Thursday for the Q4 business review and 2026 roadmap.',
    priority: AnnouncementPriority.high,
    publishedAt: now.subtract(const Duration(days: 1)),
    publishedBy: 'emp-001',
    targetRoles: EmployeeRole.values.toList(),
    acknowledgedBy: const ['emp-002', 'emp-003'],
  ),
  Announcement(
    id: 'ann-002',
    title: 'SAP BTP Upgrade Window',
    body:
        'Scheduled maintenance on Saturday 10:00-14:00 IST. Expect intermittent downtime across connected services.',
    priority: AnnouncementPriority.normal,
    publishedAt: now.subtract(const Duration(hours: 5)),
    publishedBy: 'emp-002',
    targetRoles: EmployeeRole.values.toList(),
    acknowledgedBy: const [],
  ),
];

final List<Project> mockProjects = [
  Project(
    id: 'proj-001',
    name: 'SAP EWM Implementation — UAE Retail',
    description:
        'End-to-end EWM deployment with MFS integration for the UAE flagship warehouse.',
    status: ProjectStatus.onTrack,
    ownerId: 'emp-003',
    progress: 0.72,
    dueDate: now.add(const Duration(days: 30)),
    teamMembers: const ['emp-003', 'emp-005', 'emp-006'],
    milestones: const [
      'Blueprint sign-off',
      'Integration testing',
      'User training',
    ],
  ),
  Project(
    id: 'proj-002',
    name: 'AI Copilot for Support Desk',
    description:
        'Deploy GenAI assistant to triage support tickets and recommend knowledge base solutions.',
    status: ProjectStatus.atRisk,
    ownerId: 'emp-002',
    progress: 0.45,
    dueDate: now.add(const Duration(days: 45)),
    teamMembers: const ['emp-002', 'emp-006'],
    milestones: const [
      'Model fine-tuning',
      'Pilot rollout',
      'Feedback iteration',
    ],
  ),
];

final List<SupportTicket> mockTickets = [
  SupportTicket(
    id: 'SUP-2025-031',
    subject: 'SAP TM interface latency',
    description:
        'Outbound deliveries sync failure to SAP TM for the EMEA region since 03:00 UTC.',
    status: SupportTicketStatus.inProgress,
    priority: SupportTicketPriority.high,
    createdBy: 'emp-006',
    createdAt: now.subtract(const Duration(hours: 6)),
    updatedAt: now.subtract(const Duration(hours: 2)),
    assignedTo: 'emp-003',
    tags: const ['SAP TM', 'Integration', 'Urgent'],
  ),
  SupportTicket(
    id: 'SUP-2025-028',
    subject: 'EWM RF scanner onboarding',
    description:
        'Need assistance provisioning 25 RF scanners for the new FMCG client in Mumbai.',
    status: SupportTicketStatus.open,
    priority: SupportTicketPriority.normal,
    createdBy: 'emp-005',
    createdAt: now.subtract(const Duration(days: 2)),
    tags: const ['EWM', 'Hardware'],
  ),
];

Employee? findEmployeeByEmail(String email) =>
    mockEmployees.firstWhereOrNull((employee) => employee.email == email);

Employee? findEmployeeById(String id) =>
    mockEmployees.firstWhereOrNull((employee) => employee.id == id);
