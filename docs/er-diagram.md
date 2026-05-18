# BBS Database -- ER Diagram

```mermaid
erDiagram
    PROJECTS ||--o{ PROJECT_DEPARTMENTS : "belongs to"
    DEPARTMENTS ||--o{ PROJECT_DEPARTMENTS : "hosts"
    PROJECTS ||--o{ PROJECT_CATEGORIES : "classified as"
    CATEGORIES ||--o{ PROJECT_CATEGORIES : "applies to"
    PROJECTS ||--o{ PROJECT_TAGS : "tagged with"
    TAGS ||--o{ PROJECT_TAGS : "describes"
    PROJECTS ||--o{ PROJECT_RESEARCHERS : "has"
    RESEARCHERS ||--o{ PROJECT_RESEARCHERS : "contributes to"
    PROJECTS ||--o{ PROJECT_LINKS : "external links"
    LINK_TYPES ||--o{ PROJECT_LINKS : "of type"
    PROJECTS ||--o{ PROJECT_ATTACHMENTS : "files"
    PROJECTS ||--o{ PROJECT_NOTES : "notes"
    PROJECTS ||--o{ PROJECTS : "parent / sub-project"
    STATUSES ||--o{ PROJECTS : "current status"
    LEVELS ||--o{ PROJECTS : "skill level"

    PROJECTS {
        int    project_id PK
        string title
        string slug
        string summary
        string description
        int    status_id FK
        int    level_id FK
        int    parent_project_id FK
        string semester
        string primary_url
        int    is_meta_project
    }
    DEPARTMENTS {
        int    department_id PK
        string code
        string name
        string slug
        string url
    }
    CATEGORIES {
        int    category_id PK
        string name
        string description
    }
    TAGS {
        int    tag_id PK
        string name
    }
    LEVELS {
        int    level_id PK
        string name
        int    sort_order
    }
    STATUSES {
        int    status_id PK
        string name
    }
    RESEARCHERS {
        int    researcher_id PK
        string full_name
        string affiliation
        string email
    }
    LINK_TYPES {
        int    link_type_id PK
        string name
    }
    PROJECT_DEPARTMENTS {
        int  project_id    PK,FK
        int  department_id PK,FK
        int  is_primary
    }
    PROJECT_CATEGORIES {
        int  project_id  PK,FK
        int  category_id PK,FK
    }
    PROJECT_TAGS {
        int  project_id PK,FK
        int  tag_id     PK,FK
    }
    PROJECT_RESEARCHERS {
        int    project_id    PK,FK
        int    researcher_id PK,FK
        string role          PK
    }
    PROJECT_LINKS {
        int    link_id      PK
        int    project_id   FK
        int    link_type_id FK
        string label
        string url
        int    is_canonical
    }
    PROJECT_ATTACHMENTS {
        int    attachment_id PK
        int    project_id    FK
        string file_name
        string file_path
        string mime_type
    }
    PROJECT_NOTES {
        int    note_id    PK
        int    project_id FK
        string body
        string author
        string created_at
    }
```

## Reading the diagram

- The center is `PROJECTS`. Everything else either describes a project (status, level, parent), classifies a project (department, category, tag, level), or hangs off a project (links, attachments, notes, researchers).
- All four "describes a project" relationships are many-to-many: a project can be in multiple departments and categories and have many tags and researchers.
- `parent_project_id` is a self-reference so the table also captures sub-project hierarchies (BSP > World Building, AI Image Generators Evaluation > Prompt 1/2/3/Rankings, etc.).
