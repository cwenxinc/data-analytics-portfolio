# Staff Support Resource Allocation Analysis
This project was a collaboration between the Operations Department and Programs Department at Thaddeus Resource Center. 

Over three months, I partnered with a fellow Operations intern to design and administer a staff experience survey for the Programs Department using ***Microsoft Forms***, analyze responses in ***R*** to assess training and support needs, and develop data-driven recommendations to enhance staff satisfaction, operational efficiency, and client service delivery. Key deliverables include three stakeholder-specific ***PowerPoint presentations*** tailored to senior executives, the Programs Department, and the Operations Department.

## Project Background
The **Programs Department** provides services to clients across Southern California, primarily supporting at-risk youth, single mothers, and families in need. The department consists of six roles, each contributing to different aspects of client support:
- **Marriage and Family Therapist trainee** (hereafter referred to as "therapist"): Provides therapy sessions under the supervision of a licensed clinical practitioner
- **Case manager**: Assesses client needs, develops personalized care plans, connects clients with community resources, and monitors follow-through
- **Care coordinator**: Facilitates support groups and maintains relationships with clients and service partners
- **Life coach** Provides virtual one-on-one counseling to support clients' personal and professional development
- **Program developer & resource navigator** (hereafter referred to as "resource navigator"): A combined role focused on researching, verifying, and organizing external resources to support case managers, while also developing workshops, support groups, and other client-facing programs
- **Nonprofit leadership & management** (hereafter referred to as "nonprofit leadership"): Supports the executive team in supervising department operations and ensuring alignment with organizational goals

**The project consisted of two components: a staff experience survey and one-on-one interviews.** I led the survey design and analysis, while my project partner coordinated interview scheduling and documentation. Insights from both components were integrated to inform resource allocation recommendations.

The Programs Department had 29 staff members at the time of the project:
- Survey: 21 respondents (72% participation rate). Informed consent was obtained prior to participation, and responses were collected anonymously.
- Interviews: 11 participants (40% participation rate) representing a range of roles and tenure. Interviewees provided consent for recording and transcription, and their identities were kept confidential.

**The final analysis included all roles except life coaches** due to the absence of survey responses and interview participation from this group.

## Key Findings
- Staff reported high work satisfaction overall, though satisfaction varied by role and tenure. Care coordinators, nonprofit leadership, and resource navigators showed within-role differences, with **longer-tenured staff generally reporting lower satisfaction than newer-tenured staff**.
- Perceived productivity varied across roles, with nonprofit leadership reporting the greatest challenges with consistent task completion. Post-hoc ANOVA found that **only the difference between nonprofit leadership and resource navigators was statistically significant** (Tukey adjusted p-value = 0.039; 95% CI for difference in means excluded 0).
- **Client caseload showed role-specific relationships with perceived productivity**: higher caseloads were associated with higher perceived productivity among care coordinators (r = 0.86) and case managers (r = 0.46), but lower perceived productivity among therapists (r = -0.76).
- Perceived training adequacy was strongly associated with reported productivity across all roles, particularly among resource navigators (r = 0.96, Pearson correlation p-value = 0.00075). However, **training gaps varied by role**: nonprofit leadership reported broad needs across multiple areas, care coordinators and therapists prioritized client-focused training, and case managers requested additional technical training on internal tools.
- Management support emerged as another area for improvement, **particularly among nonprofit leadership and therapists, who reported weaker communication and troubleshooting support**. Higher perceived management support was associated with higher reported productivity across roles, with a marginally significant relationship among care coordinators (r = 0.93, Pearson correlation p-value = 0.07).

Because staff needs varied considerably by role, recommendations were tailored accordingly. Key recommendations included: 
- Developing role-specific training resources with different training priorities
- Designating and training department representatives to improve information flow between leadership and staff and streamline approval processes
- Consolidating reference materials and providing standardized templates for administrative tasks

## Directory Structure
```
data
├── programs_staff_experience_survey.pdf    - Original survey
├── programs_survey.csv                     - Raw survey results
├── programs_survey_clean.csv               - Cleaned survey results
└── variable_naming_scheme.pdf              - Descriptive naming scheme applied to survey questions
presentations
├── executive.pdf                           - Presentation for senior executive
├── operations.pdf                          - Presentation for Operations Department
└── programs.pdf                            - Presentation for Programs Department
scripts
├── survey_analysis.Rmd                     - Script that anaylzes cleaned survey data and outlines findings
└── survey_preprocessing.Rmd                - Script that cleans and encodes survey data
README.md
```
