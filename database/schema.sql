-- Esquema de base de datos para Agent Directory
-- SQLite

-- Tabla principal de agents
CREATE TABLE IF NOT EXISTS agents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    source TEXT NOT NULL, -- 'moltbook', 'manual', 'api'
    source_url TEXT,
    specialty TEXT DEFAULT 'general',
    karma INTEGER DEFAULT 0,
    follower_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    is_claimed BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TEXT,
    last_active TEXT,
    human_x_handle TEXT,
    human_x_name TEXT,
    human_x_followers INTEGER,
    human_x_verified BOOLEAN DEFAULT FALSE,
    scraped_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Tabla de skills (relación muchos-a-muchos)
CREATE TABLE IF NOT EXISTS skills (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    category TEXT, -- 'language', 'framework', 'domain', 'tool'
    description TEXT
);

-- Relación agent-skills
CREATE TABLE IF NOT EXISTS agent_skills (
    agent_id INTEGER,
    skill_id INTEGER,
    proficiency INTEGER DEFAULT 3, -- 1-5
    PRIMARY KEY (agent_id, skill_id),
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE,
    FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE
);

-- Tabla de reviews/ratings
CREATE TABLE IF NOT EXISTS reviews (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id INTEGER,
    reviewer_name TEXT,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TEXT NOT NULL,
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE
);

-- Tabla de búsquedas (analytics)
CREATE TABLE IF NOT EXISTS searches (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    query TEXT,
    filters TEXT, -- JSON de filtros usados
    results_count INTEGER,
    created_at TEXT NOT NULL
);

-- Tabla de categorías/especialidades
CREATE TABLE IF NOT EXISTS specialties (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    agent_count INTEGER DEFAULT 0
);

-- Insertar especialidades iniciales
INSERT OR IGNORE INTO specialties (name, description) VALUES
('security', 'Security audit, penetration testing, hardening'),
('devops', 'Infrastructure, CI/CD, Docker, Kubernetes'),
('data', 'Databases, data analysis, SQL, NoSQL'),
('frontend', 'UI/UX, React, Vue, CSS, HTML'),
('backend', 'APIs, servers, microservices'),
('automation', 'Bots, scripts, workflow automation'),
('scraping', 'Web scraping, crawlers, data extraction'),
('qa', 'Testing, QA automation, Cypress, Jest'),
('content', 'Technical writing, documentation, content'),
('research', 'Research, analysis, summarization'),
('general', 'General purpose agent, multiple skills'),
('blockchain', 'Web3, blockchain, smart contracts'),
('ml', 'Machine learning, AI, neural networks'),
('communication', 'Slack, Discord, Telegram integrations');

-- Insertar skills comunes
INSERT OR IGNORE INTO skills (name, category, description) VALUES
('typescript', 'language', 'TypeScript programming'),
('javascript', 'language', 'JavaScript/Node.js'),
('python', 'language', 'Python programming'),
('rust', 'language', 'Rust programming'),
('go', 'language', 'Go/Golang programming'),
('bash', 'language', 'Shell scripting'),
('sql', 'language', 'SQL databases'),
('react', 'framework', 'React.js framework'),
('vue', 'framework', 'Vue.js framework'),
('docker', 'tool', 'Docker containerization'),
('kubernetes', 'tool', 'Kubernetes orchestration'),
('git', 'tool', 'Git version control'),
('security', 'domain', 'Security and auditing'),
('testing', 'domain', 'QA and testing'),
('scraping', 'domain', 'Web scraping'),
('automation', 'domain', 'Process automation'),
('api', 'domain', 'API development'),
('database', 'domain', 'Database management');

-- Índices para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_agents_specialty ON agents(specialty);
CREATE INDEX IF NOT EXISTS idx_agents_karma ON agents(karma DESC);
CREATE INDEX IF NOT EXISTS idx_agents_active ON agents(is_active);
CREATE INDEX IF NOT EXISTS idx_agent_skills_agent ON agent_skills(agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_skills_skill ON agent_skills(skill_id);
CREATE INDEX IF NOT EXISTS idx_reviews_agent ON reviews(agent_id);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON reviews(rating);
