# Staff Support Resource Allocation Analysis
This project was a collaboration between the Operations Department and Programs Department at Thaddeus Resource Center. 

Over three months, I partnered with a fellow Operations intern to design and administer a staff experience survey for the Programs Department using ***Microsoft Forms***, analyze responses in ***R*** to assess training and support needs, and develop data-driven recommendations to enhance staff satisfaction, operational efficiency, and client service delivery. Key deliverables include three ***stakeholder-specific PowerPoint presentations*** tailored to senior executives, the Programs Department, and the Operations Department.

## Project Background
The **Programs Department** provides services to clients across Southern California, primarily supporting at-risk youth, single mothers, and families in need. The department consists of six roles, each contributing to different aspects of client support:
- **Marriage and Family Therapist trainee** (hereafter referred to as "therapist"): Provides therapy sessions under the supervision of a licensed clinical practitioner
- **Case manager**: Assesses client needs, develops personalized care plans, connects clients with community resources, and monitors follow-through
- **Care coordinator**: Facilitates support groups and maintains relationships with clients and service partners
- **Life coach** Provides virtual one-on-one counseling to support clients' personal and professional development
- **Program developer & resource navigator** (hereafter referred to as "resource navigator"): A combined role focused on researching, verifying, and organizing external resources to support case managers, while also developing workshops, support groups, and other client-facing programs
- **Nonprofit leadership & management** (hereafter referred to as "nonprofit leadership"): Supports the executive team in supervising department operations and ensuring alignment with organizational goals

The project consisted of two components: a **staff experience survey** and **one-on-one interviews**. I led the survey design and analysis, while my project partner coordinated interview scheduling and documentation. Insights from both components were integrated to inform resource allocation recommendations.

The Programs Department had 29 staff members at the time of the project:
- Survey: 21 respondents (72% participation rate). Informed consent was obtained prior to participation, and responses were collected anonymously.
- Interviews: 11 participants (40% participation rate) representing a range of roles and tenure. Interviewees provided consent for recording and transcription, and their identities were kept confidential.

The final analysis included all roles **except life coaches** due to the absence of survey responses and interview participation from this group.

## Key Findings


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
